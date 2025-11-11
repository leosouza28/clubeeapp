#!/bin/bash

# Script para remover um cliente do projeto
# Uso: ./scripts/remove_client.sh [client_id]

CLIENT_ID="$1"

if [ -z "$CLIENT_ID" ]; then
    echo "❌ Uso: $0 [client_id]"
    echo "📋 Clientes disponíveis:"
    grep -E "case '[^']*':" lib/config/client_environment.dart | sed "s/.*case '\([^']*\)'.*/  - \1/"
    exit 1
fi

echo "⚠️  ATENÇÃO: Isso irá remover PERMANENTEMENTE o cliente '$CLIENT_ID'"
read -p "🗑️  Confirma a remoção? (digite 'REMOVER' para confirmar): " CONFIRM

if [ "$CONFIRM" != "REMOVER" ]; then
    echo "❌ Operação cancelada"
    exit 0
fi

PROJECT_ROOT=$(dirname "$0")/..

echo "🗑️  Removendo cliente '$CLIENT_ID'..."

# Restaurar backups se existirem
if [ -f "$PROJECT_ROOT/lib/config/client_type.dart.backup" ]; then
    echo "♻️  Restaurando backup do client_type.dart..."
    cp "$PROJECT_ROOT/lib/config/client_type.dart.backup" "$PROJECT_ROOT/lib/config/client_type.dart"
fi

if [ -f "$PROJECT_ROOT/lib/config/client_config.dart.backup" ]; then
    echo "♻️  Restaurando backup do client_config.dart..."
    cp "$PROJECT_ROOT/lib/config/client_config.dart.backup" "$PROJECT_ROOT/lib/config/client_config.dart"
fi

# Remover pasta de assets
if [ -d "$PROJECT_ROOT/assets/images/$CLIENT_ID" ]; then
    echo "📁 Removendo assets..."
    rm -rf "$PROJECT_ROOT/assets/images/$CLIENT_ID"
fi

# Limpar pubspec.yaml
sed -i.tmp "/# Assets específicos.*$CLIENT_ID/,+1d" "$PROJECT_ROOT/pubspec.yaml"
rm -f "$PROJECT_ROOT/pubspec.yaml.tmp"

echo "✅ Cliente '$CLIENT_ID' removido!"
echo "🧹 Execute 'flutter clean && flutter pub get' para limpar o cache"