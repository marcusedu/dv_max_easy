#!/usr/bin/env bash
# ==============================================================================
# Script de Compilação e Criação de Instalador (.dmg) para macOS
# DV Max - Desktop Media Client & File Organizer
# ==============================================================================
set -euo pipefail

# Diretório raiz do projeto (um nível acima deste script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

# Cores para exibição amigável
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=================================================================${NC}"
echo -e "${BLUE}           DV Max - Build & Packaging para macOS (.dmg)          ${NC}"
echo -e "${BLUE}=================================================================${NC}"

# 1. Extrair versão do pubspec.yaml
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}Erro: pubspec.yaml não encontrado na raiz (${ROOT_DIR}).${NC}"
    exit 1
fi

FULL_VERSION=$(grep -E '^version:' pubspec.yaml | head -n 1 | awk '{print $2}' | tr -d '\r')
SEMVER="${FULL_VERSION%%+*}"
BUILD_NUM="${FULL_VERSION##*+}"
[ -z "$BUILD_NUM" ] && BUILD_NUM="1"

echo -e "Versão detectada: ${GREEN}${SEMVER}${NC} (Build: ${YELLOW}${BUILD_NUM}${NC})"

# Flags opcionais
SKIP_BUILD=false
for arg in "$@"; do
    case $arg in
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --help|-h)
            echo "Uso: ./scripts/build_macos.sh [opções]"
            echo "Opções:"
            echo "  --skip-build    Pula a etapa 'flutter build macos --release' e usa o binário existente."
            echo "  --help, -h      Exibe esta mensagem de ajuda."
            exit 0
            ;;
    esac
done

# 2. Compilar aplicação com Flutter
APP_SRC_PATH="${ROOT_DIR}/build/macos/Build/Products/Release/dv_max_easy.app"

if [ "$SKIP_BUILD" = false ]; then
    echo -e "\n${BLUE}➔ [1/4] Compilando aplicação Flutter em modo Release (macOS)...${NC}"
    flutter build macos --release
else
    echo -e "\n${YELLOW}➔ [1/4] Pulando compilação (--skip-build solicitado).${NC}"
fi

if [ ! -d "${APP_SRC_PATH}" ]; then
    echo -e "${RED}Erro: Arquivo .app não encontrado em: ${APP_SRC_PATH}${NC}"
    echo "Certifique-se de que a compilação foi concluída com sucesso."
    exit 1
fi

# 3. Preparar diretório de distribuição e staging
DIST_DIR="${ROOT_DIR}/dist"
STAGE_DIR=$(mktemp -d /tmp/dv_max_dmg_stage.XXXXXX)
DMG_NAME="DV_Max_${SEMVER}_macOS.dmg"
DMG_PATH="${DIST_DIR}/${DMG_NAME}"

mkdir -p "${DIST_DIR}"

trap 'rm -rf "${STAGE_DIR}"' EXIT

echo -e "\n${BLUE}➔ [2/4] Preparando volume para geração da imagem de disco...${NC}"
APP_DEST_NAME="DV Max.app"
cp -R "${APP_SRC_PATH}" "${STAGE_DIR}/${APP_DEST_NAME}"

# Criar link simbólico para a pasta de Aplicativos (/Applications)
ln -s "/Applications" "${STAGE_DIR}/Applications"

# Se houver certificado de assinatura de código, pode ser assinado aqui;
# Caso contrário, aplica ad-hoc signing para garantir permissões locais do macOS:
echo -e "${YELLOW}   Aplicando assinatura ad-hoc para validação local do Gatekeeper...${NC}"
codesign --force --deep -s - "${STAGE_DIR}/${APP_DEST_NAME}" 2>/dev/null || true

# 4. Criar arquivo .dmg
echo -e "\n${BLUE}➔ [3/4] Empacotando instalador .dmg...${NC}"
rm -f "${DMG_PATH}"

if command -v create-dmg >/dev/null 2>&1; then
    echo -e "${GREEN}   Usando create-dmg para layout gráfico do instalador...${NC}"
    create-dmg \
        --volname "DV Max" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 110 \
        --icon "${APP_DEST_NAME}" 160 190 \
        --app-drop-link 440 190 \
        --hide-extension "${APP_DEST_NAME}" \
        --no-internet-enable \
        "${DMG_PATH}" \
        "${STAGE_DIR}" || {
            echo -e "${YELLOW}   Aviso: create-dmg falhou, caindo de volta para o utilitário nativo hdiutil...${NC}"
            hdiutil create \
                -volname "DV Max" \
                -srcfolder "${STAGE_DIR}" \
                -ov \
                -format UDZO \
                "${DMG_PATH}"
        }
else
    echo -e "   Usando utilitário nativo macOS (hdiutil)..."
    hdiutil create \
        -volname "DV Max" \
        -srcfolder "${STAGE_DIR}" \
        -ov \
        -format UDZO \
        "${DMG_PATH}"
fi

# 5. Gerar hash de integridade (SHA-256)
echo -e "\n${BLUE}➔ [4/4] Gerando checksum SHA-256...${NC}"
cd "${DIST_DIR}"
shasum -a 256 "${DMG_NAME}" > "${DMG_NAME}.sha256"
SHA_VAL=$(awk '{print $1}' "${DMG_NAME}.sha256")
FILE_SIZE=$(ls -lh "${DMG_NAME}" | awk '{print $5}')

echo -e "\n${GREEN}=================================================================${NC}"
echo -e "${GREEN}          Instalador macOS (.dmg) gerado com sucesso!            ${NC}"
echo -e "${GREEN}=================================================================${NC}"
echo -e "📁 Arquivo:    ${BLUE}${DMG_PATH}${NC}"
echo -e "⚖️ Tamanho:    ${YELLOW}${FILE_SIZE}${NC}"
echo -e "🔒 SHA-256:    ${NC}${SHA_VAL}"
echo -e "📋 Checksum:   ${DIST_DIR}/${DMG_NAME}.sha256"
echo -e "\nPara instalar localmente, dê um duplo clique no arquivo .dmg gerado e arraste o DV Max para a pasta Aplicativos."
