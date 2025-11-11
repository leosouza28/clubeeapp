#!/bin/bash

# Script para verificar a configuração atual do projeto
# Uso: ./scripts/verify_config.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

PROJECT_ROOT=$(dirname "$0")/..

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}     VERIFICAÇÃO DE CONFIGURAÇÃO - APP CLUBEE${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Android
echo -e "${BLUE}📱 ANDROID${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"

echo -e "${GREEN}Package Name (build.gradle.kts):${NC}"
namespace=$(grep "namespace = " "$PROJECT_ROOT/android/app/build.gradle.kts" | sed 's/.*"\(.*\)".*/\1/')
app_id=$(grep "applicationId = " "$PROJECT_ROOT/android/app/build.gradle.kts" | sed 's/.*"\(.*\)".*/\1/')
echo "  • namespace: $namespace"
echo "  • applicationId: $app_id"

if [ "$namespace" != "$app_id" ]; then
    echo -e "${RED}  ⚠️  AVISO: namespace e applicationId são diferentes!${NC}"
fi

echo ""
echo -e "${GREEN}App Label (AndroidManifest.xml):${NC}"
label=$(grep "android:label=" "$PROJECT_ROOT/android/app/src/main/AndroidManifest.xml" | sed 's/.*android:label="\([^"]*\)".*/\1/')
echo "  • $label"

echo ""
echo -e "${GREEN}Deep Link Scheme (AndroidManifest.xml):${NC}"
schemes=$(grep "android:scheme=" "$PROJECT_ROOT/android/app/src/main/AndroidManifest.xml" | sed 's/.*android:scheme="\([^"]*\)".*/\1/')
echo "$schemes" | while read scheme; do
    echo "  • $scheme"
done

echo ""
echo -e "${GREEN}Firebase Configuration:${NC}"
if [ -f "$PROJECT_ROOT/android/app/google-services.json" ]; then
    firebase_package=$(grep -o '"package_name": "[^"]*"' "$PROJECT_ROOT/android/app/google-services.json" | head -1 | cut -d'"' -f4)
    firebase_project=$(grep -o '"project_id": "[^"]*"' "$PROJECT_ROOT/android/app/google-services.json" | head -1 | cut -d'"' -f4)
    echo "  • Package: $firebase_package"
    echo "  • Project: $firebase_project"
    
    if [ "$firebase_package" != "$app_id" ]; then
        echo -e "${RED}  ⚠️  AVISO: Firebase package difere do applicationId!${NC}"
    else
        echo -e "${GREEN}  ✅ Firebase package está correto${NC}"
    fi
else
    echo -e "${RED}  ❌ google-services.json NÃO ENCONTRADO!${NC}"
fi

echo ""
echo -e "${GREEN}MainActivity.kt:${NC}"
package_path=$(echo "$app_id" | tr '.' '/')
main_activity_file="$PROJECT_ROOT/android/app/src/main/kotlin/$package_path/MainActivity.kt"
if [ -f "$main_activity_file" ]; then
    main_package=$(grep "^package " "$main_activity_file" | sed 's/package //')
    echo "  • Package: $main_package"
    if [ "$main_package" = "$app_id" ]; then
        echo -e "${GREEN}  ✅ MainActivity.kt com package correto${NC}"
    else
        echo -e "${RED}  ⚠️  AVISO: MainActivity.kt package ($main_package) difere do applicationId ($app_id)${NC}"
    fi
else
    echo -e "${RED}  ❌ MainActivity.kt NÃO ENCONTRADO em: $main_activity_file${NC}"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# iOS
echo -e "${BLUE}🍎 iOS${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"

echo -e "${GREEN}Bundle Identifier (project.pbxproj):${NC}"
bundle_id=$(grep "PRODUCT_BUNDLE_IDENTIFIER = " "$PROJECT_ROOT/ios/Runner.xcodeproj/project.pbxproj" | head -1 | sed 's/.*PRODUCT_BUNDLE_IDENTIFIER = \([^;]*\);/\1/')
echo "  • $bundle_id"

echo ""
echo -e "${GREEN}Display Name (Info.plist):${NC}"
display_name=$(grep -A 1 "CFBundleDisplayName" "$PROJECT_ROOT/ios/Runner/Info.plist" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
echo "  • $display_name"

echo ""
echo -e "${GREEN}Bundle Name (Info.plist):${NC}"
bundle_name=$(grep -A 1 "CFBundleName" "$PROJECT_ROOT/ios/Runner/Info.plist" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
echo "  • $bundle_name"

echo ""
echo -e "${GREEN}URL Schemes (Info.plist):${NC}"
# Extrair URL schemes do Info.plist
awk '/<key>CFBundleURLSchemes<\/key>/,/<\/array>/' "$PROJECT_ROOT/ios/Runner/Info.plist" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/' | while read scheme; do
    echo "  • $scheme"
done

echo ""
echo -e "${GREEN}Firebase Configuration:${NC}"
if [ -f "$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist" ]; then
    firebase_bundle=$(grep -A 1 "BUNDLE_ID" "$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist" | grep "<string>" | head -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    firebase_project=$(grep -A 1 "PROJECT_ID" "$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist" | grep "<string>" | head -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    echo "  • Bundle ID: $firebase_bundle"
    echo "  • Project: $firebase_project"
    
    if [ "$firebase_bundle" != "$bundle_id" ]; then
        echo -e "${RED}  ⚠️  AVISO: Firebase bundle ID difere do PRODUCT_BUNDLE_IDENTIFIER!${NC}"
    else
        echo -e "${GREEN}  ✅ Firebase bundle ID está correto${NC}"
    fi
else
    echo -e "${RED}  ❌ GoogleService-Info.plist NÃO ENCONTRADO!${NC}"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Resumo
echo -e "${BLUE}📊 RESUMO${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"

# Determinar qual cliente está configurado
if [[ "$app_id" == "com.guaraapp" ]] && [[ "$bundle_id" == "com.lsdevelopers.guaraapp" ]]; then
    echo -e "${GREEN}Cliente Configurado: Guará${NC}"
elif [[ "$app_id" == "com.valedasminas" ]] && [[ "$bundle_id" == "com.lsdevelopers.valedasminas" ]]; then
    echo -e "${GREEN}Cliente Configurado: Vale das Minas${NC}"
else
    echo -e "${YELLOW}Cliente: Configuração mista ou personalizada${NC}"
fi

echo "  • Android Package: $app_id"
echo "  • iOS Bundle ID: $bundle_id"
echo "  • Display Name: $display_name"

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
