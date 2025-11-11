# Firebase Multi-Cliente - Guia de Configuração

Este documento explica como configurar e usar o Firebase para múltiplos clientes no projeto App Clubee.

## 🔥 Visão Geral

O sistema foi configurado para suportar diferentes projetos Firebase para cada cliente, permitindo:
- Analytics separados por cliente
- Notificações push específicas
- Configurações isoladas
- Troca dinâmica entre clientes

## 📁 Estrutura de Arquivos

```
lib/
├── config/
│   ├── client_config.dart          # Configurações por cliente (incluindo Firebase)
│   └── client_type.dart            # Enum dos clientes
├── services/
│   ├── client_service.dart         # Gerenciador de clientes
│   └── firebase_service.dart       # Serviço Firebase multi-cliente
├── firebase_options_guara.dart     # Configurações Firebase do Guará
├── firebase_options_valedasminas.dart # Configurações Firebase do Vale das Minas
└── main_firebase_example.dart      # Exemplo de uso
```

## 🚀 Configuração Inicial

### 1. Criar Projetos Firebase

Para cada cliente, crie um projeto no [Firebase Console](https://console.firebase.google.com/):

#### Cliente Guará:
- **Project ID**: `guaraacquapark`
- **Android Package**: `com.guaraapp`
- **iOS Bundle ID**: `com.lsdevelopers.guaraapp`

#### Cliente Vale das Minas:
- **Project ID**: `valedasminasapp`
- **Android Package**: `com.valedasminas`
- **iOS Bundle ID**: `com.lsdevelopers.valedasminas`

### 2. Configurar FlutterFire

Para cada cliente, execute:

```bash
# Guará
flutterfire configure --project=guaraacquapark --out=lib/firebase_options_guara.dart

# Vale das Minas
flutterfire configure --project=valedasminasapp --out=lib/firebase_options_valedasminas.dart
```

### 3. Validar Configurações

Use o script helper para validar:

```bash
# Validar Guará
./scripts/firebase_client.sh guara validate

# Validar Vale das Minas
./scripts/firebase_client.sh vale_das_minas validate
```

## 📱 Uso no Código

### Inicialização no main.dart

```dart
import 'package:flutter/material.dart';
import 'config/client_type.dart';
import 'services/client_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar para um cliente específico
  await ClientService.instance.initialize(ClientType.guara);
  
  runApp(MyApp());
}
```

### Usando Firebase Analytics

```dart
final firebaseService = ClientService.instance.firebaseService;

// Logar evento
await firebaseService.logEvent('user_login', {
  'client_type': ClientService.instance.currentClientType.toString(),
  'user_id': 'user123',
});

// Definir propriedade do usuário
await firebaseService.setUserProperty('client', 'guara');

// Definir User ID
await firebaseService.setUserId('user123');
```

### Usando Firebase Messaging

```dart
final firebaseService = ClientService.instance.firebaseService;

// Obter token FCM
String? token = await firebaseService.getFCMToken();
print('FCM Token: $token');

// O handler de mensagens já está configurado automaticamente
```

### Trocar Cliente em Runtime

```dart
// Trocar para outro cliente
await ClientService.instance.setClient(ClientType.valeDasMinas);

// O Firebase será reinicializado automaticamente para o novo cliente
```

## 🛠️ Scripts Disponíveis

### `firebase_client.sh`

Gerencia configurações Firebase por cliente:

```bash
# Configurar Firebase para um cliente
./scripts/firebase_client.sh guara setup

# Testar configuração
./scripts/firebase_client.sh guara test

# Validar arquivos
./scripts/firebase_client.sh guara validate
```

### `build_client.sh`

Agora inclui validação do Firebase:

```bash
# Build para Guará (valida Firebase automaticamente)
./scripts/build_client.sh guara

# Build para Vale das Minas
./scripts/build_client.sh vale_das_minas
```

### `add_new_client.sh`

Atualizado para incluir configuração Firebase:

```bash
# Adicionar novo cliente (inclui setup Firebase)
./scripts/add_new_client.sh
```

## 🔧 Configuração de Novo Cliente

Para adicionar um novo cliente com Firebase:

1. **Execute o script de adição:**
   ```bash
   ./scripts/add_new_client.sh
   ```

2. **Configure o Firebase:**
   - Crie o projeto no Firebase Console
   - Configure Android e iOS
   - Execute o FlutterFire CLI

3. **Valide a configuração:**
   ```bash
   ./scripts/firebase_client.sh [novo_cliente] validate
   ```

## 📊 Estrutura de Events Analytics

### Events Padrão

```dart
// Abertura do app
await firebaseService.logEvent('app_open', {
  'client_type': 'guara',
  'timestamp': DateTime.now().millisecondsSinceEpoch,
});

// Login do usuário
await firebaseService.logEvent('login', {
  'method': 'email',
  'client_type': 'guara',
});

// Ação específica
await firebaseService.logEvent('button_press', {
  'button_name': 'reserve',
  'screen': 'home',
  'client_type': 'guara',
});
```

### User Properties

```dart
// Definir propriedades do usuário
await firebaseService.setUserProperty('client_type', 'guara');
await firebaseService.setUserProperty('subscription_type', 'premium');
await firebaseService.setUserId('user_123');
```

## 🔔 Notificações Push

### Configuração Automática

O Firebase Messaging é configurado automaticamente quando o cliente é inicializado:

- Permissões são solicitadas automaticamente
- Token FCM é gerado
- Handlers de mensagem são configurados

### Handlers de Mensagem

```dart
// Mensagem em foreground - já configurado
FirebaseMessaging.onMessage.listen((message) {
  // Exibir notificação local
});

// App aberto via notificação - já configurado  
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  // Navegar para tela específica
});
```

## 🐛 Troubleshooting

### Problemas Comuns

1. **Erro "No Firebase App":**
   - Verifique se o arquivo `firebase_options_[cliente].dart` existe
   - Valide com `./scripts/firebase_client.sh [cliente] validate`

2. **Token FCM null:**
   - Verifique permissões no dispositivo
   - Certifique-se que o Firebase foi inicializado corretamente

3. **Analytics não funcionando:**
   - Verifique se o Project ID está correto
   - Aguarde até 24h para dados aparecerem no console

### Debug

```dart
// Verificar status do Firebase
print('Firebase App: ${ClientService.instance.firebaseService.currentApp?.name}');
print('Cliente atual: ${ClientService.instance.firebaseService.currentClientType}');

// Verificar token FCM
String? token = await ClientService.instance.firebaseService.getFCMToken();
print('FCM Token: $token');
```

## 📋 Checklist de Deploy

Antes de fazer deploy para produção:

- [ ] Todos os arquivos `firebase_options_[cliente].dart` estão presentes
- [ ] `google-services.json` está no lugar correto (Android)
- [ ] `GoogleService-Info.plist` está no lugar correto (iOS)
- [ ] Scripts de build validam Firebase automaticamente
- [ ] Testes de Analytics e Messaging funcionando
- [ ] Tokens FCM sendo gerados corretamente

## 🎯 Próximos Passos

1. **Implementar Deep Links** via notificações
2. **Configurar Remote Config** por cliente
3. **Adicionar Crashlytics** específico por cliente
4. **Implementar A/B Testing** com Firebase
5. **Configurar Performance Monitoring**

---

Para dúvidas ou problemas, consulte a documentação oficial do [FlutterFire](https://firebase.flutter.dev/) ou entre em contato com a equipe de desenvolvimento.