import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_config_service.dart';
import '../models/app_config_model.dart';

class ContatoClubeScreen extends StatelessWidget {
  const ContatoClubeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appConfigService = AppConfigService.instance;
    final appConfig = appConfigService.appConfig;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contato'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações do Clube
            if (appConfig?.clube != null)
              //   _buildClubeCard(context, appConfig!.clube),
              // const SizedBox(height: 16),
              // Contatos
              if (appConfig?.contatos.isNotEmpty ?? false)
                _buildContatosSection(context, appConfig!.contatos),
            const SizedBox(height: 16),

            // Links úteis
            // if (appConfig != null) _buildLinksSection(context, appConfig),
          ],
        ),
      ),
    );
  }

  Widget _buildContatosSection(
    BuildContext context,
    List<ContatoModel> contatos,
  ) {
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
                    Icons.contact_phone,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Canais de Atendimento',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...contatos.map((contato) => _buildContatoItem(context, contato)),
          ],
        ),
      ),
    );
  }

  Widget _buildContatoItem(BuildContext context, ContatoModel contato) {
    IconData icon;
    Color color;

    if (contato.isWhatsApp) {
      icon = Icons.chat_bubble;
      color = Colors.green;
    } else if (contato.isTelefone) {
      icon = Icons.phone;
      color = Colors.blue;
    } else if (contato.isEmail) {
      icon = Icons.email;
      color = Colors.orange;
    } else {
      icon = Icons.info;
      color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _handleContatoTap(contato),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contato.descricao.isNotEmpty
                          ? contato.descricao
                          : contato.tipo,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatarValorContato(contato),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }

  String _formatarValorContato(ContatoModel contato) {
    if (contato.isWhatsApp || contato.isTelefone) {
      return _formatarTelefone(contato.valor);
    }
    return contato.valor;
  }

  String _formatarTelefone(String telefone) {
    // Remover todos os caracteres não numéricos
    final numeros = telefone.replaceAll(RegExp(r'[^0-9]'), '');

    if (numeros.length == 10) {
      // Formato: (99) 9999-9999
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 6)}-${numeros.substring(6)}';
    } else if (numeros.length == 11) {
      // Formato: (99) 9 9999-9999
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 3)} ${numeros.substring(3, 7)}-${numeros.substring(7)}';
    } else if (numeros.length == 13) {
      // Formato: +55 (91) 9 9142-5042
      return '+${numeros.substring(0, 2)} (${numeros.substring(2, 4)}) ${numeros.substring(4, 5)} ${numeros.substring(5, 9)}-${numeros.substring(9)}';
    }

    // Se não for nenhum dos formatos esperados, retorna o original
    return telefone;
  }

  Future<void> _handleContatoTap(ContatoModel contato) async {
    String url;

    if (contato.isWhatsApp) {
      // Remover caracteres não numéricos
      final phone = contato.valor.replaceAll(RegExp(r'[^0-9]'), '');
      url = 'https://wa.me/$phone';
    } else if (contato.isTelefone) {
      url = 'tel:${contato.valor}';
    } else if (contato.isEmail) {
      url = 'mailto:${contato.valor}';
    } else {
      return;
    }

    await _abrirUrl(url);
  }

  Future<void> _abrirUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Silenciosamente falhar
    }
  }
}
