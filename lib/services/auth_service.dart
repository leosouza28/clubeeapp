import 'dart:io';
import '../config/client_type.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'logging_service.dart';

class AuthService {
  static AuthService? _instance;
  late ApiService _apiService;
  late StorageService _storageService;
  final _log = LoggingService.instance;

  AuthService._();

  static Future<AuthService> getInstance() async {
    _instance ??= AuthService._();
    _instance!._apiService = await ApiService.getInstance();
    _instance!._storageService = await StorageService.getInstance();
    _instance!._log.debug('AuthService instance created');
    return _instance!;
  }

  // Faz login
  Future<AuthResult> login(
    ClientType clientType,
    String cpfCnpj,
    String senha,
  ) async {
    _log.operation(
      'Starting login process for user: ${cpfCnpj.substring(0, 3)}***',
    );
    try {
      final response = await _apiService.login(clientType, cpfCnpj, senha);

      if (response.success && response.data != null) {
        _log.auth('Login successful for user: ${cpfCnpj.substring(0, 3)}***');
        return AuthResult.success(response.data!.user, response.data!.token);
      } else {
        _log.auth(
          'Login failed for user: ${cpfCnpj.substring(0, 3)}*** - ${response.error}',
          isSuccess: false,
        );
        return AuthResult.error(response.error ?? 'Erro no login');
      }
    } catch (e) {
      _log.error('Login error for user: ${cpfCnpj.substring(0, 3)}***', e);
      return AuthResult.error('Erro inesperado: $e');
    }
  }

  // Faz logout
  Future<void> logout() async {
    _log.operation('Starting logout process');
    try {
      // Tentar chamar a rota de logoff no servidor
      try {
        await _apiService.logoff();
        _log.auth('Server logoff successful');
      } catch (e) {
        // Se falhar, apenas logar o erro mas continuar com o logout local
        _log.warning('Server logoff failed, continuing with local logout: $e');
      }

      // Limpar dados locais
      await _apiService.logout();
      _log.auth('Logout successful');
    } catch (e) {
      _log.error('Logout error', e);
      rethrow;
    }
  }

  // Exclui a conta do usuário
  Future<AuthResult> deleteAccount(ClientType clientType) async {
    _log.operation('Starting account deletion process');
    try {
      final response = await _apiService.deleteAccount(clientType);

      if (response.success) {
        _log.auth('Account deletion successful');
        // Fazer logout após exclusão bem-sucedida
        await logout();
        return AuthResult.successOperation();
      } else {
        _log.auth(
          'Account deletion failed: ${response.error}',
          isSuccess: false,
        );
        return AuthResult.error(response.error ?? 'Erro ao excluir conta');
      }
    } catch (e) {
      _log.error('Account deletion error', e);
      return AuthResult.error('Erro inesperado ao excluir conta: $e');
    }
  }

  // Verifica se está autenticado
  Future<bool> isAuthenticated() async {
    _log.debug('Checking authentication status');
    try {
      final isAuth = await _apiService.isAuthenticated();
      _log.debug('Authentication status: $isAuth');
      return isAuth;
    } catch (e) {
      _log.error('Error checking authentication status', e);
      return false;
    }
  }

  // Obtém o usuário atual
  Future<UserModel?> getCurrentUser() async {
    _log.debug('Getting current user');
    try {
      final loginData = await _apiService.getCurrentUser();
      if (loginData?.user != null) {
        _log.debug('Current user found: ${loginData!.user.nome}');
        _log.json(loginData.user.toJson());
      } else {
        _log.debug('No current user found');
      }
      return loginData?.user;
    } catch (e) {
      _log.error('Error getting current user', e);
      return null;
    }
  }

  // Obtém o token atual
  Future<String?> getCurrentToken() async {
    _log.debug('Getting current token');
    try {
      final token = await _storageService.getToken();
      _log.debug('Token ${token != null ? 'found' : 'not found'}');
      return token;
    } catch (e) {
      _log.error('Error getting current token', e);
      return null;
    }
  }

  // Verifica se o token ainda é válido
  Future<bool> isTokenValid() async {
    _log.debug('Checking token validity');
    try {
      final loginData = await _apiService.getCurrentUser();
      if (loginData != null) {
        final isValid = loginData.isTokenValid;
        _log.debug('Token is ${isValid ? 'valid' : 'invalid'}');
        return isValid;
      }
      _log.debug('No login data found, token is invalid');
      return false;
    } catch (e) {
      _log.error('Error checking token validity', e);
      return false;
    }
  }

  // Renovar sessão se necessário (placeholder para futuras implementações)
  Future<AuthResult> refreshSession(ClientType clientType) async {
    _log.operation('Refreshing session');
    try {
      // Por enquanto, apenas verifica se ainda está autenticado
      final isAuth = await isAuthenticated();
      final isValid = await isTokenValid();

      if (isAuth && isValid) {
        final user = await getCurrentUser();
        final token = await getCurrentToken();
        if (user != null && token != null) {
          _log.success('Session refreshed successfully');
          return AuthResult.success(user, token);
        }
      }

      _log.warning('Session refresh failed - session expired');
      return AuthResult.error('Sessão expirada');
    } catch (e) {
      _log.error('Error refreshing session', e);
      return AuthResult.error('Erro ao renovar sessão');
    }
  }

  // Atualiza dados do usuário localmente
  Future<void> updateUserData(UserModel user) async {
    _log.debug('Updating user data locally');
    try {
      await _storageService.saveUser(user);
      _log.success('User data updated successfully');
    } catch (e) {
      _log.error('Error updating user data', e);
      rethrow;
    }
  }

  // Busca títulos do usuário autenticado
  Future<TitulosResult> getTitulos(ClientType clientType) async {
    _log.operation('Fetching user titles');

    final response = await _apiService.getTitulos(clientType);

    if (response.success && response.data != null) {
      _log.success(
        'Titles fetched successfully: ${response.data!.length} titles found',
      );
      return TitulosResult.success(response.data!);
    } else if (response.success && response.data == null) {
      _log.info('API responded successfully but with no titles');
      return TitulosResult.success([]);
    } else {
      // Verificar se é erro de conexão baseado no statusCode ou mensagem
      if (response.statusCode == 0 ||
          (response.error != null && response.error!.contains('conexão'))) {
        _log.error(
          'Connection error detected - statusCode: ${response.statusCode}, error: ${response.error}',
        );
        return TitulosResult.connectionError(
          'Falha de conexão. Verifique sua internet e tente novamente.',
        );
      } else {
        _log.warning('API responded with error: ${response.error}');
        return TitulosResult.error(
          response.error ?? 'Erro desconhecido na API',
        );
      }
    }
  }

  // Busca detalhes de um título específico
  Future<TituloDetailsResult> getTituloDetails(
    ClientType clientType,
    String tituloId,
  ) async {
    _log.operation('Fetching title details for ID: $tituloId');

    final response = await _apiService.getTituloDetails(clientType, tituloId);

    if (response.success && response.data != null) {
      _log.success('Title details fetched successfully for ID: $tituloId');
      return TituloDetailsResult.success(response.data!);
    } else if (response.success && response.data == null) {
      _log.warning(
        'API responded successfully but title not found for ID: $tituloId',
      );
      return TituloDetailsResult.error('Título não encontrado');
    } else {
      // Verificar se é erro de conexão baseado no statusCode ou mensagem
      if (response.statusCode == 0 ||
          (response.error != null && response.error!.contains('conexão'))) {
        _log.error(
          'Connection error fetching title details for ID: $tituloId - ${response.error}',
        );
        return TituloDetailsResult.connectionError(
          'Falha de conexão. Verifique sua internet e tente novamente.',
        );
      } else {
        _log.warning(
          'API responded with error for ID: $tituloId - ${response.error}',
        );
        return TituloDetailsResult.error(
          response.error ?? 'Erro desconhecido na API',
        );
      }
    }
  }

  // Busca cobranças de um título
  Future<CobrancasResult> getTituloCobrancas(
    ClientType clientType,
    String tituloId,
  ) async {
    _log.operation('Fetching cobranças for title ID: $tituloId');

    final response = await _apiService.getTituloCobrancas(clientType, tituloId);

    if (response.success && response.data != null) {
      _log.success('Cobranças fetched successfully for title ID: $tituloId');
      return CobrancasResult.success(response.data!);
    } else if (response.success && response.data == null) {
      _log.warning(
        'API responded successfully but cobranças not found for title ID: $tituloId',
      );
      return CobrancasResult.error('Cobranças não encontradas');
    } else {
      if (response.statusCode == 0 ||
          (response.error != null && response.error!.contains('conexão'))) {
        _log.error(
          'Connection error fetching cobranças for title ID: $tituloId - ${response.error}',
        );
        return CobrancasResult.connectionError(
          'Falha de conexão. Verifique sua internet e tente novamente.',
        );
      } else {
        _log.warning(
          'API responded with error for title ID: $tituloId - ${response.error}',
        );
        return CobrancasResult.error(
          response.error ?? 'Erro desconhecido na API',
        );
      }
    }
  }

  // Cria negociação de cobranças
  Future<NegociacaoResult> criarNegociacaoCobrancas(
    ClientType clientType,
    String tituloId,
    List<String> cobrancasIds,
  ) async {
    _log.operation(
      'Creating negociação for title ID: $tituloId with ${cobrancasIds.length} cobranças',
    );

    final response = await _apiService.criarNegociacaoCobrancas(
      clientType,
      tituloId,
      cobrancasIds,
    );

    if (response.success && response.data != null) {
      _log.success('Negociação created successfully');
      return NegociacaoResult.success(response.data!);
    } else if (response.success && response.data == null) {
      _log.warning('API responded successfully but negociação data is null');
      return NegociacaoResult.error('Erro ao criar negociação');
    } else {
      if (response.statusCode == 0 ||
          (response.error != null && response.error!.contains('conexão'))) {
        _log.error('Connection error creating negociação - ${response.error}');
        return NegociacaoResult.connectionError(
          'Falha de conexão. Verifique sua internet e tente novamente.',
        );
      } else {
        _log.warning('API responded with error - ${response.error}');
        return NegociacaoResult.error(
          response.error ?? 'Erro desconhecido na API',
        );
      }
    }
  }

  // Busca guias de pagamento de um título
  Future<GuiasResult> getTituloGuias(
    ClientType clientType,
    String tituloId,
  ) async {
    _log.operation('Fetching guias for title ID: $tituloId');

    final response = await _apiService.getTituloGuias(clientType, tituloId);

    if (response.success && response.data != null) {
      _log.success('Guias fetched successfully for title ID: $tituloId');
      return GuiasResult.success(response.data!);
    } else if (response.success && response.data == null) {
      _log.warning(
        'API responded successfully but guias not found for title ID: $tituloId',
      );
      return GuiasResult.error('Guias não encontradas');
    } else {
      if (response.statusCode == 0 ||
          (response.error != null && response.error!.contains('conexão'))) {
        _log.error(
          'Connection error fetching guias for title ID: $tituloId - ${response.error}',
        );
        return GuiasResult.connectionError(
          'Falha de conexão. Verifique sua internet e tente novamente.',
        );
      } else {
        _log.warning(
          'API responded with error for title ID: $tituloId - ${response.error}',
        );
        return GuiasResult.error(response.error ?? 'Erro desconhecido na API');
      }
    }
  }

  // Busca uma guia específica pelo ID
  Future<GuiaResult> getGuiaById(ClientType clientType, String guiaId) async {
    _log.operation('Fetching guia by ID: $guiaId');

    final response = await _apiService.getGuiaById(clientType, guiaId);

    if (response.success && response.data != null) {
      _log.success('Guia fetched successfully by ID: $guiaId');
      return GuiaResult.success(response.data!);
    } else if (response.success && response.data == null) {
      _log.warning(
        'API responded successfully but guia not found by ID: $guiaId',
      );
      return GuiaResult.error('Guia não encontrada');
    } else {
      if (response.statusCode == 0 ||
          (response.error != null && response.error!.contains('conexão'))) {
        _log.error(
          'Connection error fetching guia by ID: $guiaId - ${response.error}',
        );
        return GuiaResult.connectionError(
          'Falha de conexão. Verifique sua internet e tente novamente.',
        );
      } else {
        _log.warning(
          'API responded with error for guia ID: $guiaId - ${response.error}',
        );
        return GuiaResult.error(response.error ?? 'Erro desconhecido na API');
      }
    }
  }

  // Busca dados do usuário logado
  Future<UserUpdateResult> getLoggedUserData(ClientType clientType) async {
    _log.info('Fetching logged user data');

    final response = await _apiService.getLoggedUser(clientType);

    if (response.success && response.data != null) {
      _log.success('Logged user data fetched successfully');
      return UserUpdateResult.success(UserModel.fromJson(response.data!));
    } else {
      _log.error('Failed to fetch logged user data: ${response.error}');
      return UserUpdateResult.error(
        response.error ?? 'Erro ao buscar dados do usuário',
      );
    }
  }

  // Altera a senha do usuário
  Future<AuthResult> changePassword(
    ClientType clientType,
    String novaSenha,
  ) async {
    _log.info('Attempting to change password');

    final response = await _apiService.changePassword(clientType, novaSenha);

    if (response.success) {
      _log.success('Password changed successfully');
      return AuthResult.successOperation();
    } else {
      _log.error('Failed to change password: ${response.error}');
      return AuthResult.error(response.error ?? 'Erro ao alterar senha');
    }
  }

  // Atualiza dados pessoais do usuário
  Future<UserUpdateResult> updatePersonalData(
    ClientType clientType,
    Map<String, dynamic> userData,
  ) async {
    _log.operation('Starting user data update process');
    try {
      final response = await _apiService.updateUserData(clientType, userData);

      _log.info(
        'Update response: success=${response.success}, data=${response.data}',
      );

      if (response.success && response.data != null) {
        _log.success('User data updated successfully');

        // Buscar dados atualizados do usuário
        final updatedUser = await getCurrentUser();
        if (updatedUser != null) {
          await updateUserData(updatedUser);
          return UserUpdateResult.success(updatedUser);
        }

        return UserUpdateResult.successOperation();
      } else {
        _log.warning('User data update failed - ${response.error}');
        return UserUpdateResult.error(
          response.error ?? 'Erro ao atualizar dados',
        );
      }
    } catch (e) {
      _log.error('User data update error', e);
      return UserUpdateResult.error('Erro inesperado: $e');
    }
  }

  // Busca endereço pelo CEP
  Future<CepResult> searchCep(String cep, ClientType clientType) async {
    _log.operation('Searching CEP: ${cep.replaceAll(RegExp(r'[^0-9]'), '')}');
    try {
      final response = await _apiService.searchCep(cep, clientType);

      if (response.success && response.data != null) {
        _log.success('CEP found successfully');
        return CepResult.success(response.data!);
      } else {
        _log.warning('CEP search failed - ${response.error}');
        return CepResult.error(response.error ?? 'Erro ao buscar CEP');
      }
    } catch (e) {
      _log.error('CEP search error', e);
      return CepResult.error('Erro inesperado: $e');
    }
  }

  // Busca lista de estados
  Future<EstadosResult> getEstados(ClientType clientType) async {
    _log.operation('Fetching states list');
    try {
      final response = await _apiService.getEstados(clientType);

      if (response.success && response.data != null) {
        _log.success('States fetched successfully');
        return EstadosResult.success(response.data!);
      } else {
        _log.warning('States fetch failed - ${response.error}');
        return EstadosResult.error(response.error ?? 'Erro ao buscar estados');
      }
    } catch (e) {
      _log.error('States fetch error', e);
      return EstadosResult.error('Erro inesperado: $e');
    }
  }

  // Busca lista de cidades por estado
  Future<CidadesResult> getCidades(
    ClientType clientType,
    String siglaEstado,
  ) async {
    _log.operation('Fetching cities for state: $siglaEstado');
    try {
      final response = await _apiService.getCidades(clientType, siglaEstado);

      if (response.success && response.data != null) {
        _log.success('Cities fetched successfully for state: $siglaEstado');
        return CidadesResult.success(response.data!);
      } else {
        _log.warning('Cities fetch failed - ${response.error}');
        return CidadesResult.error(response.error ?? 'Erro ao buscar cidades');
      }
    } catch (e) {
      _log.error('Cities fetch error', e);
      return CidadesResult.error('Erro inesperado: $e');
    }
  }

  // Upload de imagem de perfil
  Future<PhotoUploadResult> uploadProfileImage(
    ClientType clientType,
    File imageFile,
  ) async {
    _log.operation('Starting profile image upload');
    try {
      // Primeiro, obter o usuário atual para pegar o ID
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        return PhotoUploadResult.error('Usuário não autenticado');
      }

      final response = await _apiService.uploadProfileImage(
        clientType,
        imageFile,
        currentUser.id,
      );

      if (response.success && response.data != null) {
        final url = response.data!['url'] as String?;
        if (url != null) {
          _log.success('Profile image uploaded successfully');

          // Atualizar o usuário local com a nova URL da imagem
          final updatedUser = currentUser.copyWith(profileImagePublic: url);
          await updateUserData(updatedUser);

          return PhotoUploadResult.success(url);
        } else {
          return PhotoUploadResult.error('URL da imagem não retornada');
        }
      } else {
        _log.warning('Profile image upload failed - ${response.error}');
        return PhotoUploadResult.error(
          response.error ?? 'Erro ao fazer upload da imagem',
        );
      }
    } catch (e) {
      _log.error('Profile image upload error', e);
      return PhotoUploadResult.error('Erro inesperado: $e');
    }
  }

  // Busca lista de parentescos
  Future<ParentescosResult> getParentescos(ClientType clientType) async {
    _log.operation('Fetching parentescos');
    try {
      final response = await _apiService.getParentescos(clientType);

      if (response.success && response.data != null) {
        _log.operation('Parentescos fetched successfully');
        return ParentescosResult.success(response.data!);
      } else {
        _log.operation('Failed to fetch parentescos: ${response.error}');
        return ParentescosResult.error(
          response.error ?? 'Erro ao buscar parentescos',
        );
      }
    } catch (e) {
      _log.error('Error fetching parentescos', e);
      return ParentescosResult.error('Erro inesperado: $e');
    }
  }

  // Atribui uma vaga de dependente
  Future<AtribuirVagaResult> atribuirVagaDependente(
    ClientType clientType,
    Map<String, dynamic> data,
  ) async {
    _log.operation('Assigning dependente vaga');
    try {
      final response = await _apiService.atribuirVagaDependente(
        clientType,
        data,
      );

      if (response.success && response.data != null) {
        _log.operation('Dependente vaga assigned successfully');
        return AtribuirVagaResult.success(response.data!);
      } else {
        _log.operation('Failed to assign dependente vaga: ${response.error}');
        return AtribuirVagaResult.error(
          response.error ?? 'Erro ao atribuir vaga',
        );
      }
    } catch (e) {
      _log.error('Error assigning dependente vaga', e);
      return AtribuirVagaResult.error('Erro inesperado: $e');
    }
  }

  // Aplica aceite ou recusa dos termos de uso do título
  Future<AplicarAceiteResult> aplicarAceite(
    ClientType clientType,
    String tituloId,
    bool aceite,
  ) async {
    _log.operation('Applying aceite: $aceite for titulo: $tituloId');
    try {
      final response = await _apiService.aplicarAceite(
        clientType,
        tituloId,
        aceite,
      );

      if (response.success && response.data != null) {
        _log.operation('Aceite applied successfully');
        return AplicarAceiteResult.success(response.data!);
      } else {
        _log.operation('Failed to apply aceite: ${response.error}');
        return AplicarAceiteResult.error(
          response.error ?? 'Erro ao aplicar aceite',
        );
      }
    } catch (e) {
      _log.error('Error applying aceite', e);
      return AplicarAceiteResult.error('Erro inesperado: $e');
    }
  }

  // Obtém a imagem do perfil do usuário logado
  Future<LoggedUserImageResult> getLoggedUserImage(
    ClientType clientType,
  ) async {
    _log.operation('Getting logged user image');
    try {
      final response = await _apiService.getLoggedUserImage(clientType);

      if (response.success && response.data != null) {
        final imageUrl = response.data!['image_url'] as String?;
        _log.operation('Logged user image retrieved successfully');
        return LoggedUserImageResult.success(imageUrl);
      } else {
        _log.operation('Failed to get logged user image: ${response.error}');
        return LoggedUserImageResult.error(
          response.error ?? 'Erro ao buscar imagem',
        );
      }
    } catch (e) {
      _log.error('Error getting logged user image', e);
      return LoggedUserImageResult.error('Erro inesperado: $e');
    }
  }

  // Faz upload de arquivo out-of-db
  Future<UploadOutOfDbResult> uploadOutOfDb(
    ClientType clientType,
    File file,
  ) async {
    _log.operation('Uploading file out-of-db');
    try {
      final response = await _apiService.uploadOutOfDb(clientType, file);

      if (response.success && response.data != null) {
        final url = response.data!['url'] as String?;
        if (url != null) {
          _log.operation('File uploaded successfully');
          return UploadOutOfDbResult.success(url);
        } else {
          _log.operation('Upload response missing URL');
          return UploadOutOfDbResult.error('Resposta sem URL');
        }
      } else {
        _log.operation('Failed to upload file: ${response.error}');
        return UploadOutOfDbResult.error(
          response.error ?? 'Erro ao fazer upload',
        );
      }
    } catch (e) {
      _log.error('Error uploading file', e);
      return UploadOutOfDbResult.error('Erro inesperado: $e');
    }
  }

  // Atribui foto do titular para gerar carteirinha
  Future<AtribuirTitularFotoResult> atribuirTitularFoto(
    ClientType clientType,
    String tituloId,
    String url,
  ) async {
    _log.operation('Atribuindo foto do titular: $tituloId');
    try {
      final response = await _apiService.atribuirTitularFoto(
        clientType,
        tituloId,
        url,
      );

      if (response.success && response.data != null) {
        _log.operation('Foto atribuída com sucesso');
        return AtribuirTitularFotoResult.success(response.data!);
      } else {
        _log.operation('Falha ao atribuir foto: ${response.error}');
        return AtribuirTitularFotoResult.error(
          response.error ?? 'Erro ao atribuir foto',
        );
      }
    } catch (e) {
      _log.error('Erro ao atribuir foto', e);
      return AtribuirTitularFotoResult.error('Erro inesperado: $e');
    }
  }

  // Atribui foto do dependente para atualizar carteirinha
  Future<AtribuirVagaFotoResult> atribuirVagaFoto(
    ClientType clientType,
    String tituloId,
    String dependenteHash,
    String url,
  ) async {
    _log.operation('Atribuindo foto do dependente: $dependenteHash');
    try {
      final response = await _apiService.atribuirVagaFoto(
        clientType,
        tituloId,
        dependenteHash,
        url,
      );

      if (response.success && response.data != null) {
        _log.operation('Foto do dependente atribuída com sucesso');
        return AtribuirVagaFotoResult.success(response.data!);
      } else {
        _log.operation(
          'Falha ao atribuir foto do dependente: ${response.error}',
        );
        return AtribuirVagaFotoResult.error(
          response.error ?? 'Erro ao atribuir foto do dependente',
        );
      }
    } catch (e) {
      _log.error('Erro ao atribuir foto do dependente', e);
      return AtribuirVagaFotoResult.error('Erro inesperado: $e');
    }
  }
}

// Classe para padronizar resultados de autenticação
class AuthResult {
  final bool success;
  final UserModel? user;
  final String? token;
  final String? error;

  AuthResult._({required this.success, this.user, this.token, this.error});

  factory AuthResult.success(UserModel user, String token) {
    return AuthResult._(success: true, user: user, token: token);
  }

  factory AuthResult.successOperation() {
    return AuthResult._(success: true);
  }

  factory AuthResult.error(String error) {
    return AuthResult._(success: false, error: error);
  }
}

// Classe para padronizar resultados de busca de títulos
class TitulosResult {
  final bool success;
  final List<Map<String, dynamic>>? data;
  final String? error;
  final bool isConnectionError;

  TitulosResult._({
    required this.success,
    this.data,
    this.error,
    this.isConnectionError = false,
  });

  factory TitulosResult.success(List<Map<String, dynamic>> data) {
    return TitulosResult._(success: true, data: data);
  }

  factory TitulosResult.error(String error) {
    return TitulosResult._(success: false, error: error);
  }

  factory TitulosResult.connectionError(String error) {
    return TitulosResult._(
      success: false,
      error: error,
      isConnectionError: true,
    );
  }

  bool get isEmpty => success && (data == null || data!.isEmpty);
  bool get hasData => success && data != null && data!.isNotEmpty;
}

// Classe para padronizar resultados de busca de detalhes de título
class TituloDetailsResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;
  final bool isConnectionError;

  TituloDetailsResult._({
    required this.success,
    this.data,
    this.error,
    this.isConnectionError = false,
  });

  factory TituloDetailsResult.success(Map<String, dynamic> data) {
    return TituloDetailsResult._(success: true, data: data);
  }

  factory TituloDetailsResult.error(String error) {
    return TituloDetailsResult._(success: false, error: error);
  }

  factory TituloDetailsResult.connectionError(String error) {
    return TituloDetailsResult._(
      success: false,
      error: error,
      isConnectionError: true,
    );
  }
}

// Classe para padronizar resultados de cobranças
class CobrancasResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;
  final bool isConnectionError;

  CobrancasResult._({
    required this.success,
    this.data,
    this.error,
    this.isConnectionError = false,
  });

  factory CobrancasResult.success(Map<String, dynamic> data) {
    return CobrancasResult._(success: true, data: data);
  }

  factory CobrancasResult.error(String error) {
    return CobrancasResult._(success: false, error: error);
  }

  factory CobrancasResult.connectionError(String error) {
    return CobrancasResult._(
      success: false,
      error: error,
      isConnectionError: true,
    );
  }
}

// Classe para padronizar resultados de negociação
class NegociacaoResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;
  final bool isConnectionError;

  NegociacaoResult._({
    required this.success,
    this.data,
    this.error,
    this.isConnectionError = false,
  });

  factory NegociacaoResult.success(Map<String, dynamic> data) {
    return NegociacaoResult._(success: true, data: data);
  }

  factory NegociacaoResult.error(String error) {
    return NegociacaoResult._(success: false, error: error);
  }

  factory NegociacaoResult.connectionError(String error) {
    return NegociacaoResult._(
      success: false,
      error: error,
      isConnectionError: true,
    );
  }
}

// Classe para padronizar resultados de guias
class GuiasResult {
  final bool success;
  final List<dynamic>? data;
  final String? error;
  final bool isConnectionError;

  GuiasResult._({
    required this.success,
    this.data,
    this.error,
    this.isConnectionError = false,
  });

  factory GuiasResult.success(List<dynamic> data) {
    return GuiasResult._(success: true, data: data);
  }

  factory GuiasResult.error(String error) {
    return GuiasResult._(success: false, error: error);
  }

  factory GuiasResult.connectionError(String error) {
    return GuiasResult._(success: false, error: error, isConnectionError: true);
  }
}

// Classe para padronizar resultados de uma guia específica
class GuiaResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;
  final bool isConnectionError;

  GuiaResult._({
    required this.success,
    this.data,
    this.error,
    this.isConnectionError = false,
  });

  factory GuiaResult.success(Map<String, dynamic> data) {
    return GuiaResult._(success: true, data: data);
  }

  factory GuiaResult.error(String error) {
    return GuiaResult._(success: false, error: error);
  }

  factory GuiaResult.connectionError(String error) {
    return GuiaResult._(success: false, error: error, isConnectionError: true);
  }
}

// Classe para padronizar resultados de atualização de dados do usuário
class UserUpdateResult {
  final bool success;
  final UserModel? user;
  final String? error;

  UserUpdateResult._({required this.success, this.user, this.error});

  factory UserUpdateResult.success(UserModel user) {
    return UserUpdateResult._(success: true, user: user);
  }

  factory UserUpdateResult.successOperation() {
    return UserUpdateResult._(success: true);
  }

  factory UserUpdateResult.error(String error) {
    return UserUpdateResult._(success: false, error: error);
  }
}

// Classe para padronizar resultados de busca de CEP
class CepResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;

  CepResult._({required this.success, this.data, this.error});

  factory CepResult.success(Map<String, dynamic> data) {
    return CepResult._(success: true, data: data);
  }

  factory CepResult.error(String error) {
    return CepResult._(success: false, error: error);
  }
}

// Classe para padronizar resultados de busca de estados
class EstadosResult {
  final bool success;
  final List<Map<String, dynamic>>? data;
  final String? error;

  EstadosResult._({required this.success, this.data, this.error});

  factory EstadosResult.success(List<Map<String, dynamic>> data) {
    return EstadosResult._(success: true, data: data);
  }

  factory EstadosResult.error(String error) {
    return EstadosResult._(success: false, error: error);
  }
}

// Classe para padronizar resultados de busca de parentescos
class ParentescosResult {
  final bool success;
  final List<Map<String, dynamic>>? data;
  final String? error;

  ParentescosResult._({required this.success, this.data, this.error});

  factory ParentescosResult.success(List<Map<String, dynamic>> data) {
    return ParentescosResult._(success: true, data: data);
  }

  factory ParentescosResult.error(String error) {
    return ParentescosResult._(success: false, error: error);
  }
}

// Classe para padronizar resultados de atribuição de vaga
class AtribuirVagaResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;

  AtribuirVagaResult._({required this.success, this.data, this.error});

  factory AtribuirVagaResult.success(Map<String, dynamic> data) {
    return AtribuirVagaResult._(success: true, data: data);
  }

  factory AtribuirVagaResult.error(String error) {
    return AtribuirVagaResult._(success: false, error: error);
  }
}

// Classe para padronizar resultados de aceite de termos
class AplicarAceiteResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;

  AplicarAceiteResult._({required this.success, this.data, this.error});

  factory AplicarAceiteResult.success(Map<String, dynamic> data) {
    return AplicarAceiteResult._(success: true, data: data);
  }

  factory AplicarAceiteResult.error(String error) {
    return AplicarAceiteResult._(success: false, error: error);
  }
}

// Classe para padronizar resultados de busca de imagem do usuário
class LoggedUserImageResult {
  final bool success;
  final String? imageUrl;
  final String? error;

  LoggedUserImageResult._({required this.success, this.imageUrl, this.error});

  factory LoggedUserImageResult.success(String? imageUrl) {
    return LoggedUserImageResult._(success: true, imageUrl: imageUrl);
  }

  factory LoggedUserImageResult.error(String error) {
    return LoggedUserImageResult._(success: false, error: error);
  }
}

// Classe para padronizar resultados de upload out-of-db
class UploadOutOfDbResult {
  final bool success;
  final String? url;
  final String? error;

  UploadOutOfDbResult._({required this.success, this.url, this.error});

  factory UploadOutOfDbResult.success(String url) {
    return UploadOutOfDbResult._(success: true, url: url);
  }

  factory UploadOutOfDbResult.error(String error) {
    return UploadOutOfDbResult._(success: false, error: error);
  }
}

// Classe para padronizar resultados de atribuição de foto do titular
class AtribuirTitularFotoResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;

  AtribuirTitularFotoResult._({required this.success, this.data, this.error});

  factory AtribuirTitularFotoResult.success(Map<String, dynamic> data) {
    return AtribuirTitularFotoResult._(success: true, data: data);
  }

  factory AtribuirTitularFotoResult.error(String error) {
    return AtribuirTitularFotoResult._(success: false, error: error);
  }
}

// Classe para padronizar resultados de atribuição de foto do dependente
class AtribuirVagaFotoResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;

  AtribuirVagaFotoResult._({required this.success, this.data, this.error});

  factory AtribuirVagaFotoResult.success(Map<String, dynamic> data) {
    return AtribuirVagaFotoResult._(success: true, data: data);
  }

  factory AtribuirVagaFotoResult.error(String error) {
    return AtribuirVagaFotoResult._(success: false, error: error);
  }
}

// Classe para padronizar resultados de busca de cidades
class CidadesResult {
  final bool success;
  final List<Map<String, dynamic>>? data;
  final String? error;

  CidadesResult._({required this.success, this.data, this.error});

  factory CidadesResult.success(List<Map<String, dynamic>> data) {
    return CidadesResult._(success: true, data: data);
  }

  factory CidadesResult.error(String error) {
    return CidadesResult._(success: false, error: error);
  }
}

// Classe para padronizar resultados de upload de foto
class PhotoUploadResult {
  final bool success;
  final String? imageUrl;
  final String? error;

  PhotoUploadResult._({required this.success, this.imageUrl, this.error});

  factory PhotoUploadResult.success(String imageUrl) {
    return PhotoUploadResult._(success: true, imageUrl: imageUrl);
  }

  factory PhotoUploadResult.error(String error) {
    return PhotoUploadResult._(success: false, error: error);
  }
}
