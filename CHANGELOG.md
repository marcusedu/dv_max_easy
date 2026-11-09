# Changelog

Todas as alterações notáveis deste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/)
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [1.2.0] - 2026-11-09

### 🚀 Novas Funcionalidades
- **Assinatura e Notarização no macOS (`feat(macos)`)**:
  - Configuração de entitlements de Hardened Runtime (`Release.entitlements`) com suporte a execução JIT, carregamento de dylibs e acesso à rede.
  - Script de build no macOS preparado para assinatura com Apple Developer ID Application e submissão automatizada de notarização junto à Apple (`notarytool`).

### 🐛 Correções de Bugs
- **Tratamento de Nomes de Arquivos Muito Longos (`fix(downloads)`)**:
  - Truncamento preventivo e seguro de variáveis de título no template de saída (`safeFilenameTemplate`), contornando a falha do `yt-dlp` com múltiplos pontos finais em legendas longas (como posts e reels do Facebook/Instagram).
  - Recuperação automática em caso de erro de sistema de arquivos (`[Errno 63]`, `[Errno 36]`, `[Errno 206]`), reexecutando imediatamente com nome compacto.
  - Encurtamento de nome ativado ao clicar em "Tentar de novo" na fila de downloads, impedindo repetição do erro.
- **Formato de Vídeo e Remuxing de Container (`fix(downloads)`)**:
  - Adição de `--remux-video` apontando para o container configurado no perfil (`mp4` ou `mkv`).
  - Garante que mídias baixadas em stream pré-muxado (como links que vinham em `.m4v`) sejam remuxadas via stream copy para `.mp4` sem recodificação demorada.

### 🛠️ Manutenção e Infraestrutura
- **Automação de Build Multiplataforma (`ci(scripts)`)**:
  - Scripts dedicados para geração de instaladores e pacotes de distribuição para desktop: `.dmg` no macOS, `.msi` no Windows e `.deb` no Linux.

## [1.1.0] - 2026-11-09

### 🚀 Novas Funcionalidades
- **Triagem Rápida de Arquivos (`feat(triage)`)**:
  - Nova aba "Triagem" para inspecionar, classificar e organizar arquivos em diretórios locais (ex: pasta `Downloads`).
  - Painel de estatísticas com total de arquivos, espaço consumido e quebra por categorias (vídeos, áudios, imagens, documentos, compactados e instaladores).
  - Ação em um clique para expurgo seguro de instaladores antigos (`.dmg`, `.pkg`, `.exe`, `.msi`, `.deb`, etc.).
  - Triagem focada com atalhos de teclado ágeis:
    - Teclas numéricas `1` a `9`: move o arquivo para a pasta de destino configurada no slot.
    - Seta Direita (`→`) ou `Espaço`: avança para o próximo arquivo.
    - Seta Esquerda (`←`): retorna ao arquivo anterior.
    - `Del` ou `Backspace`: envia o arquivo diretamente para a lixeira do sistema operacional.
    - Tecla `T`: agrupa o item na lista temporária para decisão posterior.
    - Tecla `F`: marca o arquivo como favorito.
    - Atalho `⌘Z` / `Ctrl+Z`: desfaz a última movimentação de arquivo com restauração atômica.
  - Reprodutor nativo de áudio e vídeo com `media_kit`, controles de reprodução compactos, seeker fluido e atalho de loop.
  - Pré-visualização rica de múltiplos tipos de arquivos:
    - Documentos e PDFs via QuickLook nativo no macOS.
    - Páginas HTML com engine embarcada via WebView.
    - Arquivos Markdown (`.md`) com renderização tipográfica completa.
    - Tabelas CSV com parser tolerante a linhas irregulares e cabeçalhos ordenados.
    - Arquivos de código e texto com syntax highlighting e numeração de linhas.
- **Bandeja do Sistema e Notificações (`feat(tray)`)**:
  - Integração com a bandeja do sistema (System Tray) exibindo ícone dinâmico com indicador de downloads ativos e menu rápido.
  - Monitoramento em segundo plano da área de transferência com registro de links detectados e badge contador na barra superior.
- **Modal de Confirmação e Tags (`feat(downloads)`)**:
  - Novo modal ao colar links com seleção imediata de perfil de download e atribuição de tags personalizadas (ex: `#filmes`, `#músicas`, `#estudos`).
  - Associação automática de tags baseada no perfil selecionado.
- **Galeria de Mídia (`feat(gallery)`)**:
  - Aba de galeria com exibição em grade dos vídeos e arquivos baixados, miniaturas com reprodução ao toque e filtros por categorias e tags.
- **Editor de Cortes e Conversor (`feat(cuts)`, `feat(convert)`)**:
  - Interface visual para corte de trechos de vídeos com timeline interativa e junção contínua.
  - Painel de conversão de formatos com extração de áudio e concatenação via FFmpeg.
- **Importação de Lotes (`feat(queue)`)**:
  - Importação rápida de múltiplos links a partir de arquivos `.txt`.
- **Design Engineering e Polimento Visual (`feat(ui)`)**:
  - Resposta tátil com compressão elástica (`PressableScale`) em botões e cards.
  - Curvas de aceleração orgânicas (`AppMotion.easeOut`) e eliminação de saltos bruscos de layout (*layout shifts*).
  - Doodles decorativos personalizados na barra lateral no espírito Apple HIG.

### 🐛 Correções de Bugs
- **Lixeira do Sistema Operacional**: Correção da rotina de descarte no macOS via AppleScript e fallback resiliente para `~/.Trash`.
- **Tabelas CSV**: Tratamento defensivo no widget de visualização de tabelas para prevenir crashes em linhas com quantidades irregulares de colunas.
- **Colisão de Nomes**: Resolução automática com sufixos numéricos ao mover arquivos com nomes duplicados entre pastas.
- **Sincronização de Banco de Dados**: Atualização automática do caminho físico do arquivo no histórico de downloads quando movido através da triagem.

### ⚡ Desempenho e Melhorias
- Renderização eficiente de mídia utilizando decodificação nativa por hardware (`media_kit`).
- QuickLook thumbnail service para geração rápida de miniaturas de documentos no macOS sem consumo excessivo de memória.
- Streaming assíncrono linha-a-linha de saída de comandos do `yt-dlp` e `ffmpeg`.

### 🛠️ Manutenção e Infraestrutura
- Integração dos pacotes `media_kit`, `flutter_inappwebview`, `flutter_markdown_plus`, `tray_manager` e `window_manager`.
- Suíte completa de testes automatizados com 127 testes aprovados cobrindo fluxo de fila, triagem, tags, histórico de links e galeria.
- Internacionalização com suporte completo em pt-BR via `gen-l10n`.
