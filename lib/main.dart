import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/client_environment.dart';
import 'services/client_service.dart';
import 'services/firebase_service.dart';
import 'services/logging_service.dart';
import 'services/deep_link_service.dart';
import 'services/tracking_service.dart';
import 'screens/app_config_loading_screen.dart';
import 'screens/cortesia_link_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar cliente baseado no environment (dart-define) ou usar padrão
  final clientType = ClientEnvironment.clientType;
  ClientService.instance.setClient(clientType);

  // Inicializar Firebase para o cliente atual
  await FirebaseService.instance.initializeForClient(clientType);

  // Solicitar permissão de rastreamento (iOS)
  await TrackingService.instance.requestTrackingAuthorization();

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
  final LoggingService _log = LoggingService.instance;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    // Escutar por deep links
    _clientService.deepLinkService.onDeepLink.listen((link) {
      _log.debug('Deep link recebido: $link');
      _handleDeepLink(link);
    });
  }

  void _handleDeepLink(String link) {
    // Aqui você pode processar o deep link conforme necessário
    final deepLinkInfo = _clientService.deepLinkService.parseDeepLink(link);

    if (deepLinkInfo != null) {
      _log.debug('Deep link parsed: ${deepLinkInfo.route}');
      _log.debug('Type: ${deepLinkInfo.type}');
      _log.debug('ID: ${deepLinkInfo.id}');
      _log.debug('Parameters: ${deepLinkInfo.queryParams}');

      // Navegar para tela específica baseada no tipo
      if (deepLinkInfo.type == DeepLinkType.reservaViaLink &&
          deepLinkInfo.id != null) {
        _log.info('📍 Navegando para cortesia: ${deepLinkInfo.id}');

        // Usar navigatorKey para ter acesso ao Navigator
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) =>
                  CortesiaLinkScreen(cortesiaId: deepLinkInfo.id!),
            ),
          );
        });
      }
    }
  }

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
