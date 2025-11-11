#!/bin/bash

# Script para gerar ícones do app para um cliente específico
# Uso: ./scripts/generate_icons.sh [guara|vale_das_minas]

CLIENT=$1

if [ -z "$CLIENT" ]; then
    echo "❌ Cliente não especificado!"
    echo "Uso: $0 [guara|vale_das_minas]"
    echo ""
    echo "Clientes disponíveis:"
    echo "  🏊 guara        - Guará Acqua Park"
    echo "  ⛰️  vale_das_minas - Vale das Minas Park"
    exit 1
fi

# Verificar se o cliente é válido
if [ "$CLIENT" != "guara" ] && [ "$CLIENT" != "vale_das_minas" ]; then
    echo "❌ Cliente '$CLIENT' não reconhecido!"
    echo "Clientes disponíveis: guara, vale_das_minas"
    exit 1
fi

# Configurar nome do arquivo de configuração
if [ "$CLIENT" = "vale_das_minas" ]; then
    CONFIG_FILE="flutter_icons_valedasminas.yaml"
    ICON_PATH="assets/icons/valedasminas"
else
    CONFIG_FILE="flutter_icons_$CLIENT.yaml"
    ICON_PATH="assets/icons/$CLIENT"
fi

echo "🎨 Gerando ícones para cliente: $CLIENT"
echo "📄 Arquivo de configuração: $CONFIG_FILE"
echo "📁 Pasta de ícones: $ICON_PATH"

# Verificar se o arquivo de configuração existe
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Arquivo de configuração não encontrado: $CONFIG_FILE"
    exit 1
fi

# Verificar se os ícones existem
if [ ! -f "$ICON_PATH/icon.png" ]; then
    echo "❌ Ícone principal não encontrado: $ICON_PATH/icon.png"
    echo ""
    echo "📝 Instruções:"
    echo "   1. Coloque seu ícone principal em: $ICON_PATH/icon.png"
    echo "   2. Tamanho recomendado: 1024x1024 pixels"
    echo "   3. Formato: PNG com fundo transparente"
    exit 1
fi

if [ ! -f "$ICON_PATH/adaptive_icon.png" ]; then
    echo "⚠️  Ícone adaptativo não encontrado: $ICON_PATH/adaptive_icon.png"
    echo "   Será usado apenas o ícone principal"
fi

echo ""
echo "🔧 Gerando ícones..."

# Executar flutter_launcher_icons com o arquivo de configuração específico
dart run flutter_launcher_icons:main -f $CONFIG_FILE

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Ícones gerados com sucesso para $CLIENT!"
    echo ""
    echo "📱 Ícones Android gerados em:"
    echo "   android/app/src/main/res/mipmap-*/"
    echo ""
    echo "🍎 Ícones iOS gerados em:"
    echo "   ios/Runner/Assets.xcassets/AppIcon.appiconset/"
    echo ""
    echo "🚀 Próximos passos:"
    echo "   1. Execute: ./scripts/build_client.sh $CLIENT"
    echo "   2. Execute: flutter clean && flutter pub get"
    echo "   3. Execute: flutter build [android|ios]"
else
    echo ""
    echo "❌ Erro ao gerar ícones!"
    echo "Verifique se os arquivos de ícone estão corretos."
fi