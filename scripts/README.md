# 📦 Scripts de Compilação e Empacotamento (Build & Distribution)

Este diretório contém os scripts automatizados para compilar e gerar os pacotes de instalação oficiais do **DV Max** para as três plataformas desktop suportadas:

| Plataforma | Formato de Distribuição | Script Responsável | Requisitos |
| :--- | :--- | :--- | :--- |
| **macOS** | `.dmg` (Apple Disk Image) | [`scripts/build_macos.sh`](./build_macos.sh) | macOS 12+, Xcode / CommandLineTools |
| **Windows** | `.msi` (Windows Installer) + `.zip` | [`scripts/build_windows.ps1`](./build_windows.ps1) | Windows 10/11 x64, Visual Studio C++, `nuget.exe` no PATH, [WiX Toolset](https://wixtoolset.org/) 5 |
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

# Falha se o .msi não for gerado (é o que o GitHub Actions usa):
.\scripts\build_windows.ps1 -RequireMsi
```

### Requisitos do WiX Toolset para gerar o `.msi`:
O script suporta tanto o **WiX v4/v5** (moderno) quanto o **WiX v3**:
```powershell
# Instalação recomendada. O diretório dos tools globais precisa estar no PATH.
dotnet tool install --global wix --version 5.0.2

# Ou via Windows Package Manager:
winget install WiX
```
O `nuget.exe` também precisa estar no PATH. O plugin `flutter_inappwebview` baixa o WebView2 durante o `flutter build windows`. Sem o NuGet, a compilação para antes do WiX.
*Nota: Caso o WiX Toolset não esteja instalado na máquina, o script gerará automaticamente o pacote portátil universal `.zip` e exibirá as instruções de instalação do WiX.*

### O que o script faz:
1. Extrai a versão de 4 dígitos necessária para o Windows Installer (`X.Y.Z.Build`).
2. Compila a aplicação via `flutter build windows --release`.
3. Gera o arquivo portátil comprimido `.zip` contendo todos os binários e dependências nativas (`dist/DV_Max_<VERSAO>_windows_x64.zip`).
4. Gera o código-fonte WiX com os arquivos do bundle e um atalho no Menu Iniciar. O atalho da Área de Trabalho fica de fora: num instalador por máquina ele reprova a validação do Windows Installer.
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

## GitHub Actions

O workflow [`.github/workflows/release.yml`](../.github/workflows/release.yml) compila macOS, Windows e Linux, publica um GitHub Release e reescreve a seção Download do `README.md`. Ele roda ao enviar uma tag `v*` (por exemplo `v1.2.0`) ou pelo botão Run workflow.

No Windows o job coloca o `nuget.exe` e o WiX 5 no PATH e chama `.\scripts\build_windows.ps1 -RequireMsi`. No macOS passa `--skip-notarize`, porque o runner não tem o perfil `dvmax-notary`.
