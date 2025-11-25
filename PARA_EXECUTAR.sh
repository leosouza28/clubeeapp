# TODO: Script de build para o cliente "Nome do Cliente"

# ═══════════════════════════════════════════════════════════════
# 1. CONFIGURAR CLIENTE (escolha um)
# ═══════════════════════════════════════════════════════════════
# Este comando configura a INFRAESTRUTURA nativa (iOS/Android):
# - Package names (Android) - com.guaraapp ou com.valedasminas
# - Bundle IDs (iOS) - com.lsdevelopers.guaraapp ou .valedasminas
# - Firebase configs (google-services.json e GoogleService-Info.plist)
# - MainActivity.kt com package correto
# - Deep links (guaraapp:// ou valedasminasapp://)
#
# ATENÇÃO: Isso NÃO define qual cliente o Flutter vai usar!
# Para isso, use --dart-define=CLIENT_TYPE no passo 5

sh ./scripts/configure_client.sh guara
# ou
sh ./scripts/configure_client.sh vale_das_minas

# ═══════════════════════════════════════════════════════════════
# 2. VERIFICAR CONFIGURAÇÃO (opcional mas recomendado)
# ═══════════════════════════════════════════════════════════════
sh ./scripts/verify_config.sh

# ═══════════════════════════════════════════════════════════════
# 3. CONFIGURAR ÍCONES (se necessário)
# ═══════════════════════════════════════════════════════════════
# sh ./scripts/generate_icons.sh guara
# sh ./scripts/generate_icons.sh vale_das_minas

# ═══════════════════════════════════════════════════════════════
# 4. LIMPAR E PREPARAR
# ═══════════════════════════════════════════════════════════════
flutter clean && flutter pub get

# ═══════════════════════════════════════════════════════════════
# 5. EXECUTAR APP ✅
# ═══════════════════════════════════════════════════════════════
# IMPORTANTE: Use --dart-define para especificar o cliente

# Para Guará:
flutter run --dart-define=CLIENT_TYPE=guara

# Para Vale das Minas:
flutter run --dart-define=CLIENT_TYPE=vale_das_minas

# Ou para especificar dispositivo:
# flutter run --dart-define=CLIENT_TYPE=guara -d <device_id>
# flutter run --dart-define=CLIENT_TYPE=vale_das_minas -d <device_id>

# ═══════════════════════════════════════════════════════════════
# 6. BUILD PARA PRODUÇÃO
# ═══════════════════════════════════════════════════════════════
# IMPORTANTE: Configure o cliente ANTES de fazer o build!

# Android APK (Guará):
# flutter build apk --release --dart-define=CLIENT_TYPE=guara

# Android APK (Vale das Minas):
# flutter build apk --release --dart-define=CLIENT_TYPE=vale_das_minas

# Android App Bundle (Guará):
# flutter build appbundle --release --dart-define=CLIENT_TYPE=guara

# Android App Bundle (Vale das Minas):
# flutter build appbundle --release --dart-define=CLIENT_TYPE=vale_das_minas

# iOS (Guará):
# flutter build ios --release --dart-define=CLIENT_TYPE=guara

# iOS (Vale das Minas):
# flutter build ios --release --dart-define=CLIENT_TYPE=vale_das_minas

# ═══════════════════════════════════════════════════════════════
# 7. LIMPAR BACKUPS (após confirmar que tudo funciona)
# ═══════════════════════════════════════════════════════════════
# sh ./scripts/clean_backups.sh

# ═══════════════════════════════════════════════════════════════
# 📚 DOCUMENTAÇÃO ADICIONAL
# ═══════════════════════════════════════════════════════════════
# Veja:
# - scripts/README.md - Documentação completa dos scripts
# - docs/PERMISSOES.md - Guia de permissões Android e iOS
# - scripts/verify_config.sh - Verificar configuração atual


# Build IPA iOS - Guará
sh ./scripts/configure_client.sh guara
sh ./scripts/generate_icons.sh guara
flutter clean && flutter pub get
cd ios && pod install && cd .. && flutter build ipa --dart-define=CLIENT_TYPE=guara
# Android
flutter build appbundle --dart-define=CLIENT_TYPE=guara

# Build IPA iOS - Vale das Minas
sh ./scripts/configure_client.sh vale_das_minas
sh ./scripts/generate_icons.sh vale_das_minas
flutter clean && flutter pub get
cd ios && pod install && cd .. && flutter build ipa --dart-define=CLIENT_TYPE=vale_das_minas
# Android
flutter build appbundle --dart-define=CLIENT_TYPE=vale_das_minas
