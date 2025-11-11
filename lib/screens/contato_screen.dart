import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_config_service.dart';
import '../models/app_config_model.dart';

class ContatoScreen extends StatelessWidget {
  const ContatoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appConfigService = AppConfigService.instance;
    final appConfig = appConfigService.appConfig;

    if (appConfig == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Contato')),
        body: const Center(child: Text('Configurações não carregadas')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contato'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com informações do clube
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                        Icons.business,
                        color: Theme.of(context).primaryColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appConfig.clube.nome,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Text('Fale conosco pelos canais abaixo'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // WhatsApp
            if (appConfigService.contatosWhatsApp.isNotEmpty) ...[
              Text(
                'WhatsApp',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...appConfigService.contatosWhatsApp.map(
                (contato) => _buildContatoCard(
                  context,
                  contato,
                  Icons.chat,
                  Colors.green,
                  () => _abrirWhatsApp(contato.valor),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Telefone
            if (appConfigService.contatosTelefone.isNotEmpty) ...[
              Text(
                'Telefone',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...appConfigService.contatosTelefone.map(
                (contato) => _buildContatoCard(
                  context,
                  contato,
                  Icons.phone,
                  Colors.blue,
                  () => _fazerLigacao(contato.valor),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Email
            if (appConfigService.contatosEmail.isNotEmpty) ...[
              Text(
                'E-mail',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...appConfigService.contatosEmail.map(
                (contato) => _buildContatoCard(
                  context,
                  contato,
                  Icons.email,
                  Colors.orange,
                  () => _enviarEmail(contato.valor),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Links úteis
            Text(
              'Links Úteis',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (appConfig.urlSiteAtracoes.isNotEmpty)
              _buildLinkCard(
                context,
                'Atrações',
                'Conheça nossas atrações',
                Icons.attractions,
                () => _abrirUrl(appConfig.urlSiteAtracoes),
              ),

            if (appConfig.urlSitePoliticaPrivacidade.isNotEmpty)
              _buildLinkCard(
                context,
                'Política de Privacidade',
                'Leia nossa política de privacidade',
                Icons.privacy_tip,
                () => _abrirUrl(appConfig.urlSitePoliticaPrivacidade),
              ),

            if (appConfig.urlSiteCortesias.isNotEmpty)
              _buildLinkCard(
                context,
                'Cortesias',
                'Informações sobre cortesias',
                Icons.card_giftcard,
                () => _abrirUrl(appConfig.urlSiteCortesias),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContatoCard(
    BuildContext context,
    ContatoModel contato,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contato.valor,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (contato.descricao.isNotEmpty)
                      Text(
                        contato.descricao,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkCard(
    BuildContext context,
    String titulo,
    String descricao,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      descricao,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirWhatsApp(String numero) async {
    final url = 'https://wa.me/$numero';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _fazerLigacao(String numero) async {
    final url = 'tel:$numero';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _enviarEmail(String email) async {
    final url = 'mailto:$email';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _abrirUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
