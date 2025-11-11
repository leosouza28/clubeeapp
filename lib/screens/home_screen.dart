import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/client_service.dart';
import '../services/api_service.dart';
import '../services/app_config_service.dart';
import '../services/auth_service.dart';
import '../models/calendario_model.dart';
import '../models/titulo_model.dart';
import 'account_screen.dart';
import 'reservas_screen.dart';
import 'contato_clube_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToAccount;

  const HomeScreen({super.key, this.onNavigateToAccount});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CalendarioModel? _calendario;
  bool _isLoadingCalendario = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, DiaFuncionamentoModel> _eventosCalendario = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _carregarCalendario();
    _verificarAcesso();
  }

  Future<void> _verificarAcesso() async {
    try {
      final authService = await AuthService.getInstance();
      final isAuthenticated = await authService.isAuthenticated();

      // Só verificar se estiver autenticado
      if (!isAuthenticated) return;

      final apiService = await ApiService.getInstance();
      final clientService = ClientService.instance;

      final response = await apiService.verificarAcesso(
        clientService.currentConfig.clientType,
      );

      if (response.success) {
        // print('✅ Acesso verificado com sucesso');
        // Você pode processar a resposta aqui se necessário
        if (response.data != null) {
          // print('📊 Dados de acesso: ${response.data}');
        }
      } else {
        // print('⚠️ Erro ao verificar acesso: ${response.error}');
      }
    } catch (e) {
      // print('❌ Erro ao verificar acesso: $e');
    }
  }

  Future<void> _carregarCalendario() async {
    setState(() {
      _isLoadingCalendario = true;
    });

    try {
      final apiService = await ApiService.getInstance();
      final clientService = ClientService.instance;

      final response = await apiService.getCalendario(
        clientService.currentConfig.clientType,
      );

      if (response.success && response.data != null) {
        setState(() {
          _calendario = CalendarioModel.fromJson(response.data!);
          _eventosCalendario = {};

          // Criar mapa de eventos para o calendário
          for (var dia in _calendario!.diasFuncionamento) {
            if (dia.dateTime != null) {
              final date = DateTime(
                dia.dateTime!.year,
                dia.dateTime!.month,
                dia.dateTime!.day,
              );
              _eventosCalendario[date] = dia;
            }
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao carregar calendário: ${response.error}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro inesperado: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCalendario = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientService = ClientService.instance;
    final config = clientService.currentConfig;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar com gradiente
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            if (config.iconPath != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 0.0),
                                child: Image.asset(
                                  config.iconPath!,
                                  width: 56,
                                  height: 56,
                                ),
                              ),
                            if (config.iconPath == null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.waves,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bem-vindo ao',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    config.appName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Conteúdo principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Botões principais com design moderno
                  _buildModernButtons(context),
                  const SizedBox(height: 24),

                  // Calendário visual
                  _buildCalendarioCard(),
                  const SizedBox(height: 24),

                  // Informações do dia selecionado (sempre renderizado)
                  _buildDayInfoCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernButtons(BuildContext context) {
    final appConfigService = AppConfigService.instance;
    final bilheteriaConfig = appConfigService.appConfig?.bilheteriaAppConfig;

    // Verificar se deve mostrar o botão de ingressos
    final shouldShowIngressos =
        bilheteriaConfig?.ativada == true &&
        bilheteriaConfig?.tipo == 'SITE_EXTERNO' &&
        (bilheteriaConfig?.urlSiteExterno.isNotEmpty ?? false);

    return Column(
      children: [
        // Primeira linha de botões
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context: context,
                title: 'Minha Conta',
                subtitle: 'Acesse seu plano',
                icon: Icons.account_circle_outlined,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                ),
                onTap: () => _navegarParaConta(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context: context,
                title: 'Reservas',
                subtitle: 'Faça suas reservas',
                icon: Icons.calendar_today_outlined,
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.purple.shade600],
                ),
                onTap: () => _navegarParaReservas(context),
              ),
            ),
          ],
        ),

        // Segunda linha - botão de ingressos (condicional)
        if (shouldShowIngressos) ...[
          const SizedBox(height: 12),
          _buildActionCard(
            context: context,
            title: 'Comprar Ingressos',
            subtitle: 'Adquira seus ingressos online',
            icon: Icons.confirmation_number_outlined,
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade600],
            ),
            onTap: () => _abrirSiteIngressos(),
            isWide: true,
          ),
        ],

        // Terceira linha - botão de contato
        const SizedBox(height: 12),
        _buildActionCard(
          context: context,
          title: 'Contato com o Clube',
          subtitle: 'Tire suas dúvidas conosco',
          icon: Icons.support_agent,
          gradient: LinearGradient(
            colors: [Colors.teal.shade400, Colors.teal.shade600],
          ),
          onTap: () => _navegarParaContato(context),
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
    bool isWide = false,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: isWide ? 80 : 120,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isWide
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      const Spacer(),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarioCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_month,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Programação',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildLoadingIndicator(),
              ],
            ),
            const SizedBox(height: 20),

            _buildCalendarioContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    if (_isLoadingCalendario) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCalendarioContent() {
    if (_calendario != null && _eventosCalendario.isNotEmpty) {
      return _buildWeekCalendar();
    } else if (!_isLoadingCalendario) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text(
            'Em breve você poderá acompanhar a programação de funcionamento do Parque, aguarde!',
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(40),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
  }

  Widget _buildWeekCalendar() {
    // Calcular o início da semana (domingo)
    final startOfWeek = _focusedDay.subtract(
      Duration(days: _focusedDay.weekday % 7),
    );

    return Column(
      children: [
        // Navegação de semanas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _focusedDay = _focusedDay.subtract(const Duration(days: 7));
                });
              },
            ),
            Text(
              _getWeekRangeText(startOfWeek),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _focusedDay = _focusedDay.add(const Duration(days: 7));
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Dias da semana
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final day = startOfWeek.add(Duration(days: index));
            final normalizedDay = DateTime(day.year, day.month, day.day);
            final evento = _eventosCalendario[normalizedDay];
            final isSelected =
                _selectedDay != null && isSameDay(_selectedDay!, normalizedDay);
            final isToday = isSameDay(DateTime.now(), normalizedDay);

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = normalizedDay;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : isToday
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isToday && !isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getWeekDayName(day.weekday % 7),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildEventIndicator(evento, isSelected),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEventIndicator(DiaFuncionamentoModel? evento, bool isSelected) {
    if (evento != null) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : _getStatusColor(evento.estado),
          shape: BoxShape.circle,
        ),
      );
    }
    return const SizedBox(height: 8);
  }

  Widget _buildHorarioColumn(DiaFuncionamentoModel evento) {
    if (evento.isAberto || evento.isAbrira) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('Horário', style: Theme.of(context).textTheme.bodySmall),
          Text(
            '${evento.horaInicio} - ${evento.horaFim}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  String _getWeekDayName(int weekday) {
    switch (weekday) {
      case 0:
        return 'Dom';
      case 1:
        return 'Seg';
      case 2:
        return 'Ter';
      case 3:
        return 'Qua';
      case 4:
        return 'Qui';
      case 5:
        return 'Sex';
      case 6:
        return 'Sáb';
      default:
        return '';
    }
  }

  String _getWeekRangeText(DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final monthNames = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];

    if (startOfWeek.month == endOfWeek.month) {
      return '${startOfWeek.day} - ${endOfWeek.day} ${monthNames[startOfWeek.month - 1]}';
    } else {
      return '${startOfWeek.day} ${monthNames[startOfWeek.month - 1]} - ${endOfWeek.day} ${monthNames[endOfWeek.month - 1]}';
    }
  }

  Widget _buildDayInfoCard() {
    if (_selectedDay == null) return const SizedBox.shrink();

    final normalizedDay = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );

    final evento = _eventosCalendario[normalizedDay];

    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Informações do Dia',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (evento != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getStatusColor(evento.estado).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(
                      evento.estado,
                    ).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(evento.estado),
                          color: _getStatusColor(evento.estado),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          evento.dataString.split('\n').first,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      evento.dataString.split('\n').last,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              evento.estado,
                              style: TextStyle(
                                color: _getStatusColor(evento.estado),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        _buildHorarioColumn(evento),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.help_outline, color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nenhuma informação disponível para este dia',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Aberto':
        return Colors.green;
      case 'Abrirá':
        return Colors.blue;
      case 'Fechado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Aberto':
        return Icons.check_circle;
      case 'Abrirá':
        return Icons.schedule;
      case 'Fechado':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  // Métodos de navegação e ações
  void _navegarParaConta(BuildContext context) {
    if (widget.onNavigateToAccount != null) {
      widget.onNavigateToAccount!(); // troca de aba
    } else {
      // Fallback opcional (se a HomeScreen for usada fora do tab layout)
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const AccountScreen()));
    }
  }

  void _navegarParaContato(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ContatoClubeScreen()));
  }

  Future<void> _navegarParaReservas(BuildContext context) async {
    // Verificar se está autenticado
    final authService = await AuthService.getInstance();
    final isAuthenticated = await authService.isAuthenticated();

    if (!isAuthenticated) {
      // Redirecionar para a aba de conta
      if (widget.onNavigateToAccount != null) {
        widget.onNavigateToAccount!();
      }
      return;
    }

    // Abrir bottomsheet direto com loading
    _mostrarBottomSheetTitulos(context);
  }

  Future<void> _mostrarBottomSheetTitulos(BuildContext context) async {
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
          // Carregar dados apenas na primeira vez
          if (isLoading && titulos == null && errorMessage == null) {
            _carregarTitulosParaReserva()
                .then((resultado) {
                  if (resultado.success && resultado.data != null) {
                    final todosTitulos = resultado.data!
                        .map((json) => TituloModel.fromJson(json))
                        .toList();

                    final titulosComCortesias = todosTitulos
                        .where((titulo) => titulo.totalCortesiasHoje >= 0)
                        .toList();

                    setModalState(() {
                      titulos = titulosComCortesias;
                      isLoading = false;

                      // Se não tem cortesias, definir mensagem
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

          Widget _buildTitulosCount(
            bool isLoading,
            List<TituloModel>? titulos,
          ) {
            if (!isLoading && titulos != null) {
              return Text(
                '${titulos.length} ${titulos.length == 1 ? 'título disponível' : 'títulos disponíveis'}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              );
            }
            return const SizedBox.shrink();
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
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Handle do bottom sheet
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 4),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Título
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
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                _buildTitulosCount(isLoading, titulos),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Conteúdo
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
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      icon: const Icon(Icons.close),
                                      label: const Text('Fechar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).primaryColor,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: titulos!.length,
                              itemBuilder: (context, index) {
                                final titulo = titulos![index];
                                return _buildTituloCardReserva(context, titulo);
                              },
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

    return await apiService.getTitulos(clientService.currentConfig.clientType);
  }

  Widget _buildTituloCardReserva(BuildContext context, TituloModel titulo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Fechar bottom sheet
          Navigator.pop(context);

          // Navegar para tela de reservas
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${titulo.nomeSerie} - ${titulo.titulo}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
              if (titulo.totalCortesiasHoje > 0) const SizedBox(height: 12),
              if (titulo.totalCortesiasHoje > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Cortesias disponíveis para hoje',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirSiteIngressos() async {
    final appConfigService = AppConfigService.instance;

    // Usar URL da bilheteria das configurações se disponível
    String? url =
        appConfigService.appConfig?.bilheteriaAppConfig.urlSiteExterno;

    // Fallback para URLs estáticas se não houver configuração
    if (url == null || url.isEmpty) {
      final clientService = ClientService.instance;
      switch (clientService.currentConfig.clientType.name) {
        case 'guara':
          url = 'https://ingressosguarapark.com.br/';
          break;
        case 'valeDasMinas':
          url = 'https://ingressosvaledasminas.com.br/';
          break;
        default:
          url = 'https://ingressosguarapark.com.br/';
      }
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Não foi possível abrir o link: $url')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao abrir o site: $e')));
      }
    }
  }
}
