import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'logging_service.dart';

/// Serviço para gerenciar o App Tracking Transparency (iOS)
class TrackingService {
  static final TrackingService instance = TrackingService._internal();
  factory TrackingService() => instance;
  TrackingService._internal();

  final LoggingService _log = LoggingService.instance;

  /// Solicita permissão de rastreamento (apenas no iOS)
  Future<void> requestTrackingAuthorization() async {
    if (!Platform.isIOS) {
      _log.debug('App Tracking Transparency é apenas para iOS');
      return;
    }

    try {
      // Verificar o status atual
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      _log.debug('Status inicial de tracking: $status');

      // Se ainda não foi determinado, solicitar permissão
      if (status == TrackingStatus.notDetermined) {
        _log.info('📱 Solicitando permissão de rastreamento...');
        
        final newStatus = await AppTrackingTransparency.requestTrackingAuthorization();
        _log.info('✅ Novo status de tracking: $newStatus');
        
        // Obter o identificador de publicidade se autorizado
        if (newStatus == TrackingStatus.authorized) {
          final uuid = await AppTrackingTransparency.getAdvertisingIdentifier();
          _log.debug('Advertising Identifier: $uuid');
        }
      } else {
        _log.debug('Permissão de tracking já foi determinada: $status');
        
        // Se já foi autorizado, obter o identificador
        if (status == TrackingStatus.authorized) {
          final uuid = await AppTrackingTransparency.getAdvertisingIdentifier();
          _log.debug('Advertising Identifier: $uuid');
        }
      }
    } catch (e) {
      _log.error('Erro ao solicitar permissão de tracking', e);
    }
  }

  /// Retorna o status atual de tracking
  Future<TrackingStatus> getTrackingStatus() async {
    if (!Platform.isIOS) {
      return TrackingStatus.notSupported;
    }

    try {
      return await AppTrackingTransparency.trackingAuthorizationStatus;
    } catch (e) {
      _log.error('Erro ao obter status de tracking', e);
      return TrackingStatus.notSupported;
    }
  }

  /// Retorna se o rastreamento está autorizado
  Future<bool> isTrackingAuthorized() async {
    if (!Platform.isIOS) {
      return false;
    }

    final status = await getTrackingStatus();
    return status == TrackingStatus.authorized;
  }

  /// Retorna o Advertising Identifier (IDFA) se disponível
  Future<String?> getAdvertisingIdentifier() async {
    if (!Platform.isIOS) {
      return null;
    }

    try {
      final isAuthorized = await isTrackingAuthorized();
      if (!isAuthorized) {
        _log.debug('Tracking não autorizado, IDFA não disponível');
        return null;
      }

      return await AppTrackingTransparency.getAdvertisingIdentifier();
    } catch (e) {
      _log.error('Erro ao obter Advertising Identifier', e);
      return null;
    }
  }
}
