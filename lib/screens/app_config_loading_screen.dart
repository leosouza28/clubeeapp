import 'package:flutter/material.dart';
import '../services/app_config_service.dart';
import '../services/client_service.dart';
import '../services/deep_link_service.dart';
import '../services/logging_service.dart';
import '../widgets/main_navigation.dart';
import 'cortesia_link_screen.dart';

class AppConfigLoadingScreen extends StatefulWidget {
  const AppConfigLoadingScreen({super.key});

  @override
  State<AppConfigLoadingScreen> createState() => _AppConfigLoadingScreenState();
}

class _AppConfigLoadingScreenState extends State<AppConfigLoadingScreen> {
  final AppConfigService _appConfigService = AppConfigService.instance;
  final ClientService _clientService = ClientService.instance;
  final DeepLinkService _deepLinkService = DeepLinkService.instance;
  final LoggingService _log = LoggingService.instance;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAppConfig();
  }

  Future<void> _loadAppConfig() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _appConfigService.loadAppConfig(
        _clientService.currentConfig.clientType,
      );

      if (response.success) {
        // Configurações carregadas com sucesso
        _log.success('App config loaded successfully');

        // Verificar se há deep link pendente
        await _processarDeepLinkPendente();
      } else {
        // Erro ao carregar configurações
        setState(() {
          _isLoading = false;
          _errorMessage = response.error ?? 'Erro desconhecido';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro inesperado: $e';
      });
    }
  }

  Future<void> _processarDeepLinkPendente() async {
    if (!mounted) return;

    final pendingLink = _deepLinkService.pendingDeepLink;

    if (pendingLink != null) {
      _log.info('🔗 Deep link pendente detectado: $pendingLink');
      final info = _deepLinkService.parseDeepLink(pendingLink);

      if (info != null) {
        _log.success('Deep link parseado: ${info.toString()}');

        // Limpar o link pendente antes de navegar
        _deepLinkService.clearPendingDeepLink();

        // Processar baseado no tipo
        switch (info.type) {
          case DeepLinkType.reservaViaLink:
            if (info.id != null) {
              _log.info('Navegando para CortesiaLinkScreen com ID: ${info.id}');

              // Navegar direto para a tela de cortesia
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) =>
                      CortesiaLinkScreen(cortesiaId: info.id!),
                ),
              );
              return; // Não navega para MainNavigation
            }
            break;

          default:
            // Para outros tipos, navega normalmente para MainNavigation
            // O MainNavigationScreen vai processar
            _log.info(
              'Tipo de deep link será processado pelo MainNavigation: ${info.type}',
            );
            break;
        }
      } else {
        _log.warning('Falha ao parsear deep link pendente');
      }
    }

    // Navegar para tela principal (se não navegou para outra tela)
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _clientService.currentConfig;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Ícone do aplicativo
                if (config.iconPath != null)
                  Image.asset(config.iconPath!, width: 100, height: 100),

                if (config.iconPath == null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.waves, size: 80, color: Colors.white),
                  ),

                const SizedBox(height: 32),

                // Nome do aplicativo
                Text(
                  config.appName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                Text(
                  'Bem-vindo!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Conteúdo baseado no estado
                if (_isLoading) ...[
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Carregando configurações...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erro ao carregar configurações',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loadAppConfig,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar Novamente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Informação adicional
                Text(
                  'O aplicativo precisa carregar as configurações\npara funcionar corretamente.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
