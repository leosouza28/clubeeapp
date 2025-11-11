import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/negociacao_model.dart';

class NegociacaoDetalhesScreen extends StatelessWidget {
  final NegociacaoResponseModel negociacao;

  const NegociacaoDetalhesScreen({super.key, required this.negociacao});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guia de Pagamento'),
        elevation: 0,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCodigoCard(context),
            const SizedBox(height: 16),
            _buildResumoValoresCard(context),
            const SizedBox(height: 16),
            if (negociacao.pix != null) _buildPixCard(context),
            const SizedBox(height: 16),
            _buildCobrancasCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCodigoCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade400, Colors.purple.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.receipt_long, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Guia Gerada com Sucesso!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Código: ${negociacao.codigo}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gerado em: ${_formatarDataHora(negociacao.data)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoValoresCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo de Valores',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildLinhaValor(
              'Cobranças',
              negociacao.quantidadeCobrancas.toString(),
            ),
            const SizedBox(height: 8),
            _buildLinhaValor(
              'Valor Bruto',
              _formatarValor(negociacao.valorBruto),
            ),
            if (negociacao.valorJuros > 0) ...[
              const SizedBox(height: 8),
              _buildLinhaValor(
                'Juros',
                _formatarValor(negociacao.valorJuros),
                isJuros: true,
              ),
            ],
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            _buildLinhaValor(
              'Valor Total',
              _formatarValor(negociacao.valorTotal),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPixCard(BuildContext context) {
    final pix = negociacao.pix!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pix, color: Colors.teal.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Pagamento via PIX',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: pix.status.toUpperCase() == 'ATIVA'
                              ? Colors.green.shade100
                              : Colors.grey.shade100,
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
                      if (pix.expiraEm != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Expira: ${_formatarDataHora(pix.expiraEm!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (pix.pixCopiaECola != null &&
                      pix.pixCopiaECola!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'PIX Copia e Cola',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SelectableText(
                        pix.pixCopiaECola!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: pix.pixCopiaECola!),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Código PIX copiado!'),
                              backgroundColor: Colors.teal,
                              duration: Duration(seconds: 2),
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
                    const SizedBox(height: 12),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCobrancasCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Cobranças Incluídas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...negociacao.cobrancas.map(
              (cobranca) => _buildCobrancaItem(cobranca),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCobrancaItem(CobrancaNegociacaoModel cobranca) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
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
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
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
          if (cobranca.parcela != null && cobranca.totalParcelas != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.payments, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Parcela ${cobranca.parcela} de ${cobranca.totalParcelas}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLinhaValor(
    String label,
    String valor, {
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
          valor,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isJuros
                ? Colors.red
                : isTotal
                ? Colors.black
                : Colors.grey[800],
          ),
        ),
      ],
    );
  }

  String _formatarDataHora(DateTime data) {
    return DateFormat('dd/MM/yyyy HH:mm').format(data);
  }

  String _formatarValor(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}
