import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cota_resort_model.dart';
import '../models/guia_cobranca_resort_model.dart';
import '../services/auth_service.dart';
import '../services/client_service.dart';
import '../utils/formatters.dart';

class CotaResortDetailsScreen extends StatefulWidget {
  final String cotaId;

  const CotaResortDetailsScreen({super.key, required this.cotaId});

  @override
  State<CotaResortDetailsScreen> createState() =>
      _CotaResortDetailsScreenState();
}

class _CotaResortDetailsScreenState extends State<CotaResortDetailsScreen> {
  bool _isLoadingDetails = true;
  bool _isLoadingParcelas = false;
  bool _isLoadingGuias = false;
  CotaResortModel? _cota;
  bool _isInadimplente = false;
  double _valorBruto = 0;
  double _valorJuros = 0;
  double _valorTotal = 0;
  String? _errorMessage;
  List<GuiaCobrancaResortModel> _guias = [];

  // Modo de negociação
  bool _modoNegociacao = false;
  final Set<int> _parcelasSelecionadas = {};
  bool _isParcelasPagasExpanded = false;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _parcelaKeys = {};

  @override
  void initState() {
    super.initState();
    _loadCotaDetails();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Scroll para a próxima parcela em aberto
  void _scrollParaProximaParcela(ParcelaModel parcelaAtual) {
    if (_cota?.parcelas == null) return;

    final parcelasEmAberto = _cota!.parcelas!.where((p) => !p.pago).toList();
    final indexAtual = parcelasEmAberto.indexWhere(
      (p) => p.identificador == parcelaAtual.identificador,
    );

    if (indexAtual >= 0 && indexAtual < parcelasEmAberto.length - 1) {
      // Pegar a próxima parcela
      final proximaParcela = parcelasEmAberto[indexAtual + 1];
      final proximaKey = _parcelaKeys[proximaParcela.identificador];

      // Scroll suave para a próxima parcela usando o GlobalKey
      if (proximaKey != null && proximaKey.currentContext != null) {
        Future.delayed(const Duration(milliseconds: 100), () {
          Scrollable.ensureVisible(
            proximaKey.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.2, // Mostrar a parcela 20% do topo da tela
          );
        });
      }
    }
  }

  // Carrega os detalhes da cota (sem parcelas)
  Future<void> _loadCotaDetails() async {
    setState(() {
      _isLoadingDetails = true;
      _errorMessage = null;
    });

    try {
      final authService = await AuthService.getInstance();
      final clientService = ClientService.instance;

      final result = await authService.getCotaResortDetails(
        clientService.currentConfig.clientType,
        widget.cotaId,
        getParcelas: false,
      );

      if (result.success && result.hasData) {
        final data = result.data!;
        final cotaData = data['cota_resort'];

        setState(() {
          _cota = CotaResortModel.fromJson(cotaData);
          _isInadimplente = data['is_inadimplente'] ?? false;
          _valorBruto = (data['valor_bruto'] ?? 0).toDouble();
          _valorJuros = (data['valor_juros'] ?? 0).toDouble();
          _valorTotal = (data['valor_total'] ?? 0).toDouble();
          _isLoadingDetails = false;
        });

        // Após carregar os detalhes, carregar as parcelas
        _loadParcelas();

        // Carregar as guias de negociação
        _loadGuias();
      } else {
        setState(() {
          _isLoadingDetails = false;
          _errorMessage = result.error ?? 'Erro ao carregar detalhes da cota';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingDetails = false;
        _errorMessage = 'Erro inesperado: $e';
      });
    }
  }

  // Carrega as parcelas da cota
  Future<void> _loadParcelas() async {
    setState(() {
      _isLoadingParcelas = true;
    });

    try {
      final authService = await AuthService.getInstance();
      final clientService = ClientService.instance;

      final result = await authService.getCotaResortDetails(
        clientService.currentConfig.clientType,
        widget.cotaId,
        getParcelas: true,
      );

      if (result.success && result.hasData) {
        final data = result.data!;
        final cotaData = data['cota_resort'];

        setState(() {
          _cota = CotaResortModel.fromJson(cotaData);
          _isInadimplente = data['is_inadimplente'] ?? false;
          _valorBruto = (data['valor_bruto'] ?? 0).toDouble();
          _valorJuros = (data['valor_juros'] ?? 0).toDouble();
          _valorTotal = (data['valor_total'] ?? 0).toDouble();
          _isLoadingParcelas = false;
        });
      } else {
        setState(() {
          _isLoadingParcelas = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Erro ao carregar parcelas'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingParcelas = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado ao carregar parcelas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Carrega as guias de negociação
  Future<void> _loadGuias() async {
    setState(() {
      _isLoadingGuias = true;
    });

    try {
      final authService = await AuthService.getInstance();
      final clientService = ClientService.instance;

      final result = await authService.getGuiasNegociacao(
        clientService.currentConfig.clientType,
        widget.cotaId,
      );

      if (result.success && result.hasData) {
        final data = result.data!;
        final lista = data['lista'] as List? ?? [];

        setState(() {
          _guias = lista
              .map((g) => GuiaCobrancaResortModel.fromJson(g))
              .toList();
          _isLoadingGuias = false;
        });

        // Verificar se tem alguma guia aguardando pagamento e abrir modal
        if (_guias.isNotEmpty) {
          try {
            final guiaAguardando = _guias.firstWhere(
              (g) => g.status == 'AGUARDANDO PAGAMENTO',
            );

            print(
              '🔍 DEBUG: Guia aguardando encontrada: ${guiaAguardando.codigo}',
            );

            if (mounted) {
              // Pequeno delay para garantir que a tela foi montada
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  print(
                    '🔍 DEBUG: Abrindo modal para guia ${guiaAguardando.codigo}',
                  );
                  _mostrarModalGuia(guiaAguardando);
                }
              });
            }
          } catch (e) {
            print('🔍 DEBUG: Nenhuma guia aguardando pagamento encontrada');
          }
        }
      } else {
        setState(() {
          _isLoadingGuias = false;
        });
      }
    } catch (e) {
      // log o erro
      setState(() {
        _isLoadingGuias = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoadingDetails
          ? _buildLoadingView()
          : _errorMessage != null
          ? _buildErrorView()
          : _buildDetailsView(),
      // Resumo flutuante quando em modo negociação
      bottomNavigationBar: _modoNegociacao && _parcelasSelecionadas.isNotEmpty
          ? _buildResumoFlutuante()
          : null,
    );
  }

  // View de loading
  Widget _buildLoadingView() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          backgroundColor: Theme.of(context).primaryColor,
        ),
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }

  // View de erro
  Widget _buildErrorView() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          backgroundColor: Theme.of(context).primaryColor,
          flexibleSpace: const FlexibleSpaceBar(title: Text('Erro')),
        ),
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadCotaDetails,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // View de detalhes
  Widget _buildDetailsView() {
    if (_cota == null) return const SizedBox();

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // AppBar com informações básicas
        SliverAppBar(
          expandedHeight: 160,
          floating: false,
          pinned: true,
          backgroundColor: _cota!.isAtivo ? Colors.green : Colors.grey,
          flexibleSpace: FlexibleSpaceBar(
            // title: Text('Cota do Resort', style: const TextStyle(fontSize: 18)),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _cota!.isAtivo
                      ? [Colors.green.shade700, Colors.green]
                      : [Colors.grey.shade700, Colors.grey],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _cota!.numeroContrato,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _cota!.statusContrato,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_isInadimplente) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'INADIMPLENTE',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Conteúdo
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informações da cota
                _buildInfoSection(),
                const SizedBox(height: 24),

                // Informações do usuário (se disponível)
                if (_cota!.usuario != null) ...[
                  _buildUsuarioSection(),
                  const SizedBox(height: 24),
                ],

                // Seção de valores
                if (_valorBruto > 0 || _valorTotal > 0) ...[
                  _buildValoresSection(),
                  const SizedBox(height: 24),
                ],

                // Seção de parcelas
                _buildParcelasSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Seção de informações básicas
  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Informações do Contrato',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Número do Contrato', _cota!.numeroContrato),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Valor Negociado',
              Formatters.currency(_cota!.valorNegociado),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Status', _cota!.statusContrato),
          ],
        ),
      ),
    );
  }

  // Seção de informações do usuário
  Widget _buildUsuarioSection() {
    final usuario = _cota!.usuario!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Dados do Titular',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Nome', usuario.nome),
            const SizedBox(height: 12),
            _buildInfoRow(
              'CPF/CNPJ',
              usuario.cpfCnpj.length == 11
                  ? Formatters.cpf(usuario.cpfCnpj)
                  : Formatters.cnpj(usuario.cpfCnpj),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Email', usuario.email),
            if (usuario.telefones.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Telefone', usuario.telefones.join(', ')),
            ],
          ],
        ),
      ),
    );
  }

  // Seção de valores
  Widget _buildValoresSection() {
    return Card(
      color: _isInadimplente ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isInadimplente ? Icons.warning : Icons.payments_outlined,
                  color: _isInadimplente
                      ? Colors.red
                      : Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _isInadimplente ? 'Valores em Aberto' : 'Resumo Financeiro',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isInadimplente ? Colors.red.shade900 : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_valorBruto > 0) ...[
              _buildInfoRow('Valor Bruto', Formatters.currency(_valorBruto)),
              const SizedBox(height: 12),
            ],
            if (_valorJuros > 0) ...[
              _buildInfoRow(
                'Juros',
                Formatters.currency(_valorJuros),
                valueColor: Colors.red,
              ),
              const SizedBox(height: 12),
            ],
            if (_valorTotal > 0) ...[
              const Divider(),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Valor Total',
                Formatters.currency(_valorTotal),
                valueStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Seção de guias de negociação
  Widget _buildGuiasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.receipt,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Histórico de Negociações',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingGuias)
          const Center(child: CircularProgressIndicator())
        else
          ..._guias.map((guia) => _buildGuiaCard(guia)),
      ],
    );
  }

  Widget _buildGuiaCard(GuiaCobrancaResortModel guia) {
    Color statusColor;
    IconData statusIcon;

    switch (guia.status) {
      case 'PAGA':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'CANCELADA':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _mostrarModalGuia(guia),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 24),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Guia #${guia.codigo}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            Formatters.dateTime(guia.data),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      guia.status,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${guia.quantidadeCobrancas} ${guia.quantidadeCobrancas == 1 ? "parcela" : "parcelas"}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  Text(
                    Formatters.currency(guia.valorTotal),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Seção de parcelas
  Widget _buildParcelasSection() {
    if (_isLoadingParcelas) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Carregando parcelas... isso pode demorar de 10 a 30 segundos, aguarde!',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_cota!.parcelas == null || _cota!.parcelas!.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Nenhuma parcela encontrada',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    // Separar parcelas em aberto e pagas
    final parcelasEmAberto = _cota!.parcelas!.where((p) => !p.pago).toList();
    final parcelasPagas = _cota!.parcelas!.where((p) => p.pago).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho e botão Negociar
        Row(
          children: [
            Icon(
              Icons.receipt_long,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Parcelas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (parcelasEmAberto.isNotEmpty && !_modoNegociacao)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _modoNegociacao = true;
                    _parcelasSelecionadas.clear();
                  });
                },
                icon: const Icon(Icons.handshake, size: 20),
                label: const Text('Negociar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            if (_modoNegociacao)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _modoNegociacao = false;
                    _parcelasSelecionadas.clear();
                  });
                },
                icon: const Icon(Icons.close),
                label: const Text('Cancelar'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Parcelas em aberto
        if (parcelasEmAberto.isNotEmpty) ...[
          Text(
            'Em Aberto (${parcelasEmAberto.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          ...parcelasEmAberto.map((parcela) => _buildParcelaCard(parcela)),
        ],

        // Botões de seleção rápida quando em modo negociação
        if (_modoNegociacao) ...[
          const SizedBox(height: 16),
          _buildBotoesSelecaoRapida(parcelasEmAberto),
        ],

        // Histórico de Negociações (entre parcelas em aberto e pagas)
        if (_guias.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildGuiasSection(),
        ],

        // Parcelas pagas (em accordion)
        if (parcelasPagas.isNotEmpty) ...[
          const SizedBox(height: 24),
          Card(
            child: ExpansionTile(
              title: Text(
                'Parcelas Pagas (${parcelasPagas.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              initiallyExpanded: _isParcelasPagasExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  _isParcelasPagasExpanded = expanded;
                });
              },
              children: parcelasPagas
                  .map(
                    (parcela) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildParcelaCard(parcela),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  // Resumo flutuante na parte inferior
  Widget _buildResumoFlutuante() {
    if (_cota == null || _cota!.parcelas == null) {
      return const SizedBox.shrink();
    }

    final parcelasEmAberto = _cota!.parcelas!.where((p) => !p.pago).toList();
    final parcelasSelecionadasList = parcelasEmAberto
        .where((p) => _parcelasSelecionadas.contains(p.identificador))
        .toList();

    double valorBrutoTotal = 0;
    double valorJurosTotal = 0;
    double valorCorrecaoTotal = 0;

    for (var parcela in parcelasSelecionadasList) {
      valorBrutoTotal += parcela.valorParcela;
      valorJurosTotal += parcela.valorJurosCalculado;
      valorCorrecaoTotal += parcela.valorCorrecaoMonetaria;
    }

    final valorTotal = valorBrutoTotal + valorJurosTotal + valorCorrecaoTotal;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: Colors.blue.shade50,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.summarize, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Resumo da Negociação',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildResumoRow(
                    'Parcelas Selecionadas',
                    '${_parcelasSelecionadas.length}',
                  ),
                  const SizedBox(height: 8),
                  _buildResumoRow(
                    'Valor Bruto',
                    Formatters.currency(valorBrutoTotal),
                  ),
                  const SizedBox(height: 8),
                  _buildResumoRow(
                    'Juros',
                    Formatters.currency(valorJurosTotal),
                    valueColor: Colors.red,
                  ),
                  if (valorCorrecaoTotal > 0) ...[
                    const SizedBox(height: 8),
                    _buildResumoRow(
                      'Correção Monetária',
                      Formatters.currency(valorCorrecaoTotal),
                      valueColor: Colors.red,
                    ),
                  ],
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildResumoRow(
                    'Valor Total',
                    Formatters.currency(valorTotal),
                    valueStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _confirmarNegociacao(parcelasEmAberto),
                icon: const Icon(Icons.check),
                label: const Text('Gerar PIX'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoRow(
    String label,
    String value, {
    TextStyle? valueStyle,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style:
              valueStyle ??
              TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
        ),
      ],
    );
  }

  // Botões de seleção rápida
  Widget _buildBotoesSelecaoRapida(List<ParcelaModel> parcelasEmAberto) {
    final totalParcelas = parcelasEmAberto.length;
    final List<int> opcoesParcelas = [];

    // Gerar botões de 6 em 6
    for (int i = 6; i <= totalParcelas; i += 6) {
      opcoesParcelas.add(i);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selecione rapidamente:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...opcoesParcelas.map(
                  (quantidade) => ElevatedButton(
                    onPressed: () =>
                        _selecionarPrimeiras(parcelasEmAberto, quantidade),
                    child: Text('$quantidade Parcelas'),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _selecionarTodas(parcelasEmAberto),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Quitar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selecionarPrimeiras(List<ParcelaModel> parcelas, int quantidade) {
    setState(() {
      _parcelasSelecionadas.clear();
      for (int i = 0; i < quantidade && i < parcelas.length; i++) {
        _parcelasSelecionadas.add(parcelas[i].identificador);
      }
    });
  }

  void _selecionarTodas(List<ParcelaModel> parcelas) {
    setState(() {
      _parcelasSelecionadas.clear();
      _parcelasSelecionadas.addAll(parcelas.map((p) => p.identificador));
    });
  }

  Future<void> _confirmarNegociacao(List<ParcelaModel> parcelasEmAberto) async {
    final parcelasSelecionadasList = parcelasEmAberto
        .where((p) => _parcelasSelecionadas.contains(p.identificador))
        .toList();

    double valorTotal = 0;
    for (var parcela in parcelasSelecionadasList) {
      valorTotal += parcela.valorParcela + parcela.valorJurosCalculado + parcela.valorCorrecaoMonetaria;
    }

    try {
      final authService = await AuthService.getInstance();
      final clientService = ClientService.instance;

      // Mostrar loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await authService.criarNegociacaoResort(
        clientService.currentConfig.clientType,
        widget.cotaId,
        _parcelasSelecionadas.toList(),
        valorTotal,
      );

      // Fechar loading
      if (!mounted) return;
      Navigator.pop(context);

      if (result.success && result.hasData) {
        final guia = GuiaCobrancaResortModel.fromJson(result.data!);
        setState(() {
          _modoNegociacao = false;
          _parcelasSelecionadas.clear();
        });
        _mostrarModalGuia(guia);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Erro ao criar negociação'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Fechar loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarModalGuia(GuiaCobrancaResortModel guia) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GuiaCobrancaResortDialog(
        guia: guia,
        cotaId: widget.cotaId,
        onStatusChange: () {
          // Recarregar parcelas quando status mudar
          _loadParcelas();
          // Recarregar guias também
          _loadGuias();
        },
      ),
    );
  }

  // Seção de parcelas (antiga)
  // Card de uma parcela
  Widget _buildParcelaCard(ParcelaModel parcela) {
    final isPaga = parcela.pago;
    final isVencida = parcela.isVencida;
    final isSelecionada = _parcelasSelecionadas.contains(parcela.identificador);

    // Criar ou obter a key para esta parcela
    _parcelaKeys.putIfAbsent(parcela.identificador, () => GlobalKey());

    Color backgroundColor;
    Color borderColor;
    if (isPaga) {
      backgroundColor = Colors.green.shade50;
      borderColor = Colors.green.shade300;
    } else if (isVencida) {
      backgroundColor = Colors.red.shade50;
      borderColor = Colors.red.shade300;
    } else {
      backgroundColor = Colors.blue.shade50;
      borderColor = Colors.blue.shade300;
    }

    // Se em modo negociação e parcela não paga, adicionar borda de seleção
    if (_modoNegociacao && !isPaga && isSelecionada) {
      borderColor = Colors.green.shade700;
      backgroundColor = Colors.green.shade100;
    }

    return Card(
      key: _parcelaKeys[parcela.identificador],
      margin: const EdgeInsets.only(bottom: 12),
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: borderColor,
          width: isSelecionada && _modoNegociacao ? 3 : 1,
        ),
      ),
      child: InkWell(
        onTap: _modoNegociacao && !isPaga
            ? () {
                setState(() {
                  if (isSelecionada) {
                    _parcelasSelecionadas.remove(parcela.identificador);
                  } else {
                    _parcelasSelecionadas.add(parcela.identificador);
                    // Scroll para a próxima parcela ao selecionar
                    _scrollParaProximaParcela(parcela);
                  }
                });
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Checkbox em modo negociação
                      if (_modoNegociacao && !isPaga) ...[
                        Checkbox(
                          value: isSelecionada,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _parcelasSelecionadas.add(
                                  parcela.identificador,
                                );
                                // Scroll para a próxima parcela ao selecionar
                                _scrollParaProximaParcela(parcela);
                              } else {
                                _parcelasSelecionadas.remove(
                                  parcela.identificador,
                                );
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: borderColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${parcela.nroParcela}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Parcela ${parcela.nroParcela}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            parcela.statusParcela,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isPaga
                          ? Colors.green
                          : isVencida
                          ? Colors.red
                          : Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isPaga
                          ? 'PAGO'
                          : isVencida
                          ? 'VENCIDA'
                          : 'A VENCER',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // Informações da parcela
              _buildParcelaInfo(
                'Vencimento',
                Formatters.dateFromString(parcela.dataVencimento),
              ),
              const SizedBox(height: 8),
              _buildParcelaInfo(
                'Valor',
                Formatters.currency(
                  !isPaga
                      ? (parcela.valorTotalComJuros > 0 ? parcela.valorTotalComJuros : parcela.valorParcela)
                      : parcela.valorParcela,
                ),
                valueStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 8),
              _buildParcelaInfo(
                'Meio de Pagamento',
                parcela.meioPagamentoCodigo,
              ),

              if (parcela.tipoParcelaDescricao.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildParcelaInfo('Tipo', parcela.tipoParcelaDescricao),
              ],

              if (isPaga) ...[
                const SizedBox(height: 8),
                _buildParcelaInfo(
                  'Data de Pagamento',
                  parcela.dataPagamento != null
                      ? Formatters.dateFromString(parcela.dataPagamento!)
                      : '-',
                ),
                const SizedBox(height: 8),
                _buildParcelaInfo(
                  'Valor Pago',
                  Formatters.currency(parcela.valorLiquido),
                ),
                if (parcela.valorAcrescimo > 0) ...[
                  const SizedBox(height: 8),
                  _buildParcelaInfo(
                    'Acréscimo',
                    Formatters.currency(parcela.valorAcrescimo),
                    valueColor: Colors.orange,
                  ),
                ],
              ],

              if (!_modoNegociacao && !isPaga && parcela.existeBoletoGerado && parcela.codigoBarrasBoleto != null && parcela.codigoBarrasBoleto!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: parcela.codigoBarrasBoleto!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Código de barras copiado!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_long, size: 18, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Boleto gerado',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Essa parcela já tem o boleto gerado, clique para copiar o código de pagamento. Você também pode pagar via PIX, basta usar o botão de Negociar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.shade300,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.copy, size: 16, color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Copiar Código',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper para construir uma linha de informação
  Widget _buildInfoRow(
    String label,
    String value, {
    TextStyle? valueStyle,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style:
                valueStyle ??
                TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
          ),
        ),
      ],
    );
  }

  // Helper para construir informação de parcela
  Widget _buildParcelaInfo(
    String label,
    String value, {
    TextStyle? valueStyle,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        Text(
          value,
          style:
              valueStyle ??
              TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
        ),
      ],
    );
  }
}

// Modal da Guia de Cobrança Resort
class GuiaCobrancaResortDialog extends StatefulWidget {
  final GuiaCobrancaResortModel guia;
  final String cotaId;
  final VoidCallback onStatusChange;

  const GuiaCobrancaResortDialog({
    super.key,
    required this.guia,
    required this.cotaId,
    required this.onStatusChange,
  });

  @override
  State<GuiaCobrancaResortDialog> createState() =>
      _GuiaCobrancaResortDialogState();
}

class _GuiaCobrancaResortDialogState extends State<GuiaCobrancaResortDialog> {
  GuiaCobrancaResortModel? _guiaAtualizada;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _guiaAtualizada = widget.guia;
    // Iniciar polling para verificar status
    _startPolling();
  }

  void _startPolling() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _guiaAtualizada!.status == 'AGUARDANDO PAGAMENTO') {
        _atualizarStatus();
      }
    });
  }

  Future<void> _atualizarStatus() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final authService = await AuthService.getInstance();
      final clientService = ClientService.instance;

      final result = await authService.getGuiaNegociacao(
        clientService.currentConfig.clientType,
        widget.cotaId,
        _guiaAtualizada!.id,
      );

      if (result.success && result.hasData) {
        final statusAnterior = _guiaAtualizada!.status;
        final guiaNova = GuiaCobrancaResortModel.fromJson(result.data!);

        print(
          '🔍 DEBUG: Status anterior: $statusAnterior, Status novo: ${guiaNova.status}',
        );

        setState(() {
          _guiaAtualizada = guiaNova;
          _isRefreshing = false;
        });

        // Detectar se pagamento foi confirmado
        if (statusAnterior == 'AGUARDANDO PAGAMENTO' &&
            guiaNova.status == 'PAGA') {
          print('🔍 DEBUG: PAGAMENTO DETECTADO! Mostrando alerta...');

          // Pagamento detectado! Mostrar alerta e depois fechar modal
          if (mounted) {
            // Mostrar alerta de sucesso
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Pagamento Confirmado!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Seu pagamento foi detectado e confirmado com sucesso.',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            );

            // Aguardar 3 segundos, fechar tudo e recarregar
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                // Fechar o alerta
                Navigator.of(context).pop();

                // Fechar o modal da guia
                Navigator.of(context).pop();

                // Notificar mudança de status (recarrega parcelas e guias)
                widget.onStatusChange();
              }
            });
          }
          return; // Não continuar polling
        }

        // Se status mudou para outro estado, notificar
        if (statusAnterior != guiaNova.status) {
          widget.onStatusChange();
        }

        // Continuar polling se ainda aguardando pagamento
        if (_guiaAtualizada!.status == 'AGUARDANDO PAGAMENTO') {
          _startPolling();
        }
      } else {
        setState(() {
          _isRefreshing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code_2, size: 32, color: Colors.grey[700]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Pagamento via PIX',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Conteúdo
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status da cobrança
                    _buildStatusChip(),
                    const SizedBox(height: 20),

                    // Informações em grid
                    _buildInfoGrid(),

                    // Verificar se PIX expirou ou ainda está válido
                    if (_guiaAtualizada!.status == 'AGUARDANDO PAGAMENTO' &&
                        _guiaAtualizada!.pix != null) ...[
                      const SizedBox(height: 24),
                      // Se expirou, mostrar aviso
                      if (_guiaAtualizada!.pix!.expiraEm.isBefore(
                        DateTime.now(),
                      ))
                        _buildPixExpirado()
                      // Se ainda válido, mostrar timer e código
                      else ...[
                        _buildTempoRestante(),
                        const SizedBox(height: 20),
                        _buildPixCopiaCola(),
                      ],
                      const SizedBox(height: 24),
                    ],

                    // Parcelas Incluídas
                    _buildParcelasIncluidas(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar quando o PIX expirou
  Widget _buildPixExpirado() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300, width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.timer_off, size: 64, color: Colors.orange.shade700),
          const SizedBox(height: 16),
          Text(
            'Pagamento Expirado',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'O prazo para pagamento deste PIX expirou. Para realizar o pagamento, você precisará gerar uma nova negociação.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          Text(
            'Expira em: ${Formatters.dateTime(_guiaAtualizada!.pix!.expiraEm)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTempoRestante() {
    if (_guiaAtualizada!.pix == null) return const SizedBox.shrink();

    final pix = _guiaAtualizada!.pix!;
    final expiraEm = pix.expiraEm;
    final agora = DateTime.now();
    final diferenca = expiraEm.difference(agora);
    final totalSegundos = pix.expiraEm.difference(pix.criadoEm).inSeconds;
    final segundosRestantes = diferenca.inSeconds.clamp(0, totalSegundos);
    final progresso = segundosRestantes / totalSegundos;

    final minutos = diferenca.inMinutes.clamp(0, double.infinity);
    final segundos = (diferenca.inSeconds % 60).clamp(0, 59);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Tempo Restante',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progresso,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
    final status = _guiaAtualizada!.status;
    IconData icon;
    String mensagem;
    Color cor;

    if (status == 'PAGA') {
      icon = Icons.check_circle;
      mensagem = 'Paga';
      cor = Colors.green;
    } else if (status == 'CANCELADA') {
      icon = Icons.cancel;
      mensagem = 'Cancelada';
      cor = Colors.red;
    } else {
      icon = Icons.schedule;
      mensagem = 'Aguardando Pagamento';
      cor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: cor),
          const SizedBox(width: 8),
          Text(
            mensagem,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Row(
      children: [
        Expanded(child: _buildInfoCard('Código', _guiaAtualizada!.codigo)),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            'Valor Total',
            Formatters.currency(_guiaAtualizada!.valorTotal),
            isHighlight: true,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlight ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlight ? Colors.green[200]! : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isHighlight ? Colors.green[900] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPixCopiaCola() {
    final pix = _guiaAtualizada!.pix!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Código PIX Copia e Cola',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1.5),
          ),
          child: Text(
            pix.pixCopiaECola,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
              fontFamily: 'monospace',
              height: 1.4,
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: pix.pixCopiaECola));

            // Mostrar toast usando overlay para aparecer acima do modal
            final overlay = Overlay.of(context);
            final overlayEntry = OverlayEntry(
              builder: (context) => Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Código PIX copiado!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );

            overlay.insert(overlayEntry);

            // Remover após 2 segundos
            Future.delayed(const Duration(seconds: 2), () {
              overlayEntry.remove();
            });
          },
          icon: const Icon(Icons.copy, size: 22),
          label: const Text(
            'Copiar Código PIX',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildParcelasIncluidas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Parcelas Incluídas:',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        ..._guiaAtualizada!.cobrancas.map((cobranca) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Parcela #${cobranca.nroParcela}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  Formatters.currency(cobranca.valorTotalComJuros),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
