#!/bin/bash

# Script completo para configurar branding de um cliente
# Uso: ./scripts/setup_client_branding.sh [guara|vale_das_minas] [--create-examples]

CLIENT=$1
CREATE_EXAMPLES=$2

if [ -z "$CLIENT" ]; then
    echo "❌ Cliente não especificado!"
    echo "Uso: $0 [guara|vale_das_minas] [--create-examples]"
    echo ""
    echo "Opções:"
    echo "  --create-examples    Criar ícones de exemplo automaticamente"
    echo ""
    echo "Clientes disponíveis:"
    echo "  🏊 guara        - Guará Acqua Park"
    echo "  ⛰️  vale_das_minas - Vale das Minas Park"
    exit 1
fi

echo "🎨 Configurando branding completo para: $CLIENT"
echo ""

# Verificar se deve criar ícones de exemplo
if [ "$CREATE_EXAMPLES" = "--create-examples" ]; then
    echo "🔧 Criando ícones de exemplo..."
    python3 scripts/create_example_icons.py $CLIENT
    
    if [ $? -ne 0 ]; then
        echo "⚠️  Não foi possível criar ícones automaticamente"
        echo "    Você pode adicionar manualmente em assets/icons/$CLIENT/"
    fi
    echo ""
fi

# Configurar cliente completo
echo "🚀 Executando configuração completa..."
./scripts/prepare_build.sh $CLIENT

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Branding configurado com sucesso para $CLIENT!"
    echo ""
    echo "📋 Resumo do que foi configurado:"
    echo "   🎨 Ícones específicos do cliente (se disponíveis)"
    echo "   📱 Nomes de exibição personalizados"
    echo "   🔥 Configurações Firebase específicas"
    echo "   📦 Package names e Bundle IDs"
    echo ""
    echo "🚀 Próximos passos:"
    echo "   1. flutter build ios"
    echo "   2. flutter build android"
    echo ""
    echo "🧹 Após o build, limpe os temporários:"
    echo "   ./scripts/clean_firebase.sh"
else
    echo "❌ Erro na configuração!"
fi