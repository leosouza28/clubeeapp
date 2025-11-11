#!/bin/bash

# Script para testar deep links
# Uso: ./scripts/test_deeplinks.sh [guara|vale_das_minas] [tipo] [id]

CLIENT=$1
TIPO=${2:-evento}
ID=${3:-123}

if [ -z "$CLIENT" ]; then
    echo "❌ Cliente não especificado!"
    echo "Uso: $0 [guara|vale_das_minas] [evento|promocao|profile|reservas] [id]"
    echo ""
    echo "Exemplos:"
    echo "  $0 guara evento 123        # Teste evento 123 do Guará"
    echo "  $0 vale_das_minas promocao 456  # Teste promoção 456 do Vale das Minas"
    echo "  $0 guara profile            # Teste perfil do Guará"
    exit 1
fi

# Configurar URLs por cliente
if [ "$CLIENT" = "guara" ]; then
    SCHEME="guaraapp"
    HOST="app.guarapark.com"
    APP_NAME="Guará Park"
elif [ "$CLIENT" = "vale_das_minas" ]; then
    SCHEME="valedasminasapp"
    HOST="app.valedasminas.com"
    APP_NAME="Vale das Minas"
else
    echo "❌ Cliente '$CLIENT' não reconhecido!"
    exit 1
fi

echo "🔗 Testando deep links para: $APP_NAME"
echo ""

# Construir URLs de teste
case $TIPO in
    "evento")
        SCHEME_URL="$SCHEME://evento/$ID"
        HTTPS_URL="https://$HOST/evento/$ID"
        ;;
    "promocao")
        SCHEME_URL="$SCHEME://promocao/$ID"
        HTTPS_URL="https://$HOST/promocao/$ID"
        ;;
    "profile")
        SCHEME_URL="$SCHEME://profile"
        HTTPS_URL="https://$HOST/profile"
        ;;
    "reservas")
        SCHEME_URL="$SCHEME://reservas"
        HTTPS_URL="https://$HOST/reservas"
        ;;
    *)
        SCHEME_URL="$SCHEME://$TIPO"
        HTTPS_URL="https://$HOST/$TIPO"
        ;;
esac

echo "📱 URLs de teste geradas:"
echo "   Scheme URL: $SCHEME_URL"
echo "   HTTPS URL:  $HTTPS_URL"
echo ""

# Verificar se o app está rodando
if ! adb devices | grep -q "device$"; then
    echo "⚠️  Nenhum dispositivo Android conectado via ADB"
    echo "   Para testar no iOS, use o simulador ou dispositivo físico"
else
    echo "🤖 Testando no Android..."
    echo ""
    
    echo "1️⃣ Testando Scheme URL..."
    adb shell am start \
        -W -a android.intent.action.VIEW \
        -d "$SCHEME_URL" \
        2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Scheme URL testada com sucesso!"
    else
        echo "❌ Erro ao testar Scheme URL"
    fi
    
    echo ""
    echo "2️⃣ Testando HTTPS URL..."
    adb shell am start \
        -W -a android.intent.action.VIEW \
        -d "$HTTPS_URL" \
        2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ HTTPS URL testada com sucesso!"
    else
        echo "❌ Erro ao testar HTTPS URL"
    fi
fi

echo ""
echo "📋 Comandos para teste manual:"
echo ""
echo "Android (ADB):"
echo "  adb shell am start -W -a android.intent.action.VIEW -d \"$SCHEME_URL\""
echo "  adb shell am start -W -a android.intent.action.VIEW -d \"$HTTPS_URL\""
echo ""
echo "iOS (Simulador):"
echo "  xcrun simctl openurl booted \"$SCHEME_URL\""
echo "  xcrun simctl openurl booted \"$HTTPS_URL\""
echo ""
echo "Navegador (para testar redirecionamento):"
echo "  open \"$HTTPS_URL\""
echo ""
echo "💡 Dicas:"
echo "  - Certifique-se de que o app está configurado para $CLIENT"
echo "  - Execute: ./scripts/build_client.sh $CLIENT"
echo "  - O app deve estar rodando no dispositivo/simulador"