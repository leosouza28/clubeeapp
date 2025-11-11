import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/client_service.dart';
import '../models/device_model.dart';

class ConnectedDevicesScreen extends StatefulWidget {
  const ConnectedDevicesScreen({super.key});

  @override
  State<ConnectedDevicesScreen> createState() => _ConnectedDevicesScreenState();
}

class _ConnectedDevicesScreenState extends State<ConnectedDevicesScreen> {
  List<DeviceModel> _devices = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = await ApiService.getInstance();
      final clientService = ClientService.instance;

      final result = await apiService.getDevices(
        clientService.currentConfig.clientType,
      );

      if (result.success && result.data != null) {
        final devices = result.data!
            .map((deviceJson) => DeviceModel.fromJson(deviceJson))
            .toList();

        // Ordenar por último acesso (mais recente primeiro)
        devices.sort((a, b) => b.lastAccess.compareTo(a.lastAccess));

        setState(() {
          _devices = devices;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorMessage(result.error ?? 'Erro ao carregar dispositivos');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Erro inesperado ao carregar dispositivos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispositivos Conectados'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDevices,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _devices.isEmpty
            ? _buildEmptyState()
            : _buildDevicesList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'Nenhum dispositivo encontrado',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Faça login em outros dispositivos para vê-los aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDevices,
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return _buildDeviceCard(device);
      },
    );
  }

  Widget _buildDeviceCard(DeviceModel device) {
    final agentInfo = device.agentInfo;
    final isCurrentDevice = device.isCurrentDevice;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrentDevice
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com ícone e nome do dispositivo
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getPlatformColor(
                      device.platformIcon,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getPlatformIconData(device.platformIcon),
                    size: 28,
                    color: _getPlatformColor(device.platformIcon),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              device.deviceName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (device.forceDisconnect)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'PENDENTE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (isCurrentDevice)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'ATUAL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${agentInfo['platform']?.toUpperCase() ?? 'DESCONHECIDO'} • ${agentInfo['app']} v${agentInfo['version']}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Informações do dispositivo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.schedule,
                    'Último Acesso',
                    _formatDateTime(device.lastAccess),
                    Colors.blue,
                  ),
                  if (device.appEngine != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.location_on,
                      'Localização',
                      device.appEngine!.formattedLocation,
                      Colors.orange,
                    ),
                    if (device.appEngine!.ip != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.wifi,
                        'IP',
                        device.appEngine!.ip!,
                        Colors.green,
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.smartphone,
                    'ID do Dispositivo',
                    device.deviceId,
                    Colors.purple,
                  ),
                ],
              ),
            ),

            // Informações adicionais expandíveis
            const SizedBox(height: 16),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Text(
                  'Detalhes Técnicos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        if (device.messageToken != null) ...[
                          _buildDetailRow('Token FCM', device.messageToken!),
                          const SizedBox(height: 8),
                        ],
                        if (device.appEngine?.userAgent != null) ...[
                          _buildDetailRow(
                            'User Agent',
                            device.appEngine!.userAgent!,
                          ),
                          const SizedBox(height: 8),
                        ],
                        _buildDetailRow('Agent String', device.deviceAgent),
                        const SizedBox(height: 8),
                        _buildDetailRow('ID Interno', device.id),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Botão de desconectar (apenas para dispositivos que não são o atual e não estão pendentes)
            if (!isCurrentDevice && !device.forceDisconnect) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showDisconnectDialog(device),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Desconectar Dispositivo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],

            // Aviso para dispositivos pendentes de desconexão
            if (device.forceDisconnect) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.orange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Desconexão Pendente',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Este dispositivo será desconectado na próxima solicitação que fizer ao servidor.',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
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

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  IconData _getPlatformIconData(String platform) {
    switch (platform.toLowerCase()) {
      case 'ios':
        return Icons.phone_iphone;
      case 'android':
        return Icons.android;
      default:
        return Icons.devices;
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'ios':
        return Colors.blue;
      case 'android':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 5) {
      return 'Agora mesmo';
    } else if (difference.inHours < 1) {
      return 'Há ${difference.inMinutes} minuto${difference.inMinutes != 1 ? 's' : ''}';
    } else if (difference.inDays < 1) {
      return 'Há ${difference.inHours} hora${difference.inHours != 1 ? 's' : ''}';
    } else if (difference.inDays < 7) {
      return 'Há ${difference.inDays} dia${difference.inDays != 1 ? 's' : ''}';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDisconnectDialog(DeviceModel device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Desconectar Dispositivo'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tem certeza que deseja desconectar este dispositivo?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _getPlatformIconData(device.platformIcon),
                    color: _getPlatformColor(device.platformIcon),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.deviceName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${device.agentInfo['platform']?.toUpperCase()} • ${device.agentInfo['app']}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'O dispositivo será desconectado e precisará fazer login novamente.',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _disconnectDevice(device);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnectDevice(DeviceModel device) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Desconectando dispositivo...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );

    try {
      final apiService = await ApiService.getInstance();
      final clientService = ClientService.instance;

      final result = await apiService.disconnectDevice(
        clientService.currentConfig.clientType,
        device.deviceId,
      );

      // Fechar dialog de loading
      if (mounted) Navigator.of(context).pop();

      if (result.success) {
        _showSuccessMessage('Solicitação de desconexão enviada com sucesso!');
        // Recarregar a lista de dispositivos para mostrar o status atualizado
        await _loadDevices();
      } else {
        _showErrorMessage(result.error ?? 'Erro ao desconectar dispositivo');
      }
    } catch (e) {
      // Fechar dialog de loading
      if (mounted) Navigator.of(context).pop();
      _showErrorMessage('Erro inesperado ao desconectar dispositivo');
    }
  }
}
