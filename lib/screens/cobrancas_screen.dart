import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../models/cobranca_model.dart';
import '../models/negociacao_model.dart';
import '../services/client_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class CobrancasScreen extends StatefulWidget {
  final String tituloId;
  final String tituloNome;

  const CobrancasScreen({
    super.key,
    required this.tituloId,
    required this.tituloNome,
  });

  @override
  State<CobrancasScreen> createState() => _CobrancasScreenState();
}

class _CobrancasScreenState extends State<CobrancasScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  CobrancasResponseModel? _cobrancasData;
  List<NegociacaoResponseModel>? _guiasData;
  bool _isLoading = true;
  bool _isLoadingGuias = true;
  bool _isCreatingNegociation = false;
  String? _error;
  String? _errorGuias;
  bool _isSelectionMode = false;
  final Set<String> _selectedCobrancas = {};

  // Variáveis para verificação de status da guia
  Timer? _statusCheckTimer;
  Timer? _countdownTimer;
  int _countdownSeconds = 10;

  // ValueNotifiers para atualizar o bottom sheet
  final ValueNotifier<bool> _isPaymentConfirmedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isCheckingStatusNotifier = ValueNotifier(false);
  final ValueNotifier<int> _countdownSecondsNotifier = ValueNotifier(10);

  Map<String, double> _calcularTotais() {
    if (_cobrancasData == null) {
      return {'bruto': 0.0, 'juros': 0.0, 'total': 0.0};
    }

    double valorBruto = 0.0;
    double valorJuros = 0.0;
    double valorTotal = 0.0;

    for (var cobranca in _cobrancasData!.lista) {
      if (_selectedCobrancas.contains(cobranca.id)) {
        valorBruto += cobranca.valor;
        valorJuros += cobranca.juros;
        valorTotal += cobranca.total;
      }
    }

    return {'bruto': valorBruto, 'juros': valorJuros, 'total': valorTotal};
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController?.addListener(() {
      setState(() {
        // Atualiza o estado quando muda de aba para mostrar/ocultar o FAB
      });
    });
    _loadCobrancas();
    _loadGuias();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _countdownTimer?.cancel();
    _isPaymentConfirmedNotifier.dispose();
    _isCheckingStatusNotifier.dispose();
    _countdownSecondsNotifier.dispose();
    super.dispose();
  }

  // Método para verificar o status da guia a cada 10 segundos
  void _startStatusCheck(String guiaId, String currentStatus) {
    // Só iniciar se o status atual for AGUARDANDO PAGAMENTO
    if (currentStatus.toUpperCase() != 'AGUARDANDO PAGAMENTO') return;

    _statusCheckTimer?.cancel();
    _countdownTimer?.cancel();

    // Ativar indicador de verificação usando notifiers
    _countdownSeconds = 10;
    _isCheckingStatusNotifier.value = true;
    _countdownSecondsNotifier.value = 10;

    if (mounted) {
      setState(() {});
    }

    // Timer único que faz countdown de 1 em 1 segundo
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Decrementar
      _countdownSeconds--;
      _countdownSecondsNotifier.value = _countdownSeconds;
      if (mounted) {
        setState(() {});
      }

      // Quando chegar a 0, fazer verificação e resetar
      if (_countdownSeconds <= 0) {
        _checkGuiaStatus(guiaId, currentStatus);
        _countdownSeconds = 10;
        _countdownSecondsNotifier.value = 10;
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  Future<void> _checkGuiaStatus(String guiaId, String currentStatus) async {
    try {
      final clientService = ClientService.instance;
      final authService = await AuthService.getInstance();

      final result = await authService.getGuiaById(
        clientService.currentConfig.clientType,
        guiaId,
      );

      if (result.success && result.data != null) {
        final newStatus = result.data!['status'] as String? ?? '';

        // Se mudou de AGUARDANDO PAGAMENTO para PAGA
        if (currentStatus.toUpperCase() == 'AGUARDANDO PAGAMENTO' &&
            newStatus.toUpperCase() == 'PAGA') {
          _isPaymentConfirmedNotifier.value = true;
          _isCheckingStatusNotifier.value = false;

          if (mounted) {
            setState(() {});
          }

          _countdownTimer?.cancel();
        }
      }
    } catch (e) {
      // print('❌ Erro ao verificar status da guia: $e');
    }
  }

  void _stopStatusCheck() {
    _countdownTimer?.cancel();
    _countdownTimer = null;

    _countdownSeconds = 10;

    _isPaymentConfirmedNotifier.value = false;
    _isCheckingStatusNotifier.value = false;
    _countdownSecondsNotifier.value = 10;

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadCobrancas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final clientService = ClientService.instance;
      final authService = await AuthService.getInstance();

      final result = await authService.getTituloCobrancas(
        clientService.currentConfig.clientType,
        widget.tituloId,
      );

      if (result.success && result.data != null) {
        setState(() {
          _cobrancasData = CobrancasResponseModel.fromJson(result.data!);
          _isLoading = false;
        });
      } else if (result.isConnectionError) {
        setState(() {
          _error = 'Falha de conexão: ${result.error}';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result.error ?? 'Não foi possível carregar as cobranças';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro inesperado: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGuias() async {
    setState(() {
      _isLoadingGuias = true;
      _errorGuias = null;
    });

    try {
      final clientService = ClientService.instance;
      final authService = await AuthService.getInstance();

      final result = await authService.getTituloGuias(
        clientService.currentConfig.clientType,
        widget.tituloId,
      );

      if (result.success && result.data != null) {
        setState(() {
          _guiasData = result.data!
              .map(
                (e) =>
                    NegociacaoResponseModel.fromJson(e as Map<String, dynamic>),
              )
              .toList();
          _isLoadingGuias = false;
        });
      } else if (result.isConnectionError) {
        setState(() {
          _errorGuias = 'Falha de conexão: ${result.error}';
          _isLoadingGuias = false;
        });
      } else {
        setState(() {
          _errorGuias = result.error ?? 'Não foi possível carregar as guias';
          _isLoadingGuias = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorGuias = 'Erro inesperado: $e';
        _isLoadingGuias = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedCobrancas.length} selecionada(s)')
            : const Text('Financeiro'),
        elevation: 0,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedCobrancas.clear();
                  });
                },
              )
            : null,
        actions: _isSelectionMode
            ? [
                if (_selectedCobrancas.isNotEmpty)
                  IconButton(
                    icon: _isCreatingNegociation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.payment),
                    onPressed: _isCreatingNegociation ? null : _criarNegociacao,
                    tooltip: 'Pagar Várias',
                  ),
              ]
            : null,
        bottom: !_isSelectionMode && _tabController != null
            ? TabBar(
                controller: _tabController!,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Cobranças'),
                  Tab(text: 'Guias'),
                ],
              )
            : null,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ),
      body: _isSelectionMode
          ? Stack(
              children: [
                _buildCobrancasTab(),
                if (_selectedCobrancas.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildTotalizadorCard(),
                  ),
              ],
            )
          : _tabController != null
          ? TabBarView(
              controller: _tabController!,
              children: [_buildCobrancasTab(), _buildGuiasTab()],
            )
          : _buildCobrancasTab(),
      floatingActionButton:
          !_isSelectionMode &&
              _tabController != null &&
              _tabController!.index == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _isSelectionMode = true;
                });
              },
              icon: const Icon(Icons.check_box_outlined, color: Colors.white),
              label: const Text(
                'Negociar',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Theme.of(context).primaryColor,
            )
          : null,
    );
  }

  Widget _buildCobrancasTab() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando cobranças...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadCobrancas,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_cobrancasData == null || _cobrancasData!.lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma cobrança encontrada',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCobrancas,
      child: ListView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: _isSelectionMode && _selectedCobrancas.isNotEmpty ? 180 : 16,
        ),
        children: [
          _buildResumoCard(),
          const SizedBox(height: 16),
          _buildTituloInfo(),
          const SizedBox(height: 16),
          ..._cobrancasData!.lista.map(
            (cobranca) => _buildCobrancaCard(cobranca),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoCard() {
    final pendencias = _cobrancasData!.pendenciasFinanceiras;
    final isEmDia = pendencias.isEmDia;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEmDia
                ? [Colors.green.shade400, Colors.green.shade600]
                : [Colors.red.shade400, Colors.red.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isEmDia ? Icons.check_circle : Icons.warning,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pendencias.statusPendencia,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (pendencias.qtdPendencias > 0)
                        Text(
                          '${pendencias.qtdPendencias} ${pendencias.qtdPendencias == 1 ? 'pendência' : 'pendências'}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (pendencias.valorPendencias > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Valor Total Pendente:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatarValor(pendencias.valorPendencias),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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

  Widget _buildGuiasTab() {
    if (_isLoadingGuias) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando guias...'),
          ],
        ),
      );
    }

    if (_errorGuias != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                _errorGuias!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadGuias,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_guiasData == null || _guiasData!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma guia encontrada',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Gere uma guia selecionando cobranças',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGuias,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _guiasData!.length,
        itemBuilder: (context, index) {
          final guia = _guiasData![index];
          return _buildGuiaCard(guia);
        },
      ),
    );
  }

  Widget _buildGuiaCard(NegociacaoResponseModel guia) {
    final isAtiva = guia.status.toUpperCase() == 'AGUARDANDO PAGAMENTO';
    final isPago = guia.status.toUpperCase() == 'PAGA';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _mostrarDetalhesNegociacao(guia),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPago
                            ? [Colors.green.shade400, Colors.green.shade600]
                            : [Colors.purple.shade400, Colors.purple.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Guia ${guia.codigo}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPago
                          ? Colors.green.shade100
                          : isAtiva
                          ? Colors.orange.shade100
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      guia.status.toUpperCase(),
                      style: TextStyle(
                        color: isPago
                            ? Colors.green.shade700
                            : isAtiva
                            ? Colors.orange.shade700
                            : Colors.grey.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Gerado em: ${_formatarDataHora(guia.data)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${guia.quantidadeCobrancas} ${guia.quantidadeCobrancas == 1 ? 'cobrança' : 'cobranças'}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (guia.valorJuros > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Juros: ${_formatarValor(guia.valorJuros)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    _formatarValor(guia.valorTotal),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isPago ? Colors.green : Colors.blue,
                    ),
                  ),
                ],
              ),
              if (isAtiva && guia.pix != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pix, size: 16, color: Colors.teal.shade700),
                      const SizedBox(width: 6),
                      const Text(
                        'PIX disponível',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalizadorCard() {
    final totais = _calcularTotais();
    final qtd = _selectedCobrancas.length;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$qtd ${qtd == 1 ? 'cobrança' : 'cobranças'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Valor Bruto: ${_formatarValor(totais['bruto']!)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Juros: ${_formatarValor(totais['juros']!)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _formatarValor(totais['total']!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isCreatingNegociation
                          ? null
                          : _criarNegociacao,
                      icon: _isCreatingNegociation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.payment),
                      label: Text(
                        _isCreatingNegociation
                            ? 'Gerando Guia...'
                            : 'Pagar ${qtd == 1 ? 'Cobrança' : 'Cobranças'}',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTituloInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _cobrancasData!.nomeSerie,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Série: ${_cobrancasData!.codSerie}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Text(
                  'Título: ${_cobrancasData!.titulo}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCobrancaCard(CobrancaModel cobranca) {
    final isSelected = _selectedCobrancas.contains(cobranca.id);
    final canBeSelected = !cobranca.isPago && _isSelectionMode;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? Colors.blue.shade50 : null,
      child: InkWell(
        onTap: canBeSelected
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedCobrancas.remove(cobranca.id);
                  } else {
                    _selectedCobrancas.add(cobranca.id);
                  }
                });
              }
            : null,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            maintainState: true,
            initiallyExpanded: false,
            enabled: !_isSelectionMode,
            leading: _isSelectionMode && !cobranca.isPago
                ? Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedCobrancas.add(cobranca.id);
                        } else {
                          _selectedCobrancas.remove(cobranca.id);
                        }
                      });
                    },
                  )
                : CircleAvatar(
                    backgroundColor: _getStatusColor(
                      cobranca,
                    ).withValues(alpha: 0.2),
                    child: Icon(
                      _getStatusIcon(cobranca),
                      color: _getStatusColor(cobranca),
                    ),
                  ),
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cobranca.labelParcela != null) ...[
                        Text(
                          cobranca.labelParcela!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        cobranca.descricao,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(cobranca).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cobranca.situacao,
                    style: TextStyle(
                      color: _getStatusColor(cobranca),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Vencimento: ${_formatarData(cobranca.vencimento)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatarValor(cobranca.total),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(cobranca),
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetalhesValores(cobranca),
                    if (cobranca.paymentAppAvailable && !cobranca.isPago) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildOpcoesPagamento(cobranca),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetalhesValores(CobrancaModel cobranca) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildLinhaValor('Valor', cobranca.valor),
          if (cobranca.desconto > 0) ...[
            const SizedBox(height: 8),
            _buildLinhaValor('Desconto', cobranca.desconto, isDesconto: true),
          ],
          if (cobranca.juros > 0) ...[
            const SizedBox(height: 8),
            _buildLinhaValor('Juros', cobranca.juros, isJuros: true),
          ],
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          _buildLinhaValor('Total', cobranca.total, isTotal: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.event, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Emissão: ${_formatarData(cobranca.emissao)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaValor(
    String label,
    double valor, {
    bool isDesconto = false,
    bool isJuros = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          (isDesconto ? '- ' : '') + _formatarValor(valor),
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isDesconto
                ? Colors.green
                : isJuros
                ? Colors.red
                : isTotal
                ? Colors.black
                : Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildOpcoesPagamento(CobrancaModel cobranca) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Opções de Pagamento',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // PIX
        if (cobranca.temPixDisponivel) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pix, color: Colors.teal.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'PIX Copia e Cola',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SelectableText(
                    cobranca.pixCopiaColaValue!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _copiarPixCopiaCola(cobranca.pixCopiaColaValue!),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copiar Código PIX'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.teal.shade900,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pagar via PIX Copia e Cola o pagamento é processado em poucos segundos, basta sair dessa tela e voltar pra conferir se já foi confirmado o pagamento',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Boleto Linha Digitável
        if (cobranca.temBoletoDigitavelDisponivel) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.article, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Linha Digitável do Boleto',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SelectableText(
                    cobranca.boletoLinhaDigitavelValue!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _copiarLinhaDigitavel(
                      cobranca.boletoLinhaDigitavelValue!,
                    ),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copiar Linha Digitável'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Colors.orange.shade900,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pagar pela linha digitável pode compensar em até 2 dias úteis.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Boleto PDF
        if (cobranca.temBoletoPdfDisponivel) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _abrirBoletoPdf(cobranca.boletoUrlPdfValue!),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Abrir Boleto (PDF)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade700),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _criarNegociacao() async {
    if (_selectedCobrancas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione pelo menos 1 cobrança para criar uma negociação',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Confirmação
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gerar Guia de Pagamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Será gerada uma guia de pagamento com ${_selectedCobrancas.length} cobranças selecionadas.',
            ),
            const SizedBox(height: 12),
            Text(
              'Valor total: ${_calcularTotalSelecionadas()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'A guia conterá um código PIX para pagamento único de todas as cobranças selecionadas.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Gerar Guia'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    // Ativar loading
    setState(() {
      _isCreatingNegociation = true;
    });

    try {
      final clientService = ClientService.instance;
      final authService = await AuthService.getInstance();

      final result = await authService.criarNegociacaoCobrancas(
        clientService.currentConfig.clientType,
        widget.tituloId,
        _selectedCobrancas.toList(),
      );

      if (!mounted) return;

      if (result.success && result.data != null) {
        final negociacao = NegociacaoResponseModel.fromJson(result.data!);

        // Limpar seleção e desativar loading
        setState(() {
          _isSelectionMode = false;
          _selectedCobrancas.clear();
          _isCreatingNegociation = false;
        });

        // Mostrar BottomSheet com detalhes da negociação
        _mostrarDetalhesNegociacao(negociacao);
      } else {
        setState(() {
          _isCreatingNegociation = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Erro ao gerar guia de pagamento'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCreatingNegociation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDetalhesNegociacao(NegociacaoResponseModel negociacao) {
    // Iniciar verificação de status
    _startStatusCheck(negociacao.id, negociacao.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ValueListenableBuilder<bool>(
        valueListenable: _isPaymentConfirmedNotifier,
        builder: (context, isPaymentConfirmed, _) {
          return ValueListenableBuilder<bool>(
            valueListenable: _isCheckingStatusNotifier,
            builder: (context, isCheckingStatus, _) {
              return ValueListenableBuilder<int>(
                valueListenable: _countdownSecondsNotifier,
                builder: (context, countdownSeconds, _) {
                  return DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    builder: (context, scrollController) => Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Handle bar
                          Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 8),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          // Header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Guia de Pagamento',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _stopStatusCheck();
                                    Navigator.pop(context);
                                    _loadCobrancas();
                                    _loadGuias();
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          // Content
                          Expanded(
                            child: SingleChildScrollView(
                              controller: scrollController,
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Card de pagamento confirmado
                                  _buildSuccessCard(negociacao),
                                  const SizedBox(height: 16),
                                  _buildResumoValoresCard(negociacao),
                                  const SizedBox(height: 16),
                                  // Pagamento confirmado
                                  if (isPaymentConfirmed)
                                    _buildPaymentConfirmedCard(),
                                  if (isPaymentConfirmed)
                                    const SizedBox(height: 16),
                                  if (negociacao.pix != null &&
                                      negociacao.status ==
                                          "AGUARDANDO PAGAMENTO" &&
                                      !isPaymentConfirmed)
                                    _buildPixBottomSheetCard(negociacao.pix!),

                                  // Card de verificação de status
                                  if (isCheckingStatus && !isPaymentConfirmed)
                                    const SizedBox(height: 16),
                                  if (isCheckingStatus && !isPaymentConfirmed)
                                    _buildStatusCheckCard(),
                                  if (isCheckingStatus && !isPaymentConfirmed)
                                    const SizedBox(height: 16),

                                  _buildCobrancasIncluidas(negociacao),
                                  const SizedBox(height: 80),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    ).whenComplete(() {
      // Garantir que para a verificação quando o bottom sheet é fechado
      _stopStatusCheck();
    });
  }

  Widget _buildPaymentConfirmedCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pagamento Confirmado!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Seu pagamento foi processado com sucesso',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.favorite, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Obrigado por utilizar nossos serviços! Sua confiança é muito importante para nós.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCheckCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aguardando Pagamento',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Verificando status automaticamente',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Verificando novamente em $_countdownSeconds segundos...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_countdownSeconds',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(NegociacaoResponseModel negociacao) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 40),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Guia Gerada!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  negociacao.codigo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatarDataHora(negociacao.data),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      negociacao.status.toUpperCase() == 'AGUARDANDO PAGAMENTO'
                      ? Colors.orange.shade400
                      : Colors.blue.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  negociacao.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumoValoresCard(NegociacaoResponseModel negociacao) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text(
                'Resumo de Valores',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildResumoLinha(
            'Quantidade',
            '${negociacao.quantidadeCobrancas} ${negociacao.quantidadeCobrancas == 1 ? 'cobrança' : 'cobranças'}',
          ),
          const SizedBox(height: 8),
          _buildResumoLinha(
            'Valor Bruto',
            _formatarValor(negociacao.valorBruto),
          ),
          if (negociacao.valorJuros > 0) ...[
            const SizedBox(height: 8),
            _buildResumoLinha(
              'Juros',
              _formatarValor(negociacao.valorJuros),
              isJuros: true,
            ),
          ],
          if (negociacao.valorDesconto > 0) ...[
            const SizedBox(height: 8),
            _buildResumoLinha(
              'Desconto',
              _formatarValor(negociacao.valorDesconto),
              isDesconto: true,
            ),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Valor Total',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                _formatarValor(negociacao.valorTotal),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumoLinha(
    String label,
    String valor, {
    bool isJuros = false,
    bool isDesconto = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        Text(
          valor,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isJuros
                ? Colors.red
                : isDesconto
                ? Colors.green
                : Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildPixBottomSheetCard(PixNegociacaoModel pix) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pix, color: Colors.teal.shade700, size: 28),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Pagamento via PIX',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: pix.status.toUpperCase() == 'ATIVA'
                      ? Colors.green.shade100
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  pix.status.toUpperCase(),
                  style: TextStyle(
                    color: pix.status.toUpperCase() == 'ATIVA'
                        ? Colors.green.shade700
                        : Colors.grey.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (pix.expiraEm != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, size: 18, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Expira em: ${_formatarDataHora(pix.expiraEm!)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (pix.pixCopiaECola != null && pix.pixCopiaECola!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'PIX Copia e Cola',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: SelectableText(
                pix.pixCopiaECola!,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: pix.pixCopiaECola!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Código PIX copiado para área de transferência!',
                      ),
                      backgroundColor: Colors.teal,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 20),
                label: const Text('Copiar Código PIX'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.teal.shade900,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'O pagamento via PIX é processado em poucos segundos. Após o pagamento, volte aqui para verificar a confirmação.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCobrancasIncluidas(NegociacaoResponseModel negociacao) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list_alt, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            const Text(
              'Cobranças Incluídas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...negociacao.cobrancas.map(
          (cobranca) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (cobranca.labelParcela != null) ...[
                            Text(
                              cobranca.labelParcela!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            cobranca.descricao,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatarValor(cobranca.total),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  cobranca.descricaoPai,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (cobranca.vencimento != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Vencimento: ${_formatarData(cobranca.vencimento!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _calcularTotalSelecionadas() {
    double total = 0.0;
    for (var cobranca in _cobrancasData!.lista) {
      if (_selectedCobrancas.contains(cobranca.id)) {
        total += cobranca.total;
      }
    }
    return _formatarValor(total);
  }

  Color _getStatusColor(CobrancaModel cobranca) {
    if (cobranca.isPago) return Colors.green;
    if (cobranca.isEmAtraso) return Colors.red;
    return Colors.blue;
  }

  IconData _getStatusIcon(CobrancaModel cobranca) {
    if (cobranca.isPago) return Icons.check_circle;
    if (cobranca.isEmAtraso) return Icons.warning;
    return Icons.schedule;
  }

  String _formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy').format(data);
  }

  String _formatarDataHora(DateTime data) {
    return DateFormat('dd/MM/yyyy HH:mm').format(data);
  }

  String _formatarValor(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  void _copiarPixCopiaCola(String codigo) {
    Clipboard.setData(ClipboardData(text: codigo));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código PIX copiado!'),
        backgroundColor: Colors.teal,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copiarLinhaDigitavel(String codigo) {
    Clipboard.setData(ClipboardData(text: codigo));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Linha digitável copiada!'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _abrirBoletoPdf(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o boleto'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
