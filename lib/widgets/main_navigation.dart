import 'dart:async';
import 'package:app_clubee/screens/discover_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/account_screen.dart';
import '../screens/cortesia_link_screen.dart';
import '../screens/home_screen.dart';
import '../screens/news_screen.dart';
import '../screens/reservas_screen.dart';
import '../models/titulo_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/client_service.dart';
import '../services/deep_link_service.dart';
import '../services/firebase_service.dart';
import '../services/logging_service.dart';
import '../widgets/titulos_carteirinhas_redirect_sheet.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  /// Tabs já visitadas — só essas entram no IndexedStack (lazy load).
  final Set<int> _initializedTabs = {0};
  final DeepLinkService _deepLinkService = DeepLinkService.instance;
  final LoggingService _log = LoggingService.instance;
  StreamSubscription<String>? _deepLinkSubscription;
  StreamSubscription<RemoteMessage>? _fcmActionSubscription;

  static const int accountIndex = 3;
  static const int discoverIndex = 1;
  static const int tabCount = 4;

  @override
  void initState() {
    super.initState();
    _initializeDeepLinks();
    _initializeFCMActions();
  }

  void _initializeDeepLinks() {
    // Verificar deep link pendente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingDeepLink();
    });

    // Escutar novos deep links
    _deepLinkSubscription = _deepLinkService.onDeepLink.listen((link) {
      _log.info('🔗 New deep link received in MainNavigation: $link');
      _processDeepLink(link);
    });
  }

  void _checkPendingDeepLink() {
    final pendingLink = _deepLinkService.pendingDeepLink;
    if (pendingLink != null) {
      _log.info('🔗 Processing pending deep link: $pendingLink');
      _processDeepLink(pendingLink);
      _deepLinkService.clearPendingDeepLink();
    }
  }

  void _initializeFCMActions() {
    // Escuta notificações FCM com redirect_cortesias ou redirect_link
    _fcmActionSubscription =
        FirebaseService.notificationActionStream.listen((message) {
      _log.info(
        '🔔 FCM action recebida: ${message.notification?.title} | data: ${message.data}',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleFcmAction(message.data);
      });
    });

    // Verifica se há mensagem pendente (recebida antes do listener estar ativo)
    final pendingMessage = FirebaseService.consumePendingActionMessage();
    if (pendingMessage != null) {
      _log.info(
        '🔔 FCM mensagem pendente encontrada: ${pendingMessage.notification?.title} | data: ${pendingMessage.data}',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleFcmAction(pendingMessage.data);
      });
    }

    // Trata app iniciado a partir de notificação (estado terminado)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null && _fcmHasNotificationAction(message)) {
        _log.info(
          '🔔 FCM initial message action: ${message.notification?.title}',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _handleFcmAction(message.data);
        });
      }
    });
  }

  bool _fcmHasNotificationAction(RemoteMessage message) {
    if (isNotificationRedirectFlag(message.data['redirect_carteirinhas'])) {
      return true;
    }
    if (isNotificationRedirectFlag(message.data['redirect_cortesias'])) {
      return true;
    }
    final link = message.data['redirect_link'];
    return link != null && (link as String).isNotEmpty;
  }

  void _handleFcmAction(Map<String, dynamic> data) {
    final link = data['redirect_link'];
    if (link != null && (link as String).isNotEmpty) {
      _abrirLink(link);
      return;
    }
    if (isNotificationRedirectFlag(data['redirect_carteirinhas'])) {
      _navegarParaCarteirinhas();
      return;
    }
    if (isNotificationRedirectFlag(data['redirect_cortesias'])) {
      _navegarParaReservas();
    }
  }

  Future<void> _abrirLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _mostrarErroLink();
      return;
    }

    // Deep links do app: processar internamente (não abrir browser)
    if (_isAppDeepLink(uri)) {
      _log.info('🔔 redirect_link interno via DeepLinkService: $url');
      _deepLinkService.simulateDeepLink(url);
      return;
    }

    try {
      final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!abriu && mounted) _mostrarErroLink();
    } catch (_) {
      if (mounted) _mostrarErroLink();
    }
  }

  bool _isAppDeepLink(Uri uri) {
    final config = ClientService.instance.currentConfig;
    if (uri.scheme == config.deepLinkScheme) return true;
    if (uri.scheme == 'https' || uri.scheme == 'http') {
      final host = uri.host.toLowerCase();
      final validHosts = [
        config.deepLinkHost.toLowerCase(),
        ...config.alternativeHosts.map((h) => h.toLowerCase()),
      ];
      return validHosts.contains(host);
    }
    return false;
  }

  void _mostrarErroLink() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Não foi possível abrir o link'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _navegarParaCarteirinhas() async {
    final authService = await AuthService.getInstance();
    final isAuthenticated = await authService.isAuthenticated();

    if (!isAuthenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Faça login para acessar suas carteirinhas'),
          ),
        );
      }
      return;
    }

    if (mounted) showTitulosCarteirinhasRedirectSheet(context);
  }

  Future<void> _navegarParaReservas() async {
    final authService = await AuthService.getInstance();
    final isAuthenticated = await authService.isAuthenticated();

    if (!isAuthenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Faça login para acessar suas reservas'),
          ),
        );
      }
      return;
    }

    if (mounted) _mostrarBottomSheetTitulos();
  }

  Future<void> _mostrarBottomSheetTitulos() async {
    List<TituloModel>? titulos;
    bool isLoading = true;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (stateContext, setModalState) {
          if (isLoading && titulos == null && errorMessage == null) {
            _carregarTitulosParaReserva()
                .then((resultado) {
                  if (resultado.success && resultado.data != null) {
                    final todosTitulos = resultado.data!
                        .map((json) => TituloModel.fromJson(json))
                        .toList();
                    final titulosComCortesias = todosTitulos
                        .where((t) => t.totalCortesiasHoje >= 0)
                        .toList();
                    setModalState(() {
                      titulos = titulosComCortesias;
                      isLoading = false;
                      if (titulosComCortesias.isEmpty) {
                        errorMessage =
                            'Você não possui cortesias disponíveis para hoje';
                      }
                    });
                  } else {
                    setModalState(() {
                      isLoading = false;
                      errorMessage =
                          resultado.error ?? 'Erro ao carregar títulos';
                    });
                  }
                })
                .catchError((e) {
                  setModalState(() {
                    isLoading = false;
                    errorMessage = 'Erro inesperado: $e';
                  });
                });
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (ctx, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 4),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.card_membership,
                              color: Theme.of(context).primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selecione o Título',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                if (!isLoading && titulos != null)
                                  Text(
                                    '${titulos!.length} ${titulos!.length == 1 ? 'título disponível' : 'títulos disponíveis'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.grey.shade600,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: isLoading
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Carregando títulos...',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : errorMessage != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 48,
                                      color: Colors.orange.shade300,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () => Navigator.pop(ctx),
                                      icon: const Icon(Icons.close),
                                      label: const Text('Fechar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(context).primaryColor,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: titulos!.length,
                              itemBuilder: (context, index) =>
                                  _buildTituloCardReserva(
                                    context,
                                    titulos![index],
                                  ),
                            ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>>
  _carregarTitulosParaReserva() async {
    final apiService = await ApiService.getInstance();
    final clientService = ClientService.instance;
    return apiService.getTitulos(clientService.currentConfig.clientType);
  }

  Widget _buildTituloCardReserva(BuildContext context, TituloModel titulo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReservasScreen(
                tituloId: titulo.id,
                tituloNome: titulo.nomeSerie,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${titulo.nomeSerie} - ${titulo.titulo}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _processDeepLink(String link) {
    final info = _deepLinkService.parseDeepLink(link);

    if (info == null) {
      _log.warning('Failed to parse deep link: $link');
      return;
    }

    _log.success('Deep link parsed: ${info.toString()}');

    // Aguardar frame para garantir que a tela está montada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      switch (info.type) {
        case DeepLinkType.profile:
          _onTabTapped(accountIndex);
          break;
        case DeepLinkType.home:
          _onTabTapped(0);
          break;
        case DeepLinkType.reservaViaLink:
          _deepLinkService.clearPendingDeepLink();
          if (info.id != null && info.id!.isNotEmpty) {
            _log.info('Navegando para CortesiaLinkScreen via MainNavigation: ${info.id}');
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CortesiaLinkScreen(cortesiaId: info.id!),
              ),
            );
          } else {
            _log.warning('Reserva via link sem ID');
            _onTabTapped(0);
          }
          break;
        case DeepLinkType.fcmTest:
          _deepLinkService.clearPendingDeepLink();
          if (kDebugMode) {
            _log.info('🧪 FCM test redirect: ${info.id}');
            switch (info.id) {
              case 'cortesias':
                FirebaseService.simulateNotificationAction({
                  'redirect_cortesias': '1',
                });
                break;
              case 'carteirinhas':
                FirebaseService.simulateNotificationAction({
                  'redirect_carteirinhas': '1',
                });
                break;
              case 'link':
                final url = info.queryParams['url'] ??
                    'guaraapp://reserva-via-link/6a53b328b71cbe79cc2d0c2a';
                FirebaseService.simulateNotificationAction({
                  'redirect_link': url,
                });
                break;
              default:
                _log.warning('fcm-test desconhecido: ${info.id}');
            }
          }
          break;
        default:
          // Outros tipos podem ser processados pela HomeScreen
          _onTabTapped(0);
          break;
      }
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _initializedTabs.add(index);
    });
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return HomeScreen(onNavigateToAccount: () => _onTabTapped(accountIndex));
      case discoverIndex:
        return DiscoverScreen(isActive: _currentIndex == discoverIndex);
      case 2:
        return const NewsScreen();
      case accountIndex:
        return const AccountScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    _fcmActionSubscription?.cancel();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      _onTabTapped(0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Antes: onWillPop()
          final shouldPop = _onWillPop();

          shouldPop.then((value) {
            if (value) Navigator.of(context).maybePop();
          });
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: List<Widget>.generate(tabCount, (index) {
            if (!_initializedTabs.contains(index)) {
              return const SizedBox.shrink();
            }
            return _buildTab(index);
          }),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore_sharp),
              label: 'Descubra',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article),
              label: 'Notícias',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Conta',
            ),
          ],
        ),
      ),
    );
  }
}
