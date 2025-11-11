#!/bin/bash

# Script para testar deep links
# Uso: ./test_deeplink.sh [cliente] [tipo] [id]

CLIENTE=${1:-"guara"}
TIPO=${2:-"evento"}
ID=${3:-"123"}

case $CLIENTE in
  "guara")
    SCHEME="guaraapp"
    HOST="app.guarapark.com"
    ;;
  "vale")
    SCHEME="valedasminasapp"
    HOST="app.valedasminas.com"
    ;;
  *)
    echo "❌ Cliente não reconhecido: $CLIENTE"
    echo "Clientes disponíveis: guara, vale"
    exit 1
    ;;
esac

echo "🔗 Testando deep links para cliente: $CLIENTE"
echo "📱 Scheme: $SCHEME"
echo "🌐 Host: $HOST"
echo ""

# Testar scheme personalizado
SCHEME_URL="${SCHEME}://${TIPO}/${ID}"
echo "1️⃣ Testando scheme URL: $SCHEME_URL"
adb shell am start \
  -W -a android.intent.action.VIEW \
  -d "$SCHEME_URL" \
  com.${CLIENTE}app

echo ""
sleep 2

# Testar HTTPS URL
HTTPS_URL="https://${HOST}/${TIPO}/${ID}?promocao=teste&ref=deeplink"
echo "2️⃣ Testando HTTPS URL: $HTTPS_URL"
adb shell am start \
  -W -a android.intent.action.VIEW \
  -d "$HTTPS_URL" \
  com.${CLIENTE}app

echo ""
echo "✅ Testes de deep link concluídos!"
echo "Verifique os logs do app para confirmar a captura."