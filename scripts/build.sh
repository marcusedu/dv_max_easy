#!/usr/bin/env bash
# ==============================================================================
# Script Unificado de Build e Empacotamento Multiplataforma
# DV Max - Desktop Media Client & File Organizer
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TARGET_PLATFORM="auto"
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --platform|-p)
            TARGET_PLATFORM="$2"
            shift 2
            ;;
        --help|-h)
            echo "Uso: ./scripts/build.sh [opções]"
            echo ""
            echo "Opções:"
            echo "  -p, --platform <macos|windows|linux|auto>  Força a plataforma de destino (padrão: auto)."
            echo "  --skip-build                               Pula a etapa de compilação 'flutter build'."
            echo "  -h, --help                                 Exibe esta mensagem."
            exit 0
            ;;
        *)
            EXTRA_ARGS+=("$1")
            shift
            ;;
    esac
done

# Detectar plataforma se for auto
if [ "$TARGET_PLATFORM" = "auto" ]; then
    OS="$(uname -s)"
    case "$OS" in
        Darwin*)
            TARGET_PLATFORM="macos"
            ;;
        Linux*)
            TARGET_PLATFORM="linux"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            TARGET_PLATFORM="windows"
            ;;
        *)
            echo -e "${RED}Sistema operacional não reconhecido automaticamente: ${OS}${NC}"
            echo "Especifique a plataforma com --platform macos|windows|linux"
            exit 1
            ;;
    esac
fi

echo -e "${BLUE}➔ Plataforma selecionada: ${GREEN}${TARGET_PLATFORM}${NC}"

case "$TARGET_PLATFORM" in
    macos)
        "${SCRIPT_DIR}/build_macos.sh" "${EXTRA_ARGS[@]:-}"
        ;;
    linux)
        "${SCRIPT_DIR}/build_linux.sh" "${EXTRA_ARGS[@]:-}"
        ;;
    windows)
        if command -v powershell.exe >/dev/null 2>&1; then
            powershell.exe -ExecutionPolicy Bypass -File "${SCRIPT_DIR}/build_windows.ps1" "${EXTRA_ARGS[@]:-}"
        elif command -v pwsh >/dev/null 2>&1; then
            pwsh -File "${SCRIPT_DIR}/build_windows.ps1" "${EXTRA_ARGS[@]:-}"
        else
            echo -e "${YELLOW}Ambiente Windows/PowerShell não detectado localmente.${NC}"
            echo "Para compilar o pacote Windows (.msi), execute no PowerShell no Windows:"
            echo "  .\\scripts\\build_windows.ps1"
            exit 1
        fi
        ;;
    *)
        echo -e "${RED}Plataforma inválida: ${TARGET_PLATFORM}${NC}"
        echo "Opções válidas: macos, windows, linux"
        exit 1
        ;;
esac
