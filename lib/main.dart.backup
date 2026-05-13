import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/client_environment.dart';
import 'screens/app_config_loading_screen.dart';
import 'services/client_service.dart';
import 'services/firebase_service.dart';
import 'services/tracking_service.dart';
import 'services/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar cliente baseado no environment (dart-define) ou usar padrão
  final clientType = ClientEnvironment.clientType;
  ClientService.instance.setClient(clientType);

  // Inicializar Firebase para o cliente atual
  await FirebaseService.instance.initializeForClient(clientType);

  // Solicitar permissão de rastreamento (iOS)
  await TrackingService.instance.requestTrackingAuthorization();

  // Inicializar Deep Links
  await DeepLinkService.instance.initialize();

  // Imprimir informações do ambiente em debug
  ClientEnvironment.printEnvironmentInfo();

  runApp(const ClubeeApp());
}

class ClubeeApp extends StatefulWidget {
  const ClubeeApp({super.key});

  @override
  State<ClubeeApp> createState() => _ClubeeAppState();
}

class _ClubeeAppState extends State<ClubeeApp> {
  final ClientService _clientService = ClientService.instance;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final config = _clientService.currentConfig;

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: config.appName,
      theme: config.theme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),
      home: const AppConfigLoadingScreen(),
    );
  }
}
