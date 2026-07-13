import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';

import '../config/client_config.dart';
import '../config/client_type.dart';
import 'client_service.dart';
import 'logging_service.dart';

class DeepLinkService {
  static DeepLinkService? _instance;
  static DeepLinkService get instance =>
      _instance ??= DeepLinkService._internal();

  static const MethodChannel _nativeChannel = MethodChannel(
    'app.clubee/deeplink',
  );

  final _log = LoggingService.instance;
  String? _pendingDeepLink;
  String? _lastHandledLink;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  // Stream para notificar sobre novos deep links
  final _deepLinkController = StreamController<String>.broadcast();
  Stream<String> get onDeepLink => _deepLinkController.stream;

  DeepLinkService._internal() {
    _log.debug('DeepLinkService instance created');
  }

  /// Inicializa o serviço de deep links
  Future<void> initialize() async {
    _log.info('Initializing DeepLinkService with app_links package');
    _appLinks = AppLinks();

    // Android: escuta o MethodChannel do MainActivity (fallback confiável)
    if (Platform.isAndroid) {
      _initializeNativeChannel();
    }

    // Capturar link inicial (quando app é aberto via deep link)
    await _getInitialLink();

    // Escutar novos links (quando app está em background/foreground)
    _initializeDeepLinkListener();
  }

  /// Link que está pendente para ser processado
  String? get pendingDeepLink => _pendingDeepLink;

  /// Limpa o deep link pendente (após processar)
  void clearPendingDeepLink() {
    _log.debug('Clearing pending deep link: $_pendingDeepLink');
    _pendingDeepLink = null;
  }

  /// Inicializa o listener de deep links
  void _initializeDeepLinkListener() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _log.info('New deep link received: $uri');
        _handleIncomingDeepLink(uri.toString());
      },
      onError: (Object error) {
        _log.error('Error listening to deep links: $error');
      },
    );
  }

  /// Fallback Android: MainActivity já captura o Intent num MethodChannel
  void _initializeNativeChannel() {
    _nativeChannel.setMethodCallHandler((call) async {
      if (call.method == 'routeUpdated') {
        final link = call.arguments as String?;
        if (link != null && link.isNotEmpty) {
          _log.info('Native Android deep link (routeUpdated): $link');
          _handleIncomingDeepLink(link);
        }
      }
    });
  }

  /// Captura o link inicial se o app foi aberto via deep link
  Future<void> _getInitialLink() async {
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();

      if (initialUri != null) {
        final String initialLink = initialUri.toString();
        _log.info('Initial deep link detected (app_links): $initialLink');
        _handleIncomingDeepLink(initialLink);
        return;
      }

      _log.debug('No initial deep link from app_links');
    } catch (e) {
      _log.warning('Error getting initial link from app_links: $e');
    }

    // Fallback Android: Intent capturado no MainActivity antes do Dart subir
    if (Platform.isAndroid) {
      await _getInitialLinkFromNative();
    }
  }

  Future<void> _getInitialLinkFromNative() async {
    try {
      final link = await _nativeChannel.invokeMethod<String>('getInitialLink');
      if (link != null && link.isNotEmpty) {
        _log.info('Initial deep link detected (native channel): $link');
        _handleIncomingDeepLink(link);
      } else {
        _log.debug('No initial deep link from native channel');
      }
    } catch (e) {
      _log.warning('Error getting initial link from native channel: $e');
    }
  }

  /// Processa deep link recebido
  void _handleIncomingDeepLink(String link) {
    _log.info('Processing deep link: $link');
    _log.debug('Previous pending link: $_pendingDeepLink');

    // Evita processar o mesmo link duas vezes (app_links + native)
    if (_lastHandledLink == link && _pendingDeepLink == link) {
      _log.debug('Ignoring duplicate deep link: $link');
      return;
    }

    final config = ClientService.instance.currentConfig;

    if (_isValidDeepLink(Uri.parse(link), config)) {
      _lastHandledLink = link;
      _pendingDeepLink = link;
      _deepLinkController.add(link);
      _log.success('Deep link stored and broadcasted: $link');
    } else {
      _log.warning('Invalid deep link rejected: $link');
    }
  }

  /// Inicializa o serviço para um cliente específico
  void initializeForClient(ClientType clientType) {
    _log.info('Deep link service initialized for ${clientType.displayName}');
  }

  /// Verifica se o deep link é válido para o cliente atual
  bool _isValidDeepLink(Uri uri, ClientConfig config) {
    // Verificar scheme (se presente)
    if (uri.hasScheme &&
        uri.scheme != config.deepLinkScheme &&
        uri.scheme != 'https') {
      return false;
    }

    // Verificar host (se presente) para links HTTPS
    if (uri.hasAuthority && uri.scheme == 'https') {
      final host = uri.host.toLowerCase();
      final validHosts = [
        config.deepLinkHost.toLowerCase(),
        ...config.alternativeHosts.map((h) => h.toLowerCase()),
      ];

      if (!validHosts.contains(host)) {
        return false;
      }
    }

    return true;
  }

  /// Gera URL de deep link para compartilhamento
  String generateDeepLink(String path, {Map<String, String>? queryParams}) {
    final config = ClientService.instance.currentConfig;
    final uri = Uri(
      scheme: 'https',
      host: config.deepLinkHost,
      path: path,
      queryParameters: queryParams?.isNotEmpty == true ? queryParams : null,
    );

    _log.debug('Generated deep link: $uri');
    return uri.toString();
  }

  /// Gera URL de scheme personalizado
  String generateSchemeUrl(String path, {Map<String, String>? queryParams}) {
    final config = ClientService.instance.currentConfig;
    final uri = Uri(
      scheme: config.deepLinkScheme,
      path: path,
      queryParameters: queryParams?.isNotEmpty == true ? queryParams : null,
    );

    _log.debug('Generated scheme URL: $uri');
    return uri.toString();
  }

  /// Processa um deep link e retorna informações estruturadas
  DeepLinkInfo? parseDeepLink(String? link) {
    if (link == null || link.isEmpty) return null;

    try {
      final uri = Uri.parse(link);
      final pathSegments = uri.pathSegments;

      _log.debug('🔍 Parsing deep link: $link');
      _log.debug('🔍 URI scheme: ${uri.scheme}');
      _log.debug('🔍 URI host: ${uri.host}');
      _log.debug('🔍 URI path: ${uri.path}');
      _log.debug('🔍 Path segments: $pathSegments');

      // Para URLs com scheme customizado (guaraapp://), a rota fica no host
      // Para URLs https, a rota fica no primeiro pathSegment
      final routeIdentifier = uri.host.isNotEmpty
          ? uri.host
          : (pathSegments.isNotEmpty ? pathSegments.first : '');

      _log.debug('🔍 Route identifier: $routeIdentifier');

      if (routeIdentifier.isEmpty) {
        return DeepLinkInfo(
          originalUrl: link,
          route: '/',
          type: DeepLinkType.home,
        );
      }

      switch (routeIdentifier) {
        case 'evento':
          return DeepLinkInfo(
            originalUrl: link,
            route: '/evento',
            type: DeepLinkType.evento,
            id: pathSegments.length > 1 ? pathSegments[1] : null,
            queryParams: uri.queryParameters,
          );

        case 'promocao':
          return DeepLinkInfo(
            originalUrl: link,
            route: '/promocao',
            type: DeepLinkType.promocao,
            id: pathSegments.length > 1 ? pathSegments[1] : null,
            queryParams: uri.queryParameters,
          );

        case 'profile':
          return DeepLinkInfo(
            originalUrl: link,
            route: '/profile',
            type: DeepLinkType.profile,
            queryParams: uri.queryParameters,
          );

        case 'reservas':
          return DeepLinkInfo(
            originalUrl: link,
            route: '/reservas',
            type: DeepLinkType.reservas,
            queryParams: uri.queryParameters,
          );

        case 'eventos':
          return DeepLinkInfo(
            originalUrl: link,
            route: '/eventos',
            type: DeepLinkType.eventos,
            queryParams: uri.queryParameters,
          );

        case 'promocoes':
          return DeepLinkInfo(
            originalUrl: link,
            route: '/promocoes',
            type: DeepLinkType.promocoes,
            queryParams: uri.queryParameters,
          );

        case 'reserva-via-link':
          String? id;
          // Se o host for "reserva-via-link", é scheme customizado
          if (uri.host == 'reserva-via-link') {
            id = pathSegments.isNotEmpty ? pathSegments[0] : null;
            _log.debug(
              '🔍 Custom scheme detected - ID from pathSegments[0]: $id',
            );
          } else {
            // É HTTPS, ID está no segundo segmento
            id = pathSegments.length > 1 ? pathSegments[1] : null;
            _log.debug('🔍 HTTPS detected - ID from pathSegments[1]: $id');
          }
          _log.info('📍 Reserva via link - ID: $id');

          return DeepLinkInfo(
            originalUrl: link,
            route: '/reserva-via-link',
            type: DeepLinkType.reservaViaLink,
            id: id,
            queryParams: uri.queryParameters,
          );

        case 'fcm-test':
          // Debug: simula toque em notificação push
          // guaraapp://fcm-test/cortesias
          // guaraapp://fcm-test/carteirinhas
          // guaraapp://fcm-test/link?url=guaraapp://reserva-via-link/ID
          final action = uri.host == 'fcm-test'
              ? (pathSegments.isNotEmpty ? pathSegments[0] : null)
              : (pathSegments.length > 1
                  ? pathSegments[1]
                  : (pathSegments.isNotEmpty ? pathSegments[0] : null));
          return DeepLinkInfo(
            originalUrl: link,
            route: '/fcm-test',
            type: DeepLinkType.fcmTest,
            id: action,
            queryParams: uri.queryParameters,
          );

        default:
          return DeepLinkInfo(
            originalUrl: link,
            route: '/${pathSegments.join('/')}',
            type: DeepLinkType.unknown,
            queryParams: uri.queryParameters,
          );
      }
    } catch (e) {
      _log.error('Error parsing deep link: $link - $e');
      return null;
    }
  }

  /// Simula recebimento de deep link (para testes)
  void simulateDeepLink(String link) {
    _log.debug('Simulating deep link: $link');
    _handleIncomingDeepLink(link);
  }

  void dispose() {
    _linkSubscription?.cancel();
    _deepLinkController.close();
  }
}

// Enums e classes auxiliares
enum DeepLinkType {
  home,
  evento,
  promocao,
  profile,
  reservas,
  eventos,
  promocoes,
  reservaViaLink,
  fcmTest,
  unknown,
}

class DeepLinkInfo {
  final String originalUrl;
  final String route;
  final DeepLinkType type;
  final String? id;
  final Map<String, String> queryParams;

  DeepLinkInfo({
    required this.originalUrl,
    required this.route,
    required this.type,
    this.id,
    this.queryParams = const {},
  });

  @override
  String toString() {
    return 'DeepLinkInfo(route: $route, type: $type, id: $id, params: $queryParams)';
  }
}
