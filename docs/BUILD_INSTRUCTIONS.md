# Configuração de Build por Cliente

## Scripts Disponíveis

### 🚀 Builds Automáticos (Recomendado)

#### Android
```bash
# Guará - Release
./scripts/build_android.sh guara release

# Guará - Debug  
./scripts/build_android.sh guara debug

# Vale das Minas - Release
./scripts/build_android.sh vale_das_minas release

# Vale das Minas - Debug
./scripts/build_android.sh vale_das_minas debug
```

#### iOS (somente macOS)
```bash
# Guará - Release
./scripts/build_ios.sh guara release

# Vale das Minas - Release  
./scripts/build_ios.sh vale_das_minas release
```

### ⚙️ Configuração Manual (Alternativa)
```bash
# Para usar apenas se os scripts automáticos não funcionarem
./scripts/build_client.sh guara
./scripts/build_client.sh vale_das_minas
```

### 🧪 Builds com dart-define (Avançado)
```bash
# Android com dart-define
flutter build apk --dart-define=CLIENT_TYPE=guara --release

# iOS com dart-define  
flutter build ios --dart-define=CLIENT_TYPE=vale_das_minas --release
```

## 📦 Package Names Configurados

### Guará
- **Android**: `com.guaraapp`
- **iOS**: `com.lsdevelopers.guaraapp`

### Vale das Minas
- **Android**: `com.valedasminas`
- **iOS**: `com.lsdevelopers.valedasminas`

## 🔄 Processo Recomendado

### Para Desenvolvimento
1. Use o seletor de cliente dentro do app (aparece em debug)
2. Execute `flutter run` normalmente

### Para Build de Produção
1. **Android**: Execute `./scripts/build_android.sh [cliente] release`
2. **iOS**: Execute `./scripts/build_ios.sh [cliente] release`
3. Os scripts fazem tudo automaticamente:
   - Configuram package names
   - Fazem clean e pub get
   - Compilam com o cliente correto
   - Restauram configurações originais
   - Renomeiam os arquivos finais

## 📱 Exemplos Práticos

### Build Guará para Android
```bash
./scripts/build_android.sh guara release
# Gera: build/app/outputs/flutter-apk/app-guara-release.apk
```

### Build Vale das Minas para iOS
```bash
./scripts/build_ios.sh vale_das_minas release
# Gera: build/ios/iphoneos/Runner.app
```

## 🎯 Vantagens dos Scripts

- ✅ **Automático**: Configura tudo sem intervenção manual
- ✅ **Seguro**: Faz backup e restaura configurações
- ✅ **Limpo**: Executa flutter clean automaticamente  
- ✅ **Nomeação**: Renomeia arquivos com nome do cliente
- ✅ **Logs**: Mostra progresso detalhado
- ✅ **Validação**: Verifica parâmetros antes de executar

## 🔧 Solução de Problemas

### Erro de Permissão
```bash
chmod +x scripts/*.sh
```

### Build iOS falha
- Verifique se está no macOS
- Abra ios/Runner.xcworkspace no Xcode
- Configure certificados e provisioning profiles

### Package name não muda
- Execute `flutter clean` manualmente
- Verifique se os scripts têm permissão de escrita
- Restaure backups: `mv arquivo.bak arquivo`

## 📋 Checklist para Publicação

### Android
- [ ] Build com script: `./scripts/build_android.sh [cliente] release`
- [ ] Assinar APK com chave de produção
- [ ] Testar em dispositivos físicos
- [ ] Upload para Google Play Console

### iOS  
- [ ] Build com script: `./scripts/build_ios.sh [cliente] release`
- [ ] Abrir no Xcode e configurar certificados
- [ ] Archive e distribuir
- [ ] Upload para App Store Connect