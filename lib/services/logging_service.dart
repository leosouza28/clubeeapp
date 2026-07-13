import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Serviço centralizado de logging para toda a aplicação
class LoggingService {
  static LoggingService? _instance;
  late final Logger _logger;

  LoggingService._internal() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      // Em release, evita formatação cara de JSON/debug na UI isolate (ANR).
      level: kReleaseMode ? Level.warning : Level.debug,
    );
  }

  /// Singleton instance
  static LoggingService get instance {
    _instance ??= LoggingService._internal();
    return _instance!;
  }

  /// Log de debug - usado para informações de desenvolvimento
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log de informação - usado para informações gerais
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log de aviso - usado para situações que podem causar problemas
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log de erro - usado para erros que não param a aplicação
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log de erro fatal - usado para erros críticos
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log de sucesso para operações importantes
  void success(String message) {
    _logger.i('✅ $message');
  }

  /// Log de início de operação
  void operation(String operation) {
    _logger.i('🔄 $operation');
  }

  /// Log de ação do usuário
  void userAction(String action, {Map<String, dynamic>? context}) {
    final contextStr = context != null ? ' - Context: $context' : '';
    _logger.i('👤 User Action: $action$contextStr');
  }

  /// Log de request HTTP
  void httpRequest(
    String method,
    String url, {
    int? statusCode,
    String? error,
  }) {
    if (error != null) {
      _logger.e('🌐 HTTP $method $url - Error: $error');
    } else if (statusCode != null) {
      if (statusCode >= 200 && statusCode < 300) {
        _logger.i('🌐 HTTP $method $url - Status: $statusCode');
      } else {
        _logger.w('🌐 HTTP $method $url - Status: $statusCode');
      }
    } else {
      _logger.d('🌐 HTTP $method $url');
    }
  }

  /// Log de autenticação
  void auth(String message, {bool isSuccess = true}) {
    if (isSuccess) {
      _logger.i('🔐 Auth: $message');
    } else {
      _logger.w('🔐 Auth Failed: $message');
    }
  }

  /// Log de navegação
  void navigation(String from, String to) {
    _logger.d('🧭 Navigation: $from → $to');
  }

  /// Log de cache
  void cache(String operation, String key, {bool hit = true}) {
    if (hit) {
      _logger.d('💾 Cache HIT: $operation ($key)');
    } else {
      _logger.d('💾 Cache MISS: $operation ($key)');
    }
  }

  /// Log de performance
  void performance(String operation, Duration duration) {
    _logger.d('⚡ Performance: $operation took ${duration.inMilliseconds}ms');
  }

  /// Imprime JSON formatado no terminal
  ///
  /// Aceita tanto Map/List quanto String JSON
  /// [data] - Dados a serem formatados (Map, List ou String JSON)
  /// [title] - Título opcional para identificar o JSON
  void json(dynamic data, {String? title}) {
    if (kReleaseMode) return;
    try {
      String jsonString;

      // Se já for uma String, tenta fazer parse para validar
      if (data is String) {
        final decoded = jsonDecode(data);
        jsonString = JsonEncoder.withIndent('  ').convert(decoded);
      } else {
        // Converte Map, List ou outro objeto para JSON formatado
        jsonString = JsonEncoder.withIndent('  ').convert(data);
      }

      final header = title != null ? '📋 JSON - $title:' : '📋 JSON:';
      final separator = '─' * 80;

      _logger.i('$header\n$separator\n$jsonString\n$separator');
    } catch (e, stackTrace) {
      _logger.e(
        '❌ Erro ao formatar JSON: $e',
        error: e,
        stackTrace: stackTrace,
      );
      _logger.d('Dados recebidos: $data');
    }
  }

  /// Configura o nível de log
  void setLevel(Level level) {
    Logger.level = level;
  }
}

/// Extensão para facilitar o uso do logging
extension LoggingServiceExtension on Object {
  /// Obtém o serviço de logging
  LoggingService get log => LoggingService.instance;
}
