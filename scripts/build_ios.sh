#!/bin/bash

# Script para build do iOS por cliente
# Uso: ./scripts/build_ios.sh [guara|vale_das_minas] [debug|release]

CLIENT=$1
BUILD_MODE=${2:-release}

if [ "$CLIENT" != "guara" ] && [ "$CLIENT" != "vale_das_minas" ]; then
    echo "❌ Erro: Cliente deve ser 'guara' ou 'vale_das_minas'"
    echo "Uso: $0 [guara|vale_das_minas] [debug|release]"
    exit 1
fi

if [ "$BUILD_MODE" != "debug" ] && [ "$BUILD_MODE" != "release" ]; then
    echo "❌ Erro: Modo deve ser 'debug' ou 'release'"
    exit 1
fi

# Verificar se está no macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Erro: Build iOS só é possível no macOS"
    exit 1
fi

# Configurações por cliente
case $CLIENT in
    "guara")
        IOS_BUNDLE_ID="com.lsdevelopers.guaraapp"
        APP_NAME="Guará"
        ;;
    "vale_das_minas")
        IOS_BUNDLE_ID="com.lsdevelopers.valedasminas"
        APP_NAME="Vale das Minas"
        ;;
esac

echo "🚀 Iniciando build iOS para $APP_NAME"
echo "📦 Bundle ID: $IOS_BUNDLE_ID"
echo "🔧 Modo: $BUILD_MODE"

# Configurar bundle ID temporariamente
echo "⚙️ Configurando bundle ID..."
sed -i.bak "s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*/PRODUCT_BUNDLE_IDENTIFIER = $IOS_BUNDLE_ID/g" ios/Runner.xcodeproj/project.pbxproj

# Limpar cache
echo "🧹 Limpando cache..."
flutter clean > /dev/null 2>&1

# Baixar dependências
echo "📚 Baixando dependências..."
flutter pub get > /dev/null 2>&1

# Build
echo "🔨 Compilando..."
if [ "$BUILD_MODE" = "release" ]; then
    flutter build ios \
        --dart-define=CLIENT_TYPE=$CLIENT \
        --release \
        --no-codesign
else
    flutter build ios \
        --dart-define=CLIENT_TYPE=$CLIENT \
        --debug \
        --no-codesign
fi

# Restaurar arquivos originais
echo "♻️ Restaurando configurações..."
if [ -f "ios/Runner.xcodeproj/project.pbxproj.bak" ]; then
    mv ios/Runner.xcodeproj/project.pbxproj.bak ios/Runner.xcodeproj/project.pbxproj
fi

if [ $? -eq 0 ]; then
    echo "✅ Build concluído com sucesso!"
    echo "📁 IPA localizado em: build/ios/iphoneos/"
    echo ""
    echo "📋 Próximos passos para publicação:"
    echo "  1. Abra ios/Runner.xcworkspace no Xcode"
    echo "  2. Configure certificados de desenvolvimento/distribuição"
    echo "  3. Configure provisioning profiles"
    echo "  4. Archive e distribua via Xcode"
else
    echo "❌ Erro durante o build"
    exit 1
fi