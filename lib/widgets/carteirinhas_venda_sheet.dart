import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/carteirinha_venda_model.dart';
import '../services/auth_service.dart';
import '../services/client_service.dart';
import '../utils/formatters.dart';

Future<void> showCarteirinhasSelecaoSheet({
  required BuildContext context,
  required String tituloId,
  required CarteirinhasResumoModel resumo,
  required VoidCallback onSuccess,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _CarteirinhasSelecaoSheet(
      tituloId: tituloId,
      resumo: resumo,
      onSuccess: onSuccess,
    ),
  );
}

Future<void> showCarteirinhasPixSheet({
  required BuildContext context,
  required String tituloId,
  required VendaCarteirinhaPendenteModel venda,
  required VoidCallback onPaid,
  VoidCallback? onCancelled,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _CarteirinhasPixSheet(
      tituloId: tituloId,
      venda: venda,
      onPaid: onPaid,
      onCancelled: onCancelled,
    ),
  );
}

class _CarteirinhasSelecaoSheet extends StatefulWidget {
  final String tituloId;
  final CarteirinhasResumoModel resumo;
  final VoidCallback onSuccess;

  const _CarteirinhasSelecaoSheet({
    required this.tituloId,
    required this.resumo,
    required this.onSuccess,
  });

  @override
  State<_CarteirinhasSelecaoSheet> createState() =>
      _CarteirinhasSelecaoSheetState();
}

class _CarteirinhasSelecaoSheetState extends State<_CarteirinhasSelecaoSheet> {
  final Set<String> _selecionados = {};
  bool _isLoading = false;
  String? _error;

  List<ParticipanteCarteirinhaModel> get _elegiveis =>
      widget.resumo.participantes.where((p) => p.selecionavel).toList();

  double get _total {
    double total = 0;
    for (final p in _elegiveis) {
      if (_selecionados.contains(p.clienteId)) {
        total += p.valorUnitario ?? 0;
      }
    }
    return total;
  }

  Future<void> _gerarPix() async {
    if (_selecionados.isEmpty) {
      setState(() => _error = 'Selecione ao menos um participante.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final operacoes = _elegiveis
        .where((p) => _selecionados.contains(p.clienteId))
        .map(
          (p) => {
            'operacao': p.opDisponivel,
            'dependencia': p.dependencia,
            'cliente_id': p.clienteId,
            'cliente_nome': p.clienteNome,
          },
        )
        .toList();

    try {
      final authService = await AuthService.getInstance();
      final clientType = ClientService.instance.currentConfig.clientType;

      final result = await authService.criarVendaCarteirinhas(
        clientType,
        widget.tituloId,
        operacoes,
      );

      if (!mounted) return;

      if (result.success && result.data != null) {
        Navigator.of(context).pop();
        final venda = VendaCarteirinhaPendenteModel.fromJson(result.data!);
        await showCarteirinhasPixSheet(
          context: context,
          tituloId: widget.tituloId,
          venda: venda,
          onPaid: widget.onSuccess,
        );
      } else {
        setState(() {
          _error = result.error ?? 'Erro ao gerar PIX';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro inesperado: $e';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildComoFuncionaInfo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Como funciona',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Marque o titular e/ou dependentes que desejam emitir ou renovar a carteirinha. '
              'Quem já possui carteirinha vigente não aparece nesta lista.\n\n'
              'Confira o valor de cada operação (emissão ou renovação), veja o total no rodapé '
              'e toque em Gerar PIX. Copie o código ou pague pelo app do seu banco.\n\n'
              'Após a confirmação do pagamento, as carteirinhas são liberadas automaticamente '
              'e ficam disponíveis nesta tela.',
              style: TextStyle(
                color: Colors.blue.shade900,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipanteTile(ParticipanteCarteirinhaModel p) {
    final selected = _selecionados.contains(p.clienteId);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: selected,
        onChanged: (v) {
          setState(() {
            if (v == true) {
              _selecionados.add(p.clienteId);
            } else {
              _selecionados.remove(p.clienteId);
            }
          });
        },
        title: Text(
          p.clienteNome,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${p.tipoLabel} • ${p.statusCarteirinha}'),
            if (p.opDisponivel != null)
              Text(
                '${p.opDisponivelLabel} • ${Formatters.currency(p.valorUnitario ?? 0)}',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        secondary: CircleAvatar(
          backgroundColor:
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Icon(
            p.dependencia == 'TITULAR' ? Icons.person : Icons.people,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.badge, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Selecionar Carteirinhas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _elegiveis.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildComoFuncionaInfo();
                      }
                      return _buildParticipanteTile(_elegiveis[index - 1]);
                    },
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border:
                        Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            Formatters.currency(_total),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _gerarPix,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.pix),
                          label: Text(
                            _isLoading ? 'Gerando PIX...' : 'Gerar PIX',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CarteirinhasPixSheet extends StatefulWidget {
  final String tituloId;
  final VendaCarteirinhaPendenteModel venda;
  final VoidCallback onPaid;
  final VoidCallback? onCancelled;

  const _CarteirinhasPixSheet({
    required this.tituloId,
    required this.venda,
    required this.onPaid,
    this.onCancelled,
  });

  @override
  State<_CarteirinhasPixSheet> createState() => _CarteirinhasPixSheetState();
}

class _CarteirinhasPixSheetState extends State<_CarteirinhasPixSheet> {
  static const _pixDuracaoSegundos = 900;

  Timer? _verifyTimer;
  Timer? _countdownTimer;
  bool _isVerificando = false;
  bool _isCancelando = false;
  bool _verificacaoEmAndamento = false;
  bool _verificacaoAutomaticaAtiva = true;
  late VendaCarteirinhaPendenteModel _venda;

  @override
  void initState() {
    super.initState();
    _venda = widget.venda;
    _iniciarTimers();
    _verificarPagamento(silent: true);
  }

  @override
  void dispose() {
    _verifyTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _iniciarTimers() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (_pixExpirado && _verificacaoAutomaticaAtiva) {
        _verificarPagamento(silent: true);
      }
    });

    _verifyTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_verificacaoAutomaticaAtiva && !_pixExpirado) {
        _verificarPagamento(silent: true);
      }
    });
  }

  void _pararTimers() {
    _verificacaoAutomaticaAtiva = false;
    _verifyTimer?.cancel();
    _countdownTimer?.cancel();
  }

  DateTime? get _expiraEmLocal => _venda.expiraEm?.toLocal();

  DateTime get _inicioPixLocal {
    final expira = _expiraEmLocal;
    if (expira == null) return DateTime.now();
    return expira.subtract(const Duration(seconds: _pixDuracaoSegundos));
  }

  bool get _pixExpirado {
    final expira = _expiraEmLocal;
    if (expira == null) return _venda.expirado;
    return DateTime.now().isAfter(expira);
  }

  Duration get _tempoRestante {
    final expira = _expiraEmLocal;
    if (expira == null) return Duration.zero;
    final diff = expira.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  double get _progressoExpiracao {
    final expira = _expiraEmLocal;
    if (expira == null) return 0;
    final agora = DateTime.now();
    if (agora.isAfter(expira)) return 1;
    final total = expira.difference(_inicioPixLocal).inSeconds;
    if (total <= 0) return 0;
    final elapsed = agora.difference(_inicioPixLocal).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  String _formatarCountdown(Duration d) {
    final horas = d.inHours;
    final minutos = d.inMinutes.remainder(60);
    final segundos = d.inSeconds.remainder(60);
    if (horas > 0) {
      return '${horas.toString().padLeft(2, '0')}:'
          '${minutos.toString().padLeft(2, '0')}:'
          '${segundos.toString().padLeft(2, '0')}';
    }
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  String _formatarDataHora(DateTime dt) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal());
  }

  Future<void> _verificarPagamento({bool silent = false}) async {
    if (_verificacaoEmAndamento) return;
    _verificacaoEmAndamento = true;

    if (!silent) setState(() => _isVerificando = true);
    try {
      final authService = await AuthService.getInstance();
      final clientType = ClientService.instance.currentConfig.clientType;
      final result = await authService.verificarVendaCarteirinha(
        clientType,
        widget.tituloId,
        _venda.vendaId,
      );

      if (!mounted) return;

      if (result.success && result.data != null) {
        final verificacao = VerificarCarteirinhaVendaResult.fromJson(result.data!);
        if (verificacao.pago || verificacao.carteirinhasEmitidas) {
          _pararTimers();
          Navigator.of(context).pop();
          widget.onPaid();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pagamento confirmado! Carteirinhas emitidas.'),
              backgroundColor: Colors.green,
            ),
          );
          return;
        }
        if (verificacao.cancelada) {
          _pararTimers();
          Navigator.of(context).pop();
          widget.onPaid();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIX expirado. Você pode gerar um novo pagamento.'),
            ),
          );
          return;
        }
        if (verificacao.venda != null) {
          setState(() => _venda = verificacao.venda!);
        }
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pagamento ainda não identificado.')),
          );
        }
      } else if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Erro ao verificar pagamento')),
        );
      }
    } finally {
      _verificacaoEmAndamento = false;
      if (mounted && !silent) setState(() => _isVerificando = false);
    }
  }

  Widget _buildCountdownExpiracao() {
    final restante = _tempoRestante;
    final expirado = _pixExpirado;
    final progresso = _progressoExpiracao;
    final corBarra = progresso >= 0.85
        ? Colors.red
        : progresso >= 0.6
            ? Colors.orange
            : Colors.teal;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: expirado ? Colors.orange.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: expirado ? Colors.orange.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    expirado ? Icons.timer_off : Icons.timer_outlined,
                    size: 18,
                    color: expirado ? Colors.orange.shade800 : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    expirado ? 'PIX expirado' : 'Tempo para pagamento',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: expirado ? Colors.orange.shade900 : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              if (!expirado)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: corBarra,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatarCountdown(restante),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
            ],
          ),
          if (!expirado) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progresso,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(corBarra),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Faltam ${_formatarCountdown(restante)} para expirar',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResumoPedido() {
    final itens = _venda.itens;
    if (itens.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo do pedido',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          if (_venda.codigo.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Pedido #${_venda.codigo}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 10),
          ...itens.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.clienteNome,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${item.dependenciaLabel} • ${item.operacaoLabel}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.valor != null)
                    Text(
                      Formatters.currency(item.valor!),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                Formatters.currency(_venda.valorTotal),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _cancelarPedido() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: const Text(
          'Deseja cancelar este pedido de carteirinha? Você poderá fazer um novo pedido depois.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _isCancelando = true);
    try {
      final authService = await AuthService.getInstance();
      final clientType = ClientService.instance.currentConfig.clientType;
      final result = await authService.cancelarVendaCarteirinha(
        clientType,
        widget.tituloId,
        _venda.vendaId,
      );

      if (!mounted) return;

      if (result.success) {
        _pararTimers();
        Navigator.of(context).pop();
        widget.onCancelled?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido cancelado com sucesso.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Erro ao cancelar pedido')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pix = _venda.pix;
    final pixCode = pix?.pixCopiaECola ?? '';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.pix, color: Colors.teal.shade700),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Pagamento PIX',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildResumoPedido(),
            const SizedBox(height: 16),
            _buildCountdownExpiracao(),
            if (pixCode.isNotEmpty && !_pixExpirado) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Verificando pagamento automaticamente a cada 5 segundos',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                    const Text(
                      'PIX Copia e Cola',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      pixCode,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: pixCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Código PIX copiado!'),
                              backgroundColor: Colors.teal,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copiar Código PIX'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_pixExpirado) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  'O prazo deste PIX encerrou. Feche esta tela e gere um novo pagamento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.orange.shade900),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isVerificando || _pixExpirado
                    ? null
                    : () => _verificarPagamento(),
                icon: _isVerificando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(
                  _isVerificando ? 'Verificando...' : 'Verificar agora',
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _isCancelando ? null : _cancelarPedido,
                icon: _isCancelando
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red.shade700,
                        ),
                      )
                    : Icon(Icons.cancel_outlined, color: Colors.red.shade700),
                label: Text(
                  _isCancelando ? 'Cancelando...' : 'Cancelar pedido',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
