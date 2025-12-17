import 'dart:async';
import 'package:flutter/material.dart';
import '../services/deep_link_service.dart';
import '../services/logging_service.dart';

/// Widget de exemplo que demonstra como processar deep links
///
/// Use este widget como referência para implementar processamento de deep links
/// em outras telas do app.
class DeepLinkHandlerWidget extends StatefulWidget {
  const DeepLinkHandlerWidget({super.key});

  @override
  State<DeepLinkHandlerWidget> createState() => _DeepLinkHandlerWidgetState();
}

class _DeepLinkHandlerWidgetState extends State<DeepLinkHandlerWidget> {
  final DeepLinkService _deepLinkService = DeepLinkService.instance;
  final LoggingService _log = LoggingService.instance;
  StreamSubscription<String>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();

    // 1. Verificar se há um deep link pendente (app aberto via deep link)
    _checkPendingDeepLink();

    // 2. Escutar novos deep links (app em background/foreground)
    _listenToDeepLinks();
  }

  /// Verifica se há um deep link pendente e processa
  void _checkPendingDeepLink() {
    final pendingLink = _deepLinkService.pendingDeepLink;

    if (pendingLink != null) {
      _log.info('Processing pending deep link: $pendingLink');
      _processDeepLink(pendingLink);
      _deepLinkService.clearPendingDeepLink();
    }
  }

  /// Escuta novos deep links em tempo real
  void _listenToDeepLinks() {
    _deepLinkSubscription = _deepLinkService.onDeepLink.listen((String link) {
      _log.info('New deep link received: $link');
      _processDeepLink(link);
    });
  }

  /// Processa um deep link e navega para a tela apropriada
  void _processDeepLink(String link) {
    final info = _deepLinkService.parseDeepLink(link);

    if (info == null) {
      _log.warning('Failed to parse deep link: $link');
      return;
    }

    _log.success('Deep link parsed: ${info.toString()}');

    // Navegar baseado no tipo de deep link
    switch (info.type) {
      case DeepLinkType.evento:
        _navigateToEvento(info.id, info.queryParams);
        break;

      case DeepLinkType.promocao:
        _navigateToPromocao(info.id, info.queryParams);
        break;

      case DeepLinkType.reservaViaLink:
        _navigateToReservaViaLink(info.id, info.queryParams);
        break;

      case DeepLinkType.profile:
        _navigateToProfile();
        break;

      case DeepLinkType.reservas:
        _navigateToReservas();
        break;

      case DeepLinkType.eventos:
        _navigateToEventos();
        break;

      case DeepLinkType.promocoes:
        _navigateToPromocoes();
        break;

      case DeepLinkType.home:
        _navigateToHome();
        break;

      case DeepLinkType.unknown:
        _log.warning('Unknown deep link type: ${info.route}');
        _showUnknownLinkDialog(link);
        break;
    }
  }

  /// Navega para a tela de evento específico
  void _navigateToEvento(String? id, Map<String, String> params) {
    if (id == null) {
      _log.warning('Evento ID is null');
      return;
    }

    _log.info('Navigating to evento: $id with params: $params');

    // Exemplo de navegação:
    // Navigator.of(context).pushNamed('/evento', arguments: id);

    // Ou com Navigator 2.0:
    // context.go('/evento/$id', extra: params);
  }

  /// Navega para a tela de promoção específica
  void _navigateToPromocao(String? id, Map<String, String> params) {
    if (id == null) {
      _log.warning('Promocao ID is null');
      return;
    }

    _log.info('Navigating to promocao: $id with params: $params');
    // Navigator.of(context).pushNamed('/promocao', arguments: id);
  }

  /// Navega para a tela de reserva via link
  void _navigateToReservaViaLink(String? id, Map<String, String> params) {
    if (id == null) {
      _log.warning('Reserva ID is null');
      return;
    }

    _log.info('Navigating to reserva via link: $id with params: $params');
    // Navigator.of(context).pushNamed('/reserva-via-link', arguments: id);
  }

  /// Navega para a tela de perfil
  void _navigateToProfile() {
    _log.info('Navigating to profile');
    // Navigator.of(context).pushNamed('/profile');
  }

  /// Navega para a tela de reservas
  void _navigateToReservas() {
    _log.info('Navigating to reservas');
    // Navigator.of(context).pushNamed('/reservas');
  }

  /// Navega para a tela de eventos
  void _navigateToEventos() {
    _log.info('Navigating to eventos');
    // Navigator.of(context).pushNamed('/eventos');
  }

  /// Navega para a tela de promoções
  void _navigateToPromocoes() {
    _log.info('Navigating to promocoes');
    // Navigator.of(context).pushNamed('/promocoes');
  }

  /// Navega para a home
  void _navigateToHome() {
    _log.info('Navigating to home');
    // Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Mostra dialog para link desconhecido
  void _showUnknownLinkDialog(String link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link não reconhecido'),
        content: Text('O link recebido não é reconhecido pelo app:\n\n$link'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Este é apenas um exemplo - não renderiza UI visível
    return const SizedBox.shrink();
  }
}

/// Exemplo de uso em uma tela específica:
///
/// ```dart
/// class MinhaTelaScreen extends StatefulWidget {
///   const MinhaTelaScreen({super.key});
///
///   @override
///   State<MinhaTelaScreen> createState() => _MinhaTelaScreenState();
/// }
///
/// class _MinhaTelaScreenState extends State<MinhaTelaScreen> {
///   StreamSubscription<String>? _deepLinkSubscription;
///
///   @override
///   void initState() {
///     super.initState();
///
///     // Escutar deep links
///     _deepLinkSubscription = DeepLinkService.instance.onDeepLink.listen((link) {
///       final info = DeepLinkService.instance.parseDeepLink(link);
///       if (info?.type == DeepLinkType.evento) {
///         // Processar evento
///         _handleEvento(info!.id);
///       }
///     });
///   }
///
///   @override
///   void dispose() {
///     _deepLinkSubscription?.cancel();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(title: const Text('Minha Tela')),
///       body: const Center(child: Text('Conteúdo')),
///     );
///   }
/// }
/// ```
