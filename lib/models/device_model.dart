class DeviceModel {
  final String id;
  final String deviceId;
  final String deviceName;
  final String deviceAgent;
  final DateTime lastAccess;
  final String? messageToken;
  final AppEngineModel? appEngine;
  final bool forceDisconnect;

  DeviceModel({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.deviceAgent,
    required this.lastAccess,
    this.messageToken,
    this.appEngine,
    this.forceDisconnect = false,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['_id'] ?? '',
      deviceId: json['app_device_id'] ?? '',
      deviceName: json['app_device_name'] ?? '',
      deviceAgent: json['app_device_agent'] ?? '',
      lastAccess:
          DateTime.tryParse(json['app_device_last_access'] ?? '') ??
          DateTime.now(),
      messageToken: json['app_device_message_token'],
      appEngine: json['appEngine'] != null
          ? AppEngineModel.fromJson(json['appEngine'])
          : null,
      forceDisconnect: json['app_device_force_disconnect'] == true,
    );
  }

  // Extrai informações do user agent
  Map<String, String> get agentInfo {
    final parts = deviceAgent.split(';');
    if (parts.length >= 3) {
      return {'app': parts[0], 'platform': parts[1], 'version': parts[2]};
    }
    return {'app': deviceAgent, 'platform': 'Desconhecido', 'version': 'N/A'};
  }

  // Retorna o ícone baseado na plataforma
  String get platformIcon {
    final platform = agentInfo['platform']?.toLowerCase() ?? '';
    if (platform.contains('ios')) {
      return 'ios';
    } else if (platform.contains('android')) {
      return 'android';
    } else {
      return 'unknown';
    }
  }

  // Retorna se é o dispositivo atual (baseado no último acesso)
  bool get isCurrentDevice {
    final now = DateTime.now();
    final difference = now.difference(lastAccess);
    return difference.inMinutes <
        5; // Considera atual se último acesso foi há menos de 5 minutos
  }
}

class AppEngineModel {
  final String? ip;
  final String? city;
  final String? region;
  final String? userAgent;
  final DateTime? lastRequest;

  AppEngineModel({
    this.ip,
    this.city,
    this.region,
    this.userAgent,
    this.lastRequest,
  });

  factory AppEngineModel.fromJson(Map<String, dynamic> json) {
    return AppEngineModel(
      ip: json['ip'],
      city: json['city'],
      region: json['region'],
      userAgent: json['user_agent'],
      lastRequest: DateTime.tryParse(json['last_request'] ?? ''),
    );
  }

  // Formata a localização
  String get formattedLocation {
    if (city != null && region != null) {
      return '${city!.toUpperCase()}, ${region!.toUpperCase()}';
    } else if (city != null) {
      return city!.toUpperCase();
    } else if (region != null) {
      return region!.toUpperCase();
    }
    return 'Localização desconhecida';
  }
}
