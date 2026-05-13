import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/client_type.dart';
import '../config/client_config.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();

  FirebaseService._();

  static final StreamController<RemoteMessage> _notificationActionController =
      StreamController<RemoteMessage>.broadcast();

  /// Emite mensagens FCM que contêm redirect_cortesias: true.
  /// Escute este stream para acionar o fluxo de reservas.
  static Stream<RemoteMessage> get notificationActionStream =>
      _notificationActionController.stream;

  FirebaseApp? _currentApp;
  FirebaseMessaging? _messaging;
  FirebaseAnalytics? _analytics;
  ClientType? _currentClientType;

  FirebaseApp? get currentApp => _currentApp;
  FirebaseMessaging? get messaging => _messaging;
  FirebaseAnalytics? get analytics => _analytics;
  ClientType? get currentClientType => _currentClientType;

  Future<bool> initializeForClient(ClientType clientType) async {
    try {
      if (kDebugMode) {
        print('🔄 Inicializando Firebase Service para: $clientType');
      }

      // Se já está inicializado para o mesmo cliente, não fazer nada
      if (_currentClientType == clientType && _currentApp != null) {
        if (kDebugMode) {
          print('✅ Firebase já inicializado para: $clientType');
        }
        return true;
      }

      // Obter configuração do cliente
      final clientConfig = ClientConfig.fromClientType(clientType);

      // Nome único para cada app Firebase
      final appName = _getAppNameForClient(clientType);

      // Verificar se o app já foi inicializado
      try {
        _currentApp = Firebase.app(appName);
        if (kDebugMode) {
          print('📱 Firebase app já existe: $appName');
        }
      } catch (e) {
        // App não existe, vamos criar
        if (kDebugMode) {
          print('🔥 Criando novo Firebase app: $appName');
        }
        _currentApp = await Firebase.initializeApp(
          name: appName,
          options: clientConfig.firebaseOptions,
        );
      }

      _currentClientType = clientType;

      // Inicializar serviços do Firebase
      await _initializeFirebaseServices();

      if (kDebugMode) {
        print('✅ Firebase inicializado com sucesso para: $clientType');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro na inicialização do Firebase Service: $e');
      }
      return false;
    }
  }

  Future<void> _initializeFirebaseServices() async {
    if (_currentApp == null) return;

    try {
      // Inicializar Firebase Messaging
      _messaging = FirebaseMessaging.instance;

      // Inicializar Firebase Analytics
      _analytics = FirebaseAnalytics.instance;

      // Configurar notificações push
      await _setupPushNotifications();

      if (kDebugMode) {
        print('🔥 Serviços Firebase inicializados');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao inicializar serviços Firebase: $e');
      }
    }
  }

  Future<void> _setupPushNotifications() async {
    if (_messaging == null) return;

    try {
      // Solicitar permissão para notificações
      NotificationSettings settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('🔔 Permissão de notificação: ${settings.authorizationStatus}');
      }

      // Configurar APNS token no iOS
      if (Platform.isIOS) {
        // Aguardar o token APNS estar disponível
        _messaging!.onTokenRefresh.listen((fcmToken) {
          if (kDebugMode) {
            print('🔄 FCM Token atualizado: $fcmToken');
          }
        });

        // Tentar obter o token APNS com retry
        String? apnsToken;
        try {
          apnsToken = await _messaging!.getAPNSToken();
          if (apnsToken != null) {
            if (kDebugMode) {
              print('🍎 APNs Token obtido: $apnsToken');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print(' APNS token ainda não disponível');
          }
        }

        if (apnsToken == null && kDebugMode) {
          // print('⚠️ APNs Token não foi obtido');
        }
      }

      // Obter token FCM
      String? token = await _messaging!.getToken();
      if (token != null) {
        // Salvar token no SharedPreferences
        await _saveFCMToken(token);

        if (kDebugMode) {
          print('🎯 FCM Token: $token');
          print('💾 FCM Token salvo no local storage');
        }
      }

      // Configurar listener para atualização de token
      _messaging!.onTokenRefresh.listen((newToken) async {
        await _saveFCMToken(newToken);
        if (kDebugMode) {
          print('🔄 FCM Token atualizado e salvo: $newToken');
        }
      });

      // Configurar handlers de mensagens
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      if (kDebugMode) {
        print('✅ Notificações push configuradas com sucesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao configurar notificações push: $e');
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print(
        '📱 Mensagem recebida em foreground: ${message.notification?.title}',
      );
      print('📱 Dados da mensagem: ${message.data}');
    }
    if (_hasNotificationAction(message)) {
      _notificationActionController.add(message);
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      print('🚀 App aberto via notificação: ${message.notification?.title}');
      print('🚀 Dados da mensagem: ${message.data}');
    }
    if (_hasNotificationAction(message)) {
      _notificationActionController.add(message);
    }
  }

  /// Retorna true se a mensagem FCM contiver redirect_cortesias: true
  /// ou redirect_link com uma URL.
  static bool _hasNotificationAction(RemoteMessage message) {
    final cortesias = message.data['redirect_cortesias'];
    if (cortesias == 'true' || cortesias == true) return true;
    final link = message.data['redirect_link'];
    return link != null && (link as String).isNotEmpty;
  }

  // Salvar FCM Token no SharedPreferences
  Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao salvar FCM token: $e');
      }
    }
  }

  // Recuperar FCM Token do SharedPreferences
  static Future<String?> getSavedFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao recuperar FCM token: $e');
      }
      return null;
    }
  }

  Future<String?> getFCMToken() async {
    try {
      return await _messaging?.getToken();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao obter FCM token: $e');
      }
      return null;
    }
  }

  Future<void> logEvent(
    String eventName,
    Map<String, Object>? parameters,
  ) async {
    try {
      await _analytics?.logEvent(name: eventName, parameters: parameters);
      if (kDebugMode) {
        print('📊 Evento logado: $eventName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao logar evento: $e');
      }
    }
  }

  Future<void> setUserProperty(String name, String? value) async {
    try {
      await _analytics?.setUserProperty(name: name, value: value);
      if (kDebugMode) {
        print('👤 Propriedade do usuário definida: $name = $value');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao definir propriedade do usuário: $e');
      }
    }
  }

  Future<void> setUserId(String userId) async {
    try {
      await _analytics?.setUserId(id: userId);
      if (kDebugMode) {
        print('👤 User ID definido: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao definir User ID: $e');
      }
    }
  }

  Future<void> switchClient(ClientType newClientType) async {
    if (kDebugMode) {
      print('🔄 Mudando Firebase para cliente: $newClientType');
    }

    // Reinicializar para o novo cliente
    await initializeForClient(newClientType);
  }

  String _getAppNameForClient(ClientType clientType) {
    switch (clientType) {
      case ClientType.guara:
        return 'guara_app';
      case ClientType.valeDasMinas:
        return 'valedasminas_app';
    }
  }

  void dispose() {
    _currentApp = null;
    _messaging = null;
    _analytics = null;
    _currentClientType = null;
  }
}
