# Scripts de Configuração Multi-Cliente

Este diretório contém scripts para facilitar a configuração e build do App Clubee para diferentes clientes.

## 📋 Scripts Disponíveis

### 1. `configure_client.sh` - Configuração de Cliente

Configura automaticamente o projeto para um cliente específico, alterando:
- Package name (Android)
- Bundle ID (iOS)
- Nome do aplicativo
- Deep link schemes
- Arquivos Firebase (google-services.json e GoogleService-Info.plist)

**Uso:**
```bash
./scripts/configure_client.sh [guara|vale_das_minas]
```

**Exemplos:**
```bash
# Configurar para Guará
./scripts/configure_client.sh guara

# Configurar para Vale das Minas
./scripts/configure_client.sh vale_das_minas

# Restaurar backups
./scripts/configure_client.sh guara --restore
```

**O que ele faz:**

✅ **Android:**
- Atualiza `namespace` e `applicationId` em `build.gradle.kts`
- Atualiza `android:label` no `AndroidManifest.xml`
- Atualiza deep link schemes no `AndroidManifest.xml`
- **Cria/atualiza `MainActivity.kt` com o package correto** para cada cliente
- Copia o arquivo `google-services-{cliente}.json` para `google-services.json`
- Verifica se o package name está correto

✅ **iOS:**
- Atualiza `PRODUCT_BUNDLE_IDENTIFIER` no `project.pbxproj`
- Atualiza display name e bundle name no `Info.plist`
- Atualiza URL schemes no `Info.plist`
- Copia o arquivo `GoogleService-{Cliente}-Info.plist` para `GoogleService-Info.plist`
- Verifica se o bundle ID está correto

✅ **Flutter:**
- Configura o cliente padrão no `lib/main.dart`

**Arquivos de Backup:**
- Todos os arquivos modificados recebem uma cópia de backup com extensão `.backup`
- Use a opção `--restore` para restaurar os backups

---

### 2. `build_client.sh` - Build Automatizado

Script mais antigo para configuração e build. Similar ao `configure_client.sh` mas com foco em preparação para build.

**Uso:**
```bash
./scripts/build_client.sh [guara|vale_das_minas]
```

---

### 3. `clean_backups.sh` - Limpeza de Backups

Remove todos os arquivos de backup (.backup) criados pelo `configure_client.sh`.

**Uso:**
```bash
./scripts/clean_backups.sh
```

---

### 4. `verify_config.sh` - Verificação de Configuração

Exibe um relatório completo da configuração atual do projeto, mostrando:
- Package names (Android)
- Bundle IDs (iOS)
- Nomes de exibição
- Deep link schemes
- Configurações Firebase
- Validação de consistência

**Uso:**
```bash
./scripts/verify_config.sh
```

**Saída:**
- Mostra todas as configurações de Android e iOS
- Verifica se os arquivos Firebase estão corretos
- Identifica qual cliente está configurado
- Alerta sobre inconsistências

---

## 🔧 Configuração de Clientes

### Guará
- **Android Package:** `com.guaraapp`
- **iOS Bundle ID:** `com.lsdevelopers.guaraapp`
- **Nome:** Guará
- **Deep Link Scheme:** `guaraapp`
- **Firebase Android:** `google-services-guara.json`
- **Firebase iOS:** `GoogleService-Guara-Info.plist`

### Vale das Minas
- **Android Package:** `com.valedasminas`
- **iOS Bundle ID:** `com.lsdevelopers.valedasminas`
- **Nome:** Vale das Minas
- **Deep Link Scheme:** `valedasminasapp`
- **Firebase Android:** `google-services-valedasminas.json`
- **Firebase iOS:** `GoogleService-ValeDasMinas-Info.plist`

---

## 🚀 Fluxo de Trabalho Recomendado

### Para Desenvolvimento:
```bash
# 1. Configurar para o cliente desejado
./scripts/configure_client.sh guara

# 2. Limpar cache do Flutter
flutter clean

# 3. Instalar dependências
flutter pub get

# 4. Executar o app
flutter run
```

### Para Build de Produção:

#### Android:
```bash
# 1. Configurar cliente
./scripts/configure_client.sh guara

# 2. Limpar e preparar
flutter clean
flutter pub get

# 3. Build
flutter build apk --release
# ou
flutter build appbundle --release
```

#### iOS:
```bash
# 1. Configurar cliente
./scripts/configure_client.sh guara

# 2. Limpar e preparar
flutter clean
flutter pub get

# 3. Build
flutter build ios --release
```

### Trocar de Cliente Durante Desenvolvimento:
```bash
# Mudar de Guará para Vale das Minas
./scripts/configure_client.sh vale_das_minas
flutter clean
flutter pub get
flutter run
```

---

## 📝 Arquivos Modificados

Ao executar `configure_client.sh`, os seguintes arquivos são modificados:

### Android:
- `android/app/build.gradle.kts` (namespace e applicationId)
- `android/app/src/main/AndroidManifest.xml` (label e deep link schemes)
- `android/app/src/main/kotlin/{package}/MainActivity.kt` (criado/atualizado com package correto)
- `android/app/google-services.json` (substituído pelo arquivo do cliente)

**Nota:** As permissões do AndroidManifest.xml são preservadas durante a troca de cliente.

### iOS:
- `ios/Runner.xcodeproj/project.pbxproj` (bundle identifier)
- `ios/Runner/Info.plist` (display name, bundle name e URL schemes)
- `ios/Runner/GoogleService-Info.plist` (substituído pelo arquivo do cliente)

**Nota:** As permissões (UsageDescription) do Info.plist são preservadas durante a troca de cliente.

### Flutter:
- `lib/main.dart` (cliente padrão)

---

## 🔐 Permissões Configuradas

### Android
O app possui as seguintes permissões configuradas:
- ✅ **Internet** - Comunicação com APIs
- ✅ **Câmera** - Tirar fotos
- ✅ **Armazenamento/Galeria** - Selecionar fotos (compatível com Android 13+)
- ✅ **Bluetooth** - Impressoras térmicas (compatível com Android 12+)
- ✅ **Push Notifications** - Notificações (compatível com Android 13+)

### iOS
- ✅ **Camera** - Captura de fotos
- ✅ **Photo Library** - Seleção de imagens
- ✅ **Bluetooth** - Impressoras térmicas
- ✅ **Location** - Recursos baseados em localização
- ✅ **Microphone** - Recursos de áudio
- ✅ **Background Modes** - Notificações e atualizações

**Documentação completa:** Veja [docs/PERMISSOES.md](../docs/PERMISSOES.md)

---

## ⚠️ Importante

1. **Backups:** O script cria backups automáticos de todos os arquivos modificados
2. **Firebase:** Os arquivos Firebase específicos de cada cliente devem existir antes de executar o script
3. **Git:** Recomenda-se fazer commit antes de executar os scripts de configuração
4. **Clean:** Sempre execute `flutter clean` após trocar de cliente

---

## 🔍 Verificação

Para verificar se a configuração está correta:

```bash
# Verificar Android package
grep "namespace\|applicationId" android/app/build.gradle.kts

# Verificar iOS bundle ID
grep "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj

# Verificar Firebase Android
grep "package_name" android/app/google-services.json

# Verificar Firebase iOS
grep "BUNDLE_ID" ios/Runner/GoogleService-Info.plist
```

---

## 📞 Suporte

Em caso de problemas:
1. Verifique se todos os arquivos Firebase existem
2. Execute `./scripts/configure_client.sh [cliente] --restore` para restaurar backups
3. Execute `flutter clean && flutter pub get`
4. Se necessário, use `./scripts/clean_backups.sh` para limpar backups antigos
