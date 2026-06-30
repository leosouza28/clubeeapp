import 'package:flutter/material.dart';

import '../models/carteirinha_venda_model.dart';
import '../models/titulo_model.dart';
import '../screens/titulo_details_screen.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/client_service.dart';

bool isNotificationRedirectFlag(dynamic value) {
  return value == true || value == 'true' || value == '1' || value == 1;
}

class _TituloCarteirinhaPendente {
  final TituloModel titulo;
  final CarteirinhasResumoModel resumo;

  _TituloCarteirinhaPendente({required this.titulo, required this.resumo});

  int get totalPendente => resumo.qtdEmissao + resumo.qtdRenovacao;
}

Future<void> showTitulosCarteirinhasRedirectSheet(BuildContext context) async {
  final authService = await AuthService.getInstance();
  final isAuthenticated = await authService.isAuthenticated();

  if (!isAuthenticated) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faça login para acessar suas carteirinhas'),
        ),
      );
    }
    return;
  }

  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (bottomSheetContext) => _TitulosCarteirinhasRedirectSheet(),
  );
}

class _TitulosCarteirinhasRedirectSheet extends StatefulWidget {
  @override
  State<_TitulosCarteirinhasRedirectSheet> createState() =>
      _TitulosCarteirinhasRedirectSheetState();
}

class _TitulosCarteirinhasRedirectSheetState
    extends State<_TitulosCarteirinhasRedirectSheet> {
  List<_TituloCarteirinhaPendente>? _titulos;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarTitulosComCarteirinhasPendentes();
  }

  Future<void> _carregarTitulosComCarteirinhasPendentes() async {
    try {
      final apiService = await ApiService.getInstance();
      final authService = await AuthService.getInstance();
      final clientType = ClientService.instance.currentConfig.clientType;

      final resultado = await apiService.getTitulos(clientType);
      if (!mounted) return;

      if (!resultado.success || resultado.data == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = resultado.error ?? 'Erro ao carregar títulos';
        });
        return;
      }

      final titulosAtivos = resultado.data!
          .map((json) => TituloModel.fromJson(json))
          .where(
            (t) =>
                t.situacao.toUpperCase() == 'ATIVO' &&
                !t.bloqueado,
          )
          .toList();

      if (titulosAtivos.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Você não possui títulos ativos com carteirinhas pendentes';
        });
        return;
      }

      final pendentes = <_TituloCarteirinhaPendente>[];

      await Future.wait(
        titulosAtivos.map((titulo) async {
          final resumoResult = await authService.getCarteirinhasResumo(
            clientType,
            titulo.id,
          );
          if (!resumoResult.success || resumoResult.data == null) return;

          final resumo = CarteirinhasResumoModel.fromJson(resumoResult.data!);
          if (resumo.temElegiveis || resumo.temPendencia) {
            pendentes.add(
              _TituloCarteirinhaPendente(titulo: titulo, resumo: resumo),
            );
          }
        }),
      );

      if (!mounted) return;

      setState(() {
        _titulos = pendentes;
        _isLoading = false;
        if (pendentes.isEmpty) {
          _errorMessage =
              'Você não possui carteirinhas pendentes de emissão ou renovação';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro inesperado: $e';
      });
    }
  }

  void _abrirTituloCarteirinhas(_TituloCarteirinhaPendente item) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TituloDetailsScreen(
          tituloId: item.titulo.id,
          nomeSerie: item.titulo.nomeSerie,
          abrirCarteirinhasAutomaticamente: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.badge_outlined,
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
                            'Carteirinhas pendentes',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (!_isLoading && _titulos != null)
                            Text(
                              '${_titulos!.length} ${_titulos!.length == 1 ? 'título' : 'títulos'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Verificando carteirinhas...',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
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
                                    _errorMessage!,
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
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _titulos!.length,
                            itemBuilder: (context, index) {
                              final item = _titulos![index];
                              return _buildTituloCard(context, item);
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTituloCard(
    BuildContext context,
    _TituloCarteirinhaPendente item,
  ) {
    final resumo = item.resumo;
    final temPagamento = resumo.temPendencia;
    final subtitulo = temPagamento
        ? 'Pagamento pendente'
        : '${resumo.qtdEmissao} emissão · ${resumo.qtdRenovacao} renovação';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _abrirTituloCarteirinhas(item),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (temPagamento ? Colors.orange : Colors.blue)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  temPagamento ? Icons.pix : Icons.badge_outlined,
                  color: temPagamento ? Colors.orange.shade800 : Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.titulo.nomeSerie} - ${item.titulo.titulo}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
