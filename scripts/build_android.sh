#!/bin/bash

# Script para build do Android por cliente
# Uso: ./scripts/build_android.sh [guara|vale_das_minas] [debug|release]

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

# Configurações por cliente
case $CLIENT in
    "guara")
        ANDROID_PACKAGE="com.guaraapp"
        APP_NAME="Guará"
        ;;
    "vale_das_minas")
        ANDROID_PACKAGE="com.valedasminas"
        APP_NAME="Vale das Minas"
        ;;
esac

echo "🚀 Iniciando build Android para $APP_NAME"
echo "📦 Package: $ANDROID_PACKAGE"
echo "🔧 Modo: $BUILD_MODE"

# Configurar package name temporariamente
echo "⚙️ Configurando package name..."
sed -i.bak "s/namespace = \".*\"/namespace = \"$ANDROID_PACKAGE\"/" android/app/build.gradle.kts
sed -i.bak "s/applicationId = \".*\"/applicationId = \"$ANDROID_PACKAGE\"/" android/app/build.gradle.kts

# Limpar cache
echo "🧹 Limpando cache..."
flutter clean > /dev/null 2>&1

# Baixar dependências
echo "📚 Baixando dependências..."
flutter pub get > /dev/null 2>&1

# Build
echo "🔨 Compilando..."
if [ "$BUILD_MODE" = "release" ]; then
    flutter build apk \
        --dart-define=CLIENT_TYPE=$CLIENT \
        --release \
        --target-platform android-arm,android-arm64,android-x64
else
    flutter build apk \
        --dart-define=CLIENT_TYPE=$CLIENT \
        --debug
fi

# Restaurar arquivos originais
echo "♻️ Restaurando configurações..."
if [ -f "android/app/build.gradle.kts.bak" ]; then
    mv android/app/build.gradle.kts.bak android/app/build.gradle.kts
fi

if [ $? -eq 0 ]; then
    echo "✅ Build concluído com sucesso!"
    echo "📁 APK localizado em: build/app/outputs/flutter-apk/"
    
    # Renomear APK para incluir nome do cliente
    APK_PATH="build/app/outputs/flutter-apk"
    if [ "$BUILD_MODE" = "release" ]; then
        APK_NAME="app-release.apk"
        NEW_NAME="app-${CLIENT}-release.apk"
    else
        APK_NAME="app-debug.apk"
        NEW_NAME="app-${CLIENT}-debug.apk"
    fi
    
    if [ -f "$APK_PATH/$APK_NAME" ]; then
        cp "$APK_PATH/$APK_NAME" "$APK_PATH/$NEW_NAME"
        echo "📱 APK renomeado para: $NEW_NAME"
    fi
else
    echo "❌ Erro durante o build"
    exit 1
fi