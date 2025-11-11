import '../config/client_config.dart';
import '../config/client_type.dart';
import 'logging_service.dart';
import 'firebase_service.dart';
import 'deep_link_service.dart';

class ClientService {
  static ClientService? _instance;
  static ClientService get instance => _instance ??= ClientService._internal();
  final _log = LoggingService.instance;

  ClientService._internal() {
    _log.debug('ClientService instance created');
  }

  /// Inicializa o ClientService e o Firebase
  Future<void> initialize([ClientType? initialClient]) async {
    final clientType = initialClient ?? _currentClient;
    _log.info('Initializing ClientService for ${clientType.displayName}');

    await setClient(clientType);
    _log.success('ClientService initialized successfully');
  }

  // Cliente atual - por padrão será Guará, mas pode ser alterado
  ClientType _currentClient = ClientType.guara;

  ClientType get currentClientType => _currentClient;

  ClientConfig get currentConfig => ClientConfig.fromClientType(_currentClient);

  get clientConfig => null;

  /// Altera o cliente atual
  Future<void> setClient(ClientType clientType) async {
    _log.info(
      'Changing client from ${_currentClient.displayName} to ${clientType.displayName}',
    );

    _currentClient = clientType;

    // Inicializar Firebase para o novo cliente
    try {
      await FirebaseService.instance.initializeForClient(clientType);
      _log.success('Firebase initialized for ${clientType.displayName}');
    } catch (e) {
      _log.warning(
        'Failed to initialize Firebase for ${clientType.displayName}: $e',
      );
    }

    // Inicializar Deep Links para o novo cliente
    try {
      DeepLinkService.instance.initializeForClient(clientType);
      _log.success('Deep links initialized for ${clientType.displayName}');
    } catch (e) {
      _log.warning(
        'Failed to initialize deep links for ${clientType.displayName}: $e',
      );
    }

    _log.success('Client changed successfully to ${clientType.displayName}');
  }

  /// Obtém configuração de um cliente específico
  ClientConfig getConfigForClient(ClientType clientType) {
    _log.debug('Getting config for client: ${clientType.displayName}');
    return ClientConfig.fromClientType(clientType);
  }

  /// Lista todos os clientes disponíveis
  List<ClientType> getAllClients() {
    _log.debug('Getting all available clients');
    return ClientType.values;
  }

  /// Verifica se uma funcionalidade está habilitada para o cliente atual
  bool isFeatureEnabled(String featureName) {
    final isEnabled = currentConfig.customSettings[featureName] ?? false;
    _log.debug(
      'Feature "$featureName" is ${isEnabled ? 'enabled' : 'disabled'} for ${_currentClient.displayName}',
    );
    return isEnabled;
  }

  /// Obtém uma configuração customizada do cliente atual
  T? getCustomSetting<T>(String key) {
    final value = currentConfig.customSettings[key] as T?;
    _log.debug(
      'Custom setting "$key" for ${_currentClient.displayName}: $value',
    );
    return value;
  }

  /// Obtém o FirebaseService atual
  FirebaseService get firebaseService => FirebaseService.instance;

  /// Obtém o DeepLinkService atual
  DeepLinkService get deepLinkService => DeepLinkService.instance;
}
