#!/bin/bash

# Script para limpar arquivos de backup criados pelo configure_client.sh
# Uso: ./scripts/clean_backups.sh

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

PROJECT_ROOT=$(dirname "$0")/..

log_info "Procurando arquivos de backup (.backup)..."

# Contar arquivos de backup
backup_count=$(find "$PROJECT_ROOT" -name "*.backup" | wc -l | tr -d ' ')

if [ "$backup_count" -eq 0 ]; then
    log_info "Nenhum arquivo de backup encontrado."
    exit 0
fi

log_warn "Encontrados $backup_count arquivo(s) de backup:"
find "$PROJECT_ROOT" -name "*.backup" -exec echo "  • {}" \;

echo ""
read -p "Deseja remover todos os backups? (s/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Ss]$ ]]; then
    log_info "Removendo arquivos de backup..."
    find "$PROJECT_ROOT" -name "*.backup" -delete
    log_info "✅ Todos os backups foram removidos!"
else
    log_info "Operação cancelada."
fi
