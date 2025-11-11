#!/bin/bash

# Script para configurar package names e Firebase por cliente
# Uso: ./scripts/build_client.sh [guara|vale_das_minas]

CLIENT=$1

if [ "$CLIENT" = "guara" ]; then
    ANDROID_PACKAGE="com.guaraapp"
    IOS_BUNDLE_ID="com.lsdevelopers.guaraapp"
    FIREBASE_CONFIG="firebase_options_guara.dart"
    GOOGLE_SERVICES_FILE="google-services-guara.json"
    GOOGLE_SERVICES_IOS="GoogleService-Guara-Info.plist"
    APP_NAME="Guará Park"
    APP_DISPLAY_NAME="Guará Park"
    APP_LABEL="guara_park"
    DEEP_LINK_SCHEME="guaraapp"
    DEEP_LINK_HOST="app.guarapark.com"
    IOS_VERSION="2.0.30"
    IOS_BUILD_NUMBER="1"
elif [ "$CLIENT" = "vale_das_minas" ]; then
    ANDROID_PACKAGE="com.valedasminas"
    IOS_BUNDLE_ID="com.lsdevelopers.valedasminas"
    FIREBASE_CONFIG="firebase_options_valedasminas.dart"
    GOOGLE_SERVICES_FILE="google-services-valedasminas.json"
    GOOGLE_SERVICES_IOS="GoogleService-ValeDasMinas-Info.plist"
    APP_NAME="Vale das Minas"
    APP_DISPLAY_NAME="Vale das Minas"
    APP_LABEL="vale_das_minas"
    DEEP_LINK_SCHEME="valedasminasapp"
    DEEP_LINK_HOST="app.valedasminas.com"
    IOS_VERSION="1.0.0"
    IOS_BUILD_NUMBER="2"
else
    echo "Uso: $0 [guara|vale_das_minas]"
    echo "Clientes disponíveis:"
    echo "  - guara: Aplicativo do Guará"
    echo "  - vale_das_minas: Aplicativo do Vale das Minas"
    exit 1
fi

echo "🔧 Configurando para cliente: $CLIENT"
echo "📱 Android Package: $ANDROID_PACKAGE"
echo "🍎 iOS Bundle ID: $IOS_BUNDLE_ID"
echo "🔥 Firebase Config: $FIREBASE_CONFIG"
echo "📄 Google Services: $GOOGLE_SERVICES_FILE"
echo "📄 iOS Config: $GOOGLE_SERVICES_IOS"
echo "📱 Nome do App: $APP_NAME"
echo "🏷️ Nome de Exibição: $APP_DISPLAY_NAME"
echo "🔗 Deep Link Scheme: $DEEP_LINK_SCHEME"
echo "🌐 Deep Link Host: $DEEP_LINK_HOST"
echo "📊 iOS Version: $IOS_VERSION"
echo "🔢 iOS Build Number: $IOS_BUILD_NUMBER"

# Configurar Android
echo "🔧 Configurando Android..."
sed -i.bak "s/namespace = \".*\"/namespace = \"$ANDROID_PACKAGE\"/" android/app/build.gradle.kts
sed -i.bak "s/applicationId = \".*\"/applicationId = \"$ANDROID_PACKAGE\"/" android/app/build.gradle.kts

# Configurar nome do app no Android
sed -i.bak "s/android:label=\".*\"/android:label=\"$APP_DISPLAY_NAME\"/" android/app/src/main/AndroidManifest.xml

# Configurar deep links no Android
sed -i.bak "s/android:scheme=\"guaraapp\"/android:scheme=\"$DEEP_LINK_SCHEME\"/" android/app/src/main/AndroidManifest.xml

# Configurar iOS
echo "🔧 Configurando iOS..."
sed -i.bak "s/PRODUCT_BUNDLE_IDENTIFIER = .*$/PRODUCT_BUNDLE_IDENTIFIER = $IOS_BUNDLE_ID;/" ios/Runner.xcodeproj/project.pbxproj

# Configurar nomes no iOS
sed -i.bak "s/<string>App Clubee<\/string>/<string>$APP_DISPLAY_NAME<\/string>/" ios/Runner/Info.plist
sed -i.bak "s/<string>app_clubee<\/string>/<string>$APP_LABEL<\/string>/" ios/Runner/Info.plist

# Configurar versões no pubspec.yaml
echo "🔧 Configurando versões no pubspec.yaml..."
sed -i.bak "s/^version: .*/version: $IOS_VERSION+$IOS_BUILD_NUMBER/" pubspec.yaml
echo "✅ Versão configurada: $IOS_VERSION+$IOS_BUILD_NUMBER"

# Configurar URL Scheme no iOS
echo "🔧 Configurando URL Scheme no iOS..."
# Substituir o scheme dentro do array CFBundleURLSchemes usando sed multilinha
sed -i.bak "/<key>CFBundleURLSchemes<\/key>/,/<\/array>/ {
    s/<string>guaraapp<\/string>/<string>$DEEP_LINK_SCHEME<\/string>/
    s/<string>valedasminasapp<\/string>/<string>$DEEP_LINK_SCHEME<\/string>/
}" ios/Runner/Info.plist

# Configurar deep links no iOS (bundle URL name)
sed -i.bak "s/com\.lsdevelopers\.[^.]*\.deeplink/com.lsdevelopers.${CLIENT//_/}.deeplink/g" ios/Runner/Info.plist

# Verificar se o arquivo de configuração Firebase existe
if [ ! -f "lib/$FIREBASE_CONFIG" ]; then
    echo "❌ Erro: Arquivo de configuração Firebase não encontrado: lib/$FIREBASE_CONFIG"
    echo "💡 Certifique-se de que o arquivo existe antes de executar este script"
    exit 1
fi

echo "🔥 Configuração Firebase encontrada: $FIREBASE_CONFIG"

# Configurar arquivos Firebase específicos do cliente
echo "🔧 Configurando arquivos Firebase..."

# Copiar google-services.json para Android
if [ -f "android/app/$GOOGLE_SERVICES_FILE" ]; then
    cp -f "android/app/$GOOGLE_SERVICES_FILE" "android/app/google-services.json"
    echo "✅ Android: $GOOGLE_SERVICES_FILE → google-services.json"
else
    echo "❌ Arquivo não encontrado: android/app/$GOOGLE_SERVICES_FILE"
    exit 1
fi

# Copiar GoogleService-Info.plist para iOS (sobrescrever sempre)
if [ -f "ios/Runner/$GOOGLE_SERVICES_IOS" ]; then
    # Remove o arquivo principal se existir
    rm -f "ios/Runner/GoogleService-Info.plist"
    # Copia o arquivo do cliente específico
    cp -f "ios/Runner/$GOOGLE_SERVICES_IOS" "ios/Runner/GoogleService-Info.plist"
    echo "✅ iOS: $GOOGLE_SERVICES_IOS → GoogleService-Info.plist (sobrescrito)"
else
    echo "❌ Arquivo não encontrado: ios/Runner/$GOOGLE_SERVICES_IOS"
    exit 1
fi

# Configurar cliente no main.dart
echo "🔧 Configurando cliente no main.dart..."
if [ "$CLIENT" = "guara" ]; then
    sed -i.bak "s/ClientService.instance.setClient(ClientType\.[^)]*)/ClientService.instance.setClient(ClientType.guara)/" lib/main.dart
else
    sed -i.bak "s/ClientService.instance.setClient(ClientType\.[^)]*)/ClientService.instance.setClient(ClientType.valeDasMinas)/" lib/main.dart
fi

echo ""
echo "✅ Configuração concluída para $CLIENT!"
echo "📋 Resumo das alterações:"
echo "   - Android Package: $ANDROID_PACKAGE"
echo "   - iOS Bundle ID: $IOS_BUNDLE_ID"
echo "   - Versão (pubspec.yaml): $IOS_VERSION+$IOS_BUILD_NUMBER"
echo "   - URL Scheme: $DEEP_LINK_SCHEME"
echo "   - Firebase Config: $FIREBASE_CONFIG"
echo ""
echo "🚀 Próximos passos:"
echo "   1. Execute: flutter clean"
echo "   2. Execute: flutter pub get"
echo "   3. Para Android:"
echo "      flutter build apk"
echo "      ou: flutter build appbundle"
echo "   4. Para iOS:"
echo "      flutter build ios"
echo ""
echo "💡 Nota: As versões agora estão configuradas no pubspec.yaml"
echo "   e serão aplicadas automaticamente durante o build."
echo ""
echo "📝 Arquivos Firebase temporários criados:"
echo "   📱 android/app/google-services.json"
echo "   🍎 ios/Runner/GoogleService-Info.plist"
echo ""
echo "⚠️  Para limpar os arquivos temporários após o build:"
echo "   ./scripts/clean_firebase.sh"