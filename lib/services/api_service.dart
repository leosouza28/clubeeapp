import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_clubee/services/logging_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/client_type.dart';
import '../models/login_model.dart';
import '../services/client_service.dart';
import '../services/device_service.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';

class ApiService {
  static ApiService? _instance;
  late StorageService _storageService;
  late DeviceService _deviceService;

  // Stream para notificar logout por falta de autorização
  static final _unauthorizedLogoutController =
      StreamController<bool>.broadcast();
  static Stream<bool> get unauthorizedLogoutStream =>
      _unauthorizedLogoutController.stream;

  // Configurações por cliente
  static const Map<ClientType, Map<String, dynamic>> _clientConfigs = {
    ClientType.guara: {
      'port': '8001',
      'clube_id': '62f169709ef63880246b4caa',
      'apiUrl': "https://api.guarapark.app",
    },
    ClientType.valeDasMinas: {
      'port': '8002',
      'clube_id': '68d18e77f0d20fe8813947ff',
      'apiUrl': "https://api-valedasminaspark.lsdevelopers.dev",
    },
  };

  ApiService._();

  static Future<ApiService> getInstance() async {
    _instance ??= ApiService._();
    _instance!._storageService = await StorageService.getInstance();
    _instance!._deviceService = await DeviceService.getInstance();
    return _instance!;
  }

  // Obtém a URL base baseada no cliente
  String _getBaseUrl(ClientType clientType) {
    final config = _clientConfigs[clientType]!;
    final String apiUrl;
    if (kDebugMode) {
      apiUrl = 'http://192.168.68.118:${config['port']}';
    } else {
      apiUrl = config['apiUrl'];
    }
    return apiUrl;
  }

  // Obtém o clube ID baseado no cliente
  String _getClubeId(ClientType clientType) {
    final config = _clientConfigs[clientType]!;
    return config['clube_id'];
  }

  // Monta os headers padrão para todas as requisições
  Future<Map<String, String>> _getDefaultHeaders(
    ClientType clientType, {
    bool includeAuth = false,
  }) async {
    final deviceInfo = await _deviceService.getAllDeviceInfo();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'clube-id': _getClubeId(clientType),
      'app-device-id': deviceInfo['device_id'] ?? '',
      'app-device-name': deviceInfo['device_name'] ?? '',
      'app-device-agent': deviceInfo['device_agent'] ?? '',
    };

    // Adiciona IP se disponível
    if (deviceInfo['device_ip'] != null) {
      headers['app-device-ip'] = deviceInfo['device_ip']!;
    }

    // Adiciona FCM Token se disponível
    final fcmToken = await FirebaseService.getSavedFCMToken();
    if (fcmToken != null) {
      headers['messaging-token'] = fcmToken;
    }

    // Adiciona Authorization se necessário
    if (includeAuth) {
      final token = await _storageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Faz login na API
  Future<ApiResponse<LoginResponse>> login(
    ClientType clientType,
    String cpfCnpj,
    String senha,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v1/login');

      final loginRequest = LoginRequest(cpfCnpj: cpfCnpj, senha: senha);
      final headers = await _getDefaultHeaders(clientType);

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(loginRequest.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Verifica se a resposta contém um token válido
        if (responseData.containsKey('token') &&
            responseData['token'] != null) {
          final loginResponse = LoginResponse.fromJson(responseData);

          // Salva os dados do login automaticamente
          await _storageService.saveLoginData(loginResponse);

          return ApiResponse.success(loginResponse);
        } else {
          return ApiResponse.error(
            'Login inválido: Token não encontrado na resposta',
            response.statusCode,
          );
        }
      } else if (response.statusCode == 401) {
        return ApiResponse.error(
          'Credenciais inválidas. Verifique seu documento e senha.',
          response.statusCode,
        );
      } else if (response.statusCode == 400) {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Dados de login inválidos',
          response.statusCode,
        );
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          'Erro no login: ${errorData['message'] ?? 'Erro desconhecido'}',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error(
        'Erro de conexão. Verifique se o servidor está rodando na porta correta.',
        0,
      );
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Faz logout (limpa dados locais)
  Future<void> logout() async {
    await _storageService.clearLoginData();
  }

  // Faz logoff no servidor
  Future<ApiResponse<void>> logoff() async {
    try {
      // Pega o client type do usuário logado via getCurrentUser
      final loginData = await getCurrentUser();
      if (loginData == null) {
        return ApiResponse.error('Usuário não autenticado', 401);
      }

      // Usar o clientType do ClientService
      final clientService = ClientService.instance;
      final clientType = clientService.currentConfig.clientType;

      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v1/logoff');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.put(url, headers: headers);

      if (response.statusCode == 200) {
        return ApiResponse.success(null);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao fazer logoff no servidor',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Erro de conexão ao fazer logoff: $e', 500);
    }
  }

  // Exclui a conta do usuário
  Future<ApiResponse<void>> deleteAccount(ClientType clientType) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v1/usuarios/excluir-conta');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.put(url, headers: headers);

      if (response.statusCode == 200) {
        return ApiResponse.success(null);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao excluir conta',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Erro de conexão ao excluir conta: $e', 500);
    }
  }

  // Verifica se o usuário está autenticado
  Future<bool> isAuthenticated() async {
    return await _storageService.isAuthenticated();
  }

  // Obtém dados do usuário logado
  Future<LoginResponse?> getCurrentUser() async {
    return await _storageService.getLoginData();
  }

  // Verifica se a resposta é 401 e faz logout automático
  Future<void> _checkUnauthorizedAndLogout(int statusCode) async {
    if (statusCode == 401) {
      // print('🚨 Status 401 detectado - Fazendo logout automático');
      await logout();
      // Emitir evento para notificar a UI sobre logout por falta de autorização
      _unauthorizedLogoutController.add(true);
    }
  }

  // Método genérico para requisições GET autenticadas
  Future<ApiResponse<Map<String, dynamic>>> get(
    ClientType clientType,
    String endpoint,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl$endpoint');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.get(url, headers: headers);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ApiResponse.success(responseData);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro na requisição',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Método genérico para requisições POST autenticadas
  Future<ApiResponse<Map<String, dynamic>>> post(
    ClientType clientType,
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl$endpoint');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      );

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ApiResponse.success(responseData);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro na requisição',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Busca títulos do usuário autenticado
  Future<ApiResponse<List<Map<String, dynamic>>>> getTitulos(
    ClientType clientType,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v1/meus-titulos');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.get(url, headers: headers);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        final List<Map<String, dynamic>> titulos = responseData
            .cast<Map<String, dynamic>>();
        return ApiResponse.success(titulos);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao buscar títulos',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Busca cotas do resort do usuário autenticado
  Future<ApiResponse<List<Map<String, dynamic>>>> getCotasResort(
    ClientType clientType,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v1/resort/cotas');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.get(url, headers: headers);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> cotasData = responseData['cotas_resort'] ?? [];
        final List<Map<String, dynamic>> cotas = cotasData
            .cast<Map<String, dynamic>>();
        return ApiResponse.success(cotas);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao buscar cotas do resort',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Busca detalhes de uma cota do resort específica
  Future<ApiResponse<Map<String, dynamic>>> getCotaResortDetails(
    ClientType clientType,
    String cotaId, {
    bool getParcelas = false,
  }) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final queryParams = getParcelas ? '?get_parcelas=1' : '';
      final url = Uri.parse('$baseUrl/v1/resort/cotas/$cotaId$queryParams');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.get(url, headers: headers);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ApiResponse.success(responseData);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao buscar detalhes da cota',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Cria uma negociação para parcelas selecionadas
  Future<ApiResponse<Map<String, dynamic>>> criarNegociacaoResort(
    ClientType clientType,
    String cotaId,
    List<int> parcelasIdentificadores,
    double valorCalculadoFront,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v1/resort/cotas/$cotaId/negociacao-app');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final body = jsonEncode({
        'parcelas': parcelasIdentificadores,
        'valor_calculado_front': valorCalculadoFront,
      });

      final response = await http.post(url, headers: headers, body: body);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ApiResponse.success(responseData);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao criar negociação',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Lista todas as negociações (guias) de uma cota
  Future<ApiResponse<Map<String, dynamic>>> getGuiasNegociacao(
    ClientType clientType,
    String cotaId,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v1/resort/cotas/$cotaId/negociacao');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.get(url, headers: headers);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ApiResponse.success(responseData);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao buscar guias de negociação',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Busca detalhes de uma negociação (guia) específica
  Future<ApiResponse<Map<String, dynamic>>> getGuiaNegociacao(
    ClientType clientType,
    String cotaId,
    String guiaId,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v1/resort/cotas/$cotaId/negociacao/$guiaId');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.get(url, headers: headers);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ApiResponse.success(responseData);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao buscar guia de negociação',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Verifica acesso do usuário autenticado
  Future<ApiResponse<Map<String, dynamic>>> verificarAcesso(
    ClientType clientType,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v1/verificar-acesso');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.get(url, headers: headers);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ApiResponse.success(responseData);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao verificar acesso',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Busca calendário de funcionamento do clube
  Future<ApiResponse<Map<String, dynamic>>> getCalendario(
    ClientType clientType,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v-public/calendario');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ApiResponse.success(responseData);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao buscar calendário',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Busca notícias públicas
  Future<ApiResponse<Map<String, dynamic>>> getNoticias(
    ClientType clientType,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v-public/noticias/1');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ApiResponse.success(responseData);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao buscar notícias',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Busca notificações do usuário
  Future<ApiResponse<List<dynamic>>> getNotificacoesUsuario(
    ClientType clientType,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v1/usuario/notificacoes');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.get(url, headers: headers);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        return ApiResponse.success(responseData);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao buscar notificações',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Busca cortesias disponíveis para uma data específica
  Future<ApiResponse<List<Map<String, dynamic>>>> getCortesiasDisponiveis(
    ClientType clientType,
    String tituloId,
    String data,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse(
        '$baseUrl/v1/cortesias-disponiveis/$tituloId/$data',
      );

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.get(url, headers: headers);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        final List<Map<String, dynamic>> cortesias = responseData
            .cast<Map<String, dynamic>>();
        return ApiResponse.success(cortesias);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao buscar cortesias disponíveis',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro desconhecido: $e', 0);
    }
  }

  // Busca informações de horário para cortesias disponíveis
  Future<ApiResponse<Map<String, dynamic>>> getCortesiasDisponiveisHorario(
    ClientType clientType,
    String tituloId,
    String data,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse(
        '$baseUrl/v1/cortesias-disponiveis-horario/$tituloId/$data',
      );

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.get(url, headers: headers);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ApiResponse.success(responseData);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao buscar horário de cortesias',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Busca termos de uso de cortesias
  Future<ApiResponse<Map<String, dynamic>>> getTermosDeUso(
    ClientType clientType,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v-public/cortesias/termos-de-uso');

      final headers = await _getDefaultHeaders(clientType, includeAuth: false);

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ApiResponse.success(responseData);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao buscar termos de uso',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Efetua uma nova reserva de cortesia
  Future<ApiResponse<Map<String, dynamic>>> criarReserva(
    ClientType clientType,
    Map<String, dynamic> reservaData,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v1/cortesias');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(reservaData),
      );

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ApiResponse.success(responseData);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao criar reserva',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Cancela uma reserva de cortesia
  Future<ApiResponse<Map<String, dynamic>>> cancelarReserva(
    ClientType clientType,
    String idReserva,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v1/cortesias');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final body = {'id_reserva': idReserva};

      final response = await http.delete(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (kDebugMode) {
        print('Cancelar Reserva Response Status: ${response.statusCode}');
        print('Cancelar Reserva Response Body: ${response.body}');
      }

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        try {
          // Tenta fazer parse do JSON
          final responseData = jsonDecode(response.body);

          // Se a resposta for um Map, retorna como está
          if (responseData is Map<String, dynamic>) {
            return ApiResponse.success(responseData);
          }
          // Se a resposta for um boolean ou outro tipo, cria um Map
          else {
            return ApiResponse.success({'success': responseData});
          }
        } catch (e) {
          // Se não conseguir fazer parse, assume que o cancelamento foi bem-sucedido
          return ApiResponse.success({
            'success': true,
            'message': 'Reserva cancelada com sucesso',
          });
        }
      } else {
        final errorData = _parseErrorResponse(response);
        String errorMessage = 'Erro ao cancelar reserva';

        // Tratamento específico dos erros mencionados na imagem
        if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        } else if (response.statusCode == 401) {
          errorMessage = 'Não autorizado';
        } else if (response.statusCode == 404) {
          errorMessage = 'Reserva não encontrada';
        }

        return ApiResponse.error(errorMessage, response.statusCode);
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Analisa resposta de erro
  Map<String, dynamic> _parseErrorResponse(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'message': 'Erro HTTP ${response.statusCode}',
        'status_code': response.statusCode,
      };
    }
  }

  // Busca detalhes de um título específico
  Future<ApiResponse<Map<String, dynamic>>> getTituloDetails(
    ClientType clientType,
    String tituloId,
  ) async {
    try {
      final response = await get(clientType, '/v1/meus-titulos/$tituloId');

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!);
      } else {
        return ApiResponse.error(
          response.error ?? 'Erro ao carregar detalhes do título',
          response.statusCode ?? 0,
        );
      }
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Busca cobranças de um título
  Future<ApiResponse<Map<String, dynamic>>> getTituloCobrancas(
    ClientType clientType,
    String tituloId,
  ) async {
    try {
      final response = await get(
        clientType,
        '/v1/meus-titulos/$tituloId/cobrancas',
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!);
      } else {
        return ApiResponse.error(
          response.error ?? 'Erro ao carregar cobranças',
          response.statusCode ?? 0,
        );
      }
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getCarteirinhasResumo(
    ClientType clientType,
    String tituloId, {
    bool incluirParticipantes = false,
  }) async {
    try {
      final query = incluirParticipantes ? '?participantes=1' : '';
      final response = await get(
        clientType,
        '/v1/meus-titulos/$tituloId/carteirinhas$query',
      );
      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!);
      }
      return ApiResponse.error(
        response.error ?? 'Erro ao carregar carteirinhas',
        response.statusCode ?? 0,
      );
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getVendaCarteirinhaPendente(
    ClientType clientType,
    String tituloId,
  ) async {
    try {
      final response = await get(
        clientType,
        '/v1/meus-titulos/$tituloId/carteirinhas/venda-pendente',
      );
      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!);
      }
      return ApiResponse.error(
        response.error ?? 'Erro ao buscar venda pendente',
        response.statusCode ?? 0,
      );
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> simularVendaCarteirinhas(
    ClientType clientType,
    String tituloId,
    List<Map<String, dynamic>> operacoes,
  ) async {
    try {
      final response = await post(
        clientType,
        '/v1/meus-titulos/$tituloId/carteirinhas/simular',
        {'operacoes': operacoes},
      );
      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!);
      }
      return ApiResponse.error(
        response.error ?? 'Erro ao simular venda de carteirinhas',
        response.statusCode ?? 0,
      );
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> criarVendaCarteirinhas(
    ClientType clientType,
    String tituloId,
    List<Map<String, dynamic>> operacoes,
  ) async {
    try {
      final response = await post(
        clientType,
        '/v1/meus-titulos/$tituloId/carteirinhas/venda',
        {'operacoes': operacoes},
      );
      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!);
      }
      return ApiResponse.error(
        response.error ?? 'Erro ao gerar PIX de carteirinhas',
        response.statusCode ?? 0,
      );
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> verificarVendaCarteirinha(
    ClientType clientType,
    String tituloId,
    String vendaId,
  ) async {
    try {
      final response = await post(
        clientType,
        '/v1/meus-titulos/$tituloId/carteirinhas/venda-pendente/verificar',
        {'venda_id': vendaId},
      );
      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!);
      }
      return ApiResponse.error(
        response.error ?? 'Erro ao verificar pagamento',
        response.statusCode ?? 0,
      );
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> cancelarVendaCarteirinha(
    ClientType clientType,
    String tituloId,
    String vendaId,
  ) async {
    try {
      final response = await post(
        clientType,
        '/v1/meus-titulos/$tituloId/carteirinhas/venda-pendente/cancelar',
        {'venda_id': vendaId},
      );
      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!);
      }
      return ApiResponse.error(
        response.error ?? 'Erro ao cancelar pedido',
        response.statusCode ?? 0,
      );
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Cria negociação de cobranças
  Future<ApiResponse<Map<String, dynamic>>> criarNegociacaoCobrancas(
    ClientType clientType,
    String tituloId,
    List<String> cobrancasIds,
  ) async {
    try {
      final response = await post(
        clientType,
        '/v2/titulos/cobrancas/negociacao-app',
        {'titulo_id': tituloId, 'cobrancas_ids': cobrancasIds},
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!);
      } else {
        return ApiResponse.error(
          response.error ?? 'Erro ao criar negociação',
          response.statusCode ?? 0,
        );
      }
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Busca guias de pagamento de um título
  Future<ApiResponse<List<dynamic>>> getTituloGuias(
    ClientType clientType,
    String tituloId,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse(
        '$baseUrl/v2/titulos/cobrancas/guias-app/$tituloId',
      );

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.get(url, headers: headers);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        // Parse da resposta
        final dynamic responseData = jsonDecode(response.body);

        // Se a resposta for uma lista direta
        if (responseData is List) {
          return ApiResponse.success(responseData);
        }
        // Se a resposta for um objeto com uma propriedade lista
        else if (responseData is Map && responseData['lista'] != null) {
          return ApiResponse.success(responseData['lista'] as List<dynamic>);
        }
        // Resposta vazia ou formato inesperado
        return ApiResponse.success([]);
      } else {
        return ApiResponse.error(
          'Erro ao carregar guias: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Busca uma guia específica pelo ID
  Future<ApiResponse<Map<String, dynamic>>> getGuiaById(
    ClientType clientType,
    String guiaId,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse(
        '$baseUrl/v2/titulos/cobrancas/verificar-guias-app/$guiaId',
      );

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.get(url, headers: headers);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        // Parse da resposta
        final dynamic responseData = jsonDecode(response.body);

        if (responseData is Map<String, dynamic>) {
          return ApiResponse.success(responseData);
        } else {
          return ApiResponse.error('Formato de resposta inválido', 422);
        }
      } else {
        return ApiResponse.error(
          'Erro ao carregar guia: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Busca cortesias/reservas de um título
  Future<ApiResponse<List<Map<String, dynamic>>>> getCortesias(
    ClientType clientType,
    String tituloId,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v1/cortesias/$tituloId');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.get(url, headers: headers);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        // Parse direto da resposta como lista
        final dynamic responseData = jsonDecode(response.body);

        if (responseData is List) {
          final List<Map<String, dynamic>> cortesias = responseData
              .cast<Map<String, dynamic>>();

          LoggingService.instance.json(cortesias);

          return ApiResponse.success(cortesias);
        } else {
          // Se não for lista, pode ser um objeto com uma propriedade 'data' ou 'cortesias'
          Map<String, dynamic> responseMap =
              responseData as Map<String, dynamic>;

          List<dynamic> cortesiasList = [];
          if (responseMap.containsKey('data')) {
            cortesiasList = responseMap['data'] as List<dynamic>;
          } else if (responseMap.containsKey('cortesias')) {
            cortesiasList = responseMap['cortesias'] as List<dynamic>;
          } else {
            // Se não tiver estrutura conhecida, retorna lista vazia
            cortesiasList = [];
          }

          final List<Map<String, dynamic>> cortesias = cortesiasList
              .cast<Map<String, dynamic>>();

          return ApiResponse.success(cortesias);
        }
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao carregar cortesias',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Busca dados do usuário logado
  Future<ApiResponse<Map<String, dynamic>>> getLoggedUser(
    ClientType clientType,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v2/logged-user');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.get(url, headers: headers);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ApiResponse.success(responseData);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao buscar dados do usuário',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Altera senha do usuário
  Future<ApiResponse<Map<String, dynamic>>> changePassword(
    ClientType clientType,
    String novaSenha,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v1/usuarios/alterar-senha');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final body = jsonEncode({'nova_senha': novaSenha});

      final response = await http.put(url, headers: headers, body: body);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        // Sucesso na alteração da senha
        return ApiResponse.success(<String, dynamic>{
          'message': 'Senha alterada com sucesso',
        });
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao alterar senha',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Recupera senha do usuário (envia nova senha por email/SMS)
  Future<Map<String, dynamic>> recoverPassword(
    ClientType clientType,
    String document,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v1/enviar-recuperacao-senha');

      final headers = await _getDefaultHeaders(clientType, includeAuth: false);

      final body = jsonEncode({'value': document});

      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['mensagem'] ?? 'Nova senha enviada com sucesso!',
        };
      } else {
        final errorData = _parseErrorResponse(response);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erro ao solicitar nova senha',
          'error': errorData['message'],
        };
      }
    } on SocketException {
      return {
        'success': false,
        'error': 'Erro de conexão. Verifique sua internet.',
      };
    } catch (e) {
      return {'success': false, 'error': 'Erro inesperado: $e'};
    }
  }

  // Atualiza dados do usuário logado
  Future<ApiResponse<Map<String, dynamic>>> updateUserData(
    ClientType clientType,
    Map<String, dynamic> userData,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v2/logged-user/editar');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final body = jsonEncode(userData);

      final response = await http.put(url, headers: headers, body: body);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          // Verificar se a resposta é um Map válido
          if (responseData is Map<String, dynamic>) {
            return ApiResponse.success(responseData);
          } else {
            // Se não for um Map, criar um Map com informação de sucesso
            return ApiResponse.success({
              'success': true,
              'message': 'Dados atualizados com sucesso',
            });
          }
        } catch (e) {
          // Se não conseguir fazer decode do JSON, assumir sucesso
          return ApiResponse.success({
            'success': true,
            'message': 'Dados atualizados com sucesso',
          });
        }
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao atualizar dados',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Busca endereço pelo CEP usando API interna
  Future<ApiResponse<Map<String, dynamic>>> searchCep(
    String cep,
    ClientType clientType,
  ) async {
    try {
      final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');

      if (cleanCep.length != 8) {
        return ApiResponse.error('CEP deve ter 8 dígitos', 400);
      }

      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v3/admin/comum/cep?cep=$cleanCep');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.get(url, headers: headers);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return ApiResponse.success({
          'cep': data['cep'] ?? '',
          'logradouro': data['logradouro'] ?? '',
          'bairro': data['bairro'] ?? '',
          'cidade': data['cidade'] ?? '',
          'estado': data['estado'] ?? '',
        });
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'CEP não encontrado',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Busca lista de estados
  Future<ApiResponse<List<Map<String, dynamic>>>> getEstados(
    ClientType clientType,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v3/admin/comum/estados');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.get(url, headers: headers);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        final List<Map<String, dynamic>> estados = responseData
            .cast<Map<String, dynamic>>();
        return ApiResponse.success(estados);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao buscar estados',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Busca lista de cidades por estado
  Future<ApiResponse<List<Map<String, dynamic>>>> getCidades(
    ClientType clientType,
    String siglaEstado,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse(
        '$baseUrl/v3/admin/comum/cidades?sigla=$siglaEstado',
      );

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.get(url, headers: headers);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        final List<Map<String, dynamic>> cidades = responseData
            .cast<Map<String, dynamic>>();
        return ApiResponse.success(cidades);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao buscar cidades',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Upload de imagem de perfil
  Future<ApiResponse<Map<String, dynamic>>> uploadProfileImage(
    ClientType clientType,
    File imageFile,
    String userId,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v3/admin/comum/upload');

      // Criar request multipart
      final request = http.MultipartRequest('POST', url);

      // Adicionar headers
      final deviceInfo = await _deviceService.getAllDeviceInfo();
      request.headers.addAll({
        'clube-id': _clientConfigs[clientType]!['clube_id']!,
        'app-device-id': deviceInfo['device_id']!,
        'app-device-name': deviceInfo['device_name']!,
        'app-device-agent': deviceInfo['device_agent']!,
      });

      // Adicionar IP se disponível
      if (deviceInfo['device_ip'] != null) {
        request.headers['app-device-ip'] = deviceInfo['device_ip']!;
      }

      // Adicionar token de autorização
      final token = await _storageService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Adicionar o arquivo
      final fileBytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: 'profile_image.jpg',
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      // Adicionar o user_id como campo do form
      request.fields['user_id'] = userId;
      request.fields['tipo'] = "profile_image";

      // Enviar request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ApiResponse.success(responseData);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao fazer upload da imagem',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  /// Obter opções disponíveis para criar acesso
  Future<ApiResponse<Map<String, dynamic>>> getCriarAcessoOpcoes(
    ClientType clientType,
    String documento,
  ) async {
    try {
      final String baseUrl = _getBaseUrl(clientType);
      final uri = Uri.parse('$baseUrl/v3/criar-acesso/opcoes');
      final headers = await _getDefaultHeaders(clientType);

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({'documento': documento}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao buscar opções de criação de acesso',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  /// Solicitar código de verificação para criar acesso
  Future<ApiResponse<Map<String, dynamic>>> solicitarCodigoCriarAcesso(
    ClientType clientType,
    String usuarioId,
    String metodo,
  ) async {
    try {
      final String baseUrl = _getBaseUrl(clientType);
      final uri = Uri.parse('$baseUrl/v3/criar-acesso/solicita-codigo');
      final headers = await _getDefaultHeaders(clientType);

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({'usuario_id': usuarioId, 'metodo': metodo}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao solicitar código',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  /// Concluir criação de acesso
  Future<ApiResponse<Map<String, dynamic>>> concluirCriarAcesso(
    ClientType clientType,
    String usuarioId,
    String metodo,
    String senha,
    String codigo,
  ) async {
    try {
      final String baseUrl = _getBaseUrl(clientType);
      final uri = Uri.parse('$baseUrl/v3/criar-acesso/concluir');
      final headers = await _getDefaultHeaders(clientType);

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'usuario_id': usuarioId,
          'metodo': metodo,
          'senha': senha,
          'codigo': codigo,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao concluir criação de acesso',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  /// Buscar configurações do aplicativo
  Future<ApiResponse<Map<String, dynamic>>> getAppConfiguracoes(
    ClientType clientType,
  ) async {
    try {
      final String baseUrl = _getBaseUrl(clientType);
      final uri = Uri.parse('$baseUrl/v3/app/configuracoes');
      final headers = await _getDefaultHeaders(clientType);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao carregar configurações',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  /// Buscar cortesia por link
  Future<ApiResponse<Map<String, dynamic>>> getCortesiaLink(
    ClientType clientType,
    String cortesiaId,
  ) async {
    try {
      final String baseUrl = _getBaseUrl(clientType);
      final uri = Uri.parse('$baseUrl/v-public/cortesias-link/$cortesiaId');
      final headers = await _getDefaultHeaders(clientType);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao carregar cortesia',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  /// Buscar usuário por documento (CPF)
  Future<ApiResponse<Map<String, dynamic>>> buscarUsuarioPorDocumento(
    ClientType clientType,
    String documento,
  ) async {
    try {
      final String baseUrl = _getBaseUrl(clientType);
      final uri = Uri.parse('$baseUrl/v-public/usuario-geral-por-documento');
      final headers = await _getDefaultHeaders(clientType);

      final body = jsonEncode({'documento': documento});

      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Se retornar null, retornar erro
        if (data == null) {
          return ApiResponse.error('Usuário não encontrado', 404);
        }
        return ApiResponse.success(data as Map<String, dynamic>);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao buscar usuário',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  /// Enviar formulário de cortesia via link
  Future<ApiResponse<Map<String, dynamic>>> enviarCortesiaLink(
    ClientType clientType,
    Map<String, dynamic> payload,
  ) async {
    try {
      final String baseUrl = _getBaseUrl(clientType);
      final uri = Uri.parse('$baseUrl/v-public/cortesias-link');
      final headers = await _getDefaultHeaders(clientType);

      final body = jsonEncode(payload);

      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao confirmar reserva',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Obter buffer de impressão de agendamento
  Future<Map<String, dynamic>> getAgendamentoPrintBuffer(
    ClientType clientType,
    String idAgendamento,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final headers = await _getDefaultHeaders(clientType, includeAuth: true);
      final url =
          '$baseUrl/v2/admin/agendamento-corretor/bt-printer/buffer?id=$idAgendamento';
      final response = await http.get(Uri.parse(url), headers: headers);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message':
              'Erro ao buscar buffer de impressão: ${response.statusCode}',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar buffer de impressão: $e');
      }
      return {
        'success': false,
        'message': 'Erro ao buscar buffer de impressão',
      };
    }
  }

  // Busca a lista de dispositivos conectados do usuário
  Future<ApiResponse<List<Map<String, dynamic>>>> getDevices(
    ClientType clientType,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v1/devices');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.get(url, headers: headers);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        final List<Map<String, dynamic>> devices = responseData
            .cast<Map<String, dynamic>>();
        return ApiResponse.success(devices);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao buscar dispositivos',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Desconecta um dispositivo específico
  Future<ApiResponse<Map<String, dynamic>>> disconnectDevice(
    ClientType clientType,
    String deviceId,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v1/devices/disconnect');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final body = jsonEncode({'deviceId': deviceId});

      final response = await http.put(url, headers: headers, body: body);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        // Tratar diferentes tipos de resposta
        try {
          final responseData = jsonDecode(response.body);

          // Se a resposta for um Map, retornar como está
          if (responseData is Map<String, dynamic>) {
            return ApiResponse.success(responseData);
          }

          // Se for boolean ou outro tipo, criar um Map wrapper
          return ApiResponse.success({
            'success': responseData,
            'message': 'Dispositivo desconectado com sucesso',
          });
        } catch (e) {
          // Se não conseguir fazer decode, considerar sucesso simples
          return ApiResponse.success({
            'success': true,
            'message': 'Dispositivo desconectado com sucesso',
          });
        }
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao desconectar dispositivo',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Busca lista de parentescos
  Future<ApiResponse<List<Map<String, dynamic>>>> getParentescos(
    ClientType clientType,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v3/admin/comum/parentescos');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.get(url, headers: headers);

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        final List<Map<String, dynamic>> parentescos = responseData
            .cast<Map<String, dynamic>>();
        return ApiResponse.success(parentescos);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao buscar parentescos',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Atribui uma vaga de dependente
  Future<ApiResponse<Map<String, dynamic>>> atribuirVagaDependente(
    ClientType clientType,
    Map<String, dynamic> data,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v1/titulos/atribuir-vaga');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      // Adiciona o campo novo_app: true
      final bodyData = Map<String, dynamic>.from(data);
      bodyData['novo_app'] = true;

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(bodyData),
      );

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // A API pode retornar true (booleano) ou um objeto JSON
        try {
          final responseBody = response.body;

          // Se a resposta for apenas "true" (texto), tratar como sucesso
          if (responseBody.trim() == 'true') {
            return ApiResponse.success({
              'success': true,
              'message': 'Dependente atribuído com sucesso',
            });
          }

          // Tentar fazer parse como JSON
          final responseData = jsonDecode(responseBody);

          // Se a resposta for um Map, retornar como está
          if (responseData is Map<String, dynamic>) {
            return ApiResponse.success(responseData);
          }

          // Se for boolean ou outro tipo primitivo, criar um Map wrapper
          return ApiResponse.success({
            'success': responseData,
            'message': 'Dependente atribuído com sucesso',
          });
        } catch (e) {
          // Se não conseguir fazer decode, considerar sucesso simples
          return ApiResponse.success({
            'success': true,
            'message': 'Dependente atribuído com sucesso',
          });
        }
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao atribuir vaga',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Aplica aceite ou recusa dos termos de uso do título
  Future<ApiResponse<Map<String, dynamic>>> aplicarAceite(
    ClientType clientType,
    String tituloId,
    bool aceite,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v1/titulos/aplicar-aceite');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final bodyData = {'titulo_id': tituloId, 'status': aceite};

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(bodyData),
      );

      // Verificar se é 401 e fazer logout
      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);
          if (responseData is Map<String, dynamic>) {
            return ApiResponse.success(responseData);
          }
          return ApiResponse.success({
            'success': true,
            'message': 'Aceite aplicado com sucesso',
          });
        } catch (e) {
          return ApiResponse.success({
            'success': true,
            'message': 'Aceite aplicado com sucesso',
          });
        }
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao aplicar aceite',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Obtém a imagem do usuário logado
  Future<ApiResponse<Map<String, dynamic>>> getLoggedUserImage(
    ClientType clientType,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v1/logged-user-image');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.get(url, headers: headers);

      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is Map<String, dynamic>) {
          return ApiResponse.success(responseData);
        }
        return ApiResponse.success({'image_url': null});
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao buscar imagem do usuário',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Faz upload de arquivo out-of-db
  Future<ApiResponse<Map<String, dynamic>>> uploadOutOfDb(
    ClientType clientType,
    File file,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v3/admin/comum/upload-outofdb');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);
      headers.remove('Content-Type'); // Remover para multipart

      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);

      // Adicionar arquivo
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData is Map<String, dynamic>) {
          return ApiResponse.success(responseData);
        }
        return ApiResponse.success({'url': null});
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao fazer upload',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Atribui foto do titular para gerar carteirinha
  Future<ApiResponse<Map<String, dynamic>>> atribuirTitularFoto(
    ClientType clientType,
    String tituloId,
    String url,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final apiUrl = Uri.parse('$baseUrl/v1/titulos/atribuir-titular-foto');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final bodyData = {'url': url, 'titulo_id': tituloId};

      final response = await http.post(
        apiUrl,
        headers: headers,
        body: jsonEncode(bodyData),
      );

      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);
          if (responseData is Map<String, dynamic>) {
            return ApiResponse.success(responseData);
          }
          return ApiResponse.success({
            'success': true,
            'message': 'Foto atribuída com sucesso',
          });
        } catch (e) {
          return ApiResponse.success({
            'success': true,
            'message': 'Foto atribuída com sucesso',
          });
        }
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao atribuir foto',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Atribui foto do dependente para atualizar carteirinha
  Future<ApiResponse<Map<String, dynamic>>> atribuirVagaFoto(
    ClientType clientType,
    String tituloId,
    String dependenteHash,
    String url,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final apiUrl = Uri.parse('$baseUrl/v1/titulos/atribuir-vaga-foto');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final bodyData = {
        'titulo': {'_id': tituloId},
        'dependente': {'hash': dependenteHash},
        'url': url,
      };

      final response = await http.post(
        apiUrl,
        headers: headers,
        body: jsonEncode(bodyData),
      );

      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);
          if (responseData is Map<String, dynamic>) {
            return ApiResponse.success(responseData);
          }
          return ApiResponse.success({
            'success': true,
            'message': 'Foto do dependente atribuída com sucesso',
          });
        } catch (e) {
          return ApiResponse.success({
            'success': true,
            'message': 'Foto do dependente atribuída com sucesso',
          });
        }
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao atribuir foto do dependente',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Busca tags disponíveis e tags selecionadas pelo usuário
  Future<ApiResponse<Map<String, dynamic>>> getUserTags(
    ClientType clientType,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v1/user-tags');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.get(url, headers: headers);

      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(responseData);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao buscar interesses',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }

  // Salva as tags selecionadas pelo usuário
  Future<ApiResponse<bool>> setUserTags(
    ClientType clientType,
    List<String> tagIds,
  ) async {
    try {
      final baseUrl = _getBaseUrl(clientType);
      final url = Uri.parse('$baseUrl/v1/user-tags');

      final headers = await _getDefaultHeaders(clientType, includeAuth: true);

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'tags': tagIds}),
      );

      await _checkUnauthorizedAndLogout(response.statusCode);

      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro ao salvar interesses',
          response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão', 0);
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e', 0);
    }
  }
}

// Classe para padronizar respostas da API
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResponse._({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse._(success: true, data: data);
  }

  factory ApiResponse.error(String error, int statusCode) {
    return ApiResponse._(success: false, error: error, statusCode: statusCode);
  }
}
