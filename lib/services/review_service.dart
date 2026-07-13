import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config_service.dart';
import 'logging_service.dart';

class ReviewService {
  static ReviewService? _instance;
  ReviewService._internal();

  static ReviewService get instance {
    _instance ??= ReviewService._internal();
    return _instance!;
  }

  static const _prefsKey = 'last_in_app_review_at';
  static const _cooldown = Duration(days: 90);

  final InAppReview _inAppReview = InAppReview.instance;
  final _log = LoggingService.instance;

  /// Solicita avaliação nativa se disponível; caso contrário abre a listagem da loja.
  /// Respeita cooldown local de 90 dias.
  Future<void> maybeRequestReview() async {
    try {
      if (!await _canRequest()) {
        _log.info('InAppReview: cooldown ativo, pulando solicitação');
        return;
      }

      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        await _markRequested();
        _log.info('InAppReview: requestReview chamado');
        return;
      }

      final appStoreId =
          AppConfigService.instance.appConfig?.iosAppStoreId.trim() ?? '';
      await _inAppReview.openStoreListing(
        appStoreId: appStoreId.isEmpty ? null : appStoreId,
      );
      await _markRequested();
      _log.info('InAppReview: openStoreListing chamado (appStoreId=$appStoreId)');
    } catch (e, st) {
      _log.error('InAppReview: falha ao solicitar review', e, st);
    }
  }

  Future<bool> _canRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return true;
    final last = DateTime.tryParse(raw);
    if (last == null) return true;
    return DateTime.now().difference(last) >= _cooldown;
  }

  Future<void> _markRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, DateTime.now().toIso8601String());
  }
}
