#!/bin/bash

# Script rápido para adicionar cliente com parâmetros na linha de comando
# Uso: ./scripts/quick_add_client.sh "Nome Cliente" "#FF5722" "#FFC107" "com.cliente" "com.lsdevelopers.cliente"

CLIENT_NAME="$1"
PRIMARY_COLOR="$2"
SECONDARY_COLOR="$3"
ANDROID_PACKAGE="$4"
IOS_BUNDLE="$5"

if [ $# -lt 5 ]; then
    echo "❌ Uso: $0 \"Nome Cliente\" \"#PrimáriaHex\" \"#SecundáriaHex\" \"android.package\" \"ios.bundle.id\""
    echo ""
    echo "📋 Exemplo:"
    echo "  $0 \"Clube ABC\" \"#E91E63\" \"#FF5722\" \"com.clubeabc\" \"com.lsdevelopers.clubeabc\""
    echo ""
    echo "💡 Para versão interativa, use: ./scripts/add_new_client.sh"
    exit 1
fi

# Gerar identificadores automaticamente
CLIENT_ID=$(echo "$CLIENT_NAME" | sed 's/[^a-zA-Z0-9]/_/g' | tr '[:upper:]' '[:lower:]' | sed 's/__*/_/g' | sed 's/^_\|_$//g')
CLIENT_CAMEL=$(echo "$CLIENT_NAME" | sed 's/[^a-zA-Z0-9]//g' | sed 's/\(.\)\(.*\)/\L\1\E\2/')

API_URL="https://api.$CLIENT_ID.clubee.com"
SUPPORT_EMAIL="suporte@$CLIENT_ID.com"
MAX_USERS="1000"
ENABLE_FEATURE_X="true"

echo "🚀 Adicionando cliente rapidamente..."
echo "👤 Nome: $CLIENT_NAME"
echo "🆔 ID: $CLIENT_ID"
echo "🐪 Enum: $CLIENT_CAMEL"
echo "📱 Android: $ANDROID_PACKAGE"
echo "🍎 iOS: $IOS_BUNDLE"

# Executar o script principal com respostas automáticas
{
    echo "$CLIENT_NAME"
    echo "$PRIMARY_COLOR"
    echo "$SECONDARY_COLOR"
    echo "$API_URL"
    echo "$ANDROID_PACKAGE"
    echo "$IOS_BUNDLE"
    echo "$SUPPORT_EMAIL"
    echo "$MAX_USERS"
    echo "y"
    echo "y"
} | $(dirname "$0")/add_new_client.sh

echo ""
echo "✅ Cliente '$CLIENT_NAME' adicionado!"
echo "🧪 Teste agora: flutter run --dart-define=CLIENT_TYPE=$CLIENT_ID"