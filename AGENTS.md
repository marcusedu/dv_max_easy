# AGENTS.md

Instruções para quem for alterar este repositório. O app ainda não foi implementado. `lib/main.dart` é o contador do template Flutter. Não avance feature sem o escopo desta fase estar explícito na tarefa.

## O que é este app

Cliente desktop chamado DV Max, pacote `dv_max_easy`, em Flutter para macOS, Windows e Linux, em volta do [yt-dlp](https://github.com/yt-dlp/yt-dlp) instalado na máquina. O processo baixa, o app mostra metadados, fila, progresso e perfis. FFmpeg entra na fase 1 de dois jeitos: o yt-dlp já o chama para juntar faixa de vídeo e áudio, embutir legenda e extrair áudio; e o app o chama, numa ação explícita, para concatenar as partes de uma playlist na ordem da lista.

Alvos da fase 1: macOS, Windows e Linux. Telefone fica fora. Flutter Web fica fora até existir um companheiro local. O navegador não executa o yt-dlp.

## Fases

Fase 1, a única que se implementa agora quando a tarefa pedir código:

- Colar ou soltar um link e ver título, duração e faixas antes de baixar.
- Fila com progresso, cancelar, tentar de novo e revelar o arquivo na pasta.
- Playlist confirmada vira um grupo na fila: título da lista, itens embaixo na ordem original, grupo expansível. Cada item baixa sozinho. Não há junção automática.
- No pai do grupo, a ação Unir na ordem da playlist. Oferecida quando a leva termina e disponível depois, no item pai. Partes originais permanecem até o usuário apagá-las. Se codec ou resolução divergirem, avisar antes de reencodar. Sem essa divergência, concatenar com stream copy. Capítulos seguem o título de cada parte.
- Dois perfis semeados no primeiro arranque, Música e Filmes. Cada um guarda pasta, formato, altura máxima, idioma de áudio, legendas, bitrate máximo, limite de velocidade (`-r`) e fragmentos concorrentes (`-N`, inteiro de 1 a 16, omitido quando vazio). Filmes começa selecionado.
- Ajustes globais: pasta padrão, binários do yt-dlp e do FFmpeg, concorrência da fila, idioma da interface. Textos visíveis nascem em ARB com `gen-l10n` desde o primeiro PR de tela. O único locale da v1 é pt-BR. Casos de uso devolvem código de erro, não frase.
- Ao abrir ou ao focar a janela, se a área de transferência tiver um link novo, perguntar uma vez. Sem histórico de clipboard.

Fase 2, não implementar até haver tarefa explícita:

- Abrir pelo Finder, Explorer ou menu Compartilhar. Um ajuste, desligado por padrão, permite começar o download sem perguntar. Com ele desligado, a confirmação continua. A fase 1 não implementa esse ajuste.
- Painel de conversão de arquivo local com FFmpeg (mp4, mkv, webm, avi, mpg, mp3 e afins). A união de partes de playlist não é esse painel.
- Listas salvas de links, além da fila e do histórico.

Exploração posterior, sem código:

- UI web falando com um serviço em `127.0.0.1` que reutiliza os mesmos casos de uso. Sem servidor remoto de download.

## Filosofia de interface e Diretrizes de Design / UI/UX (Design Engineering)

Aparência no espírito do HIG da Apple, em desktop, nos três sistemas operacionais (macOS, Windows e Linux), com a sensibilidade de **Design Engineering** de Emil Kowalski: *o acabamento invisível composto cria uma experiência que as pessoas amam sem saber explicar o porquê*.

### 1. Princípios Fundamentais de Design Engineering
- **Gosto apurado e intenção (*Taste is trained*)**: A beleza e o polimento são alavancas de produto. Não faça apenas funcionar; estude o porquê de os melhores apps de desktop parecerem naturais e refinados.
- **Detalhes invisíveis compõem o todo**: Cada milissegundo de atraso evitado, cada curva de transição afinada e cada estado `:active` reativo somam-se na percepção de qualidade superior.
- **Hierarquia calma e foco no conteúdo**: Muito respiro, tipografia neutra e legível, barra lateral e barra de ferramentas integradas, atalhos de teclado de primeira classe, movimento curto e acento de cor único.

### 2. Movimento, Curvas de Easing e Física
- **Curvas de Easing intencionais**:
  - **Nunca usar `ease-in` para UI**: Ele retarda a partida da animação exatamente no instante em que o olho do usuário está observando mais atentamente, transmitindo sensação de lentidão.
  - **Usar strong ease-out**: `AppMotion.easeOut = Cubic(0.23, 1.0, 0.32, 1.0)`. Inicia veloz e desacelera suavemente.
  - **Transições de tela**: Duração máxima de 200–220ms com fade combinado a leve deslocamento vertical (1.2% a 1.5%), evitando crossfade puramente estático.
- **Limites estritos de duração**:
  - Feedback de clique/pressão: 100–140ms.
  - Tooltips e popovers compactos: 150–240ms.
  - Dropdowns e menus: 160–220ms.
  - Transições de seções e modais: 200–260ms.
  - Ações repetidas centenas de vezes ao dia (como atalhos de teclado) não devem ter animações bloqueantes.
- **Nunca animar a partir de `scale(0)`**:
  - Nada no mundo real surge a partir do nada absoluto. Elementos que entram devem partir de `scale(0.95)` a `scale(0.97)` combinados com opacidade (`0 -> 1`), proporcionando entrada física natural.

### 3. Feedback Tátil e Estados de Pressão (`:active`)
- **Resposta imediata à pressão física**:
  - Botões (`FilledButton`, `OutlinedButton`, `IconButton`), chips de filtro e cards interativos devem implementar feedback de compressão tátil (`scale: 0.97` a `scale: 0.98`) sob clique/pressão via `PressableScale`.
  - O recuo na pressão é instantâneo e o retorno na liberação é elástico e suave, confirmando que a interface ouviu a ação do usuário.

### 4. Zero Saltos Estruturais de Layout (*No Layout Shifts*)
- **Inserção e remoção orgânicas**:
  - Banners (aviso de link no clipboard, alerta de duplicata ou arquivo local) nunca devem surgir com corte abrupto de 0ms, empurrando o formulário e a lista de downloads violentamente.
  - Devem ser orquestrados com `AnimatedSize` e `AnimatedOpacity`/`FadeTransition`, expandindo e retraindo a altura com suavidade contínua.

### 5. Desempenho Percebido e Fluidez Contínua
- **Barras de progresso com física contínua**:
  - Eventos de stdout do processo chegam em rajadas espaçadas. `LinearProgressIndicator` cru salta em trancos mecânicos desconfortáveis.
  - Usar `SmoothProgressIndicator` (interpolação por `TweenAnimationBuilder` sobre `AppMotion.fast`), convertendo atualizações discretas em um fluxo visual contínuo e orgânico.

### 6. Densidade Desktop e Ergonomia (Apple HIG)
- **Não usar `CupertinoApp` nem controles de telefone**: Eles degradam a densidade de ponteiro e menus no Windows e no Linux.
- **Densidade de ponteiro em desktop**:
  - Menus de contexto e popups devem ser compactos (itens de 28 a 32px de altura), com atalhos de teclado alinhados à direita em tom neutro.
  - `TooltipTheme` desktop com espera curta (240ms em vez dos 500ms lentos do padrão mobile).
- **Tipografia e Tokens**:
  - No macOS: fonte nativa do sistema. Nos outros: fonte neutra de alta legibilidade (Inter ou equivalente), com a mesma escala.
  - Grade de 8 (AppSpacing: s=8, m=16, l=24, xl=32). Raio dos painéis entre 10 e 12 (`panelRadius = 12`, `controlRadius = 10`).

### 7. Estados Vazios (*Empty States*) Orientadores
- Um estado vazio nunca deve ser um espaço em branco deserto nem uma linha isolada de texto no canto.
- Deve apresentar um arranjo centrado e equilibrado com ícone sutil em baixa opacidade, orientação clara do que fazer e menção aos atalhos rápidos (`⌘L`, `⌘V`).

## Arquitetura

Features, com camadas. UI não monta argumento de processo e não lê arquivo de configuração.

```text
lib/
  app/            # arranque, tema, rotas, janela
  design/         # tokens, tipografia, componentes de chrome
  core/           # erro, caminho de app support, relógio
  features/
    probe/        # metadados de uma URL
    downloads/    # fila e progresso
    profiles/
    settings/
```

Cada feature, quando passar de um tipo, separa `domain`, `application`, `infrastructure` e `presentation`. Domínio não importa Flutter.

Estado com Riverpod. Widget chama um caso de uso. O caso de uso depende de uma porta (`YtDlp`, `ClipboardPort`, `SettingsStore`). Infra implementa a porta. Teste troca a porta por um fake.

Persistência da fase 1: JSON no diretório de suporte do app (perfis, ajustes, fila para retomar). Sem Drift até a fila precisar de consulta de verdade.

Processo:

- `yt-dlp` em subprocesso, argumentos em lista, sem shell.
- Metadados com dump JSON. Progresso por stdout, uma linha por evento.
- Cancelar mata a árvore do processo.
- URL e caminhos vêm do usuário. Nada disso é concatenado numa string de shell.
- Faixa de áudio que não é a padrão sai da lista de formatos do JSON (`language`, format id) e vira seletor do yt-dlp, inclusive `--audio-multistreams` quando o perfil pede mais de uma faixa. O app não monta o próprio mux de faixas.
- Concatenar partes de playlist é um comando próprio de FFmpeg, só a partir da ação do pai do grupo, com os arquivos já baixados e na ordem da lista.

## Qualidade

- `flutter analyze` sem issues novos. Lints do `analysis_options.yaml` continuam ligados.
- Caso de uso e domínio têm teste de unidade com fake do processo. Sem rede nos testes.
- `const` onde o widget não muda. Sem `setState` para estado que vive fora da tela.
- Sem `print`. Log atrás de uma porta, com o comando redigido o bastante para não gravar query string sensível se o ajuste de privacidade estiver ativo.
- Comentário só para restrição que o código não mostra.
- Diferença pequena. Sem abstração para um único chamador.

## Verificação

Mudança de UI pede o app desktop rodando e o fluxo exercitado (colar, sondar, enfileirar, cancelar, concluir). Teste de widget não substitui isso. Se o yt-dlp não estiver no PATH, a tela de ajustes tem de dizer isso com clareza. Não declarar a tarefa pronta sem esse caminho visto.
