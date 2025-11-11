#!/bin/bash

# Script para preparar o build - garante que os arquivos Firebase estejam corretos
# Uso: ./scripts/prepare_build.sh [guara|vale_das_minas]

CLIENT=$1

if [ -z "$CLIENT" ]; then
    echo "❌ Cliente não especificado!"
    echo "Uso: $0 [guara|vale_das_minas]"
    exit 1
fi

echo "🔧 Preparando build para cliente: $CLIENT"

# Verificar se existem ícones para o cliente
ICON_PATH="assets/icons"
if [ "$CLIENT" = "vale_das_minas" ]; then
    ICON_PATH="$ICON_PATH/valedasminas"
else
    ICON_PATH="$ICON_PATH/$CLIENT"
fi

if [ -f "$ICON_PATH/icon.png" ]; then
    echo "🎨 Gerando ícones específicos do cliente..."
    ./scripts/generate_icons.sh $CLIENT
    
    if [ $? -ne 0 ]; then
        echo "⚠️  Erro ao gerar ícones, continuando sem eles..."
    fi
else
    echo "ℹ️  Ícones específicos não encontrados em $ICON_PATH/icon.png"
    echo "   Usando ícones padrão. Para personalizar:"
    echo "   1. Adicione icon.png em $ICON_PATH/"
    echo "   2. Execute: ./scripts/generate_icons.sh $CLIENT"
fi

echo ""

# Configurar cliente
./scripts/build_client.sh $CLIENT

echo ""
echo "🏗️ Executando flutter clean e pub get..."

# Limpar e obter dependências
flutter clean
flutter pub get

echo ""
echo "✅ Projeto pronto para build!"
echo ""
echo "🚀 Para fazer o build:"
echo "   flutter build ios    # para iOS"
echo "   flutter build apk    # para Android APK"
echo "   flutter build appbundle # para Android App Bundle"
echo ""
echo "🔗 Para testar deep links:"
echo "   ./scripts/test_deeplinks.sh $CLIENT evento 123"
echo "   ./scripts/test_deeplinks.sh $CLIENT profile"
echo ""
echo "🧹 Após o build, limpe os arquivos temporários:"
echo "   ./scripts/clean_firebase.sh"