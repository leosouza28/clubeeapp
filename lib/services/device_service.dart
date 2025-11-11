import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class DeviceService {
  static DeviceService? _instance;
  late StorageService _storageService;

  DeviceService._();

  static Future<DeviceService> getInstance() async {
    _instance ??= DeviceService._();
    _instance!._storageService = await StorageService.getInstance();
    return _instance!;
  }

  // Gera um ID único para o dispositivo
  Future<String> getDeviceId() async {
    String? deviceId = await _storageService.getDeviceId();

    if (deviceId == null) {
      // Gera um novo ID único
      deviceId = _generateUniqueId();
      await _storageService.saveDeviceId(deviceId);
    }

    return deviceId;
  }

  // Obtém o nome do dispositivo
  Future<String> getDeviceName() async {
    String? deviceName = await _storageService.getDeviceName();

    if (deviceName == null) {
      deviceName = await _getDeviceNameFromSystem();
      await _storageService.saveDeviceName(deviceName);
    }

    return deviceName;
  }

  // Obtém o agent do dispositivo
  Future<String> getDeviceAgent() async {
    String? deviceAgent = await _storageService.getDeviceAgent();

    if (deviceAgent == null) {
      deviceAgent = await _buildDeviceAgent();
      await _storageService.saveDeviceAgent(deviceAgent);
    }

    return deviceAgent;
  }

  // Obtém o IP do dispositivo (placeholder - implementação real requer mais dependências)
  Future<String?> getDeviceIp() async {
    String? deviceIp = await _storageService.getDeviceIp();

    if (deviceIp == null) {
      // Por enquanto retorna null, pode ser implementado com network_info_plus
      deviceIp = await _getDeviceIpFromSystem();
      if (deviceIp != null) {
        await _storageService.saveDeviceIp(deviceIp);
      }
    }

    return deviceIp;
  }

  // Gera um ID único baseado em timestamp e random
  String _generateUniqueId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = random.nextInt(999999);
    return 'device_${timestamp}_$randomPart';
  }

  // Obtém o nome do dispositivo do sistema
  Future<String> _getDeviceNameFromSystem() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.name} (${iosInfo.model})';
      } else if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        return '${webInfo.browserName} on ${webInfo.platform}';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return '${macInfo.computerName} (${macInfo.model})';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return windowsInfo.computerName;
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        return '${linuxInfo.name} ${linuxInfo.version}';
      }
    } catch (e) {
      // Se falhar, retorna um nome genérico
      return 'Unknown Device';
    }

    return 'Unknown Device';
  }

  // Constrói o device agent no formato: empresa,plataforma,versionCode
  Future<String> _buildDeviceAgent() async {
    const empresa = 'Clubee';
    final plataforma = _getPlatformName();
    const versionCode = '1.0.0'; // Pode ser obtido do package_info_plus

    return '$empresa,$plataforma,$versionCode';
  }

  // Obtém o nome da plataforma
  String _getPlatformName() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else if (kIsWeb) {
      return 'web';
    } else if (Platform.isMacOS) {
      return 'macos';
    } else if (Platform.isWindows) {
      return 'windows';
    } else if (Platform.isLinux) {
      return 'linux';
    }
    return 'unknown';
  }

  // Placeholder para obter IP do dispositivo
  Future<String?> _getDeviceIpFromSystem() async {
    // Implementação básica - retorna null por enquanto
    // Para implementar completamente, precisaríamos de network_info_plus
    return null;
  }

  // Força a regeneração de todas as informações do dispositivo
  Future<void> refreshDeviceInfo() async {
    await _storageService.remove('device_id');
    await _storageService.remove('device_name');
    await _storageService.remove('device_agent');
    await _storageService.remove('device_ip');
  }

  // Obtém todas as informações do dispositivo de uma vez
  Future<Map<String, String?>> getAllDeviceInfo() async {
    return {
      'device_id': await getDeviceId(),
      'device_name': await getDeviceName(),
      'device_agent': await getDeviceAgent(),
      'device_ip': await getDeviceIp(),
    };
  }
}
