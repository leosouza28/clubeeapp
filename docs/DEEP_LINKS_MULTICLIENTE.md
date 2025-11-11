# Sistema de Deep Links Multi-Cliente - App Clubee

Sistema completo de deep links específicos por cliente, permitindo navegação direta para conteúdos específicos.

## 🔗 Configuração por Cliente

### Guará Park
- **Scheme personalizado:** `guaraapp://`
- **Host HTTPS:** `app.guarapark.com`
- **Hosts alternativos:** `guarapark.app`, `www.guarapark.app`
- **Exemplo:** `guaraapp://evento/123` ou `https://app.guarapark.com/evento/123`

### Vale das Minas
- **Scheme personalizado:** `valedasminasapp://`
- **Host HTTPS:** `app.valedasminas.com`
- **Hosts alternativos:** `valedasminas.app`, `www.valedasminas.app`
- **Exemplo:** `valedasminasapp://promocao/456` ou `https://app.valedasminas.com/promocao/456`

## 📱 Rotas Implementadas

### Rotas Principais
```
/                     # Página inicial
/profile             # Perfil do usuário
/reservas            # Minhas reservas
/eventos             # Lista de eventos
/promocoes           # Lista de promoções
```

### Rotas Dinâmicas
```
/evento/:id          # Detalhes de evento específico
/promocao/:id        # Detalhes de promoção específica
/share/:type/:id     # Conteúdo compartilhado
```

### Exemplos de URLs Completas

#### Guará Park
```bash
# Scheme personalizado
guaraapp://profile
guaraapp://evento/123
guaraapp://promocao/456

# HTTPS
https://app.guarapark.com/profile
https://app.guarapark.com/evento/123
https://app.guarapark.com/promocao/456
```

#### Vale das Minas
```bash
# Scheme personalizado
valedasminasapp://profile
valedasminasapp://evento/789
valedasminasapp://promocao/012

# HTTPS
https://app.valedasminas.com/profile
https://app.valedasminas.com/evento/789
https://app.valedasminas.com/promocao/012
```

## 🚀 Como Usar

### 1. Configurar Cliente

```bash
# Configurar para Guará (inclui deep links)
./scripts/build_client.sh guara

# Configurar para Vale das Minas
./scripts/build_client.sh vale_das_minas
```

### 2. Testar Deep Links

```bash
# Teste básico
./scripts/test_deeplinks.sh guara evento 123

# Teste de promoção
./scripts/test_deeplinks.sh vale_das_minas promocao 456

# Teste de perfil
./scripts/test_deeplinks.sh guara profile
```

### 3. Gerar Links para Compartilhamento

```dart
// No código Flutter
final deepLinkService = ClientService.instance.deepLinkService;

// Gerar link HTTPS para compartilhamento
String shareUrl = deepLinkService.generateDeepLink('/evento/123');
// Resultado: https://app.guarapark.com/evento/123

// Gerar URL com scheme personalizado
String schemeUrl = deepLinkService.generateSchemeUrl('/evento/123');
// Resultado: guaraapp://evento/123
```

## 🔧 Configuração Técnica

### Android (AndroidManifest.xml)
```xml
<!-- Deep Links HTTP/HTTPS -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" />
</intent-filter>

<!-- Deep Links Custom Scheme -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="guaraapp" />
</intent-filter>
```

### iOS (Info.plist)
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>app.guarapark.deeplink</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>guaraapp</string>
        </array>
    </dict>
    <dict>
        <key>CFBundleURLName</key>
        <string>app.guarapark.https</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>https</string>
        </array>
    </dict>
</array>
```

## 🧪 Testes

### Teste Manual Android
```bash
# Via ADB
adb shell am start -W -a android.intent.action.VIEW -d "guaraapp://evento/123"
adb shell am start -W -a android.intent.action.VIEW -d "https://app.guarapark.com/evento/123"
```

### Teste Manual iOS
```bash
# Via Simulador
xcrun simctl openurl booted "guaraapp://evento/123"
xcrun simctl openurl booted "https://app.guarapark.com/evento/123"
```

### Teste via Navegador
```bash
# Abrir no navegador (deve redirecionar para o app se instalado)
open "https://app.guarapark.com/evento/123"
```

## 📋 Funcionalidades

### ✅ Validação de Links
- Verifica se o link é válido para o cliente atual
- Rejeita links de outros clientes
- Redireciona para home em caso de erro

### ✅ Isolamento por Cliente
- Cada cliente tem seus próprios schemes e hosts
- Links de um cliente não abrem no app de outro
- Configuração automática via scripts

### ✅ Suporte Completo
- **Custom schemes:** `guaraapp://`, `valedasminasapp://`
- **HTTPS URLs:** Universal links para iOS, App links para Android
- **Fallback:** Redirecionamento para home em caso de erro

### ✅ Navegação Inteligente
- Roteamento baseado em GoRouter
- Parâmetros dinâmicos nas URLs
- Query parameters suportados

## 🔄 Workflow de Desenvolvimento

### Setup Inicial
```bash
# 1. Configurar cliente
./scripts/build_client.sh guara

# 2. Executar app
flutter run --dart-define=CLIENT_TYPE=guara

# 3. Testar deep links
./scripts/test_deeplinks.sh guara evento 123
```

### Adicionar Nova Rota
1. **Definir no DeepLinkService:** Adicionar nova rota em `_createRoutesForClient()`
2. **Implementar builder:** Criar método `_buildNovaPage()`
3. **Testar:** Usar script de teste com nova rota
4. **Documentar:** Atualizar esta documentação

### Deploy
1. **Build para produção:** `flutter build [platform] --dart-define=CLIENT_TYPE=[cliente]`
2. **Configurar domínios:** Verificar DNS para hosts HTTPS
3. **Testar em produção:** Verificar deep links em apps publicados

## 🌐 Configuração de Domínios

### App Links Android
Para funcionar em produção, configure:
1. **Digital Asset Links** no domínio
2. **Verificação automática** no Play Console
3. **HTTPS obrigatório** para universal links

### Universal Links iOS
Para funcionar em produção, configure:
1. **Apple App Site Association** no domínio
2. **HTTPS obrigatório**
3. **Certificados válidos**

## 🐛 Troubleshooting

### Link não abre o app
1. Verificar se app está instalado
2. Confirmar configuração correta do cliente
3. Testar scheme personalizado primeiro
4. Verificar logs de validação

### Redireciona para navegador
1. Verificar configuração de domínios
2. Confirmar App Links/Universal Links
3. Testar scheme personalizado como alternativa

### Página não encontrada
1. Verificar rota no DeepLinkService
2. Confirmar parâmetros da URL
3. Checar logs de navegação

## 💡 Exemplos de Uso

### Compartilhamento de Evento
```dart
// Gerar link para compartilhar
final eventId = "123";
final shareUrl = DeepLinkService.instance.generateDeepLink('/evento/$eventId');

// Compartilhar via Share Plus
Share.share('Confira este evento incrível: $shareUrl');
```

### Navegação Programática
```dart
// Navegar para evento específico
context.go('/evento/123');

// Navegar com parâmetros de query
context.go('/eventos?categoria=aquatico&destaque=true');
```

### Verificação de Link Válido
```dart
// Verificar se pode processar um link
final isValid = DeepLinkService.instance._isValidDeepLink(
  Uri.parse('https://app.guarapark.com/evento/123'),
  ClientService.instance.currentConfig,
);
```