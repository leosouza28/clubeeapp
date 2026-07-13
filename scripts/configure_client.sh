#!/bin/bash

# Script para configurar o package name baseado no cliente
# Uso: ./scripts/configure_client.sh [guara|vale_das_minas]

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Verificar se foi passado um cliente
if [ $# -eq 0 ]; then
    log_error "Uso: $0 [guara|vale_das_minas]"
    echo "Clientes disponíveis:"
    echo "  guara         - Configura para o cliente Guará"
    echo "  vale_das_minas - Configura para o cliente Vale das Minas"
    exit 1
fi

CLIENT=$1
PROJECT_ROOT=$(dirname "$0")/..

# Definir configurações por cliente
case $CLIENT in
    "guara")
        ANDROID_PACKAGE="com.guaraapp"
        IOS_BUNDLE_ID="com.lsdevelopers.guaraapp"
        APP_NAME="Guará"
        APP_DISPLAY_NAME="Guará"
        APP_BUNDLE_NAME="guara"
        DEEP_LINK_SCHEME="guaraapp"
        DEEP_LINK_URL_NAME="com.lsdevelopers.guaraapp.deeplink"
        ;;
    "vale_das_minas")
        ANDROID_PACKAGE="com.valedasminas"
        IOS_BUNDLE_ID="com.lsdevelopers.valedasminas"
        APP_NAME="Vale das Minas"
        APP_DISPLAY_NAME="Vale das Minas"
        APP_BUNDLE_NAME="vale_das_minas"
        DEEP_LINK_SCHEME="valedasminasapp"
        DEEP_LINK_URL_NAME="com.lsdevelopers.valedasminas.deeplink"
        ;;
    *)
        log_error "Cliente '$CLIENT' não reconhecido"
        log_error "Clientes disponíveis: guara, vale_das_minas"
        exit 1
        ;;
esac

log_info "Configurando projeto para o cliente: $APP_NAME"
log_info "Android Package: $ANDROID_PACKAGE"
log_info "iOS Bundle ID: $IOS_BUNDLE_ID"

# Função para fazer backup de um arquivo
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        cp "$file" "$file.backup"
        log_info "Backup criado: $file.backup"
    fi
}

# Função para restaurar backups
restore_backups() {
    log_info "Restaurando backups..."
    find "$PROJECT_ROOT" -name "*.backup" | while read backup_file; do
        original_file="${backup_file%.backup}"
        mv "$backup_file" "$original_file"
        log_info "Restaurado: $original_file"
    done
    
    # Restaurar placeholders no Info.plist se não houver backup
    local info_plist="$PROJECT_ROOT/ios/Runner/Info.plist"
    if [ -f "$info_plist" ] && [ ! -f "$info_plist.backup" ]; then
        log_info "Restaurando placeholders no Info.plist..."
        sed -i.tmp 's/<string>Guará<\/string>/<string>{{APP_DISPLAY_NAME}}<\/string>/g' "$info_plist"
        sed -i.tmp 's/<string>Guará Acqua Park<\/string>/<string>{{APP_DISPLAY_NAME}}<\/string>/g' "$info_plist"
        sed -i.tmp 's/<string>Vale das Minas<\/string>/<string>{{APP_DISPLAY_NAME}}<\/string>/g' "$info_plist"
        sed -i.tmp 's/<string>guara<\/string>/<string>{{APP_BUNDLE_NAME}}<\/string>/g' "$info_plist"
        sed -i.tmp 's/<string>guara_acqua_park<\/string>/<string>{{APP_BUNDLE_NAME}}<\/string>/g' "$info_plist"
        sed -i.tmp 's/<string>vale_das_minas<\/string>/<string>{{APP_BUNDLE_NAME}}<\/string>/g' "$info_plist"
        sed -i.tmp 's/<string>guaraapp<\/string>/<string>{{DEEP_LINK_SCHEME}}<\/string>/g' "$info_plist"
        sed -i.tmp 's/<string>valedasminasapp<\/string>/<string>{{DEEP_LINK_SCHEME}}<\/string>/g' "$info_plist"
        sed -i.tmp 's/<string>com\.lsdevelopers\.[^<]*\.deeplink<\/string>/<string>{{DEEP_LINK_URL_NAME}}<\/string>/g' "$info_plist"
        rm -f "$info_plist.tmp"
        log_info "Placeholders restaurados no Info.plist"
    fi
}

# Configurar MainActivity.kt com package correto
configure_main_activity() {
    log_info "Configurando MainActivity.kt..."
    
    local kotlin_base="$PROJECT_ROOT/android/app/src/main/kotlin"
    
    # Converter package para path (ex: com.valedasminas -> com/valedasminas)
    local package_path=$(echo "$ANDROID_PACKAGE" | tr '.' '/')
    local main_activity_dir="$kotlin_base/$package_path"
    local main_activity_file="$main_activity_dir/MainActivity.kt"
    
    # Remover TODOS os MainActivity.kt existentes para evitar conflitos
    log_info "Removendo MainActivity.kt de outros clientes..."
    find "$kotlin_base" -name "MainActivity.kt" -type f -delete
    
    # Remover diretórios vazios de packages antigos
    find "$kotlin_base" -type d -empty -delete 2>/dev/null || true
    
    # Criar diretório do package se não existir
    mkdir -p "$main_activity_dir"
    
    # Criar MainActivity.kt com package correto
    cat > "$main_activity_file" << EOF
package $ANDROID_PACKAGE

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app.clubee/deeplink"
    private var initialLink: String? = null
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent, notifyFlutter = false)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Necessário para app_links / plugins lerem o Intent atualizado (singleTop)
        setIntent(intent)
        handleIntent(intent, notifyFlutter = true)
    }

    private fun handleIntent(intent: Intent?, notifyFlutter: Boolean) {
        val uri = intent?.data ?: return
        val link = uri.toString()
        initialLink = link

        if (notifyFlutter) {
            methodChannel?.invokeMethod("routeUpdated", link)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialLink" -> result.success(initialLink)
                    else -> result.notImplemented()
                }
            }

            // Se o Intent chegou no onCreate, envia assim que o engine estiver pronto
            initialLink?.let { link ->
                channel.invokeMethod("routeUpdated", link)
            }
        }
    }
}

EOF
    
    log_info "✅ MainActivity.kt criado: $main_activity_file"
}

# Configurar Android
configure_android() {
    log_info "Configurando Android..."
    
    local build_gradle="$PROJECT_ROOT/android/app/build.gradle.kts"
    local manifest="$PROJECT_ROOT/android/app/src/main/AndroidManifest.xml"
    
    # Backup
    backup_file "$build_gradle"
    backup_file "$manifest"
    
    # Atualizar build.gradle.kts
    sed -i.tmp "s/namespace = \".*\"/namespace = \"$ANDROID_PACKAGE\"/" "$build_gradle"
    sed -i.tmp "s/applicationId = \".*\"/applicationId = \"$ANDROID_PACKAGE\"/" "$build_gradle"
    rm -f "$build_gradle.tmp"
    
    # Atualizar AndroidManifest.xml
    if [ -f "$manifest" ]; then
        # Atualizar o nome do app
        sed -i.tmp "s/android:label=\"[^\"]*\"/android:label=\"$APP_DISPLAY_NAME\"/" "$manifest"
        
        # Atualizar deep link scheme
        sed -i.tmp "s/android:scheme=\"guaraapp\"/android:scheme=\"$DEEP_LINK_SCHEME\"/" "$manifest"
        sed -i.tmp "s/android:scheme=\"valedasminasapp\"/android:scheme=\"$DEEP_LINK_SCHEME\"/" "$manifest"
        
        rm -f "$manifest.tmp"
        log_info "AndroidManifest.xml atualizado"
    fi
    
    # Verificar e criar MainActivity.kt com package correto
    configure_main_activity
    
    # Configurar google-services.json
    configure_firebase_android
    
    log_info "Android configurado com package: $ANDROID_PACKAGE"
}

# Configurar arquivos Firebase para Android
configure_firebase_android() {
    log_info "Configurando Firebase para Android..."
    
    local firebase_source=""
    local firebase_dest="$PROJECT_ROOT/android/app/google-services.json"
    
    case $CLIENT in
        "guara")
            firebase_source="$PROJECT_ROOT/android/app/google-services-guara.json"
            ;;
        "vale_das_minas")
            firebase_source="$PROJECT_ROOT/android/app/google-services-valedasminas.json"
            ;;
    esac
    
    if [ ! -f "$firebase_source" ]; then
        log_error "Arquivo Firebase não encontrado: $firebase_source"
        log_error "Certifique-se de que o arquivo existe antes de continuar"
        exit 1
    fi
    
    # Fazer backup do google-services.json atual se existir
    if [ -f "$firebase_dest" ]; then
        backup_file "$firebase_dest"
    fi
    
    # Copiar arquivo Firebase do cliente
    cp "$firebase_source" "$firebase_dest"
    log_info "✅ Firebase Android configurado: $(basename $firebase_source) → google-services.json"
    
    # Verificar se o package name no google-services.json está correto
    local package_in_file=$(grep -o '"package_name": "[^"]*"' "$firebase_dest" | head -1 | cut -d'"' -f4)
    if [ "$package_in_file" != "$ANDROID_PACKAGE" ]; then
        log_warn "⚠️  Package name no google-services.json ($package_in_file) difere do esperado ($ANDROID_PACKAGE)"
        log_warn "Verifique se o arquivo Firebase está correto para este cliente"
    else
        log_info "✅ Package name verificado: $package_in_file"
    fi
}

# Configurar iOS
configure_ios() {
    log_info "Configurando iOS..."
    
    local info_plist="$PROJECT_ROOT/ios/Runner/Info.plist"
    local project_pbxproj="$PROJECT_ROOT/ios/Runner.xcodeproj/project.pbxproj"
    
    # Backup
    backup_file "$info_plist"
    backup_file "$project_pbxproj"
    
    # Restaurar placeholders primeiro (se não existir backup)
    if [ -f "$info_plist" ]; then
        # Restaurar todos os possíveis valores para placeholders
        sed -i.tmp 's/<string>Guará<\/string>/<string>{{APP_DISPLAY_NAME}}<\/string>/g' "$info_plist"
        sed -i.tmp 's/<string>Guará Acqua Park<\/string>/<string>{{APP_DISPLAY_NAME}}<\/string>/g' "$info_plist"
        sed -i.tmp 's/<string>Vale das Minas<\/string>/<string>{{APP_DISPLAY_NAME}}<\/string>/g' "$info_plist"
        sed -i.tmp 's/<string>guara<\/string>/<string>{{APP_BUNDLE_NAME}}<\/string>/g' "$info_plist"
        sed -i.tmp 's/<string>guara_acqua_park<\/string>/<string>{{APP_BUNDLE_NAME}}<\/string>/g' "$info_plist"
        sed -i.tmp 's/<string>vale_das_minas<\/string>/<string>{{APP_BUNDLE_NAME}}<\/string>/g' "$info_plist"
        sed -i.tmp 's/<string>guaraapp<\/string>/<string>{{DEEP_LINK_SCHEME}}<\/string>/g' "$info_plist"
        sed -i.tmp 's/<string>valedasminasapp<\/string>/<string>{{DEEP_LINK_SCHEME}}<\/string>/g' "$info_plist"
        sed -i.tmp 's/<string>com\.lsdevelopers\.guaraapp\.deeplink<\/string>/<string>{{DEEP_LINK_URL_NAME}}<\/string>/g' "$info_plist"
        sed -i.tmp 's/<string>com\.lsdevelopers\.valedasminas\.deeplink<\/string>/<string>{{DEEP_LINK_URL_NAME}}<\/string>/g' "$info_plist"
        sed -i.tmp 's/<string>com\.lsdevelopers\.guaraapp\.deeplink\.https<\/string>/<string>{{DEEP_LINK_URL_NAME}}\.https<\/string>/g' "$info_plist"
        sed -i.tmp 's/<string>com\.lsdevelopers\.valedasminas\.deeplink\.https<\/string>/<string>{{DEEP_LINK_URL_NAME}}\.https<\/string>/g' "$info_plist"
        
        # Agora substituir placeholders pelos valores do cliente
        sed -i.tmp "s/{{APP_DISPLAY_NAME}}/$APP_DISPLAY_NAME/g" "$info_plist"
        sed -i.tmp "s/{{APP_BUNDLE_NAME}}/$APP_BUNDLE_NAME/g" "$info_plist"
        sed -i.tmp "s/{{DEEP_LINK_SCHEME}}/$DEEP_LINK_SCHEME/g" "$info_plist"
        sed -i.tmp "s/{{DEEP_LINK_URL_NAME}}/$DEEP_LINK_URL_NAME/g" "$info_plist"
        rm -f "$info_plist.tmp"
        log_info "Info.plist atualizado com configurações do cliente"
    fi
    
    # Atualizar project.pbxproj
    if [ -f "$project_pbxproj" ]; then
        sed -i.tmp "s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*/PRODUCT_BUNDLE_IDENTIFIER = $IOS_BUNDLE_ID/g" "$project_pbxproj"
        
        # Adicionar CODE_SIGN_ENTITLEMENTS se não existir
        if ! grep -q "CODE_SIGN_ENTITLEMENTS" "$project_pbxproj"; then
            log_info "Adicionando CODE_SIGN_ENTITLEMENTS ao project.pbxproj..."
            
            # Adicionar entitlements em todas as configurações (Debug, Release, Profile)
            sed -i.tmp '/PRODUCT_BUNDLE_IDENTIFIER = /a\
				CODE_SIGN_ENTITLEMENTS = Runner/runner.entitlements;
' "$project_pbxproj"
            log_info "✅ CODE_SIGN_ENTITLEMENTS adicionado"
        else
            log_info "CODE_SIGN_ENTITLEMENTS já existe no projeto"
        fi
        
        rm -f "$project_pbxproj.tmp"
    fi
    
    # Garantir que o arquivo runner.entitlements existe
    local entitlements_file="$PROJECT_ROOT/ios/Runner/runner.entitlements"
    if [ ! -f "$entitlements_file" ]; then
        log_info "Criando runner.entitlements..."
        cat > "$entitlements_file" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>aps-environment</key>
	<string>development</string>
</dict>
</plist>
EOF
        log_info "✅ runner.entitlements criado"
    else
        log_info "runner.entitlements já existe"
    fi
    
    # Configurar Firebase para iOS
    configure_firebase_ios
    
    log_info "iOS configurado com bundle ID: $IOS_BUNDLE_ID"
    log_info "Display Name: $APP_DISPLAY_NAME"
    log_info "Deep Link Scheme: $DEEP_LINK_SCHEME"
    log_info "ℹ️  Permissões (Bluetooth, Location, Camera, Microphone, Background) já estão configuradas no Info.plist"
    log_info "ℹ️  Entitlements configurado para Push Notifications"
}

# Configurar arquivos Firebase para iOS
configure_firebase_ios() {
    log_info "Configurando Firebase para iOS..."
    
    local firebase_source=""
    local firebase_dest="$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist"
    
    case $CLIENT in
        "guara")
            firebase_source="$PROJECT_ROOT/ios/Runner/GoogleService-Guara-Info.plist"
            ;;
        "vale_das_minas")
            firebase_source="$PROJECT_ROOT/ios/Runner/GoogleService-ValeDasMinas-Info.plist"
            ;;
    esac
    
    if [ ! -f "$firebase_source" ]; then
        log_error "Arquivo Firebase não encontrado: $firebase_source"
        log_error "Certifique-se de que o arquivo existe antes de continuar"
        exit 1
    fi
    
    # Fazer backup do GoogleService-Info.plist atual se existir
    if [ -f "$firebase_dest" ]; then
        backup_file "$firebase_dest"
    fi
    
    # Copiar arquivo Firebase do cliente
    cp "$firebase_source" "$firebase_dest"
    log_info "✅ Firebase iOS configurado: $(basename $firebase_source) → GoogleService-Info.plist"
    
    # Verificar se o bundle ID no GoogleService-Info.plist está correto
    local bundle_in_file=$(grep -A 1 "BUNDLE_ID" "$firebase_dest" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    if [ -n "$bundle_in_file" ] && [ "$bundle_in_file" != "$IOS_BUNDLE_ID" ]; then
        log_warn "⚠️  Bundle ID no GoogleService-Info.plist ($bundle_in_file) difere do esperado ($IOS_BUNDLE_ID)"
        log_warn "Verifique se o arquivo Firebase está correto para este cliente"
    elif [ -n "$bundle_in_file" ]; then
        log_info "✅ Bundle ID verificado: $bundle_in_file"
    fi
}

# Atualizar cliente no main.dart
configure_main_dart() {
    log_info "Configurando cliente padrão no main.dart..."
    
    local main_dart="$PROJECT_ROOT/lib/main.dart"
    backup_file "$main_dart"
    
    case $CLIENT in
        "guara")
            sed -i.tmp "s/ClientService.instance.setClient(ClientType\.[^)]*)/ClientService.instance.setClient(ClientType.guara)/" "$main_dart"
            ;;
        "vale_das_minas")
            sed -i.tmp "s/ClientService.instance.setClient(ClientType\.[^)]*)/ClientService.instance.setClient(ClientType.valeDasMinas)/" "$main_dart"
            ;;
    esac
    rm -f "$main_dart.tmp"
    
    log_info "Cliente padrão configurado no main.dart"
}

# Executar configurações
case "$2" in
    "--restore")
        restore_backups
        log_info "Todos os backups foram restaurados"
        exit 0
        ;;
    *)
        configure_android
        configure_ios
        configure_main_dart
        
        echo ""
        log_info "✅ Configuração concluída para o cliente: $APP_NAME"
        echo ""
        echo "📋 Resumo das alterações:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📱 Android:"
        echo "   • Package: $ANDROID_PACKAGE"
        echo "   • Display Name: $APP_DISPLAY_NAME"
        echo "   • Deep Link Scheme: $DEEP_LINK_SCHEME"
        echo "   • Firebase: google-services.json (copiado do cliente)"
        echo ""
        echo "🍎 iOS:"
        echo "   • Bundle ID: $IOS_BUNDLE_ID"
        echo "   • Display Name: $APP_DISPLAY_NAME"
        echo "   • Deep Link Scheme: $DEEP_LINK_SCHEME"
        echo "   • Deep Link URL Name: $DEEP_LINK_URL_NAME"
        echo "   • Firebase: GoogleService-Info.plist (copiado do cliente)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        log_info "📝 Arquivos modificados:"
        echo "   • android/app/build.gradle.kts"
        echo "   • android/app/src/main/AndroidManifest.xml"
        echo "   • android/app/src/main/kotlin/.../MainActivity.kt (package atualizado)"
        echo "   • android/app/google-services.json (substituído)"
        echo "   • ios/Runner.xcodeproj/project.pbxproj"
        echo "   • ios/Runner/Info.plist"
        echo "   • ios/Runner/GoogleService-Info.plist (substituído)"
        echo "   • lib/main.dart"
        echo ""
        log_info "🔄 Para restaurar as configurações originais:"
        echo "   $0 $CLIENT --restore"
        echo ""
        log_info "🚀 Próximos passos:"
        echo "   1. Execute 'flutter clean' para limpar o cache"
        echo "   2. Execute 'flutter pub get' para atualizar dependências"
        echo "   3. Compile o app normalmente:"
        echo "      • Android: flutter build apk ou flutter build appbundle"
        echo "      • iOS: flutter build ios"
        echo ""
        ;;
esac