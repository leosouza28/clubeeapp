import '../models/app_config_model.dart';
import '../services/api_service.dart';
import '../config/client_type.dart';

class AppConfigService {
  static AppConfigService? _instance;
  AppConfigService._internal();

  static AppConfigService get instance {
    _instance ??= AppConfigService._internal();
    return _instance!;
  }

  AppConfigModel? _appConfig;
  bool _isLoaded = false;

  /// Configurações do aplicativo
  AppConfigModel? get appConfig => _appConfig;

  /// Indica se as configurações foram carregadas
  bool get isLoaded => _isLoaded;

  /// Carrega as configurações do aplicativo
  Future<ApiResponse<AppConfigModel>> loadAppConfig(
    ClientType clientType,
  ) async {
    try {
      final apiService = await ApiService.getInstance();
      final response = await apiService.getAppConfiguracoes(clientType);

      if (response.success && response.data != null) {
        _appConfig = AppConfigModel.fromJson(response.data!);
        _isLoaded = true;
        return ApiResponse.success(_appConfig!);
      } else {
        _isLoaded = false;
        return ApiResponse.error(
          response.error ?? 'Erro ao carregar configurações',
          response.statusCode ?? 0,
        );
      }
    } catch (e) {
      _isLoaded = false;
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  /// Recarrega as configurações do aplicativo
  Future<ApiResponse<AppConfigModel>> reloadAppConfig(
    ClientType clientType,
  ) async {
    _isLoaded = false;
    _appConfig = null;
    return loadAppConfig(clientType);
  }

  /// Limpa as configurações
  void clearConfig() {
    _appConfig = null;
    _isLoaded = false;
  }

  /// Getter para URL de bilheteria
  String? get bilheteriaUrl {
    if (_appConfig?.bilheteriaAppConfig.ativada == true &&
        _appConfig?.bilheteriaAppConfig.isSiteExterno == true) {
      return _appConfig?.bilheteriaAppConfig.urlSiteExterno;
    }
    return null;
  }

  /// Getter para contatos de WhatsApp
  List<ContatoModel> get contatosWhatsApp {
    return _appConfig?.contatos
            .where((contato) => contato.isWhatsApp)
            .toList() ??
        [];
  }

  /// Getter para contatos de telefone
  List<ContatoModel> get contatosTelefone {
    return _appConfig?.contatos
            .where((contato) => contato.isTelefone)
            .toList() ??
        [];
  }

  /// Getter para contatos de email
  List<ContatoModel> get contatosEmail {
    return _appConfig?.contatos.where((contato) => contato.isEmail).toList() ??
        [];
  }
}
