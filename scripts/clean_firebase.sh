#!/bin/bash

# Script para limpar arquivos temporários Firebase
# Remove os arquivos google-services.json e GoogleService-Info.plist
# que são criados temporariamente durante o build

echo "🧹 Limpando arquivos temporários Firebase..."

# Remover google-services.json do Android (arquivo temporário)
if [ -f "android/app/google-services.json" ]; then
    rm "android/app/google-services.json"
    echo "✅ Removido: android/app/google-services.json"
fi

# Remover GoogleService-Info.plist do iOS (arquivo temporário)
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    rm "ios/Runner/GoogleService-Info.plist"
    echo "✅ Removido: ios/Runner/GoogleService-Info.plist"
fi

echo ""
echo "✨ Limpeza concluída!"
echo ""
echo "📝 Nota: Os arquivos específicos do cliente foram mantidos:"
echo "   📱 android/app/google-services-guara.json"
echo "   📱 android/app/google-services-valedasminas.json"
echo "   🍎 ios/Runner/GoogleService-Guara-Info.plist"
echo "   🍎 ios/Runner/GoogleService-ValeDasMinas-Info.plist"