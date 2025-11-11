import 'package:flutter/material.dart';
import '../../config/client_type.dart';
import '../../services/client_service.dart';

/// Widget que se adapta automaticamente às configurações do cliente atual
class ClientAwareButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  const ClientAwareButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
          Text(text),
        ],
      ),
    );
  }

  double _getBorderRadius() {
    final clientType = ClientService.instance.currentClientType;
    switch (clientType) {
      case ClientType.guara:
        return 8.0; // Bordas mais quadradas para Guará
      case ClientType.valeDasMinas:
        return 12.0; // Bordas mais arredondadas para Vale das Minas
    }
  }
}

/// Widget para exibir logo do cliente atual
class ClientLogo extends StatelessWidget {
  final double? width;
  final double? height;

  const ClientLogo({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final config = ClientService.instance.currentConfig;

    return Image.asset(
      config.logoPath,
      width: width ?? 120,
      height: height ?? 60,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback caso a imagem não exista
        return Container(
          width: width ?? 120,
          height: height ?? 60,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.business,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                config.clientType.displayName,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget para exibir informações específicas do cliente
class ClientInfoCard extends StatelessWidget {
  const ClientInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final config = ClientService.instance.currentConfig;
    final service = ClientService.instance;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClientLogo(width: 60, height: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.appName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'ID: ${config.clientType.id}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, 'API Base', config.apiBaseUrl),
            _buildInfoRow(
              context,
              'Android Package',
              config.androidPackageName,
            ),
            _buildInfoRow(context, 'iOS Bundle ID', config.iosBundleId),
            _buildInfoRow(context, 'Cor Primária', config.primaryColor),
            _buildInfoRow(
              context,
              'Suporte',
              service.getCustomSetting<String>('supportEmail') ?? 'N/A',
            ),
            _buildInfoRow(
              context,
              'Máx. Usuários',
              '${service.getCustomSetting<int>('maxUsers') ?? 0}',
            ),
            if (service.isFeatureEnabled('enableFeatureX')) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  '✓ Feature X Habilitada',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
