# Firebase Multi-Cliente - App Clubee

Sistema de configuração Firebase para múltiplos clientes no App Clubee.

## 📁 Estrutura de Arquivos Firebase

### Arquivos de Configuração por Cliente

#### Cliente Guará
- `lib/firebase_options_guara.dart` - Configurações Firebase geradas pelo FlutterFire CLI
- `android/app/google-services-guara.json` - Configuração Android do projeto Firebase
- `ios/Runner/GoogleService-Guara-Info.plist` - Configuração iOS do projeto Firebase

#### Cliente Vale das Minas
- `lib/firebase_options_valedasminas.dart` - Configurações Firebase geradas pelo FlutterFire CLI
- `android/app/google-services-valedasminas.json` - Configuração Android do projeto Firebase
- `ios/Runner/GoogleService-ValeDasMinas-Info.plist` - Configuração iOS do projeto Firebase

## 🚀 Como Usar

### 1. Validar Configurações Firebase

```bash
# Validar configurações do Guará
./scripts/firebase_client.sh guara validate

# Validar configurações do Vale das Minas
./scripts/firebase_client.sh vale_das_minas validate
```

### 2. Preparar Build para um Cliente

```bash
# Preparar build completo (recomendado)
./scripts/prepare_build.sh guara
./scripts/prepare_build.sh vale_das_minas

# OU configurar manualmente
./scripts/build_client.sh guara
flutter clean && flutter pub get
```

### 3. Fazer o Build

```bash
# iOS
flutter build ios

# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle
```

### 4. Limpar Arquivos Temporários (Após o Build)

```bash
# Remover arquivos temporários Firebase
./scripts/clean_firebase.sh
```

## 🔧 Scripts Disponíveis

### `prepare_build.sh`
Script recomendado para preparar build completo incluindo limpeza e pub get.

**Uso:**
```bash
./scripts/prepare_build.sh [guara|vale_das_minas]
```

### `build_client.sh`
Script para configurar o aplicativo para um cliente específico (sem limpeza automática).

**O que faz:**
- Configura package names Android/iOS
- Copia arquivos Firebase específicos do cliente
- Configura cliente no código principal
- **Mantém** arquivos temporários para o build

### `firebase_client.sh`
Script principal para gerenciar configurações Firebase por cliente.

**Ações disponíveis:**
- `setup` - Configurar Firebase para o cliente
- `test` - Testar configuração Firebase
- `validate` - Validar arquivos de configuração

### `clean_firebase.sh`
Remove arquivos temporários Firebase mantendo os arquivos específicos de cada cliente.

**⚠️ Importante:** Execute apenas **APÓS** fazer o build!

## 📱 Projetos Firebase

### Guará Acqua Park
- **Project ID:** `guaraacquapark`
- **Android Package:** `com.guaraapp`
- **iOS Bundle ID:** `com.lsdevelopers.guaraapp`

### Vale das Minas Park
- **Project ID:** `valedasminasapp`
- **Android Package:** `com.valedasminas`
- **iOS Bundle ID:** `com.lsdevelopers.valedasminas`

## 🔥 Como Funciona o Firebase Multi-Cliente

### 1. Configuração Dinâmica
O `FirebaseService` inicializa automaticamente com as configurações do cliente ativo:

```dart
// Inicialização automática no main.dart
await FirebaseService.instance.initializeForClient(clientType);
```

### 2. Troca de Cliente
É possível trocar de cliente dinamicamente:

```dart
// Trocar para outro cliente
await FirebaseService.instance.switchClient(ClientType.valedasminas);
```

### 3. Serviços Firebase
Cada cliente tem seus próprios serviços isolados:
- **Analytics:** Eventos enviados para o projeto correto
- **Messaging:** Tokens FCM específicos por cliente
- **Isolamento:** Cada cliente é uma instância Firebase separada

## 🛠️ Configuração Inicial de um Novo Cliente

Para adicionar um novo cliente Firebase:

1. **Criar projeto no Firebase Console**
2. **Configurar com FlutterFire CLI:**
   ```bash
   flutterfire configure --project=novo-projeto-id --out=lib/firebase_options_novocliente.dart
   ```
3. **Baixar arquivos de configuração:**
   - Android: `google-services.json` → `google-services-novocliente.json`
   - iOS: `GoogleService-Info.plist` → `GoogleService-NovoCliente-Info.plist`
4. **Atualizar scripts** com as novas configurações
5. **Atualizar `ClientConfig`** com as opções Firebase

## ⚠️ Importantes

### Arquivos Temporários
Durante o build, os arquivos são copiados temporariamente:
- `google-services.json` (copiado e removido após build)
- `GoogleService-Info.plist` (copiado e removido após build)

### Arquivos Permanentes
Os arquivos específicos dos clientes são mantidos permanentemente:
- `google-services-[cliente].json`
- `GoogleService-[Cliente]-Info.plist`

### Versionamento Git
**Incluir no Git:**
- ✅ `firebase_options_*.dart`
- ✅ `google-services-*.json`
- ✅ `GoogleService-*-Info.plist`

**Ignorar do Git:**
- ❌ `google-services.json` (temporário)
- ❌ `GoogleService-Info.plist` (temporário)

## 🐛 Troubleshooting

### Erro: "Arquivo não encontrado"
1. Verifique se os arquivos Firebase estão nos locais corretos
2. Execute `./scripts/firebase_client.sh [cliente] validate`
3. Certifique-se de que os nomes dos arquivos estão corretos

### Erro: "Firebase não inicializado"
1. Verifique se o Firebase foi inicializado no `main.dart`
2. Confirme que o `firebase_options_*.dart` existe
3. Execute flutter clean e flutter pub get

### Erro: "Projeto Firebase incorreto"
1. Verifique o Project ID no firebase_options
2. Confirme que os arquivos Google Services são do projeto correto
3. Regenere os arquivos com FlutterFire CLI se necessário