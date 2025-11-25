import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/cortesia_model.dart';
import '../services/api_service.dart';
import '../services/client_service.dart';
import 'nova_reserva_screen.dart';

class ReservasScreen extends StatefulWidget {
  final String tituloId;
  final String tituloNome;
  final String? hashToOpen;

  const ReservasScreen({
    super.key,
    required this.tituloId,
    required this.tituloNome,
    this.hashToOpen,
  });

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<CortesiaModel> _cortesiasAtivas = [];
  List<CortesiaModel> _cortesiasCanceladas = [];
  bool _carregando = true;
  String? _erro;
  bool _hashJaProcessado =
      false; // Controla se o hash automático já foi processado

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarCortesias();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarCortesias() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final client = ClientService.instance;
      final apiService = await ApiService.getInstance();

      final resultado = await apiService.getCortesias(
        client.currentClientType,
        widget.tituloId,
      );

      if (resultado.error != null) {}
      if (resultado.data != null) {}

      if (resultado.success && resultado.data != null) {
        try {
          final cortesias = resultado.data!
              .map((item) => CortesiaModel.fromJson(item))
              .toList();
          // Ordenar por data de criação (mais recentes primeiro)
          cortesias.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          final ativas = cortesias
              .where((c) => c.status != 'CANCELADA')
              .toList();
          final canceladas = cortesias
              .where((c) => c.status == 'CANCELADA')
              .toList();

          setState(() {
            _cortesiasAtivas = ativas;
            _cortesiasCanceladas = canceladas;
            _carregando = false;
          });
        } catch (parseError) {
          setState(() {
            _erro = 'Erro ao processar dados das cortesias: $parseError';
            _carregando = false;
          });
        }
      } else {
        setState(() {
          _erro = resultado.error ?? 'Erro ao carregar reservas';
          _carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        _erro = 'Erro de conexão: $e';
        _carregando = false;
      });
    }

    // Após carregar as cortesias, verificar se deve abrir automaticamente alguma
    _verificarHashParaAbrir();
  }

  void _verificarHashParaAbrir() {
    if (widget.hashToOpen != null &&
        widget.hashToOpen!.isNotEmpty &&
        !_hashJaProcessado) {
      // Procurar a cortesia com o hash fornecido
      final todasCortesias = [..._cortesiasAtivas, ..._cortesiasCanceladas];
      final cortesiaEncontrada = todasCortesias
          .where((cortesia) => cortesia.hash == widget.hashToOpen)
          .firstOrNull;

      if (cortesiaEncontrada != null) {
        // Marcar como processado para evitar abrir novamente
        _hashJaProcessado = true;

        // Aguardar o próximo frame para garantir que a UI foi construída
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _verDetalhes(cortesiaEncontrada);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reservas - ${widget.tituloNome}'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'Ativas (${_cortesiasAtivas.length})',
              icon: const Icon(Icons.assignment),
            ),
            Tab(
              text: 'Canceladas (${_cortesiasCanceladas.length})',
              icon: const Icon(Icons.cancel),
            ),
          ],
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar reservas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _erro!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _carregarCortesias,
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCortesiasList(_cortesiasAtivas, isActive: true),
                _buildCortesiasList(_cortesiasCanceladas, isActive: false),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) => NovaReservaScreen(
                    tituloId: widget.tituloId,
                    tituloNome: widget.tituloNome,
                  ),
                ),
              )
              .then((_) => _carregarCortesias());
        },
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCortesiasList(
    List<CortesiaModel> cortesias, {
    required bool isActive,
  }) {
    if (cortesias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.event_available : Icons.cancel_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isActive
                  ? 'Nenhuma reserva ativa encontrada'
                  : 'Nenhuma reserva cancelada encontrada',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            if (isActive) ...[
              const SizedBox(height: 8),
              Text(
                'Toque no + para criar uma nova reserva',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarCortesias,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cortesias.length,
        itemBuilder: (context, index) {
          final cortesia = cortesias[index];
          return _buildCortesiaCard(cortesia);
        },
      ),
    );
  }

  Widget _buildCortesiaCard(CortesiaModel cortesia) {
    Color statusColor;
    IconData statusIcon;

    switch (cortesia.status) {
      case 'AGUARDANDO VINCULO':
        statusColor = Colors.orange;
        statusIcon = Icons.link;
        break;
      case 'PENDENTE':
        statusColor = Colors.blue;
        statusIcon = Icons.schedule;
        break;
      case 'PARCIALMENTE_RETIRADA':
        statusColor = Colors.amber;
        statusIcon = Icons.people_outline;
        break;
      case 'RETIRADA':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'CANCELADA':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data da reserva em destaque
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Colors.blue.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatarDataCompleta(cortesia.data),
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize:
                            14, // Voltando para 14 já que agora tem mais espaço
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Status da reserva
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        cortesia.statusDisplay,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Informações principais
            Row(
              children: [
                Icon(
                  Icons.card_giftcard,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cortesia.tipoCortesiaDisplay,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.people, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${cortesia.totalCortesiasRetiradas}/${cortesia.totalCortesias} retiradas',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            if (cortesia.convidados.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.group, color: Colors.purple.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${cortesia.convidados.length} convidado(s) cadastrado(s)',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Botões de ação - Layout melhorado
            // Cortesias canceladas não têm acesso a nenhuma ação
            if (cortesia.status != 'CANCELADA') ...[
              Column(
                children: [
                  // Primeira linha: Detalhes (sempre presente)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _verDetalhes(cortesia),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Ver Detalhes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  // Segunda linha: Ações de compartilhamento (se disponível)
                  if (cortesia.podeCompartilhar &&
                      cortesia.siteUrl != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _compartilharLink(cortesia.siteUrl!),
                            icon: const Icon(Icons.share, size: 16),
                            label: const Text('Compartilhar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue.shade600,
                              side: BorderSide(color: Colors.blue.shade600),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _copiarLink(cortesia.siteUrl!),
                            icon: const Icon(Icons.link, size: 16),
                            label: const Text('Copiar Link'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green.shade600,
                              side: BorderSide(color: Colors.green.shade600),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Terceira linha: Cancelar (se disponível)
                  if (cortesia.podeCancelar) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _cancelarReserva(cortesia),
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Cancelar Reserva'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(color: Colors.red.shade600),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ] else ...[
              // Para cortesias canceladas, mostrar apenas informação
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.red.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta reserva foi cancelada e não possui ações disponíveis.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
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

  String _formatarDataCompleta(DateTime data) {
    const meses = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    const diasSemana = [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo',
    ];

    // DateTime.weekday retorna 1-7 (Monday-Sunday), ajustamos para 0-6
    final diaSemana = diasSemana[data.weekday - 1];
    final dia = data.day;
    final mes = meses[data.month - 1];
    final ano = data.year;

    return '$diaSemana, $dia de $mes de $ano';
  }

  void _compartilharLink(String url) {
    // Compartilhamento nativo usando share_plus
    Share.share(
      url,
      subject: 'Convite para reserva de cortesia',
      sharePositionOrigin: Rect.fromLTWH(0, 0, 100, 100), // Fix para iOS/macOS
    );
  }

  void _copiarLink(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copiado para a área de transferência'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _verDetalhes(CortesiaModel cortesia) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildDetalhesModal(cortesia),
    );
  }

  Widget _buildDetalhesModal(CortesiaModel cortesia) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Detalhes da Reserva',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Conteúdo
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informações básicas com layout melhorado
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informações Básicas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Data da reserva com destaque
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade50,
                                    Colors.blue.shade100,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.blue.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Data da Reserva',
                                          style: TextStyle(
                                            color: Colors.blue.shade600,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatarDataCompleta(cortesia.data),
                                          style: TextStyle(
                                            color: Colors.blue.shade800,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Grid de informações
                            Row(
                              children: [
                                // Status
                                Expanded(
                                  child: _buildInfoCard(
                                    'Status',
                                    cortesia.statusDisplay,
                                    Icons.info_outline,
                                    _getStatusColor(cortesia.status),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Tipo
                                Expanded(
                                  child: _buildInfoCard(
                                    'Tipo',
                                    cortesia.tipoCortesiaDisplay,
                                    Icons.card_giftcard,
                                    Colors.purple.shade600,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                // Total de cortesias
                                Expanded(
                                  child: _buildInfoCard(
                                    'Total',
                                    '${cortesia.totalCortesias}',
                                    Icons.confirmation_number,
                                    Colors.orange.shade600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Cortesias retiradas
                                Expanded(
                                  child: _buildInfoCard(
                                    'Retiradas',
                                    '${cortesia.totalCortesiasRetiradas}',
                                    Icons.check_circle,
                                    Colors.green.shade600,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Data de criação
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.grey.shade600,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Criado em: ',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _formatarDataHora(cortesia.createdAt),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Link de compartilhamento
                      if (cortesia.siteUrl != null) ...[
                        const SizedBox(height: 24),
                        _buildDetalheSection('Link de Compartilhamento', [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Link para Compartilhamento',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          cortesia.siteUrl!,
                                          style: TextStyle(
                                            color: Colors.blue.shade600,
                                            fontSize: 12,
                                            fontFamily: 'monospace',
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () =>
                                            _copiarLink(cortesia.siteUrl!),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.copy,
                                            size: 16,
                                            color: Colors.blue.shade600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _compartilharLink(
                                          cortesia.siteUrl!,
                                        ),
                                        icon: const Icon(Icons.share, size: 16),
                                        label: const Text('Compartilhar'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.blue.shade600,
                                          side: BorderSide(
                                            color: Colors.blue.shade600,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _copiarLink(cortesia.siteUrl!),
                                        icon: const Icon(Icons.link, size: 16),
                                        label: const Text('Copiar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.green.shade600,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ],

                      // Convidados
                      if (cortesia.convidados.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildDetalheSection(
                          'Convidados (${cortesia.convidados.length})',
                          cortesia.convidados
                              .map(
                                (convidado) => _buildConvidadoItem(convidado),
                              )
                              .toList(),
                        ),
                      ],

                      // Histórico de retiradas
                      if (cortesia.retiradas.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildDetalheSection(
                          'Histórico de Retiradas (${cortesia.retiradas.length})',
                          cortesia.retiradas
                              .map((retirada) => _buildRetiradaItem(retirada))
                              .toList(),
                        ),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetalheSection(String titulo, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildConvidadoItem(ConvidadoModel convidado) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: convidado.retirado
            ? Colors.green.shade50
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: convidado.retirado
              ? Colors.green.shade200
              : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                convidado.retirado ? Icons.check_circle : Icons.schedule,
                color: convidado.retirado
                    ? Colors.green.shade600
                    : Colors.orange.shade600,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                convidado.retirado ? 'Retirado' : 'Pendente',
                style: TextStyle(
                  color: convidado.retirado
                      ? Colors.green.shade600
                      : Colors.orange.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            convidado.nome,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            'Documento: ${convidado.cpf}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          if (convidado.pessoaMenorIdade != null) ...[
            const SizedBox(height: 4),
            Text(
              'Menor: ${convidado.pessoaMenorIdade!.nome}',
              style: TextStyle(
                color: Colors.blue.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (convidado.dataHoraRetirada != null) ...[
            const SizedBox(height: 4),
            Text(
              'Retirado em: ${_formatarDataHora(convidado.dataHoraRetirada!)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
          if (convidado.qrcodeData != null &&
              convidado.qrcodeData!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Text(
                    'QR Code do Convidado',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: QrImageView(
                      data: convidado.qrcodeData!,
                      version: QrVersions.auto,
                      size: 150,
                      backgroundColor: Colors.white,
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

  Widget _buildRetiradaItem(RetiradaModel retirada) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.blue.shade600, size: 16),
              const SizedBox(width: 4),
              Text(
                'Quantidade: ${retirada.quantidade}',
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            retirada.usuarioSistema.nome,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            _formatarDataHora(retirada.dataHora),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatarDataHora(DateTime dateTime) {
    // Converter para o fuso horário local do dispositivo
    final localDateTime = dateTime.toLocal();
    return '${localDateTime.day.toString().padLeft(2, '0')}/${localDateTime.month.toString().padLeft(2, '0')}/${localDateTime.year} às ${localDateTime.hour.toString().padLeft(2, '0')}:${localDateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'AGUARDANDO VINCULO':
        return Colors.orange;
      case 'PENDENTE':
        return Colors.blue;
      case 'PARCIALMENTE_RETIRADA':
        return Colors.amber;
      case 'RETIRADA':
        return Colors.green;
      case 'CANCELADA':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _cancelarReserva(CortesiaModel cortesia) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Reserva'),
        content: const Text(
          'Tem certeza que deseja cancelar esta reserva? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _executarCancelamento(cortesia);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _executarCancelamento(CortesiaModel cortesia) async {
    // Mostrar indicador de loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final apiService = await ApiService.getInstance();
      final clientType = ClientService.instance.currentClientType;

      final response = await apiService.cancelarReserva(
        clientType,
        cortesia.id,
      );

      if (response.error != null) {}

      // Fechar loading
      if (context.mounted) Navigator.of(context).pop();

      if (response.success) {
        // Atualizar a lista de cortesias
        await _carregarCortesias();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reserva cancelada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Erro ao cancelar reserva'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Fechar loading
      if (context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cancelar reserva: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
