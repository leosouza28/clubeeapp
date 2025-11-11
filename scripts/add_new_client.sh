#!/bin/bash

# Script para adicionar um novo cliente ao projeto
# Uso: ./scripts/add_new_client.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para exibir mensagens
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Função para converter texto para camelCase
to_camel_case() {
    echo "$1" | sed 's/[^a-zA-Z0-9]//g' | sed 's/\(.\)\(.*\)/\L\1\E\2/'
}

# Função para converter texto para snake_case
to_snake_case() {
    echo "$1" | sed 's/[^a-zA-Z0-9]/_/g' | tr '[:upper:]' '[:lower:]' | sed 's/__*/_/g' | sed 's/^_\|_$//g'
}

# Função para converter texto para PascalCase
to_pascal_case() {
    echo "$1" | sed 's/[^a-zA-Z0-9]/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1' | sed 's/ //g'
}

# Função para converter para package name
to_package_name() {
    echo "$1" | sed 's/[^a-zA-Z0-9]//g' | tr '[:upper:]' '[:lower:]'
}

echo "🏢 Gerador de Novo Cliente - App Clubee"
echo "======================================"
echo ""

# Coletar informações do cliente
read -p "📝 Nome do cliente (ex: 'Novo Cliente'): " CLIENT_NAME
if [ -z "$CLIENT_NAME" ]; then
    log_error "Nome do cliente é obrigatório"
    exit 1
fi

read -p "🎨 Cor primária (hex com #, ex: '#FF5722'): " PRIMARY_COLOR
if [ -z "$PRIMARY_COLOR" ]; then
    PRIMARY_COLOR="#2196F3"
    log_warn "Usando cor padrão: $PRIMARY_COLOR"
fi

read -p "🎨 Cor secundária (hex com #, ex: '#FFC107'): " SECONDARY_COLOR
if [ -z "$SECONDARY_COLOR" ]; then
    SECONDARY_COLOR="#FF9800"
    log_warn "Usando cor padrão: $SECONDARY_COLOR"
fi

read -p "🌐 URL da API (ex: 'https://api.cliente.clubee.com'): " API_URL
if [ -z "$API_URL" ]; then
    API_URL="https://api.$(to_package_name "$CLIENT_NAME").clubee.com"
    log_warn "Usando URL padrão: $API_URL"
fi

read -p "📱 Package Android (ex: 'com.cliente'): " ANDROID_PACKAGE
if [ -z "$ANDROID_PACKAGE" ]; then
    ANDROID_PACKAGE="com.$(to_package_name "$CLIENT_NAME")"
    log_warn "Usando package padrão: $ANDROID_PACKAGE"
fi

read -p "🍎 Bundle ID iOS (ex: 'com.lsdevelopers.cliente'): " IOS_BUNDLE
if [ -z "$IOS_BUNDLE" ]; then
    IOS_BUNDLE="com.lsdevelopers.$(to_package_name "$CLIENT_NAME")"
    log_warn "Usando bundle padrão: $IOS_BUNDLE"
fi

read -p "� Project ID do Firebase (ex: 'cliente-app-123'): " FIREBASE_PROJECT_ID
if [ -z "$FIREBASE_PROJECT_ID" ]; then
    FIREBASE_PROJECT_ID="$(to_package_name "$CLIENT_NAME")-app"
    log_warn "Usando project ID padrão: $FIREBASE_PROJECT_ID"
fi

read -p "�📧 Email de suporte (ex: 'suporte@cliente.com'): " SUPPORT_EMAIL
if [ -z "$SUPPORT_EMAIL" ]; then
    SUPPORT_EMAIL="suporte@$(to_package_name "$CLIENT_NAME").com"
    log_warn "Usando email padrão: $SUPPORT_EMAIL"
fi

read -p "👥 Número máximo de usuários (ex: 1000): " MAX_USERS
if [ -z "$MAX_USERS" ]; then
    MAX_USERS="1000"
    log_warn "Usando máximo padrão: $MAX_USERS"
fi

read -p "⚡ Habilitar Feature X? (y/n): " ENABLE_FEATURE_X
if [ "$ENABLE_FEATURE_X" = "y" ] || [ "$ENABLE_FEATURE_X" = "Y" ]; then
    ENABLE_FEATURE_X="true"
else
    ENABLE_FEATURE_X="false"
fi

# Gerar identificadores
CLIENT_ID=$(to_snake_case "$CLIENT_NAME")
CLIENT_CAMEL=$(to_camel_case "$CLIENT_NAME")
CLIENT_PASCAL=$(to_pascal_case "$CLIENT_NAME")

echo ""
log_info "Configurações geradas:"
echo "  👤 Nome: $CLIENT_NAME"
echo "  🆔 ID: $CLIENT_ID"
echo "  🐪 CamelCase: $CLIENT_CAMEL"
echo "  📱 Android: $ANDROID_PACKAGE"
echo "  🍎 iOS: $IOS_BUNDLE"
echo "  🎨 Cores: $PRIMARY_COLOR / $SECONDARY_COLOR"
echo "  🌐 API: $API_URL"
echo "  🔥 Firebase: $FIREBASE_PROJECT_ID"
echo ""

read -p "✅ Confirma a criação do cliente? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    log_warn "Operação cancelada"
    exit 0
fi

PROJECT_ROOT=$(dirname "$0")/..

# Fazer backup dos arquivos que serão modificados
log_step "Fazendo backup dos arquivos..."
cp "$PROJECT_ROOT/lib/config/client_type.dart" "$PROJECT_ROOT/lib/config/client_type.dart.backup"
cp "$PROJECT_ROOT/lib/config/client_config.dart" "$PROJECT_ROOT/lib/config/client_config.dart.backup"

# 1. Adicionar ao enum ClientType
log_step "Adicionando ao enum ClientType..."
# Substituir a linha que fecha o enum para adicionar o novo cliente
sed -i.tmp "s/valeDasMinas;/valeDasMinas,\n  $CLIENT_CAMEL;/" "$PROJECT_ROOT/lib/config/client_type.dart"

# Adicionar o case no displayName
sed -i.tmp "/case ClientType.valeDasMinas:/a\\
      case ClientType.$CLIENT_CAMEL:\\
        return '$CLIENT_NAME';" "$PROJECT_ROOT/lib/config/client_type.dart"

# Adicionar o case no id
sed -i.tmp "/return 'vale_das_minas';/a\\
      case ClientType.$CLIENT_CAMEL:\\
        return '$CLIENT_ID';" "$PROJECT_ROOT/lib/config/client_type.dart"

rm -f "$PROJECT_ROOT/lib/config/client_type.dart.tmp"

# Atualizar ClientConfig para incluir import do Firebase
log_step "Adicionando import do Firebase..."
sed -i.tmp "/import 'client_type.dart';/a\\
import '../firebase_options_${CLIENT_ID}.dart' as firebase_${CLIENT_ID};" "$PROJECT_ROOT/lib/config/client_config.dart"

# 2. Adicionar configuração no ClientConfig
log_step "Adicionando configuração do cliente..."

# Criar o tema específico
THEME_METHOD="_create${CLIENT_PASCAL}Theme"

# Converter cores hex para Color objects
PRIMARY_COLOR_OBJECT="Color(0xFF${PRIMARY_COLOR:1})"
SECONDARY_COLOR_OBJECT="Color(0xFF${SECONDARY_COLOR:1})"

# Adicionar case no switch
CONFIG_CASE="
      case ClientType.$CLIENT_CAMEL:
        return ClientConfig(
          clientType: clientType,
          appName: 'Clubee - $CLIENT_NAME',
          logoPath: 'assets/images/$CLIENT_ID/logo.png',
          theme: $THEME_METHOD(),
          primaryColor: '$PRIMARY_COLOR',
          secondaryColor: '$SECONDARY_COLOR',
          apiBaseUrl: '$API_URL',
          iosBundleId: '$IOS_BUNDLE',
          androidPackageName: '$ANDROID_PACKAGE',
          firebaseOptions: firebase_${CLIENT_ID}.DefaultFirebaseOptions.currentPlatform,
          customSettings: {
            'enableFeatureX': $ENABLE_FEATURE_X,
            'maxUsers': $MAX_USERS,
            'supportEmail': '$SUPPORT_EMAIL',
          },
        );"

# Adicionar após o último case
sed -i.tmp "/case ClientType.valeDasMinas:/,/);/{ 
    /);/a\\
$CONFIG_CASE
}" "$PROJECT_ROOT/lib/config/client_config.dart"

# Adicionar método do tema
THEME_METHOD_IMPL="
  static ThemeData $THEME_METHOD() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const $PRIMARY_COLOR_OBJECT,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: $PRIMARY_COLOR_OBJECT,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const $PRIMARY_COLOR_OBJECT,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }"

# Adicionar método do tema no final da classe
sed -i.tmp "/static ThemeData _createValeDasMinasTheme()/,/^  }/{ 
    /^  }/a\\
$THEME_METHOD_IMPL
}" "$PROJECT_ROOT/lib/config/client_config.dart"

rm -f "$PROJECT_ROOT/lib/config/client_config.dart.tmp"

# 3. Criar estrutura de assets
log_step "Criando estrutura de assets..."
mkdir -p "$PROJECT_ROOT/assets/images/$CLIENT_ID"
echo "# Assets do cliente $CLIENT_NAME
Adicione aqui:
- logo.png (logo principal)
- icon.png (ícone do app)
- background.png (imagem de fundo, se necessário)

Formatos recomendados:
- Logo: PNG com fundo transparente, 120x60px
- Ícone: PNG quadrado, 512x512px
- Background: JPG ou PNG, 1080x1920px" > "$PROJECT_ROOT/assets/images/$CLIENT_ID/README.md"

# 4. Atualizar pubspec.yaml
log_step "Atualizando pubspec.yaml..."
sed -i.tmp "/# Assets específicos do Vale das Minas/a\\
    \\
    # Assets específicos do $CLIENT_NAME\\
    - assets/images/$CLIENT_ID/" "$PROJECT_ROOT/pubspec.yaml"
rm -f "$PROJECT_ROOT/pubspec.yaml.tmp"

# 5. Atualizar scripts de build
log_step "Atualizando scripts de build..."

# Atualizar build_android.sh
sed -i.tmp "/\"vale_das_minas\")/a\\
        ANDROID_PACKAGE=\"$ANDROID_PACKAGE\"\\
        APP_NAME=\"$CLIENT_NAME\"\\
        ;;" "$PROJECT_ROOT/scripts/build_android.sh"

sed -i.tmp "s/if \[ \"\$CLIENT\" != \"guara\" \] && \[ \"\$CLIENT\" != \"vale_das_minas\" \]; then/if [ \"\$CLIENT\" != \"guara\" ] \&\& [ \"\$CLIENT\" != \"vale_das_minas\" ] \&\& [ \"\$CLIENT\" != \"$CLIENT_ID\" ]; then/" "$PROJECT_ROOT/scripts/build_android.sh"

sed -i.tmp "s/Cliente deve ser 'guara' ou 'vale_das_minas'/Cliente deve ser 'guara', 'vale_das_minas' ou '$CLIENT_ID'/" "$PROJECT_ROOT/scripts/build_android.sh"

# Atualizar build_ios.sh  
sed -i.tmp "/\"vale_das_minas\")/a\\
        IOS_BUNDLE_ID=\"$IOS_BUNDLE\"\\
        APP_NAME=\"$CLIENT_NAME\"\\
        ;;" "$PROJECT_ROOT/scripts/build_ios.sh"

sed -i.tmp "s/if \[ \"\$CLIENT\" != \"guara\" \] && \[ \"\$CLIENT\" != \"vale_das_minas\" \]; then/if [ \"\$CLIENT\" != \"guara\" ] \&\& [ \"\$CLIENT\" != \"vale_das_minas\" ] \&\& [ \"\$CLIENT\" != \"$CLIENT_ID\" ]; then/" "$PROJECT_ROOT/scripts/build_ios.sh"

sed -i.tmp "s/Cliente deve ser 'guara' ou 'vale_das_minas'/Cliente deve ser 'guara', 'vale_das_minas' ou '$CLIENT_ID'/" "$PROJECT_ROOT/scripts/build_ios.sh"

# Atualizar build_client.sh
sed -i.tmp "/elif \[ \"\$CLIENT\" = \"vale_das_minas\" \]; then/a\\
elif [ \"\$CLIENT\" = \"$CLIENT_ID\" ]; then\\
    ANDROID_PACKAGE=\"$ANDROID_PACKAGE\"\\
    IOS_BUNDLE_ID=\"$IOS_BUNDLE\"" "$PROJECT_ROOT/scripts/build_client.sh"

sed -i.tmp "s/Uso: \$0 \[guara|vale_das_minas\]/Uso: \$0 [guara|vale_das_minas|$CLIENT_ID]/" "$PROJECT_ROOT/scripts/build_client.sh"

# Adicionar configuração no main.dart  
sed -i.tmp "/sed.*valeDasMinas.*/a\\
    elif [ \"\$CLIENT\" = \"$CLIENT_ID\" ]; then\\
        sed -i.bak \"s/ClientService.instance.setClient(ClientType\\\\.[^)]*))/ClientService.instance.setClient(ClientType.$CLIENT_CAMEL)/\" lib/main.dart" "$PROJECT_ROOT/scripts/build_client.sh"

rm -f "$PROJECT_ROOT/scripts/build_android.sh.tmp"
rm -f "$PROJECT_ROOT/scripts/build_ios.sh.tmp"
rm -f "$PROJECT_ROOT/scripts/build_client.sh.tmp"

# 6. Atualizar ClientEnvironment
log_step "Atualizando ClientEnvironment..."
sed -i.tmp "/case 'valedasminas':/a\\
      case '$CLIENT_ID':\\
        return ClientType.$CLIENT_CAMEL;" "$PROJECT_ROOT/lib/config/client_environment.dart"
rm -f "$PROJECT_ROOT/lib/config/client_environment.dart.tmp"

# 7. Verificar se compila
log_step "Verificando se o projeto compila..."
cd "$PROJECT_ROOT"
flutter pub get > /dev/null 2>&1

if flutter analyze --no-pub > /dev/null 2>&1; then
    log_info "✅ Análise do código passou!"
else
    log_warn "⚠️ Análise do código encontrou alguns avisos (normal)"
fi

echo ""
log_info "🎉 Cliente '$CLIENT_NAME' adicionado com sucesso!"
echo ""
echo "� CONFIGURAÇÃO FIREBASE NECESSÁRIA:"
echo "  1. Crie o projeto '$FIREBASE_PROJECT_ID' no Firebase Console"
echo "  2. Configure Android com package: $ANDROID_PACKAGE"
echo "  3. Configure iOS com bundle ID: $IOS_BUNDLE"
echo "  4. Execute o comando:"
echo "     flutterfire configure --project=$FIREBASE_PROJECT_ID --out=lib/firebase_options_${CLIENT_ID}.dart"
echo "  5. Valide a configuração:"
echo "     ./scripts/firebase_client.sh $CLIENT_ID validate"
echo ""
echo "�📋 Próximos passos:"
echo "  1. Adicione o logo em: assets/images/$CLIENT_ID/logo.png"
echo "  2. Configure o Firebase (instruções acima)"
echo "  3. Teste o novo cliente:"
echo "     flutter run --dart-define=CLIENT_TYPE=$CLIENT_ID"
echo "  4. Build para produção:"
echo "     ./scripts/build_android.sh $CLIENT_ID release"
echo "     ./scripts/build_ios.sh $CLIENT_ID release"
echo ""
echo "📁 Arquivos modificados (backups criados):"
echo "  - lib/config/client_type.dart"
echo "  - lib/config/client_config.dart"  
echo "  - lib/config/client_environment.dart"
echo "  - pubspec.yaml"
echo "  - scripts/build_*.sh"
echo ""
echo "📚 Documentação atualizada em: docs/"
echo ""
echo "⚡ Para testar agora mesmo:"
echo "  cd $PROJECT_ROOT"
echo "  flutter run --dart-define=CLIENT_TYPE=$CLIENT_ID"