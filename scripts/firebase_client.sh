#!/bin/bash

# Script para gerenciar configurações Firebase por cliente
# Uso: ./scripts/firebase_client.sh [guara|vale_das_minas] [action]
# Actions: setup, test, validate

CLIENT=$1
ACTION=${2:-setup}

if [ "$CLIENT" = "guara" ]; then
    FIREBASE_CONFIG="firebase_options_guara.dart"
    PROJECT_ID="guaraacquapark"
    ANDROID_PACKAGE="com.guaraapp"
    IOS_BUNDLE_ID="com.lsdevelopers.guaraapp"
elif [ "$CLIENT" = "vale_das_minas" ]; then
    FIREBASE_CONFIG="firebase_options_valedasminas.dart"
    PROJECT_ID="valedasminasapp"
    ANDROID_PACKAGE="com.valedasminas"
    IOS_BUNDLE_ID="com.lsdevelopers.valedasminas"
else
    echo "❌ Cliente inválido!"
    echo "Uso: $0 [guara|vale_das_minas] [setup|test|validate]"
    echo ""
    echo "Clientes disponíveis:"
    echo "  🏊 guara        - Guará Acqua Park"
    echo "  ⛰️  vale_das_minas - Vale das Minas Park"
    echo ""
    echo "Ações disponíveis:"
    echo "  📦 setup       - Configurar Firebase para o cliente"
    echo "  🧪 test        - Testar configuração Firebase"
    echo "  ✅ validate    - Validar arquivos de configuração"
    exit 1
fi

case $ACTION in
    "setup")
        echo "🔥 Configurando Firebase para: $CLIENT"
        echo "📁 Arquivo de configuração: $FIREBASE_CONFIG"
        echo "🎯 Project ID: $PROJECT_ID"
        echo ""
        
        # Verificar se o arquivo existe
        if [ ! -f "lib/$FIREBASE_CONFIG" ]; then
            echo "❌ Erro: Arquivo de configuração não encontrado!"
            echo "📍 Arquivo esperado: lib/$FIREBASE_CONFIG"
            echo ""
            echo "💡 Para criar o arquivo, execute:"
            echo "   flutterfire configure --project=$PROJECT_ID --out=lib/$FIREBASE_CONFIG"
            exit 1
        fi
        
        echo "✅ Arquivo de configuração encontrado!"
        echo "🔧 Validando configuração..."
        
        # Verificar se contém as chaves necessárias
        if grep -q "projectId.*$PROJECT_ID" "lib/$FIREBASE_CONFIG"; then
            echo "✅ Project ID correto: $PROJECT_ID"
        else
            echo "❌ Project ID incorreto ou não encontrado"
            exit 1
        fi
        
        if grep -q "$ANDROID_PACKAGE" "lib/$FIREBASE_CONFIG"; then
            echo "✅ Android Package configurado: $ANDROID_PACKAGE"
        else
            echo "⚠️  Android Package não encontrado no arquivo"
        fi
        
        if grep -q "$IOS_BUNDLE_ID" "lib/$FIREBASE_CONFIG"; then
            echo "✅ iOS Bundle ID configurado: $IOS_BUNDLE_ID"
        else
            echo "⚠️  iOS Bundle ID não encontrado no arquivo"
        fi
        
        echo ""
        echo "🎉 Configuração Firebase validada para $CLIENT!"
        ;;
        
    "test")
        echo "🧪 Testando configuração Firebase para: $CLIENT"
        echo ""
        
        if [ ! -f "lib/$FIREBASE_CONFIG" ]; then
            echo "❌ Arquivo de configuração não encontrado: lib/$FIREBASE_CONFIG"
            exit 1
        fi
        
        echo "📊 Analisando arquivo de configuração..."
        
        # Contar configurações Android
        ANDROID_CONFIGS=$(grep -c "android" "lib/$FIREBASE_CONFIG")
        echo "📱 Configurações Android encontradas: $ANDROID_CONFIGS"
        
        # Contar configurações iOS  
        IOS_CONFIGS=$(grep -c "ios" "lib/$FIREBASE_CONFIG")
        echo "🍎 Configurações iOS encontradas: $IOS_CONFIGS"
        
        # Verificar se tem API Key
        if grep -q "apiKey" "lib/$FIREBASE_CONFIG"; then
            echo "🔑 API Key encontrada: ✅"
        else
            echo "🔑 API Key encontrada: ❌"
        fi
        
        # Verificar se tem App ID
        if grep -q "appId" "lib/$FIREBASE_CONFIG"; then
            echo "📱 App ID encontrado: ✅"
        else
            echo "📱 App ID encontrado: ❌"
        fi
        
        echo ""
        echo "🏁 Teste concluído!"
        ;;
        
    "validate")
        echo "✅ Validando configurações Firebase para: $CLIENT"
        echo ""
        
        # Definir arquivos Firebase específicos do cliente
        google_services_file=""
        google_services_ios=""
        
        case "$CLIENT" in
            "guara")
                google_services_file="google-services-guara.json"
                google_services_ios="GoogleService-Guara-Info.plist"
                ;;
            "vale_das_minas")
                google_services_file="google-services-valedasminas.json"
                google_services_ios="GoogleService-ValeDasMinas-Info.plist"
                ;;
        esac
        
        # Lista de arquivos necessários
        REQUIRED_FILES=(
            "lib/$FIREBASE_CONFIG"
            "android/app/$google_services_file"
            "ios/Runner/$google_services_ios"
        )
        
        ALL_VALID=true
        
        for file in "${REQUIRED_FILES[@]}"; do
            if [ -f "$file" ]; then
                echo "✅ $file"
            else
                echo "❌ $file (FALTANDO)"
                ALL_VALID=false
            fi
        done
        
        echo ""
        
        if [ "$ALL_VALID" = true ]; then
            echo "🎉 Todas as configurações Firebase estão presentes!"
            echo ""
            echo "🚀 Você pode prosseguir com:"
            echo "   ./scripts/build_client.sh $CLIENT"
        else
            echo "⚠️  Algumas configurações estão faltando!"
            echo ""
            echo "💡 Para configurar o Firebase:"
            echo "   1. Execute: flutterfire configure --project=$PROJECT_ID"
            echo "   2. Mova o arquivo gerado para: lib/$FIREBASE_CONFIG"
            echo "   3. Certifique-se de que os arquivos Google Services estão corretos:"
            echo "      - android/app/$google_services_file"
            echo "      - ios/Runner/$google_services_ios"
            echo "   4. Execute novamente: $0 $CLIENT validate"
        fi
        ;;
        
    *)
        echo "❌ Ação inválida: $ACTION"
        echo "Ações disponíveis: setup, test, validate"
        exit 1
        ;;
esac