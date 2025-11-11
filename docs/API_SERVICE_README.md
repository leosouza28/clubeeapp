# API Service - Guará & Vale das Minas

Este documento descreve como usar o serviço de API integrado no aplicativo Clubee.

## Configuração

### Dependências Adicionadas
- `http: ^1.5.0` - Para requisições HTTP
- `shared_preferences: ^2.5.3` - Para armazenamento local (equivalente ao MMKV)
- `device_info_plus: ^12.2.0` - Para informações do dispositivo

### Configuração do Servidor

O aplicativo está configurado para conectar com servidores locais:

- **Guará**: `http://localhost:8001`
- **Vale das Minas**: `http://localhost:8002`

## Estrutura de Serviços

### 1. StorageService
Gerencia o armazenamento local de dados (equivalente ao MMKV).

**Localização**: `lib/services/storage_service.dart`

**Principais métodos**:
- `saveToken(String token)` - Salva o token de autenticação
- `getToken()` - Recupera o token salvo
- `saveUser(UserModel user)` - Salva dados do usuário
- `getUser()` - Recupera dados do usuário
- `saveLoginData(LoginResponse)` - Salva token + dados do usuário
- `clearLoginData()` - Limpa todos os dados de autenticação

### 2. DeviceService
Gerencia informações do dispositivo para os headers da API.

**Localização**: `lib/services/device_service.dart`

**Principais métodos**:
- `getDeviceId()` - ID único do dispositivo
- `getDeviceName()` - Nome do dispositivo
- `getDeviceAgent()` - Agent no formato: "Clubee,android,1.0.0"
- `getDeviceIp()` - IP do dispositivo (placeholder)

### 3. ApiService
Gerencia todas as comunicações com a API.

**Localização**: `lib/services/api_service.dart`

**Headers automáticos**:
- `clube-id` - ID do clube baseado no cliente
- `app-device-id` - ID único do dispositivo
- `app-device-name` - Nome do dispositivo
- `app-device-agent` - Agent do dispositivo
- `app-device-ip` - IP do dispositivo (se disponível)
- `Authorization` - Bearer token (quando necessário)

### 4. AuthService
Serviço de alto nível para autenticação.

**Localização**: `lib/services/auth_service.dart`

**Principais métodos**:
- `login(ClientType, cpfCnpj, senha)` - Realiza login
- `logout()` - Faz logout
- `isAuthenticated()` - Verifica se está autenticado
- `getCurrentUser()` - Obtém usuário atual

## Modelos de Dados

### UserModel
**Localização**: `lib/models/user_model.dart`

Representa o usuário completo retornado pela API com todos os campos do JSON de resposta.

### LoginModel
**Localização**: `lib/models/login_model.dart`

Contém:
- `LoginRequest` - Para enviar CPF/CNPJ e senha
- `LoginResponse` - Para processar resposta do login

## Configuração por Cliente

### IDs dos Clubes:
- **Guará**: `62f169709ef63880246b4caa`
- **Vale das Minas**: `68d18e77f0d20fe8813947ff`

### Portas do Servidor:
- **Guará**: `8001`
- **Vale das Minas**: `8002`

## Exemplo de Uso

### Login
```dart
final authService = await AuthService.getInstance();
final result = await authService.login(
  ClientType.guara,
  '12345678901',
  'minha_senha'
);

if (result.success) {
  print('Login realizado: ${result.user!.nome}');
} else {
  print('Erro: ${result.error}');
}
```

### Verificar Autenticação
```dart
final authService = await AuthService.getInstance();
final isAuth = await authService.isAuthenticated();

if (isAuth) {
  final user = await authService.getCurrentUser();
  print('Usuário logado: ${user?.nome}');
}
```

### Fazer Requisições Autenticadas
```dart
final apiService = await ApiService.getInstance();
final response = await apiService.get(
  ClientType.guara,
  '/v1/meus-dados'
);

if (response.success) {
  print('Dados: ${response.data}');
}
```

## Estrutura de Resposta da API

### Login Bem-sucedido
```json
{
  "_id": "633f75c57f0b885e7dad52f2",
  "nome": "LEONARDO SOUZA",
  "cpf_cnpj": "02581748206",
  "email": "lsouzaus@gmail.com",
  "clube": {
    "_id": "62f169709ef63880246b4caa",
    "nome": "Guará"
  },
  "token": "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "iat": 1761241725,
  "exp": 4916915325
}
```

## Persistência de Dados

O sistema automaticamente:
1. Salva o token e dados do usuário após login bem-sucedido
2. Verifica autenticação ao inicializar a tela de conta
3. Inclui o token automaticamente em requisições autenticadas
4. Limpa todos os dados ao fazer logout

## Tratamento de Erros

Todos os serviços retornam objetos de resposta padronizados:
- `success: bool` - Indica se a operação foi bem-sucedida
- `data` - Dados da resposta (quando sucesso)
- `error: String` - Mensagem de erro (quando falha)
- `statusCode: int` - Código HTTP da resposta

## Segurança

- Tokens são armazenados localmente de forma segura
- Headers obrigatórios são incluídos automaticamente
- Validação de token de expiração
- Limpeza automática de dados sensíveis no logout

## Próximas Implementações

- [ ] Renovação automática de token
- [ ] Cache de requisições
- [ ] Retry automático em caso de falha
- [ ] Implementação completa do IP do dispositivo
- [ ] Interceptors para logging de requisições
- [ ] Compressão de dados