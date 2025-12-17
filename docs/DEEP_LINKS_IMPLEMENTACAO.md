# Implementação de Deep Links com app_links

## 📱 Visão Geral

O app agora utiliza o pacote `app_links` para gerenciar deep links de forma multiplataforma (Android e iOS).

## 🔗 Tipos de Deep Links Suportados

### 1. **HTTPS Universal Links**
- `https://app.guarapark.com/evento/123`
- `https://guarapark.app/promocao/456`
- `https://www.guarapark.app/reserva-via-link/789`

### 2. **Custom URL Schemes**
- `guaraapp://evento/123`
- `guaraapp://reserva-via-link/789`
- `valedasminasapp://promocao/456`

## 🛠️ Implementação

### Arquivos Principais

1. **`lib/main.dart`**
   - Inicializa o `DeepLinkService` no startup do app
   
2. **`lib/services/deep_link_service.dart`**
   - Gerencia captura e parsing de deep links
   - Usa o pacote `app_links`
   
3. **`lib/screens/app_config_loading_screen.dart`**
   - Verifica deep links pendentes após carregar configurações
   - Redireciona para `CortesiaLinkScreen` se tipo for `reservaViaLink`
   - Delega outros tipos para `MainNavigationScreen`
   
4. **`lib/widgets/main_navigation.dart`**
   - Processa deep links de navegação principal (profile, home)
   - Escuta links em tempo real
   
5. **`lib/screens/home_screen.dart`**
   - Processa deep links de funcionalidades (reservas, eventos, promoções)
   - Redireciona para telas específicas

### Serviço de Deep Links

O `DeepLinkService` foi atualizado para usar `app_links`:

```dart
// Inicialização no main.dart
await DeepLinkService.instance.initialize();

// Escutar novos deep links
DeepLinkService.instance.onDeepLink.listen((String link) {
  // Processar o link
  final info = DeepLinkService.instance.parseDeepLink(link);
  // Navegar para a tela apropriada
});

// Verificar se há link pendente
final pendingLink = DeepLinkService.instance.pendingDeepLink;
if (pendingLink != null) {
  // Processar link pendente
  DeepLinkService.instance.clearPendingDeepLink();
}
```

### Rotas Disponíveis

#### Eventos
- **HTTPS**: `https://app.guarapark.com/evento/123`
- **Scheme**: `guaraapp://evento/123`
- **Tipo**: `DeepLinkType.evento`
- **Status**: A implementar navegação específica

#### Promoções
- **HTTPS**: `https://app.guarapark.com/promocao/456`
- **Scheme**: `guaraapp://promocao/456`
- **Tipo**: `DeepLinkType.promocao`
- **Status**: A implementar navegação específica

#### Reserva via Link
- **HTTPS**: `https://app.guarapark.com/reserva-via-link/789`
- **Scheme**: `guaraapp://reserva-via-link/789`
- **Tipo**: `DeepLinkType.reservaViaLink`
- **Status**: ✅ Implementado
- **Ação**: Abre `CortesiaLinkScreen` com o ID da cortesia
- **Nota**: Não requer autenticação prévia (validação na tela)

#### Perfil
- **HTTPS**: `https://app.guarapark.com/profile`
- **Scheme**: `guaraapp://profile`
- **Tipo**: `DeepLinkType.profile`
- **Status**: ✅ Implementado (navega para aba Account)

#### Reservas
- **HTTPS**: `https://app.guarapark.com/reservas`
- **Scheme**: `guaraapp://reservas`
- **Tipo**: `DeepLinkType.reservas`
- **Status**: ✅ Implementado (requer autenticação)

## 📋 Configuração Multi-Cliente

### Guará Acqua Park
- **Scheme**: `guaraapp`
- **Hosts HTTPS**: 
  - `app.guarapark.com`
  - `guarapark.app`
  - `www.guarapark.app`

### Vale das Minas Park
- **Scheme**: `valedasminasapp`
- **Hosts HTTPS**: 
  - `app.valedasminas.com`
  - `valedasminas.app`
  - `www.valedasminas.app`

## 🤖 Android

### AndroidManifest.xml

Os intent-filters foram configurados para cada cliente:

```xml
<!-- Deep Links - HTTPS -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="app.guarapark.com" />
    <data android:scheme="https" android:host="guarapark.app" />
    <data android:scheme="https" android:host="www.guarapark.app" />
</intent-filter>

<!-- Deep Links - Custom Scheme -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="guaraapp" />
</intent-filter>
```

### App Links Verification (HTTPS)

Para que os links HTTPS funcionem sem mostrar o seletor de app, é necessário:

1. Criar o arquivo `.well-known/assetlinks.json` no servidor:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.guaraapp",
    "sha256_cert_fingerprints": [
      "SHA256_DO_CERTIFICADO_DE_RELEASE"
    ]
  }
}]
```

2. Hospedar em: `https://app.guarapark.com/.well-known/assetlinks.json`

3. Obter o SHA256 do certificado:
```bash
keytool -list -v -keystore android/app/guara.keystore
```

## 🍎 iOS

### Info.plist

O arquivo Info.plist já está configurado:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.lsdevelopers.guara.deeplink</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>guaraapp</string>
        </array>
    </dict>
</array>
```

### Universal Links (HTTPS)

Para habilitar Universal Links no iOS:

1. Criar o arquivo `apple-app-site-association` (sem extensão):

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.lsdevelopers.guaraapp",
        "paths": ["*"]
      }
    ]
  }
}
```

2. Hospedar em: `https://app.guarapark.com/.well-known/apple-app-site-association`

3. Adicionar o domínio no Xcode:
   - Abrir o projeto no Xcode
   - Ir em **Signing & Capabilities**
   - Adicionar **Associated Domains**
   - Adicionar: `applinks:app.guarapark.com`

## 🧪 Testes

### Testar Deep Links no Android

```bash
# Custom Scheme - Reserva via Link (App Fechado)
adb shell am start -W -a android.intent.action.VIEW \
  -d "guaraapp://reserva-via-link/abc123" com.guaraapp

# HTTPS - Reserva via Link (App Fechado)
adb shell am start -W -a android.intent.action.VIEW \
  -d "https://app.guarapark.com/reserva-via-link/abc123" com.guaraapp

# Reservas gerais
adb shell am start -W -a android.intent.action.VIEW \
  -d "guaraapp://reservas" com.guaraapp

# Profile
adb shell am start -W -a android.intent.action.VIEW \
  -d "guaraapp://profile" com.guaraapp
```

### Testar Deep Links no iOS

```bash
# Simular no simulador
xcrun simctl openurl booted "guaraapp://reserva-via-link/abc123"
xcrun simctl openurl booted "https://app.guarapark.com/reserva-via-link/abc123"
xcrun simctl openurl booted "guaraapp://reservas"
xcrun simctl openurl booted "guaraapp://profile"
```

### Cenários de Teste

#### 1. App Fechado + Deep Link de Cortesia
**Passo a passo:**
1. Fechar completamente o app (swipe up no iOS / fechar no Android)
2. Clicar em link: `guaraapp://reserva-via-link/xyz789`
3. **Resultado esperado:**
   - App abre
   - Carrega configurações
   - Redireciona direto para `CortesiaLinkScreen`
   - Exibe formulário ou QR codes

#### 2. App em Background + Deep Link de Cortesia
**Passo a passo:**
1. App aberto em qualquer tela
2. Minimizar app (home button)
3. Clicar em link: `guaraapp://reserva-via-link/xyz789`
4. **Resultado esperado:**
   - App volta ao foreground
   - Navega para `CortesiaLinkScreen`

#### 3. App Ativo + Deep Link de Cortesia
**Passo a passo:**
1. App aberto e visível
2. Receber notificação ou clicar em link
3. **Resultado esperado:**
   - Navega imediatamente para `CortesiaLinkScreen`

#### 4. Deep Link de Profile (App Fechado)
**Passo a passo:**
1. App fechado
2. Clicar: `guaraapp://profile`
3. **Resultado esperado:**
   - App abre
   - Carrega configurações
   - Abre na aba Account

### Testar no Flutter (Desenvolvimento)

```dart
// Simular deep link (útil para debug)
DeepLinkService.instance.simulateDeepLink('guaraapp://reserva-via-link/test123');
```

## 📊 Parsing de Deep Links

O serviço retorna um objeto `DeepLinkInfo`:

```dart
final info = DeepLinkService.instance.parseDeepLink(link);

print(info?.route);        // '/evento'
print(info?.type);         // DeepLinkType.evento
print(info?.id);           // '123'
print(info?.queryParams);  // Map de parâmetros
```

## 🔄 Fluxo de Processamento

### 1. Inicialização do App
```
main.dart → DeepLinkService.initialize() → Listeners ativos
```

### 2. App Fechado → Link Recebido
```
Sistema → app_links → getInitialLink()
  ↓
DeepLinkService armazena em _pendingDeepLink
  ↓
AppConfigLoadingScreen carrega configurações
  ↓
_processarDeepLinkPendente() verifica link
  ↓
Parse do deep link
  ↓
┌─────────────────────────────────┐
│ Tipo: reservaViaLink?           │
├─────────────────────────────────┤
│ SIM → CortesiaLinkScreen        │
│ NÃO → MainNavigationScreen      │
│        (processa outros tipos)   │
└─────────────────────────────────┘
```

### 3. App em Background/Foreground → Link Recebido
```
Sistema → app_links → uriLinkStream
  ↓
DeepLinkService._handleIncomingDeepLink()
  ↓
Broadcast via onDeepLink stream
  ↓
MainNavigationScreen e HomeScreen escutam
  ↓
Processamento e navegação imediata
```

### 4. Processamento por Tela

**MainNavigationScreen:**
- `DeepLinkType.profile` → Navega para aba Account
- `DeepLinkType.home` → Navega para aba Home
- Outros tipos → Delega para HomeScreen

**HomeScreen:**
- `DeepLinkType.reservas` → Abre tela de reservas (requer autenticação)
- `DeepLinkType.reservaViaLink` → Abre `CortesiaLinkScreen` com o ID específico
- `DeepLinkType.eventos` → (a implementar)
- `DeepLinkType.promocoes` → (a implementar)
- `DeepLinkType.evento` → (a implementar)
- `DeepLinkType.promocao` → (a implementar)

### 5. Diagrama de Fluxo

```
┌─────────────────┐
│   Deep Link     │
│   Recebido      │
└────────┬────────┘
         │
         ├─── App Fechado ──────┐
         │                      │
         │                 getInitialLink()
         │                      │
         │              _pendingDeepLink
         │                      │
         │            Config Loading Screen
         │                      │
         │            MainNavigationScreen
         │                      │
         │          _checkPendingDeepLink()
         │                      │
         └─── App Ativo ────────┤
                                │
                         uriLinkStream
                                │
                         onDeepLink.listen()
                                │
                        ┌───────┴────────┐
                        │                │
              MainNavigationScreen  HomeScreen
                        │                │
                  Navega Tab        Navega Tela
```

## 🚨 Importante

- **Multi-cliente**: Cada cliente tem seu próprio scheme e hosts
- **Validação**: Links são validados antes de serem processados
- **Limpeza**: Sempre limpe o link pendente após processar
- **Stream**: Use o stream para reagir a novos links em tempo real

## 📚 Referências

- [app_links Package](https://pub.dev/packages/app_links)
- [Android App Links](https://developer.android.com/training/app-links)
- [iOS Universal Links](https://developer.apple.com/ios/universal-links/)

## 💡 Exemplos Práticos

### Compartilhar Link de Reserva

```dart
// Gerar link de cortesia para compartilhar
final cortesiaId = 'abc123def456';
final deepLink = DeepLinkService.instance.generateDeepLink(
  '/reserva-via-link/$cortesiaId',
  queryParams: {'source': 'share'},
);

// deepLink = "https://app.guarapark.com/reserva-via-link/abc123def456?source=share"

// Compartilhar via share_plus
Share.share(
  'Você foi convidado! Acesse sua cortesia: $deepLink',
  subject: 'Convite - Guará Acqua Park',
);
```

**O que acontece quando o usuário clica:**
1. Se o app estiver instalado → Abre direto na `CortesiaLinkScreen`
2. A tela valida o ID da cortesia
3. Exibe o formulário ou os QR Codes, dependendo do status

### Notificação Push com Deep Link

```dart
// No handler de notificação
void handleNotification(Map<String, dynamic> data) {
  final deepLink = data['deep_link'];
  
  if (deepLink != null) {
    // Simular recebimento do link
    DeepLinkService.instance.simulateDeepLink(deepLink);
  }
}
```

### Email Marketing com Deep Link

```html
<!-- Email HTML -->
<a href="https://app.guarapark.com/promocao/verao2024?source=email&campaign=summer">
  Aproveite nossa promoção de verão!
</a>
```

Quando o usuário clicar:
1. Se o app estiver instalado → Abre direto na promoção
2. Se não tiver o app → Abre no navegador (configurar web fallback)

### SMS com Link de Cortesia

```
Olá! Você ganhou uma cortesia para o Guará Acqua Park!
Preencha seus dados aqui: https://app.guarapark.com/reserva-via-link/xyz789

Válido até: 31/12/2025
```

**Fluxo:**
1. Cliente recebe SMS com link
2. Clica no link
3. App abre direto na `CortesiaLinkScreen`
4. Preenche dados dos convidados
5. Recebe QR Codes para entrada

### QR Code para Reserva Rápida

```dart
// Gerar QR Code com deep link
final qrData = DeepLinkService.instance.generateSchemeUrl(
  '/reserva-via-link/evento123',
);

// qrData = "guaraapp://reserva-via-link/evento123"

// Usar com package qr_flutter
QrImageView(
  data: qrData,
  version: QrVersions.auto,
  size: 200.0,
)
```
