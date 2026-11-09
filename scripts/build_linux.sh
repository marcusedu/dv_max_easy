#!/usr/bin/env bash
# ==============================================================================
# Script de Compilação e Criação de Instalador (.deb / .tar.gz) para Linux
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
echo -e "${BLUE}       DV Max - Build & Packaging para Linux (.deb / tar.gz)     ${NC}"
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

SKIP_BUILD=false
for arg in "$@"; do
    case $arg in
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --help|-h)
            echo "Uso: ./scripts/build_linux.sh [opções]"
            echo "Opções:"
            echo "  --skip-build    Pula a etapa 'flutter build linux --release' e usa o bundle existente."
            echo "  --help, -h      Exibe esta mensagem de ajuda."
            exit 0
            ;;
    esac
done

BUNDLE_DIR="${ROOT_DIR}/build/linux/x64/release/bundle"

if [ "$SKIP_BUILD" = false ]; then
    echo -e "\n${BLUE}➔ [1/4] Compilando aplicação Flutter em modo Release (Linux x64)...${NC}"
    flutter build linux --release
else
    echo -e "\n${YELLOW}➔ [1/4] Pulando compilação (--skip-build solicitado).${NC}"
fi

if [ ! -d "${BUNDLE_DIR}" ]; then
    echo -e "${RED}Erro: Bundle Linux não encontrado em: ${BUNDLE_DIR}${NC}"
    exit 1
fi

DIST_DIR="${ROOT_DIR}/dist"
mkdir -p "${DIST_DIR}"

# ------------------------------------------------------------------------------
# 2. Criar pacote Debian (.deb)
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}➔ [2/4] Gerando pacote Debian (.deb)...${NC}"
PKG_NAME="dv-max-easy"
DEB_STAGE=$(mktemp -d /tmp/dv_max_deb_stage.XXXXXX)
trap 'rm -rf "${DEB_STAGE}"' EXIT

DEB_ROOT="${DEB_STAGE}/pkg"
mkdir -p "${DEB_ROOT}/DEBIAN"
mkdir -p "${DEB_ROOT}/usr/lib/${PKG_NAME}"
mkdir -p "${DEB_ROOT}/usr/bin"
mkdir -p "${DEB_ROOT}/usr/share/applications"
mkdir -p "${DEB_ROOT}/usr/share/icons/hicolor/1024x1024/apps"
mkdir -p "${DEB_ROOT}/usr/share/pixmaps"

# Copiar bundle para /usr/lib/dv-max-easy
cp -r "${BUNDLE_DIR}/"* "${DEB_ROOT}/usr/lib/${PKG_NAME}/"

# Launcher executável em /usr/bin/dv-max
cat << 'EOF' > "${DEB_ROOT}/usr/bin/dv-max"
#!/usr/bin/env sh
exec /usr/lib/dv-max-easy/dv_max_easy "$@"
EOF
chmod 755 "${DEB_ROOT}/usr/bin/dv-max"

# Copiar ícones
if [ -f "${ROOT_DIR}/assets/app_icon.png" ]; then
    cp "${ROOT_DIR}/assets/app_icon.png" "${DEB_ROOT}/usr/share/icons/hicolor/1024x1024/apps/${PKG_NAME}.png"
    cp "${ROOT_DIR}/assets/app_icon.png" "${DEB_ROOT}/usr/share/pixmaps/${PKG_NAME}.png"
fi

# Atalho .desktop para o menu de aplicativos
cat << EOF > "${DEB_ROOT}/usr/share/applications/${PKG_NAME}.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=DV Max
GenericName=Gerenciador de Mídia
Comment=Cliente desktop para download de vídeos e organizador de arquivos
Exec=/usr/bin/dv-max %U
Icon=${PKG_NAME}
Terminal=false
Categories=AudioVideo;Network;Utility;
StartupWMClass=dv_max_easy
MimeType=x-scheme-handler/dvmax;
Keywords=download;video;audio;organizer;triage;yt-dlp;ffmpeg;
EOF
chmod 644 "${DEB_ROOT}/usr/share/applications/${PKG_NAME}.desktop"

# Arquivo DEBIAN/control
INSTALLED_SIZE=$(du -sk "${DEB_ROOT}/usr" | cut -f1)

cat << EOF > "${DEB_ROOT}/DEBIAN/control"
Package: ${PKG_NAME}
Version: ${SEMVER}-${BUILD_NUM}
Section: video
Priority: optional
Architecture: amd64
Installed-Size: ${INSTALLED_SIZE}
Maintainer: Marcus Software <contato@marcussoftware.info>
Depends: libc6 (>= 2.31), libgtk-3-0 (>= 3.24.0), libglib2.0-0, libx11-6
Recommends: ffmpeg, yt-dlp
Homepage: https://github.com/marcusduarte/dv_max_easy
Description: Cliente desktop para downloads de mídia e organizador de arquivos
 DV Max é um cliente desktop elegante em Flutter para macOS, Windows e Linux,
 com suporte a filas de download integradas ao yt-dlp, editor visual de cortes,
 galeria de mídia categorizada e central de triagem rápida com atalhos de teclado.
EOF
chmod 644 "${DEB_ROOT}/DEBIAN/control"

DEB_FILE="${DIST_DIR}/DV_Max_${SEMVER}_amd64.deb"

if command -v dpkg-deb >/dev/null 2>&1; then
    dpkg-deb --build --root-owner-group "${DEB_ROOT}" "${DEB_FILE}"
    echo -e "${GREEN}   Pacote .deb gerado com sucesso!${NC}"
else
    echo -e "${YELLOW}   Aviso: dpkg-deb não encontrado no PATH. Usando empacotamento ar/tar fallback...${NC}"
    (
        cd "${DEB_ROOT}"
        tar -czf "${DEB_STAGE}/control.tar.gz" -C DEBIAN .
        tar -czf "${DEB_STAGE}/data.tar.gz" --exclude='./DEBIAN' .
        echo "2.0" > "${DEB_STAGE}/debian-binary"
        cd "${DEB_STAGE}"
        ar rcs "${DEB_FILE}" debian-binary control.tar.gz data.tar.gz
    )
    echo -e "${GREEN}   Pacote .deb criado via fallback com sucesso!${NC}"
fi

# ------------------------------------------------------------------------------
# 3. Criar arquivo portátil Tarball (.tar.gz)
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}➔ [3/4] Gerando pacote portátil universal (.tar.gz)...${NC}"
TAR_NAME="DV_Max_${SEMVER}_linux_x64.tar.gz"
TAR_PATH="${DIST_DIR}/${TAR_NAME}"
TAR_STAGE=$(mktemp -d /tmp/dv_max_tar_stage.XXXXXX)
PKG_FOLDER="DV_Max_${SEMVER}_linux_x64"

mkdir -p "${TAR_STAGE}/${PKG_FOLDER}"
cp -r "${BUNDLE_DIR}/"* "${TAR_STAGE}/${PKG_FOLDER}/"
cp "${DEB_ROOT}/usr/share/applications/${PKG_NAME}.desktop" "${TAR_STAGE}/${PKG_FOLDER}/"
if [ -f "${ROOT_DIR}/assets/app_icon.png" ]; then
    cp "${ROOT_DIR}/assets/app_icon.png" "${TAR_STAGE}/${PKG_FOLDER}/dv_max_easy.png"
fi

cat << 'EOF' > "${TAR_STAGE}/${PKG_FOLDER}/install.sh"
#!/usr/bin/env sh
set -e
TARGET_DIR="${HOME}/.local/share/dv_max_easy"
BIN_DIR="${HOME}/.local/bin"
DESKTOP_DIR="${HOME}/.local/share/applications"
ICON_DIR="${HOME}/.local/share/icons/hicolor/1024x1024/apps"

echo "Instalando DV Max para o usuário atual..."
mkdir -p "${TARGET_DIR}" "${BIN_DIR}" "${DESKTOP_DIR}" "${ICON_DIR}"
cp -r ./* "${TARGET_DIR}/"
ln -sf "${TARGET_DIR}/dv_max_easy" "${BIN_DIR}/dv-max"
if [ -f "${TARGET_DIR}/dv_max_easy.png" ]; then
    cp "${TARGET_DIR}/dv_max_easy.png" "${ICON_DIR}/dv-max-easy.png"
fi

sed -e "s|/usr/bin/dv-max|${BIN_DIR}/dv-max|g" \
    -e "s|Icon=dv-max-easy|Icon=${ICON_DIR}/dv-max-easy.png|g" \
    "${TARGET_DIR}/dv_max_easy.desktop" > "${DESKTOP_DIR}/dv-max-easy.desktop"
chmod +x "${DESKTOP_DIR}/dv-max-easy.desktop"

echo "DV Max instalado em ${TARGET_DIR}."
echo "Certifique-se de que ${BIN_DIR} está no seu PATH."
EOF
chmod +x "${TAR_STAGE}/${PKG_FOLDER}/install.sh"

tar -czf "${TAR_PATH}" -C "${TAR_STAGE}" "${PKG_FOLDER}"
rm -rf "${TAR_STAGE}"

# Se appimagetool estiver presente, gera também o AppImage
if command -v appimagetool >/dev/null 2>&1; then
    echo -e "\n${BLUE}   Detectado appimagetool! Gerando .AppImage...${NC}"
    APPDIR=$(mktemp -d /tmp/dv_max_appdir.XXXXXX)
    cp -r "${BUNDLE_DIR}/"* "${APPDIR}/"
    cp "${DEB_ROOT}/usr/share/applications/${PKG_NAME}.desktop" "${APPDIR}/"
    cp "${ROOT_DIR}/assets/app_icon.png" "${APPDIR}/dv_max_easy.png"
    cat << 'EOF' > "${APPDIR}/AppRun"
#!/usr/bin/env sh
HERE="$(dirname "$(readlink -f "${0}")")"
exec "${HERE}/dv_max_easy" "$@"
EOF
    chmod +x "${APPDIR}/AppRun"
    APPIMAGE_OUT="${DIST_DIR}/DV_Max_${SEMVER}_x86_64.AppImage"
    appimagetool "${APPDIR}" "${APPIMAGE_OUT}" || true
    rm -rf "${APPDIR}"
fi

# ------------------------------------------------------------------------------
# 4. Gerar Checksums SHA-256
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}➔ [4/4] Gerando checksums SHA-256...${NC}"
cd "${DIST_DIR}"
if [ -f "$(basename "${DEB_FILE}")" ]; then
    sha256sum "$(basename "${DEB_FILE}")" > "$(basename "${DEB_FILE}").sha256" 2>/dev/null || shasum -a 256 "$(basename "${DEB_FILE}")" > "$(basename "${DEB_FILE}").sha256"
fi
sha256sum "${TAR_NAME}" > "${TAR_NAME}.sha256" 2>/dev/null || shasum -a 256 "${TAR_NAME}" > "${TAR_NAME}.sha256"

echo -e "\n${GREEN}=================================================================${NC}"
echo -e "${GREEN}          Instaladores Linux gerados com sucesso!                ${NC}"
echo -e "${GREEN}=================================================================${NC}"
[ -f "${DEB_FILE}" ] && echo -e "📦 Pacote .deb:   ${BLUE}${DEB_FILE}${NC}"
echo -e "📦 Tarball .gz:   ${BLUE}${TAR_PATH}${NC}"
echo -e "📋 Checksums em:  ${DIST_DIR}/*.sha256"
echo -e "\nPara instalar o .deb no Ubuntu/Debian/Mint:"
echo -e "  sudo apt install ${DEB_FILE}"
echo -e "ou"
echo -e "  sudo dpkg -i ${DEB_FILE}"
