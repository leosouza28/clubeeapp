import 'package:flutter/material.dart';
import '../services/client_service.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final clientService = ClientService.instance;
    final config = clientService.currentConfig;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Placeholder para logo do cliente
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.business,
                              color: Theme.of(context).primaryColor,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              config.clientType.displayName,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        config.appName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getAboutText(config.clientType.id),
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informações de Contato',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildContactRow(
                        context,
                        Icons.email,
                        'Email de Suporte',
                        clientService.getCustomSetting<String>(
                              'supportEmail',
                            ) ??
                            'suporte@exemplo.com',
                      ),
                      _buildContactRow(
                        context,
                        Icons.language,
                        'Website',
                        _getWebsite(config.clientType.id),
                      ),
                      _buildContactRow(
                        context,
                        Icons.phone,
                        'Telefone',
                        _getPhone(config.clientType.id),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Versão do App',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Versão 1.0.0',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'Build ${config.clientType.id}_001',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAboutText(String clientId) {
    switch (clientId) {
      case 'guara':
        return 'O Guará é um clube dedicado ao esporte e lazer, oferecendo as melhores experiências para seus associados e visitantes.';
      case 'vale_das_minas':
        return 'O Vale das Minas é um clube tradicional que combina história, esporte e entretenimento em um ambiente familiar e acolhedor.';
      default:
        return 'Bem-vindo ao nosso clube! Aqui você encontra as melhores atividades esportivas e de lazer.';
    }
  }

  String _getWebsite(String clientId) {
    switch (clientId) {
      case 'guara':
        return 'www.guara.com.br';
      case 'vale_das_minas':
        return 'www.valedasminas.com.br';
      default:
        return 'www.clubee.com.br';
    }
  }

  String _getPhone(String clientId) {
    switch (clientId) {
      case 'guara':
        return '(11) 1234-5678';
      case 'vale_das_minas':
        return '(31) 9876-5432';
      default:
        return '(11) 0000-0000';
    }
  }
}
