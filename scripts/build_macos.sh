#!/usr/bin/env bash
# ==============================================================================
# Script de Compilação, Assinatura (Code Signing) e Criação de DMG para macOS
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

echo -e "${BLUE}=================================================================${NC}"
echo -e "${BLUE}       DV Max - Build, Code Signing & Packaging macOS (.dmg)     ${NC}"
echo -e "${BLUE}=================================================================${NC}"

if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}Erro: pubspec.yaml não encontrado na raiz (${ROOT_DIR}).${NC}"
    exit 1
fi

FULL_VERSION=$(grep -E '^version:' pubspec.yaml | head -n 1 | awk '{print $2}' | tr -d '\r')
SEMVER="${FULL_VERSION%%+*}"
BUILD_NUM="${FULL_VERSION##*+}"
[ -z "$BUILD_NUM" ] && BUILD_NUM="1"

echo -e "Versão detectada: ${GREEN}${SEMVER}${NC} (Build: ${YELLOW}${BUILD_NUM}${NC})"

# Parâmetros
SKIP_BUILD=false
SIGN_IDENTITY="${APPLE_DEVELOPER_ID:-}"
NOTARIZE_PROFILE="${APPLE_NOTARY_PROFILE:-}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --identity|-i)
            SIGN_IDENTITY="$2"
            shift 2
            ;;
        --notarize-profile|-n)
            NOTARIZE_PROFILE="$2"
            shift 2
            ;;
        --help|-h)
            echo "Uso: ./scripts/build_macos.sh [opções]"
            echo ""
            echo "Opções:"
            echo "  -i, --identity <NOME>       Identidade do certificado para assinar o app e o dmg."
            echo "                              Exemplo: 'Developer ID Application: Seu Nome (TEAM_ID)'"
            echo "                              (Se omitido, detecta automaticamente no Keychain)."
            echo "  -n, --notarize-profile <P>  Nome do perfil de credenciais salvo via 'xcrun notarytool store-credentials'."
            echo "  --skip-build                Pula a etapa 'flutter build macos --release' e usa o binário existente."
            echo "  -h, --help                  Exibe esta mensagem de ajuda."
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# Detecção automática de identidade se não informada
if [ -z "${SIGN_IDENTITY}" ]; then
    # Procura primeiro por Developer ID Application (distribuição pública fora da App Store)
    DEV_ID=$(security find-identity -p codesigning -v 2>/dev/null | grep "Developer ID Application:" | head -n 1 | sed -E 's/.*"(.*)".*/\1/' || true)
    if [ -n "${DEV_ID}" ]; then
        SIGN_IDENTITY="${DEV_ID}"
        echo -e "Certificado detectado no Keychain: ${GREEN}${SIGN_IDENTITY}${NC}"
    else
        # Se não tiver Developer ID, tenta Apple Development (para testes locais)
        DEV_APPLE=$(security find-identity -p codesigning -v 2>/dev/null | grep "Apple Development:" | head -n 1 | sed -E 's/.*"(.*)".*/\1/' || true)
        if [ -n "${DEV_APPLE}" ]; then
            SIGN_IDENTITY="${DEV_APPLE}"
            echo -e "Certificado de desenvolvimento detectado: ${YELLOW}${SIGN_IDENTITY}${NC} (modo desenvolvimento local)"
        else
            SIGN_IDENTITY="-"
            echo -e "${YELLOW}Nenhum certificado da Apple encontrado no Keychain. Usando assinatura ad-hoc (-).${NC}"
        fi
    fi
else
    echo -e "Identidade informada manualmente: ${GREEN}${SIGN_IDENTITY}${NC}"
fi

# ------------------------------------------------------------------------------
# 1. Compilar aplicação com Flutter
# ------------------------------------------------------------------------------
APP_SRC_PATH="${ROOT_DIR}/build/macos/Build/Products/Release/dv_max_easy.app"

if [ "$SKIP_BUILD" = false ]; then
    echo -e "\n${BLUE}➔ [1/5] Compilando aplicação Flutter em modo Release (macOS)...${NC}"
    flutter build macos --release
else
    echo -e "\n${YELLOW}➔ [1/5] Pulando compilação (--skip-build solicitado).${NC}"
fi

if [ ! -d "${APP_SRC_PATH}" ]; then
    echo -e "${RED}Erro: Arquivo .app não encontrado em: ${APP_SRC_PATH}${NC}"
    exit 1
fi

DIST_DIR="${ROOT_DIR}/dist"
STAGE_DIR=$(mktemp -d /tmp/dv_max_dmg_stage.XXXXXX)
DMG_NAME="DV_Max_${SEMVER}_macOS.dmg"
DMG_PATH="${DIST_DIR}/${DMG_NAME}"
APP_DEST_NAME="DV Max.app"
APP_IN_STAGE="${STAGE_DIR}/${APP_DEST_NAME}"
ENTITLEMENTS="${ROOT_DIR}/macos/Runner/Release.entitlements"

mkdir -p "${DIST_DIR}"
trap 'rm -rf "${STAGE_DIR}"' EXIT

# ------------------------------------------------------------------------------
# 2. Copiar e Assinar Bundle (.app) e Bibliotecas Aninhadas
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}➔ [2/5] Preparando e assinando binários com Hardened Runtime...${NC}"
cp -R "${APP_SRC_PATH}" "${APP_IN_STAGE}"

if [ "${SIGN_IDENTITY}" != "-" ]; then
    echo -e "   Assinando frameworks e bibliotecas dinâmicas internas..."
    # 1. Assinar frameworks e bibliotecas dinâmicas em Contents/Frameworks
    if [ -d "${APP_IN_STAGE}/Contents/Frameworks" ]; then
        find "${APP_IN_STAGE}/Contents/Frameworks" \( -name "*.framework" -o -name "*.dylib" \) | while read -r item; do
            codesign --force --sign "${SIGN_IDENTITY}" --timestamp --options runtime "${item}" 2>/dev/null || true
        done
    fi

    # 2. Assinar o bundle principal com Entitlements e Hardened Runtime
    echo -e "   Assinando aplicação principal com Release.entitlements..."
    codesign --force --deep --sign "${SIGN_IDENTITY}" --timestamp --options runtime \
        --entitlements "${ENTITLEMENTS}" "${APP_IN_STAGE}"

    # 3. Validar assinatura
    echo -e "   Verificando integridade da assinatura..."
    codesign --verify --deep --strict --verbose=1 "${APP_IN_STAGE}"
    echo -e "${GREEN}   Assinatura do .app validada com sucesso!${NC}"
else
    echo -e "${YELLOW}   Aplicando assinatura ad-hoc para execução local...${NC}"
    codesign --force --deep -s - "${APP_IN_STAGE}" 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 3. Criar imagem .dmg
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}➔ [3/5] Gerando imagem de disco .dmg...${NC}"
ln -s "/Applications" "${STAGE_DIR}/Applications"
rm -f "${DMG_PATH}"

if command -v create-dmg >/dev/null 2>&1; then
    echo -e "${GREEN}   Usando create-dmg com layout visual...${NC}"
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
            hdiutil create -volname "DV Max" -srcfolder "${STAGE_DIR}" -ov -format UDZO "${DMG_PATH}"
        }
else
    hdiutil create -volname "DV Max" -srcfolder "${STAGE_DIR}" -ov -format UDZO "${DMG_PATH}"
fi

# Assinar o arquivo .dmg se houver certificado
if [ "${SIGN_IDENTITY}" != "-" ]; then
    echo -e "\n${BLUE}   Assinando o arquivo .dmg...${NC}"
    codesign --force --sign "${SIGN_IDENTITY}" --timestamp "${DMG_PATH}"
fi

# ------------------------------------------------------------------------------
# 4. Notarização com Apple (notarytool) se configurada
# ------------------------------------------------------------------------------
if [ -n "${NOTARIZE_PROFILE}" ]; then
    echo -e "\n${BLUE}➔ [4/5] Enviando para Notarização da Apple (notarytool)...${NC}"
    echo -e "   Perfil utilizado: ${GREEN}${NOTARIZE_PROFILE}${NC}"
    xcrun notarytool submit "${DMG_PATH}" --keychain-profile "${NOTARIZE_PROFILE}" --wait
    
    echo -e "\n${BLUE}   Grampeando ticket de notarização no DMG (stapler)...${NC}"
    xcrun stapler staple "${DMG_PATH}"
    echo -e "${GREEN}   Ticket grampeado com sucesso! O Gatekeeper aceitará o app sem alertas.${NC}"
else
    echo -e "\n${YELLOW}➔ [4/5] Notarização pulada (adicione --notarize-profile <nome> para notarizar).${NC}"
fi

# ------------------------------------------------------------------------------
# 5. Checksum SHA-256
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}➔ [5/5] Gerando checksum SHA-256...${NC}"
cd "${DIST_DIR}"
shasum -a 256 "${DMG_NAME}" > "${DMG_NAME}.sha256"
SHA_VAL=$(awk '{print $1}' "${DMG_NAME}.sha256")
FILE_SIZE=$(ls -lh "${DMG_NAME}" | awk '{print $5}')

echo -e "\n${GREEN}=================================================================${NC}"
echo -e "${GREEN}          Instalador macOS (.dmg) pronto com sucesso!            ${NC}"
echo -e "${GREEN}=================================================================${NC}"
echo -e "📁 Arquivo:    ${BLUE}${DMG_PATH}${NC}"
echo -e "⚖️ Tamanho:    ${YELLOW}${FILE_SIZE}${NC}"
echo -e "🔑 Assinatura: ${GREEN}${SIGN_IDENTITY}${NC}"
echo -e "🔒 SHA-256:    ${NC}${SHA_VAL}"
echo -e "📋 Checksum:   ${DIST_DIR}/${DMG_NAME}.sha256"
