# 📦 Scripts de Compilação e Empacotamento (Build & Distribution)

Este diretório contém os scripts automatizados para compilar e gerar os pacotes de instalação oficiais do **DV Max** para as três plataformas desktop suportadas:

| Plataforma | Formato de Distribuição | Script Responsável | Requisitos |
| :--- | :--- | :--- | :--- |
| **macOS** | `.dmg` (Apple Disk Image) | [`scripts/build_macos.sh`](./build_macos.sh) | macOS 12+, Xcode / CommandLineTools |
| **Windows** | `.msi` (Windows Installer) + `.zip` | [`scripts/build_windows.ps1`](./build_windows.ps1) | Windows 10/11 x64, Visual Studio C++, [WiX Toolset](https://wixtoolset.org/) |
| **Linux** | `.deb` (Debian/Ubuntu) + `.tar.gz` | [`scripts/build_linux.sh`](./build_linux.sh) | Linux x64, `clang`, `cmake`, `ninja`, `pkg-config`, `libgtk-3-dev` |

---

## 🚀 Uso Rápido (Multiplataforma)

Você pode usar o script unificado [`scripts/build.sh`](./build.sh), que detecta o sistema operacional atual automaticamente:

```bash
# Detecta automaticamente macOS, Linux ou Windows (se executado via Git Bash/MSYS2)
./scripts/build.sh

# Ou force a compilação de uma plataforma específica:
./scripts/build.sh --platform macos
./scripts/build.sh --platform linux
./scripts/build.sh --platform windows
```

Todos os instaladores gerados são gravados na pasta **`dist/`** na raiz do projeto, acompanhados de seus respectivos arquivos de integridade `.sha256`.

---

## 🍏 1. macOS (`.dmg`)

### Execução:
```bash
# Compilação e empacotamento completo:
./scripts/build_macos.sh

# Se você já tiver compilado via 'flutter build macos --release' e quiser apenas gerar o DMG:
./scripts/build_macos.sh --skip-build
```

### O que o script faz:
1. Lê dinamicamente a versão e build de `pubspec.yaml` (ex: `1.1.0+2`).
2. Executa `flutter build macos --release`.
3. Prepara uma estrutura de volume com o aplicativo `DV Max.app` e o link para a pasta `/Applications`.
4. Aplica assinatura ad-hoc (`codesign`) para garantir execução local sem bloqueios do Gatekeeper.
5. Utiliza o utilitário nativo `hdiutil` para gerar uma imagem comprimida UDZO (ou `create-dmg` se instalado via `brew install create-dmg` para layout gráfico com ícones posicionados).
6. Calcula o checksum SHA-256 e salva em `dist/DV_Max_<VERSAO>_macOS.dmg.sha256`.

---

## 🪟 2. Windows (`.msi` e `.zip`)

### Execução no PowerShell (Windows 10/11 ou CI):
```powershell
# Execução direta:
.\scripts\build_windows.ps1

# Se já tiver executado 'flutter build windows --release':
.\scripts\build_windows.ps1 -SkipBuild
```

### Requisitos do WiX Toolset para gerar o `.msi`:
O script suporta tanto o **WiX v4/v5** (moderno) quanto o **WiX v3**:
```powershell
# Instalação recomendada (WiX v4 via .NET CLI):
dotnet tool install --global wix

# Ou via Windows Package Manager:
winget install WiX
```
*Nota: Caso o WiX Toolset não esteja instalado na máquina, o script gerará automaticamente o pacote portátil universal `.zip` e exibirá as instruções de instalação do WiX.*

### O que o script faz:
1. Extrai a versão de 4 dígitos necessária para o Windows Installer (`X.Y.Z.Build`).
2. Compila a aplicação via `flutter build windows --release`.
3. Gera o arquivo portátil comprimido `.zip` contendo todos os binários e dependências nativas (`dist/DV_Max_<VERSAO>_windows_x64.zip`).
4. Gera o código-fonte WiX com inclusão de todos os arquivos do bundle, DLLs de plugins e atalhos na Área de Trabalho e no Menu Iniciar.
5. Compila o instalador `.msi` (`dist/DV_Max_<VERSAO>_x64.msi`).
6. Calcula o checksum SHA-256 de todos os artefatos.

---

## 🐧 3. Linux (`.deb`, `.tar.gz` e `.AppImage`)

### Execução:
```bash
./scripts/build_linux.sh

# Se já tiver executado 'flutter build linux --release':
./scripts/build_linux.sh --skip-build
```

### O que o script faz:
1. Executa `flutter build linux --release`.
2. Constrói a estrutura de diretórios padrão Debian (`/usr/lib/dv-max-easy/`, `/usr/bin/dv-max`, `.desktop` e ícones).
3. Cria o arquivo de controle com dependências do sistema (`libc6`, `libgtk-3-0`, `libglib2.0-0`, etc.).
4. Empacota o arquivo `.deb` oficial usando `dpkg-deb` (com fallback via `ar`/`tar` caso não esteja no Debian/Ubuntu).
5. Cria o arquivo `.tar.gz` portátil com um script `install.sh` para instalação local sem privilégios de root (`~/.local/share/`).
6. Se o utilitário `appimagetool` estiver disponível no PATH, também gera o executável universal `.AppImage`.
7. Calcula os checksums SHA-256.

---

## 🤖 Exemplo para GitHub Actions (CI/CD)

```yaml
name: Release Builds

on:
  push:
    tags:
      - 'v*'

jobs:
  macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
      - name: Build macOS DMG
        run: ./scripts/build_macos.sh
      - uses: actions/upload-artifact@v4
        with:
          name: macos-dmg
          path: dist/*.dmg

  windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
      - name: Install WiX
        run: dotnet tool install --global wix
      - name: Build Windows MSI
        run: .\scripts\build_windows.ps1
      - uses: actions/upload-artifact@v4
        with:
          name: windows-installer
          path: dist/*.*

  linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Linux Build Dependencies
        run: sudo apt-get update && sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev
      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
      - name: Build Linux Packages
        run: ./scripts/build_linux.sh
      - uses: actions/upload-artifact@v4
        with:
          name: linux-packages
          path: dist/*.*
```
