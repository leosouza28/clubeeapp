import 'dart:async';
import 'package:flutter/services.dart';
import '../config/client_config.dart';
import '../config/client_type.dart';
import 'client_service.dart';
import 'logging_service.dart';

class DeepLinkService {
  static DeepLinkService? _instance;
  static DeepLinkService get instance =>
      _instance ??= DeepLinkService._internal();

  final _log = LoggingService.instance;
  String? _pendingDeepLink;

  // Stream para notificar sobre novos deep links
  final _deepLinkController = StreamController<String>.broadcast();
  Stream<String> get onDeepLink => _deepLinkController.stream;

  DeepLinkService._internal() {
    _log.debug('DeepLinkService instance created');
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
    // Canal para capturar deep links
    const platform = MethodChannel('app.clubee/deeplink');

    platform.setMethodCallHandler((call) async {
      if (call.method == 'routeUpdated') {
        final String link = call.arguments;
        _handleIncomingDeepLink(link);
      }
    });

    // Capturar link inicial (quando app é aberto via deep link)
    _getInitialLink();
  }

  /// Captura o link inicial se o app foi aberto via deep link
  Future<void> _getInitialLink() async {
    try {
      const platform = MethodChannel('app.clubee/deeplink');
      final String? initialLink = await platform.invokeMethod('getInitialLink');

      if (initialLink != null && initialLink.isNotEmpty) {
        _log.info('Initial deep link detected: $initialLink');
        _handleIncomingDeepLink(initialLink);
      }
    } catch (e) {
      _log.warning('Error getting initial link: $e');
    }
  }

  /// Processa deep link recebido
  void _handleIncomingDeepLink(String link) {
    _log.info('Processing deep link: $link');

    final config = ClientService.instance.currentConfig;

    if (_isValidDeepLink(Uri.parse(link), config)) {
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
