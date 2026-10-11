# Cliente desktop para yt-dlp — desenho da fase 1

| Campo | Valor |
| --- | --- |
| Autor | _pendente_ |
| Data | 2026-10-10 |
| Status | Rascunho |
| Pacote | `dv_max_easy` (`publish_to: none`, versão atual `1.0.0+1`) |
| Público | Engenheiros que vão implementar o app depois desta revisão |
| Escopo deste documento | Fase 1, com costuras explícitas para a fase 2 e para um eventual companheiro em `127.0.0.1` |

## Visão geral

O repositório hoje é o contador do template Flutter, e esse contador nem analisa. `lib/main.dart` tem `colorScheme: .fromSeed(...)` e `mainAxisAlignment: .center`, sintaxe inválida. `pubspec.yaml` só depende de `flutter` e `cupertino_icons`. Não existe domínio, fila nem integração com processo. As pastas `macos/`, `linux/` e `windows/` já estão geradas; `android/`, `ios/` e `web/` também, mas não são alvo da fase 1.

O produto é um cliente desktop, para uma pessoa, em volta do `yt-dlp` e do `ffmpeg` que o usuário já instalou. O app sonda a URL, mostra título, duração, canal, faixas de áudio e legendas, e só então enfileira o download com um perfil nomeado. A dor concreta da fase 1 é esta: no YouTube e em sites parecidos um vídeo expõe várias faixas de áudio, e o seletor padrão do yt-dlp fica com a faixa default ou a de maior taxa. Hoje o usuário baixa a faixa à parte e muxa na mão. A fase 1 resolve isso lendo `language`, `format_id`, `vcodec` e `acodec` do JSON de `yt-dlp -J` e passando um seletor explícito, com `--audio-multistreams` quando o perfil pede mais de uma faixa. O ffmpeg continua sendo o processo que o próprio yt-dlp dispara para juntar streams de um único URL, embutir legenda e extrair áudio. O app não monta esse mux.

Playlist confirmada é outra coisa, e também é fase 1. Vira um grupo expansível na fila: o pai mostra o título da lista, os filhos ficam na ordem da playlist, e cada filho é um processo `yt-dlp` próprio. Não há concatenação automática. Quando a leva termina, o pai oferece **Unir na ordem da playlist**. Essa ação chama o ffmpeg direto, uma vez, sobre os arquivos já baixados. Não é o estúdio de conversão da fase 2.

A interface segue o espírito do HIG em desktop nos três sistemas: hierarquia calma, barra lateral persistente, barra de ferramentas, espaço em branco, movimento curto, claro/escuro do sistema, um acento só, atalhos de teclado. Não é um app de iPhone. SF Pro não entra no pacote.

## Contexto e motivação

### Estado atual

- `lib/main.dart`: `MyApp` / `MyHomePage` com `_counter` e `setState`. Além de não haver arquitetura para preservar, o arquivo não é o template válido: `colorScheme: .fromSeed(seedColor: Colors.deepPurple)` e `mainAxisAlignment: .center` não compilam. `flutter analyze` já fica vermelho antes de qualquer PR. O PR 1 substitui `lib/main.dart` e `test/widget_test.dart` por inteiro. Não vale corrigir essas duas linhas no meio do contador.
- `test/widget_test.dart`: smoke test do contador. Também sai inteiro no PR 1, não porque “a home vai quebrar um teste verde”, e sim porque a tela e o teste atuais não são a base do produto.
- `analysis_options.yaml`: `flutter_lints` ^6, com `analyzer.exclude` nas pastas de plataforma. `flutter analyze` olha `lib/` e `test/`. `avoid_print` permanece ligado. Nenhum PR usa `print`.
- `macos/Runner/DebugProfile.entitlements` e `macos/Runner/Release.entitlements` ligam `com.apple.security.app-sandbox`. O de debug ainda traz `allow-jit` e `network.server`. No `project.pbxproj`, as configurações Debug e Profile apontam para `DebugProfile.entitlements`; Release aponta para `Release.entitlements`. Não há `ENABLE_APP_SANDBOX` separado. Com sandbox, o processo Flutter não executa `/opt/homebrew/bin/yt-dlp` nem grava numa pasta arbitrária escolhida pelo usuário.
- `macos/Runner/Configs/AppInfo.xcconfig`: `PRODUCT_NAME = dv_max_easy`, bundle id `marcussoftware.info.dvMaxEasy`. O executável e o bundle id ficam assim. O título da janela é **DV Max**, vindo de `AppIdentity.displayName`.
- `linux/CMakeLists.txt`: `APPLICATION_ID` é `marcussoftware.info.dv_max_easy`. Não é, por si, o diretório de suporte.
- `windows/runner/Runner.rc`: `CompanyName` `marcussoftware.info`, `ProductName` `dv_max_easy`.
- `AGENTS.md` na raiz fixa fases, a união explícita da playlist, a filosofia visual e a regra de que a UI não monta argumento de processo nem lê arquivo de configuração.

Não há backend, conta, modelo de domínio nem telemetria. Não vamos inventar isso na fase 1.

### Dor

Num vídeo com áudio `ja` e `en`, `bestvideo*+bestaudio/best` (o equivalente prático do default atual) escolhe uma faixa. O usuário que quer o japonês, ou japonês mais o original, não tem como dizer isso sem montar `-f` e, no caso de duas faixas, `--audio-multistreams`. O app precisa mostrar as faixas que a sondagem realmente devolveu e gravar a escolha no perfil, não pedir que a pessoa escreva um seletor.

Playlist e URL de canal ampliam outro problema: enfileirar centenas de itens sem contar é fácil de fazer errado, e misturar música com aula num arquivo só, sem pedir, também. A fase 1 conta com `--flat-playlist`, pede confirmação, baixa cada item separado e só concatena se a pessoa acionar o pai do grupo.

### Por que não empacotar o yt-dlp

Os extratores quebram com frequência. Um binário congelado dentro do app fica velho na semana seguinte, aumenta o instalador e mistura licenças. A fase 1 usa o executável que a pessoa já mantém (`brew`, `winget`, pacote da distro, binário oficial) e oferece `yt-dlp -U` sabendo que instalações de gerenciador de pacote podem recusar a atualização. O app mostra o stderr; não trata isso como falha fatal do produto.

## Objetivos e não objetivos

### Objetivos da fase 1

- Colar uma URL ou soltar URLs na janela. Vários URLs soltos de uma vez não entram na fila calados: cada um passa pelo cartão, um por vez.
- Sondar metadados antes de enfileirar um vídeo: título, miniatura, duração, canal, idiomas de áudio, legendas.
- Fila com progresso, velocidade, ETA, cancelar, tentar de novo e revelar no gerenciador de arquivos.
- Playlist confirmada vira um grupo expansível. O pai mostra o título da lista. Os filhos aparecem na ordem da playlist, que não é reescolhida na hora de unir. Cada filho é um processo `yt-dlp`, com progresso, cancelamento e retry próprios. Não há junção automática. Playlists mistas (música, curso) continuam como arquivos separados dentro do grupo.
- No pai, a ação **Unir na ordem da playlist**. Aparece quando a leva terminou e continua disponível depois. Dispensar o convite não remove a ação. A união concatena as partes concluídas, na ordem da lista, num arquivo novo. As partes originais ficam no disco até a pessoa apagá-las. O arquivo unido não substitui os filhos: o grupo conserva a organização e ganha a saída unida. Se codec, resolução, taxa de quadros ou layout de áudio impedirem stream copy, o app avisa e só reencoda depois de confirmação. Se forem compatíveis, usa o concat demuxer com `-c copy`. Cada parte vira um capítulo com o título daquela parte, quando o contêiner guarda capítulo.
- Perfis nomeados. O perfil é o dono de pasta de destino, contêiner, altura máxima ou “melhor”, idioma de áudio preferido com fallback, legendas (embutir ou arquivo separado), bitrate máximo opcional, limite de taxa de download opcional (`-r`), fragmentos concorrentes opcionais (`-N`) e template de nome. O primeiro arranque grava Música e Filmes e deixa Filmes selecionado.
- Ajustes globais: pasta padrão, idioma da interface (`uiLanguage`, default `pt-BR`, único locale embarcado), caminho do yt-dlp e do ffmpeg, concorrência máxima (default 2), interruptor do aviso de clipboard, versão do yt-dlp e ação para rodar `yt-dlp -U`. Os ajustes globais não duplicam as escolhas de mídia.
- Clipboard: uma leitura no arranque a frio e uma leitura quando a janela ganha foco. Se o texto for uma URL `http(s)` nova nesta sessão, uma faixa no topo oferece sondar. Sem histórico, sem loop de polling, sem URL que não seja URL.
- Binário ausente: estado bloqueante com seletor de caminho e uma dica curta de instalação. Não baixa o binário pelo app.
- Playlist grande: sondar a contagem e exigir confirmação antes de enfileirar. O caminho principal é o vídeo único.
- Erro do extrator em linguagem simples, com log copiável. O caso de uso devolve código estável. A frase pt-BR mora no ARB do `gen-l10n`, não num mapa solto em Dart.
- Fila, perfis e ajustes sobrevivem a reinício em JSON no diretório de suporte do aplicativo.
- Testes de unidade do montador de seletor, do planejador de união, da contenção de caminho e da máquina de estados, com processo falso. Sem rede. Um teste de widget só para a regra da faixa. O binário real fica no passe manual de desktop, inclusive cancelar no meio do merge e unir duas partes compatíveis.

### Fora de escopo

- **Estúdio de conversão de arquivo local (fase 2).** Se o clipboard ou o drop for um arquivo existente (`mp3`, `mp4`, `webm`, `avi`, `mpg`, `mkv`, `m4a`), a fase 1 responde “Conversão ainda não disponível”. Uma URL de mídia (`https://…/arquivo.mp4`) continua sendo download. A união de partes de playlist **não** é esse painel e **não** espera a fase 2: é a ação do pai do grupo, limitada a concatenar saídas já baixadas daquela leva.
- **Share / Open with / Services do SO (fase 2).** macOS Share Extension ou Services, alvo esparso de compartilhamento no Windows, MIME `.desktop` no Linux. Entrada de link na fase 1: colar, arrastar e a faixa. “Revelar na pasta” (saída) é fase 1 e não se confunde com share de entrada. Nenhum PR da fase 1 implementa share, nem o interruptor. Quando a fase 2 existir, o share só começa o download sem faixa se o ajuste `shareAutoStart` estiver ligado. O default desse ajuste é desligado. A fase 1 não grava a chave.
- **Listas salvas de links** além da fila e de um histórico simples de concluídos. O grupo de playlist não é uma biblioteca: vive na fila e no histórico do mesmo JSON.
- **Flutter Web e telefone.** O sandbox do browser não gera processo. Não há porte WASM realista de Python + extratores + ffmpeg. Não vamos desenhar servidor remoto de download.
- SponsorBlock, editor de capítulos (além dos capítulos gerados na união), sincronização de conta, player embutido.
- Empacotar yt-dlp ou ffmpeg.
- Drift/SQLite, GetIt, `CupertinoApp`, download silencioso ao abrir na fase 1. A faixa de clipboard nunca baixa sozinha. O auto-start do share fica para a fase 2 e só com o interruptor, default desligado.
- Perfil padrão por host. Ideia de fase 1.5, fora do schema v1 e do primeiro corte de PRs.
- Um processo `yt-dlp` só para a playlist inteira. Continua rejeitado.

### Costura que não pode fechar

Os casos de uso moram em `application/` e dependem de portas. Um adaptador HTTP futuro, só em `127.0.0.1` com segredo compartilhado, chamaria os mesmos casos de uso. A UI Flutter desktop é um adaptador. Nada de regra de formato, de fila ou de argumento ffmpeg dentro de widget. A fonte `MediaSource` é um tipo selado (`RemoteUrl` | `LocalFile`) para a fase 2 pendurar conversão sem reclassificar URL de mídia como arquivo local.

## Desenho proposto

### Linguagem visual

Toolkit: `MaterialApp` com Material 3 como biblioteca de widgets, não como casca de telefone. Isso não é `CupertinoApp`. Proibido na fase 1: `CupertinoNavigationBar`, tab bar inferior, `FloatingActionButton` como ação primária, `Drawer` no lugar da lateral, controles que dependem de polegar.

Tokens, em `lib/design/`:

| Token | Valor |
| --- | --- |
| Grade | 8. Espaços 8, 16, 24, 32. |
| Raio de painel | 12. Raio de controle (campo, chip, botão) 10. |
| Lateral | 220 lógicos, persistente, não colapsa em overlay na largura mínima. |
| Janela mínima | 960 × 640. Abertura sugerida 1200 × 760. |
| Acento | Um só. Claro `#1F6F8B`, escuro `#7FCBE0`. O roxo `Colors.deepPurple` do contador sai junto com o arquivo. |
| Neutros | Superfície e texto via `ColorScheme` derivado do brilho da plataforma, com os papéis de superfície ajustados para painel, não para cartão de feed. |
| Tipo | Título de janela 20/28, título de seção 17/24, corpo 14/20, meta 12/16. Peso regular e semibold apenas. |
| Fonte | macOS: fonte do sistema (`fontFamily` nulo). Linux e Windows: Inter empacotada (OFL), pesos 400 e 600, arquivo de licença junto do asset. |
| Movimento | 120–180 ms, `Curves.easeOut`. Sem bounce, sem hero que atravessa a janela. |
| Densidade | Alvo de ponteiro. Hit target mínimo 28 lógicos na lateral; botão primário 32 de altura. |

Tema claro e escuro seguem `MediaQuery.platformBrightnessOf`. Não há interruptor manual na fase 1.

`cupertino_icons` sai do `pubspec.yaml` quando nenhum import restar. Ícones: `Icons` do Material, usados com parcimônia. Não são a voz visual.

Chrome, no espírito do Finder / Music:

```text
+------------------------------------------------------------------+
|  barra de ferramentas: seção, estado dos binários, atalho       |
+-----------+------------------------------------------------------+
|  Fila     |  faixa de clipboard (só se houver oferta)           |
|  Concluídos|  compositor: campo de URL + soltar                  |
|  Perfis   |  cartão de metadados depois da sondagem             |
|  Ajustes  |  grupo expansível da playlist, ou lista simples     |
+-----------+------------------------------------------------------+
```

A primeira tela da Fila, com fila vazia, é a zona de soltar mais o campo de URL e o estado das dependências. Estado vazio diz o que fazer em uma frase e oferece uma ação.

O tamanho mínimo não espera o pacote `window_manager`. O PR 1 grava 960 × 640 nos três runners:

- `macos/Runner/MainFlutterWindow.swift`: `window.contentMinSize = NSSize(width: 960, height: 640)`.
- `linux/runner/my_application.cc`: `gtk_window_set_default_size` na abertura e `gtk_widget_set_size_request` de 960 × 640 como mínimo.
- `windows/runner/win32_window.cpp`: no `WM_GETMINMAXINFO`, `ptMinTrackSize` 960 × 640.

`window_manager` entra só no PR da faixa, para o callback de foco. Não é a fonte do tamanho mínimo.

O título da janela, em todos os sistemas, é `AppIdentity.displayName`, cujo valor é `DV Max`. O pacote continua `dv_max_easy`. O bundle id continua `marcussoftware.info.dvMaxEasy`. O executável não é renomeado. No macOS, `CFBundleDisplayName` também fica `DV Max`, para a barra de menus não mostrar o nome do pacote. `PRODUCT_NAME` no `AppInfo.xcconfig` permanece `dv_max_easy`.

Atalhos no PR 1, com `Shortcuts` e `CallbackShortcuts` (Command no macOS, Control nos outros). Ações cuja feature ainda não existe ficam ligadas a um `Intent` que o provider ignora até o PR correspondente registrar o handler. O mapa não espera o último PR.

| Atalho | Ação |
| --- | --- |
| Cmd/Ctrl+L | Foco no campo de URL |
| Cmd/Ctrl+Enter | Baixar o cartão atual, se a sondagem terminou |
| Cmd/Ctrl+, | Ajustes |
| Cmd/Ctrl+1…4 | Fila, Concluídos, Perfis, Ajustes |
| Cmd/Ctrl+. | Cancelar o job em foco |
| Esc | Dispensar a faixa de clipboard |

Não há download disparado pelo clipboard no arranque. A faixa nunca dispara o processo sozinha. Jobs que já estavam `queued` no disco ocupam vaga no arranque; isso está na máquina de estados, não é auto-start de clipboard.

### Classificação da entrada

Um único lugar, `ClassifyInput`, devolve o resultado. Clipboard, campo e drop usam a mesma função. Comparação de extensão é insensível a maiúsculas.

| Entrada | Resultado |
| --- | --- |
| URL `http` ou `https`, inclusive caminho terminado em `.mp4`, `.mp3`, `.webm`, `.avi`, `.mpg`, `.mkv`, `.m4a` | `RemoteUrl`. É download. Userinfo na URL é preservado no argumento do processo e removido do log. |
| Vários `RemoteUrl` num drop ou num colar | Não enfileira o conjunto. O primeiro vai para o campo e para a sondagem / cartão. Os demais ficam numa fila de sessão, só em RAM, e cada um espera a pessoa concluir ou dispensar o cartão anterior. Playlist no meio desse lote ainda pede a confirmação dela. |
| `file://` que resolve para arquivo existente com extensão de mídia da lista acima | `LocalFile`. Faixa “Conversão ainda não disponível”. |
| `file://` de diretório, ou arquivo existente sem essas extensões | Rejeição `not_a_download`. Frase curta, sem sondar. |
| Caminho local absoluto ou `~` que existe, com extensão de mídia | `LocalFile`. A mesma frase da fase 2. |
| Caminho local que não existe | Ignorar. Não é download e não é conversão. |
| Diretório existente | Rejeição `not_a_download`. |
| Texto que não é URL nem caminho | Ignorar. No clipboard, guardar só o SHA-256, nunca o texto. |

`https://user:pass@host/v` é `RemoteUrl`. O yt-dlp recebe a URL intacta, num elemento de argv. O log, com redação ligada, não vê usuário nem senha.

### Fluxo principal

```mermaid
flowchart TD
  entrada["Colar, soltar ou faixa"] --> classificar{"ClassifyInput"}
  classificar -->|arquivo local| fase2["Conversão ainda não disponível"]
  classificar -->|rejeição| ocioso["Sem sondagem"]
  classificar -->|http ou https| deps{"yt-dlp e ffprobe ok?"}
  deps -->|não| setup["Estado bloqueante de configuração"]
  deps -->|sim| flat["Sondagem flat, teto de 8 MiB"]
  flat --> tipo{"O que voltou?"}
  tipo -->|vídeo único, ou playlist com 1 item resolvido| cheio["-J com --no-playlist na URL do vídeo"]
  tipo -->|playlist com 2 ou mais| confirmar["Confirmação com a contagem"]
  tipo -->|JSON acima de 8 MiB ou acima de 500 itens| recusa["Não enfileira"]
  confirmar -->|cancela| ocioso
  confirmar -->|confirma| grupo["Grupo + um job por item, -f só do perfil"]
  cheio --> cartao["Cartão + chips de perfil e de faixa"]
  cartao --> baixar["Ação Baixar"]
  baixar --> fila["Job queued"]
  grupo --> fila
  fila --> rodar["Até N processos yt-dlp"]
  rodar --> unir{"Leva terminal e ao menos 2 concluídos?"}
  unir -->|sim| acao["Pai oferece Unir na ordem da playlist"]
```

Vídeo único é o caminho sem diálogo. Playlist com 2 ou mais entradas pede confirmação. De 200 a 500 entradas a confirmação exige um checkbox (“Entendo que são N itens”), com foco inicial em Cancelar. Acima de 500 entradas o botão de enfileirar fica desligado; a frase diz o teto. O mesmo teto vale para jobs não terminais na fila inteira (`queued`, `running`, `postprocessing`, `interrupted`): se a leva não cabe, nada daquela leva é gravado.

Se o stdout flat passar de 8 MiB, o processo é morto, o JSON parcial é descartado e nada é enfileirado. Não usamos “quantidade desconhecida” para criar job sem entrada. “Quantidade desconhecida” só aparece quando o JSON completo parseou, `playlist_count` veio vazio e mesmo assim `entries` tem tamanho conhecido: a contagem usada é `entries.length`. Se `entries` não veio, não há o que enfileirar.

URL `watch` com `list=` no query, no caminho de vídeo único, usa `--no-playlist` na sondagem completa. Isso não cobre playlist de um item só cujo URL é a página da lista. Esse caso está no algoritmo abaixo.

### Algoritmo de enfileirar playlist

A sondagem flat é uma chamada, não N sondagens completas. Custo de N vezes `-J` não é o desenho.

1. Rodar o comando flat da seção de comandos, com teto de 8 MiB e timeout de 60 s.
2. Se o tipo não for playlist, ou se a playlist tiver exatamente uma entrada: resolver a URL canônica dessa entrada (passos 4a–4d). Se a entrada não existir e o URL original já for um vídeo, sondar o original com `--no-playlist`. Se for playlist de um item, sondar **a URL da entrada** com `--no-playlist`, nunca o URL da playlist sem esse flag (o `-J` da playlist é um objeto playlist, sem formatos de vídeo). Seguir o cartão de vídeo único. Sem grupo.
3. Se houver duas ou mais entradas e a confirmação passar nos tetos: criar um `PlaylistGroup` com o título flat (`title` da playlist, ou o URL se o título vier vazio) e a pasta de destino resolvida naquele instante.
4. Para cada entrada, na ordem do array `entries`:
   - 4a. Se `url` for `http` ou `https` absoluto, essa é a URL do job.
   - 4b. Senão, se `webpage_url` for `http` ou `https` absoluto, usar essa.
   - 4c. Senão, se o host da playlist for YouTube e `url` ou `id` casar `^[A-Za-z0-9_-]{11}$`, usar `https://www.youtube.com/watch?v=` mais esse id. Host YouTube, em minúsculas e sem ponto final: é `youtube.com`, termina em `.youtube.com` (`www.youtube.com`, `m.youtube.com`, `music.youtube.com`), é `youtu.be`, ou termina em `.youtu.be`. O id de 11 caracteres vale tanto no campo `id` quanto quando o flat põe só o id em `url`.
   - 4d. Senão, criar o filho já em `failed`, código `entry_url_unresolved`, sem processo e sem argv. O grupo conserva o buraco. A união pula esse índice e cita o título.
   - Título do job: `title` da entrada, senão o id, senão a URL. É cópia. A frase da união usa essa cópia.
   - `playlistIndex` 1-based, na ordem do array. A união usa esse número, não a ordem em que os processos terminaram.
   - `-f` sai do perfil snapshotted, sem `format_id` de nenhum item. A função pura recebe `tracks: const []` e os idiomas do perfil. Não há segunda sondagem por item.
5. Gravar argv de cada filho no enqueue, como na seção do snapshot. O grupo guarda, do mesmo instante, `container`, `destinationFolder`, `maxBitrateKbps` (nulo se o perfil não tinha) e `maxHeight` (null em “melhor” e em só áudio; 1080 ou 720 nos outros presets). Nada disso é relido do perfil vivo na hora de unir.

Testes de fixture, sem rede: JSON flat de duas entradas (uma com `url` absoluta, outra só com `id` do YouTube) produz dois jobs nessa ordem e nenhum `format_id` no `-f`. Outra fixture: webpage `https://www.youtube.com/playlist?list=EXAMPLE` e uma entrada cuja `url` é só o id de 11 caracteres, sem `webpage_url`; a URL do job é `https://www.youtube.com/watch?v=` mais esse id, e não há `-J` por item. O helper de host aceita `m.youtube.com` e `music.youtube.com` e rejeita `youtube.com.evil`. URL de playlist com uma entrada faz a sondagem completa na URL resolvida da entrada, com `--no-playlist` presente e o URL da playlist ausente dessa segunda chamada.

### Perfis e o cartão

Depois da sondagem de um vídeo, o cartão mostra miniatura, título, canal, duração e chips de faixa de áudio. O chip inicial é o idioma preferido do perfil se ele existir na lista; senão o fallback; senão a faixa que o JSON marca como original/default, se houver; senão a primeira faixa de áudio. A pessoa pode trocar antes de Baixar. Essa troca vale para aquele job; não reescreve o perfil salvo a menos que ela edite o perfil.

Miniatura, uma regra só, também na seção de segurança: a URL tem de ser `https` e tem de ser exatamente uma das URLs em `thumbnails` daquele `ProbeReport`. O widget é `Image.network`. Não há outro `HttpClient` no app para buscar mídia ou imagem. `Image.network` pode seguir redirecionamento; não vamos escrever um cliente para impedir isso. Se a URL não cumprir a regra, o cartão não mostra imagem.

O perfil guarda a preferência (`ja`, depois `pt`, por exemplo), não um `format_id` de um vídeo específico. O `format_id` entra no seletor do job de vídeo único porque a sondagem daquele URL o conhece. Playlist não reutiliza o `format_id` do primeiro item.

Escada de qualidade, um campo só, mais três opcionais separados. “Taxa” são os três, e nenhum substitui o outro:

| Preset | Efeito |
| --- | --- |
| Melhor | Sem teto de altura |
| 1080p | `height<=1080` no vídeo |
| 720p | `height<=720` |
| Só áudio | `-x` e `--audio-format` `mp3` ou `m4a` |

| Campo | Flag | Validação |
| --- | --- | --- |
| Bitrate máximo, kbps | filtro `tbr` no vídeo, ou `--audio-quality ${kbps}K` no só áudio | inteiro positivo ou nulo |
| Limite de download | `-r` | nulo, ou `2m` normalizado para `2M` |
| Fragmentos concorrentes | `-N` | nulo, ou inteiro de 1 a 16 |

`-N` nulo não entra no argv. O yt-dlp fica com o próprio default. Valor fora de 1–16 é erro de formulário, não é gravado. O intervalo é o que ainda ajuda sem abrir dezenas de conexões por item. Os três campos entram no snapshot do job.

Sugestão de contêiner no texto de ajuda, não um bloqueio: MKV quando o vídeo for VP9/AV1 ou o áudio for Opus; MP4 quando vídeo H.264 e áudio AAC. Se a pessoa insistir em MP4 com Opus, passamos `--merge-output-format mp4` e deixamos o yt-dlp/ffmpeg falarem. Não usamos `--recode-video` na fase 1. Reencodar na união da playlist é outra ação, confirmada, e não usa `--recode-video` do yt-dlp.

Legendas no perfil: lista de idiomas, modo `nenhuma` | `embutir` | `arquivo separado`, e um interruptor “incluir automáticas”, default desligado.

- Embutir: `--embed-subs` e `--sub-langs`. Válido para mp4, webm e mkv. Em perfil só áudio o formulário recusa esse modo.
- Arquivo separado: `--write-subs`, `--sub-langs`, e não passa `--embed-subs`.
- Nenhuma: nenhum flag de legenda.
- Sempre que o modo não for `nenhuma`, o argv leva `--convert-subs` `srt`. Não é campo de perfil. É escolha fixa da fase 1 para o arquivo de legenda ter um formato só.
- `--sub-langs` recebe os códigos com `.*` (`pt.*,en.*`). Com automáticas desligadas, o mesmo argumento termina em `,-live_chat`. Com automáticas ligadas, não acrescentamos filtro que jogue fora `*-orig`; live chat continua de fora.

Pasta do perfil nula significa “usar a pasta padrão global” no momento de enfileirar. O caminho resolvido entra no argv gravado no job. Mudar o ajuste depois não move item já na fila.

Se `profiles.json` ainda não existe, o primeiro arranque grava os dois perfis da tabela e aponta `selectedProfileId` para Filmes. Um URL solto é mais vezes vídeo do que extração de áudio, então o cartão já pode baixar sem a pessoa criar um perfil. Se o arquivo já existe e a pessoa apagou um dos dois, o arranque não recria sozinho. O botão na seção Perfis passa a ser “Restaurar este modelo” e só aparece quando não há perfil com aquele `name`. Restaurar grava de novo os campos da tabela, com id novo. Se `selectedProfileId` não aponta para um perfil vivo, a escolha cai em Filmes se esse nome existir, senão em Música, senão Baixar fica desabilitado.

| Campo | Música | Filmes |
| --- | --- | --- |
| `name` | Música | Filmes |
| `destinationFolder` | null | null |
| `mediaKind` | `audio` | `video` |
| `container` | `mp3` | `mkv` |
| `preset` | `audio` | `h1080` |
| `preferredAudioLanguages` | `[]` | `["ja", "pt"]` |
| `audioFallback` | `any` | `any` |
| `subtitleLanguages` | `[]` | `["pt"]` |
| `subtitleMode` | `none` | `embed` |
| `includeAutoSubtitles` | false | false |
| `maxBitrateKbps` | null | null |
| `rateLimit` | null | null |
| `concurrentFragments` | null | null |
| `filenameTemplate` | `%(title)s [%(id)s].%(ext)s` | `%(title)s [%(id)s].%(ext)s` |

Esses são os valores do semeio e do restaurar. A pessoa edita em seguida. `ja` / `pt` em Filmes ilustram a dor de faixa; não são uma decisão de que todo filme é japonês. `concurrentFragments` nulo omite `-N`.

Fase 1.5, não implementar agora: mapa host → `profileId`. A chave não existe no schema v1.

### Clipboard

`ClipboardPort.readText()` é chamado de dois pontos apenas:

1. Depois do primeiro frame do arranque a frio.
2. No foco da janela (`window_manager`, callback de foco). Não há `Timer`.

No macOS, se a API expuser o `changeCount` do pasteboard, guardamos só o inteiro e pulamos a leitura do texto quando o contador não mudou. Nos outros sistemas, lemos o texto no foco e comparamos em memória.

Regras, depois de `ClassifyInput`:

- Não-URL: hash SHA-256 em RAM, nunca o texto, nunca o log.
- URL já oferecida nesta sessão (aceita ou dispensada): não oferecer de novo. O conjunto guarda a URL normalizada só em RAM.
- `LocalFile`: faixa informativa de fase 2, sem sondar.
- `RemoteUrl`: faixa “Sondar”, que preenche o compositor e segue o fluxo normal. Não enfileira sozinha.
- A faixa não é modal. Esc ou o fechar dispensa. Dispensar uma oferta de união de playlist é outra UI e não usa esta faixa.
- Ajuste global desliga a leitura por completo.
- Log não recebe clipboard.

Normalização para dedupe: trim, remover aspas em volta, scheme e host em minúsculas. A query permanece. Não reescrevemos o URL que vai para o yt-dlp além do trim.

### Binários ausentes

Enquanto `yt-dlp` ou o par ffmpeg/ffprobe não passarem na checagem, a janela inteira é o estado de configuração. Não dá para sondar por baixo. Merge, extração de áudio, legenda e união de playlist chamam `ffprobe` ao lado do ffmpeg. ffmpeg sozinho não basta.

Checagem do caminho, disparada pela pessoa e uma vez ao abrir se já houver caminho salvo:

- O caminho foi escolhido por ela, ou apareceu na busca confirmada. Não há varredura silenciosa de `~/Downloads`, `/tmp`, `%TEMP%` nem da pasta de destino.
- Seguir symlinks até o alvo. O alvo final tem de ser arquivo regular. Link quebrado e diretório são recusados. No POSIX o alvo final precisa do bit de execução. Script com `+x` é aceito: o `yt-dlp` do Homebrew em `/opt/homebrew/bin/yt-dlp` costuma ser symlink para script, e esse é o caminho de exemplo deste documento.
- O caminho resolvido não pode cair dentro de Downloads, do temporário do SO, nem da pasta de destino dos downloads. Isso continua valendo depois de seguir o link.
- Rodar `[binário, "--version"]` com lista de argumentos e timeout de 5 s. A primeira linha é a versão mostrada.
- ffmpeg só é aceito se, no mesmo diretório do alvo resolvido, existir `ffprobe` (ou `ffprobe.exe`) que também passe na mesma checagem de arquivo regular executável. Senão a mensagem é explícita: o pós-processo e a união vão falhar sem o ffprobe.

“Procurar no PATH” não assume o PATH de um app aberto pelo Finder ou pelo Dock. No macOS esse PATH muitas vezes não tem `/opt/homebrew/bin`, então `brew install yt-dlp ffmpeg` seguido só de `which` falha. A busca, quando a pessoa pede, olha nesta ordem e não executa nada até a confirmação:

- Cada diretório do `PATH` do ambiente do processo.
- macOS, a mais: `/opt/homebrew/bin`, `/usr/local/bin`.
- Linux, a mais: `/usr/local/bin`, `/usr/bin`.
- Windows, a mais, só se existirem: `%LOCALAPPDATA%\Microsoft\WinGet\Links`, `%ProgramFiles%\yt-dlp`, `%ProgramFiles%\ffmpeg\bin`, e `%ChocolateyInstall%\bin` quando a variável existir.

A UI lista o caminho encontrado. Grava só depois que a pessoa confirma. `where` e `which` também são listas de argumentos, nunca shell, e não são a única fonte.

Dica curta, uma linha por SO, sem virar tutorial:

- macOS: `brew install yt-dlp ffmpeg`
- Windows: `winget install yt-dlp.yt-dlp Gyan.FFmpeg` ou o binário oficial
- Linux: pacote da distro ou o binário oficial do yt-dlp, mais ffmpeg do distro

`yt-dlp -U` é um botão nos Ajustes. Timeout 60 s. Sucesso e recusa do gerenciador de pacote aparecem no mesmo painel. A versão exibida é a de `--version`, relida depois. Instalações de pacote que recusam `-U` não são falha fatal.

### Fila, grupo e máquina de estados

Um job é um vídeo. Playlist confirmada vira um `PlaylistGroup` mais N jobs com o mesmo `groupId`, na ordem da lista, não um processo único de playlist. Cancelar, progresso e retry ficam por item. A concorrência global (default 2, intervalo permitido 1–4) limita quantos estão em `running` ou `postprocessing`.

```mermaid
stateDiagram-v2
  [*] --> queued: gravado na fila
  queued --> running: há vaga, inclusive no arranque
  queued --> cancelled: removido antes de começar
  running --> postprocessing: evento postprocess
  running --> completed: Exit 0 e dest válido
  running --> failed: Exit diferente de zero, ou dest inválido
  running --> cancelled: cancelar
  postprocessing --> completed: Exit 0 e dest válido
  postprocessing --> failed
  postprocessing --> cancelled
  running --> interrupted: processo morreu com o app
  postprocessing --> interrupted: processo morreu com o app
  failed --> queued: tentar de novo
  interrupted --> queued: tentar de novo
  cancelled --> [*]
  completed --> [*]
```

A transição de arranque não está desenhada como mágica à parte: ao carregar o JSON, quem está `running` ou `postprocessing` é reescrito para `interrupted` antes de o escalonador olhar vagas. Quem está `queued` permanece `queued` e pode ir para `running` assim que houver vaga, no mesmo arranque. No mesmo load, `join.state == running` vira `failed` com `join_interrupted`: o ffmpeg morreu com o app e não é religado. Se `join.partialPath` existir e o arquivo tiver nascido nesta tentativa (mtime ou birth time maior ou igual a `join.startedAt`), apagar esse parcial. `join.outputPath` fica nulo. Isso não é download disparado pelo clipboard. O `AGENTS.md` proíbe download silencioso ao abrir no sentido da faixa, não no sentido de abandonar uma fila que a pessoa já confirmou.

No arranque não retomamos processo morto. Retry de `failed` ou `interrupted` volta a `queued` e usa o argv snapshotted. O yt-dlp continua arquivo parcial se ele ainda estiver na pasta temporária do destino. Não há timeout de stall na fase 1.

`Exit` é o único sinal de `completed` ou `failed`. Linha `finished` do progresso não completa o job. Evento `postprocess` move `running` para `postprocessing` e nada mais. Exit 0 com `dest:` ausente, repetido ou fora da pasta é `failed`, código `output_dest_missing` ou `output_outside_destination`, sem “revelar”.

Histórico é a mesma lista filtrada por `completed`. Teto de 500 concluídos; os mais antigos saem do JSON. Job não concluído não entra nesse despejo. Teto à parte: no máximo 500 jobs nos estados `queued`, `running`, `postprocessing` e `interrupted`, somados. Passou disso, o enqueue recusa com `queue_full`. Grupo não é o 501º job; conta pelos filhos.

Progresso na UI: o notificador coalesça a 2 Hz. Velocidade e ETA vêm dos campos do evento. ETA ausente aparece como “—”.

### Snapshot de argv e retry

No enqueue o caso de uso monta a lista de argumentos do yt-dlp, sem o executável e sem o par `--ffmpeg-location`. Essa lista é gravada no job (`argv`). Entram nela, e não são relidos do perfil vivo: `--no-warnings`, `--newline`, `--progress`, `--progress-delta`, os dois `--progress-template` (download e postprocess), `--convert-subs`, `-r`, `-N` quando `concurrentFragments` não é nulo, template, `-x`, `--audio-format`, `--audio-quality`, `-P`, `-o`, `-f`, `--audio-multistreams` quando couber, `--no-mtime` e `--print` `after_move:dest:%(filepath)s`. Sem os templates de progresso o parser não vê bytes, então eles não ficam de fora do exemplo de `jobs.json`.

Na hora de rodar, inclusive no retry e depois de `interrupted`:

- `argv[0]` efetivo é o `ytDlpPath` **atual** dos ajustes.
- `--ffmpeg-location` recebe o `ffmpegPath` **atual**, inserido pela infra ao spawnar. É a única exceção relida de ajustes, para um caminho corrigido valer no retry sem reabrir a escolha de faixa.
- O resto sai do snapshot. Editar ou apagar o perfil não muda `-f`, `-P`, legendas, `-r` nem `-N` de um job já gravado. Se o perfil não tinha fragmentos, o argv não ganha `-N` depois.

O teste da máquina de estados cobre isso: falha, altera o perfil (outro `-f`, outra pasta, outro `-r`), retry, e o argv observado no fake é o original, exceto os dois binários. O mesmo assert exige que a lista snapshotted ainda contenha `--newline`, `--progress`, `--progress-delta` e os dois `--progress-template`.

Apagar perfil não apaga jobs. Job novo é que exige perfil vivo. `profileName` no job é cópia para o histórico.

### União da playlist

Decisão de produto, fechada. Não é conversão de arquivo arbitrário.

A oferta existe quando, e só quando:

- `join.state` não é `running` (no load, `running` já virou `failed`);
- o grupo tem pelo menos dois filhos em `completed`, cada um com `outputPath` que passou na contenção de download;
- todo filho está em `completed`, `failed` ou `cancelled` (ninguém em `queued`, `running`, `postprocessing` ou `interrupted`);
- nenhum arquivo de filho `completed` ainda está aberto por um processo nosso. Na prática o estado `completed` já implica `Exit` e contenção feita; um retry tira o filho de `completed`, e a oferta some até a leva terminar de novo.

Dispensar a oferta grava `joinOfferDismissed: true` e esconde o convite inline. O item de menu do pai, **Unir na ordem da playlist**, continua enquanto a condição acima for verdadeira. Unir de novo gera outro arquivo com nome livre; não apaga a união anterior nem os filhos.

A ordem é `playlistIndex` crescente, só entre os `completed` com saída válida. Filho `failed`, `cancelled` ou `entry_url_unresolved` é pulado. A nota `join_skipped` lista cada índice 1-based e o `title` daquele job (“2 — Nome da aula”). Título vazio cai para só o número. Isso não é falha: se o ffmpeg sair 0, `join.state` fica `done` e `errorCode` fica nulo. Se não houver dois concluídos, a ação não aparece; não há união de um arquivo só.

O arquivo unido fica na `destinationFolder` do grupo, snapshotted no enqueue. O nome é o título da playlist sanitizado (sem `/`, `\`, `..`, quebras de linha; trim; no máximo 120 caracteres; se esvaziar, `playlist`) mais a extensão do `container` do grupo. Se o nome existir, tentar ` - união`, depois ` - união 2` até 20. Arquivo existente só ocupa o nome: não vira união concluída. União concluída é só `join.state == done` com `join.outputPath` apontando para ela. Se todos os nomes existirem, `join_target_exists`, sem sobrescrever. `-n` no ffmpeg, não `-y`.

Antes do spawn, gravar no JSON `join.state = running`, `join.startedAt` e `join.partialPath` (o caminho escolhido). `join.outputPath` continua nulo até o sucesso. Os filhos permanecem no grupo. Só o último sucesso fica em `join.outputPath`. Uniões anteriores continuam no disco, na pasta do grupo; o app não as apaga e não as revela.

Cancelar, exit diferente de zero, ou o reparo de arranque: apagar `partialPath` se o arquivo existir e a data de nascimento (birth time, ou mtime se o SO não tiver birth time) for maior ou igual a `startedAt`. Se não der para apagar, `errorCode` `join_partial_left` e `outputPath` nulo. Não deixar o parcial como se fosse união pronta.

Compatibilidade para stream copy, via ffprobe, na ordem dos streams de cada arquivo incluído. A lista inteira tem de ser igual, não só o primeiro vídeo e o primeiro áudio:

- mesma quantidade e a mesma ordem de `codec_type`;
- em cada stream, o mesmo `codec_name`;
- vídeo: também `width`, `height`, `avg_frame_rate` como string racional (`30000/1001` não é `30/1`) e `pix_fmt`;
- áudio: também `sample_rate`, `channels` e `channel_layout` (ausente casa com ausente);
- legenda: entra na lista; uma legenda a mais já é divergência;
- qualquer outro `codec_type` também entra, com `codec_name`.

Se as listas casam, o plano é o concat demuxer com `-c copy`. Esse modo conserva faixas extras e legendas, porque elas já eram iguais, e a lista de arquivos vai para um arquivo, não para o argv. Se alguma lista divergir, o app mostra as diferenças e não spawna até a pessoa confirmar o reencode. O reencode **não** usa `-f concat`: o demuxer de concat não decodifica e falha justo quando codec ou tamanho diferem. O caminho confirmado continua sendo um filtro `concat=n=…`, um `-i` por arquivo, escala e resample para um alvo só. O texto do filtro vai para um arquivo UTF-8 no diretório de suporte, passado com `-filter_complex_script`. A saída tem no máximo um vídeo e um áudio. Faixas de áudio além da primeira e legendas não são preservadas; o diálogo diz isso. Cancelar a confirmação não muda os filhos. O diálogo é modal de propósito. A faixa de clipboard continua não modal.

No Windows, `CreateProcess` recusa uma linha de comando a partir de 32767 caracteres, já contando o NUL final. O gráfico fora do argv não basta: 500 vezes `-i` mais um caminho ainda estoura. Por isso o reencode no Windows aceita no máximo 100 partes concluídas, e mesmo abaixo disso o app mede a linha quotada (executável, cada `-i`, o script, o ffmeta e a saída) e não spawna se o comprimento for maior que 32766. Os dois casos marcam `join.state` `failed` com `spawn_failed`, sem processo. A ação do pai continua disponível. Stream copy de até 500 partes não usa esse teto, porque o demuxer lê a lista do arquivo. No macOS e no Linux o teto de 100 não existe; se a soma dos argumentos passar de `ARG_MAX` menos 4096, o mesmo `spawn_failed` vale, sem spawn.

Alvo do filtro, a partir da primeira parte incluída que tenha aquele tipo de stream, senão da primeira parte:

- vídeo: largura e altura dessa parte; se `maxHeight` do grupo não for nulo e a altura for maior, reduzir para essa altura com largura par (`scale=-2:maxHeight`). `fps` é o `avg_frame_rate` dessa parte; se vier `0/0` ou vazio, `30`. `format=yuv420p`.
- áudio: `sample_rate` e layout dessa parte (`aformat`). `-b:a` é `192k` se `maxBitrateKbps` do grupo for nulo, senão `${maxBitrateKbps}k`. Os dois campos vêm do grupo, não do perfil vivo.
- parte sem vídeo, quando a saída tem vídeo: `color=c=black` do tamanho e da taxa alvo, duração `format.duration`. Parte sem áudio, quando a saída tem áudio: `anullsrc` com o mesmo layout e duração. Assim o `concat` recebe o mesmo número de entradas.

Duração de capítulo: `format.duration` do ffprobe, em segundos, convertida para milissegundos inteiros. Se alguma parte concluída não tiver duração positiva, a união não inventa capítulo: a pessoa confirma “unir sem capítulos” ou desiste. Sem essa confirmação não há spawn.

Capítulos: um por parte incluída, título daquela parte. Contêineres `mkv`, `mp4` e `m4a` recebem o FFMETADATA como último `-i` e `-map_metadata` nesse índice, nos dois planos (copy e filtro). Em `mp3` o ffmpeg em geral não guarda capítulo; a UI diz isso e segue sem fingir que o mp3 os tem. Título de capítulo perde quebra de linha e escapa `\`, `=`, `;`, `#` e quebra de linha segundo o ffmetadata.

A união é estado no grupo (`idle`, `running`, `failed`, `done`), não um job filho. Cancelar mata a árvore do ffmpeg pela mesma porta `ProcessTree`. O progresso do ffmpeg tem parser próprio, descrito nos comandos. Essas linhas não entram no varredor de JSON do yt-dlp.

Isto não abre o estúdio da fase 2. Não há drop de arquivo local para concatenar, nem escolha livre de codec fora do par “copy se a lista de streams casa / filtro concat confirmado para o contêiner do perfil”.

### Processos

Uma porta `ProcessTree` serve sondagem, download, `yt-dlp -U`, ffprobe e a união. `YtDlp` e o caso de uso da união montam argv e chamam essa porta. Teste usa fake. Produção não usa `Process.start` do Dart, porque ele não cria grupo de processo.

Contrato de spawn, o mesmo para todos:

| Peça | Regra |
| --- | --- |
| Executável | Caminho absoluto já checado. `argv[0]` é esse caminho. O resto é a lista, um elemento por argumento. `shell` não existe. |
| Ambiente | O ambiente do processo Flutter, herdado. Nada de clipboard e nada de segredo novo. |
| Diretório de trabalho | Download e união: a pasta de destino do job ou do grupo, criada antes se faltar, e já contida nela mesma. Sondagem, `--version` e `-U`: o diretório de suporte. |
| stdout / stderr | Dois pipes. O filho não herda o stdout do Flutter. |
| Timeout | Opcional. Estourar chama o mesmo cancelamento e o job fica `failed` com `probe_timeout` ou `update_timeout`, não `cancelled`. Download de mídia não tem timeout. |
| Cancelar antes do pid | Ver abaixo. |
| Grupo | POSIX: grupo novo. Windows: Job Object nosso. Nunca sinalizar o grupo do Flutter. |

POSIX, `dart:ffi` direto em `libSystem` (macOS) e `libc` (Linux), sem pacote de terceiros. Nenhum pacote estável cobre `posix_spawnattr_setpgroup` e `posix_spawn_file_actions_adddup2` nos dois sistemas; o binding mora num arquivo de infra.

1. `pipe` para stdout e `pipe` para stderr. Flag close-on-exec nas pontas do pai.
2. `posix_spawnattr_init`.
3. `posix_spawnattr_setflags` com `POSIX_SPAWN_SETPGROUP`.
4. `posix_spawnattr_setpgroup(attr, 0)`. O pgid do filho fica igual ao pid do filho, não ao grupo do Flutter.
5. `posix_spawn_file_actions_adddup2` da ponta de escrita do pipe de stdout para `STDOUT_FILENO`, e o equivalente para stderr. Fechar as pontas de leitura no filho.
6. `posix_spawn(&pid, path, file_actions, attr, argv, envp)`. O código de retorno já reporta falha de exec. Não há pipe de erro extra.
7. O pai fecha as pontas de escrita e lê as de leitura.
8. Se `posix_spawn` falhar, o job falha com `spawn_failed`. Não há sinal.
9. Gravar o pid e `startedAt` da porta `Clock`. Em seguida `waitpid(pid, &status, WNOHANG)`. Se o filho já tiver saído, esse status é o exit. Não marcar `process_group_failed` e não sinalizar. `--version` e um ffprobe curto podem morrer nessa janela; sucesso continua sucesso.
10. Se ainda estiver vivo, `getpgid(pid)` tem de ser igual a `pid` e diferente de `getpgrp()` do Flutter. `getpgid` com `ESRCH` não é falha de grupo: repetir o `waitpid` com `WNOHANG` e, se saiu, usar o status. Filho vivo ainda no grupo do Flutter: **não** mandar sinal negativo.
11. Identidade para um sinal posterior, enquanto o filho está vivo e o pgid confere: no Linux, campo 22 de `/proc/<pid>/stat` (start time); no macOS, `proc_pidinfo` com `PROC_PIDTBSDINFO` (`pbi_start_tvsec` / `pbi_start_tvusec`). Guardar esse valor. Antes de `SIGTERM` ou `SIGKILL`, reler. Se mudou, o pid foi reusado: não sinalizar. Se a leitura da identidade falhar, não sinalizar no escuro; o cancelamento fica `process_group_failed` sem ter mandado sinal.
12. Só então, se ainda precisarmos matar um filho vivo fora do grupo do app e com a mesma identidade: `SIGKILL` positivo quando o grupo novo não existiu, ou o cancelamento normal abaixo quando existiu. Marcar `process_group_failed` apenas no caso em que o grupo novo não ficou provado.

Cancelar no POSIX: `SIGTERM` para `-pgid` somente depois dos passos 10 e 11, com a identidade ainda igual. Esperar até 2 s pelo exit. Senão `SIGKILL` para o mesmo `-pgid`, de novo só se a identidade não mudou.

Windows, pacote `win32` (bindings de `kernel32`), no PR do `ProcessTree`:

1. `CreateJobObject`.
2. `SetInformationJobObject` com `JOBOBJECT_EXTENDED_LIMIT_INFORMATION` e `JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE`. Esse flag é o cinto se o app morrer. Não é o cancelamento explícito.
3. Pipes de stdout e stderr com `SetHandleInformation` para as pontas do pai não serem herdadas.
4. `CreateProcessW` com `CREATE_SUSPENDED | CREATE_NO_WINDOW`, handles de std herdados, `CREATE_BREAKAWAY_FROM_JOB` quando o host já estiver num job. Se o breakaway falhar, seguir o fallback.
5. `AssignProcessToJobObject(job, process)`. Se falhar, fallback.
6. `ResumeThread` só depois do assign bem sucedido.
7. Cancelar: `TerminateJobObject(job, 1)`. Esperar o processo. Fechar o handle do job **depois** do exit. Fechar o handle não substitui `TerminateJobObject` enquanto o handle ainda é nosso.

Fallback Windows, só se o Job Object não ficou dono do processo: `taskkill.exe` em `GetSystemDirectory()`, não um `taskkill` achado no PATH. Argumentos: o caminho absoluto, `/PID`, o pid decimal, `/T`, `/F`. Antes, `OpenProcess` e `GetProcessTimes`: o creation time tem de ser o gravado no spawn. Se o pid foi reusado, não chamar taskkill. Não há `cmd.exe`.

Corrida de cancelar antes do pid, por job id, sob um lock:

- `cancel` com processo ainda nulo grava `cancelRequested` e volta.
- `start` olha a flag antes de spawnar. Se já estiver pedida, não spawna e o estado fica `cancelled`.
- O pid só é publicado ainda dentro do lock, no retorno de `posix_spawn` / `ResumeThread`. Se a flag ligou nesse meio, o cancelamento roda antes de qualquer evento de progresso ser entregue à fila.

Sondagem grande: se o stdout de `-J` passar de 256 KiB e estiver abaixo do teto de 8 MiB, o parse roda em `Isolate.run`. O limiar de 256 KiB é só para não travar a UI. O teto de 8 MiB é o que recusa a playlist. Os dois números ficam nomeados em `core`.

Escrita de `jobs.json`: debounce de 500 ms e escrita atômica (arquivo `.tmp` no mesmo diretório, `rename`). Estado terminal grava na hora.

### Comandos concretos

Binário ilustrativo. Na vida real o caminho vem dos ajustes, e no retry o caminho pode ser outro sem trocar o resto.

Sondagem barata de contagem:

```text
/opt/homebrew/bin/yt-dlp
  -J
  --flat-playlist
  --no-warnings
  --socket-timeout 20
  https://www.youtube.com/playlist?list=EXAMPLE
```

Sondagem completa de um vídeo:

```text
/opt/homebrew/bin/yt-dlp
  -J
  --no-playlist
  --no-warnings
  --socket-timeout 20
  https://www.youtube.com/watch?v=EXAMPLE
```

`-J` já simula e não baixa mídia. Timeout do processo: 45 s para vídeo, 60 s para flat.

Download de vídeo único, 1080p, áudio japonês com fallback, MKV, legendas pt embutidas, limite `2M`. Os ids `137` e `251` são os da sondagem daquele URL e já terão passado na allow-list:

```text
/opt/homebrew/bin/yt-dlp
  --no-warnings
  --newline
  --progress
  --progress-delta 0.5
  --progress-template
  download:{"event":"download","status":"%(progress.status)s","downloaded":"%(progress.downloaded_bytes|)s","total":"%(progress.total_bytes|)s","total_estimate":"%(progress.total_bytes_estimate|)s","speed":"%(progress.speed|)s","eta":"%(progress.eta|)s","id":"%(info.id)s"}
  --progress-template
  postprocess:{"event":"postprocess","status":"%(progress.status)s","postprocessor":"%(progress.postprocessor|)s"}
  --ffmpeg-location
  /opt/homebrew/bin/ffmpeg
  -P
  /Users/me/Movies/Filmes
  -o
  %(title)s [%(id)s].%(ext)s
  --merge-output-format
  mkv
  -f
  137+251/bv*[height<=1080]+ba[language^=ja]/bv*[height<=1080]+ba/b[height<=1080]
  --embed-subs
  --sub-langs
  pt.*,-live_chat
  --convert-subs
  srt
  -r
  2M
  --no-mtime
  --print
  after_move:dest:%(filepath)s
  https://www.youtube.com/watch?v=EXAMPLE
```

O `|` no template é tentativa de default vazio. Não está provado que funcione em campo `progress.*`. O parser trata string vazia, ausência e o literal `NA` como “sem número”. Os testes cobrem os três.

Contrato do `--print`, para fixture: o yt-dlp corta no primeiro `:`. `after_move` é o WHEN. O template é `dest:%(filepath)s`. Uma linha de stdout inteira, depois do split em `\n` e `\r`, que case `^dest:(.+)$`, é o caminho. Não se parte JSON no primeiro `:`.

Duas faixas no mesmo arquivo:

```text
-f
137+251+140/bv*[height<=1080]+ba[language^=ja]+ba[language^=en]/bv*[height<=1080]+ba[language^=ja]/bv*[height<=1080]+ba
--audio-multistreams
```

Sem `--audio-multistreams` o yt-dlp descarta as faixas de áudio além da primeira. O flag só entra com duas ou mais faixas pedidas. Não ligamos `--video-multistreams`.

Item de playlist, sem id de formato, japonês com fallback, mesmo perfil de filme:

```text
-f
bv*[height<=1080]+ba[language^=ja]/bv*[height<=1080]+ba/b[height<=1080]
```

Só áudio, mp3, japonês, **sem** bitrate máximo no perfil. `--audio-quality 0` aqui significa “melhor” do extrator lossy, e só nesse caso:

```text
/opt/homebrew/bin/yt-dlp
  --no-warnings
  --newline
  --progress
  --progress-delta 0.5
  --progress-template
  download:{"event":"download","status":"%(progress.status)s","downloaded":"%(progress.downloaded_bytes|)s","total":"%(progress.total_bytes|)s","total_estimate":"%(progress.total_bytes_estimate|)s","speed":"%(progress.speed|)s","eta":"%(progress.eta|)s","id":"%(info.id)s"}
  --ffmpeg-location
  /opt/homebrew/bin/ffmpeg
  -x
  --audio-format
  mp3
  --audio-quality
  0
  -f
  251/ba[language^=ja]/ba
  -P
  /Users/me/Music
  -o
  %(title)s [%(id)s].%(ext)s
  --no-mtime
  --print
  after_move:dest:%(filepath)s
  https://www.youtube.com/watch?v=EXAMPLE
```

Só áudio com `maxBitrateKbps` 192. O flag já aceita bitrate. Não existe tabela 0–10:

```text
-x
--audio-format
mp3
--audio-quality
192K
-f
ba[language^=ja]/ba
```

`m4a` com bitrate nulo também leva `--audio-quality` `0`. Com bitrate preenchido, leva `${kbps}K`, igual ao mp3. Bitrate de vídeo continua sendo filtro `[tbr<=N]` no termo de vídeo, aproximação, campo diferente de `-r`.

Arquivo de legenda separado, no lugar do par de embed:

```text
--write-subs
--sub-langs
pt.*,-live_chat
--convert-subs
srt
```

ffprobe, antes da união, um arquivo por vez:

```text
/opt/homebrew/bin/ffprobe
  -v
  error
  -show_entries
  format=duration:stream=index,codec_name,codec_type,width,height,avg_frame_rate,pix_fmt,sample_rate,channels,channel_layout
  -of
  json
  /Users/me/Movies/Filmes/parte 1.mkv
```

Lista do concat demuxer, só no plano `-c copy`. Arquivo temporário no diretório de suporte, UTF-8, um `file` por parte na ordem do `playlistIndex`. O demuxer trata `\` como escape, então cada caminho é escrito com barra `/`, inclusive no Windows: `C:\Users\me\Movies\Aula 1.mkv` vira `C:/Users/me/Movies/Aula 1.mkv`. A linha gravada não contém barra invertida. Aspas simples no caminho viram `'\''`. Caminho com quebra de linha é recusado. Exemplo POSIX e o equivalente Windows:

```text
file '/Users/me/Movies/Filmes/Aula 1.mkv'
file '/Users/me/Movies/Filmes/Aula 2.mkv'
file 'C:/Users/me/Movies/Aula 1.mkv'
```

Fixture do PR 8: o caminho `C:\Users\me\Movies\Aula 1.mkv` é assertado como `file 'C:/Users/me/Movies/Aula 1.mkv'`, sem `\U` nem `\f` literais.

FFMETADATA, tempos acumulados em milissegundos, título já escapado:

```text
;FFMETADATA1
[CHAPTER]
TIMEBASE=1/1000
START=0
END=123456
title=Aula 1
[CHAPTER]
TIMEBASE=1/1000
START=123456
END=250000
title=Aula 2
```

Stream copy, quando o plano disse que os streams casam:

```text
/opt/homebrew/bin/ffmpeg
  -hide_banner
  -nostats
  -progress
  pipe:1
  -n
  -f
  concat
  -safe
  0
  -i
  /Users/me/Library/Application Support/.../join-list.txt
  -i
  /Users/me/Library/Application Support/.../join-chapters.ffmeta
  -map
  0
  -map_metadata
  1
  -c
  copy
  /Users/me/Movies/Filmes/Nome da playlist.mkv
```

`-safe 0` só porque os caminhos são absolutos e foram escritos por nós depois da contenção. Não vem de string da pessoa.

Reencode, só depois do diálogo, duas partes de vídeo com tamanho ou codec diferentes. Não há `-f concat` nem o arquivo de lista do demuxer. O filtro decodifica, escala e junta. O gráfico inteiro mora em `join-filter.txt` (UTF-8, sem BOM, diretório de suporte). O argv leva `-filter_complex_script` e nunca `-filter_complex`. O FFMETADATA é o último input (índice 2 aqui):

```text
/opt/homebrew/bin/ffmpeg
  -hide_banner
  -nostats
  -progress
  pipe:1
  -n
  -i
  /Users/me/Movies/Filmes/Aula 1.mkv
  -i
  /Users/me/Movies/Filmes/Aula 2.mkv
  -i
  /Users/me/Library/Application Support/.../join-chapters.ffmeta
  -filter_complex_script
  /Users/me/Library/Application Support/.../join-filter.txt
  -map
  [v]
  -map
  [a]
  -map_metadata
  2
  -c:v
  libx264
  -crf
  20
  -preset
  veryfast
  -c:a
  aac
  -b:a
  192k
  /Users/me/Movies/Filmes/Nome da playlist.mkv
```

O arquivo `join-filter.txt` contém só o gráfico, por exemplo `[0:v:0]scale=1920:1080:flags=bicubic,setsar=1,fps=30000/1001,format=yuv420p[v0];[1:v:0]scale=1920:1080:flags=bicubic,setsar=1,fps=30000/1001,format=yuv420p[v1];[0:a:0]aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo[a0];[1:a:0]aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo[a1];[v0][a0][v1][a1]concat=n=2:v=1:a=1[v][a]`.

`192k` é o default. Se o grupo tem `maxBitrateKbps` 160, `-b:a` é `160k`. MP4 acrescenta `-movflags` `+faststart`. Só áudio usa `concat=n=…:v=0:a=1`, um `-map [a]`, e `-c:a` `libmp3lame` ou `aac` conforme o contêiner; não leva `-c:v`. MP3 não leva o ffmeta como se capítulo fosse garantido. Parte sem trilha de vídeo entra como `color=c=black:s=1920x1080:r=30000/1001:d=12.5`, não como `[n:v:0]`.

Antes do spawn o app monta a linha de comando como o Windows a vê: argumentos separados por um espaço, cada um entre aspas se tiver espaço ou estiver vazio, mais o caminho do executável. Se essa linha tiver mais de 32766 caracteres, ou se no Windows houver mais de 100 partes, o caso de uso devolve `spawn_failed` e não chama `CreateProcess`. Cem caminhos de 260 caracteres mais os flags fixos ficam abaixo de 32767; cento e um já é recusa, mesmo com caminho curto. No POSIX a mesma função compara o tamanho dos argv com `ARG_MAX` menos 4096 e não aplica o teto de 100.

O teste do PR 8, com divergência confirmada, exige `-filter_complex_script` apontando para o arquivo cujo conteúdo tem `concat=n=`, e exige a ausência de `-filter_complex` e do par `-f` / `concat`. Outra fixture monta 100 caminhos Windows de 200 caracteres: a linha quotada fica abaixo de 32767 e o gráfico não aparece no argv. Uma terceira, com 101 partes no Windows, devolve `spawn_failed` e não spawna. Listas de streams iguais exigem `-f concat` e `-c copy`, e exigem a ausência de `-filter_complex` e de `-filter_complex_script`. Stream copy de 500 partes não cai no teto de 100.

Progresso do ffmpeg, parser só da união, lendo o pipe de `-progress` e nada mais: linhas `chave=valor`. `out_time_ms` é microssegundos, apesar do nome; a UI divide por 1000 antes de comparar com a duração em milissegundos ou de desenhar a barra. `progress=end` não marca `done`. Exit 0, arquivo existente e contenção da união marcam `done`. Exit diferente de zero marca `failed` e apaga o parcial como acima. Essas linhas não passam no varredor de JSON do yt-dlp.

### Parser de progresso

Stdout e stderr são pipes separados.

- stderr: UTF-8 com substituição, split em `\n` e em `\r`. Cada pedaço não vazio é `LogLine`. Nunca é progresso e nunca é `dest:`.
- stdout: o mesmo split, para um progresso que tenha vindo só com CR. Pedaço vazio sai fora.
- Em cada pedaço de stdout, nesta ordem:
  1. Se o pedaço inteiro casa `^dest:(.+)$`, é `Destination`. Não é JSON.
  2. Senão, um varredor extrai objetos JSON de topo. Ele anda caractere a caractere, respeita string e escape, e conta chaves. Cada objeto completo vira evento, em ordem. Texto antes, entre ou depois vira `LogLine`. Isso cobre `}{` colado do template `postprocess` (yt-dlp issue 7193) sem partir no primeiro `{` de uma frase. Objeto que não fecha naquele pedaço é `LogLine`; não há buffer entre linhas na fase 1.
  3. Objeto com `event` igual a `download` é `Progress`. `postprocess` é `Postprocess`. Outro JSON é `LogLine`.
- `bytesTotal`: inteiro de `total` se o campo existir, não for vazio e não for `NA`. Senão o mesmo para `total_estimate`. Senão null. `downloaded`, `speed` e `eta` seguem a mesma leitura. `status` `downloading` atualiza bytes. `finished` no evento de download não completa o job. `error` no progresso vira `LogLine` e o job espera o `Exit`.
- A UI coalesça a 2 Hz. O fake do teste não coalesça: cada evento chega.
- Linha `out_time_ms=` ou `progress=` do ffmpeg da união não entra neste varredor. O runner da união tem o parser descrito nos comandos.

Fixtures do PR da fila, texto de stdout/stderr gravado no teste:

- caminho feliz com `total` preenchido;
- `total` vazio e `total_estimate` preenchido;
- literal `NA` sem o default ter funcionado;
- dois objetos `postprocess` colados por `}{`;
- uma linha `dest:/tmp/exemplo.mkv`;
- aviso não JSON no stdout e uma frase `ERROR:` no stderr, esta última só `LogLine`;
- um pedaço terminado em `\r` sem `\n`.

### Montador de seletor

Função pura em `features/downloads/domain`, sem Flutter e sem IO. Entrada: preset, bitrate opcional, faixas escolhidas já ordenadas (cada uma com `formatId` e `language` opcionais), `fallbackToAnyAudio`, tipo de mídia. Saída: string `-f`, booleano `audioMultistreams`, e os argumentos de extração de áudio (`-x`, `--audio-format`, `--audio-quality`) quando couber.

Allow-list, antes de interpolar qualquer coisa vinda do JSON:

- Idioma, depois de minúsculas: `^[a-z0-9]{2,8}(-[a-z0-9]{1,8})*$`.
- `format_id`: `^[A-Za-z0-9._-]{1,64}$`.

Se o idioma falhar, ele não vira filtro; o chip mostra o rótulo cru. Se o `format_id` falhar, o termo usa `bv*` ou `ba`, não o id. `und`, vazio e `original` não viram filtro, como já não casam a allow-list de idioma útil para `language^=`. Isso não é RCE: argv continua sendo uma lista. Evita um `-f` que muda de significado porque o extrator mandou `ja]/ba` ou um id com `+`.

Algoritmo, vídeo:

1. Termo de vídeo: `bv*` mais `height<=H` se o preset não for “melhor”, mais `tbr<=N` se houver bitrate. Se a sondagem escolheu um `format_id` de vídeo compatível com o preset e a allow-list, o primeiro termo usa esse id.
2. Para cada faixa de áudio escolhida, termo `formatId` se conhecido e válido, senão `ba[language^=code]` se o código passou na allow-list.
3. Se uma faixa: `video+audio / videoGenerico+ba[language^=code] / videoGenerico+ba / b` com o teto de altura no `b` quando houver.
4. Se várias: `video+a1+a2+…` e os fallbacks na mesma ordem, `audioMultistreams = true`.
5. Se `fallbackToAnyAudio` for falso, omitir os termos `+ba` sem idioma.
6. Playlist passa `tracks` vazio e os idiomas do perfil no lugar das faixas sondadas. Nenhum id de outro vídeo entra.
7. Só áudio: não há termo de vídeo. `-x` e `--audio-format` são argumentos à parte. `--audio-quality` é `0` se `maxBitrateKbps` for nulo, ou `${kbps}K` se não for.

O chip mostra o rótulo cru (`ja-JP`, ou “idioma não informado”) junto do codec (`opus`, `mp4a`).

Template de nome, na validação do perfil: rejeitar vazio, mais de 180 caracteres, `/`, `\` ou `..`. Não aceitar caminho absoluto. O destino é sempre `-P`. O yt-dlp ainda pode limpar separador dentro de `%(title)s`; a contenção abaixo é o que impede um título que vira `..`.

`--windows-filenames` entra só no Windows. Não ligamos `--restrict-filenames` por default.

### Contenção de caminho

“Filho da pasta” não é prefixo de string. `/Users/me/Movies-evil` não está dentro de `/Users/me/Movies`.

1. Tornar a pasta do job, ou a pasta do grupo no caso da união, absoluta e resolver symlinks (`FileSystemEntity.resolveSymbolicLinks`). Se a pasta não resolver, falhar antes do spawn.
2. Download: no fim do processo, exigir exatamente uma linha `dest:`. Zero ou duas ou mais: `failed`, código `output_dest_missing`, `outputPath` nulo, sem revelar. União: não existe linha `dest:`. O caminho é o que foi posto no argv do ffmpeg (`partialPath`). Exit 0 sem o arquivo nesse caminho é `failed` da união, não `output_dest_missing`.
3. Tornar esse caminho absoluto. Resolver symlinks no ancestral mais profundo que já existe e acrescentar o resto dos componentes, sem normalizar `..` para dentro. O arquivo pode existir nessa hora; a checagem não depende de string crua.
4. Calcular o caminho relativo da pasta resolvida até a saída resolvida, por componente, não por `startsWith`. No Windows, comparar sem distinguir maiúsculas e ignorando separador final.
5. Falhar com `output_outside_destination` se o relativo for `.` (a própria pasta), for absoluto, tiver componente vazio, ou tiver **qualquer** componente `..`, mesmo no meio (`ok/../../fora.mkv`). Não oferecer revelar.
6. Os passos 1 e 3–5 valem para a união. O passo 2 não: a união não lê `dest:`.

Testes: prefixo `Movies-evil`; `-P` que é symlink para fora da pasta lexical; `dest:` ausente com exit 0; duas linhas `dest:`; título que o template de impressão devolve como `..`; relativo `ok/../../fora.mkv`; no Windows, diferença de maiúsculas e barra final. A união, no PR 8, testa exit 0 no caminho escolhido sem nenhuma linha `dest:`.

### Erros

O caso de uso e o domínio devolvem código. A frase pt-BR fica em `lib/l10n/app_pt.arb`, uma chave por código, gerada pelo `gen-l10n` desde o PR 1. Não há segundo ARB. O log integral continua copiável ao lado da frase. Enquanto o PR do arquivo de log não entrou, o buffer de `LogLine` daquele job, em memória, já é o que o botão copia.

| Código | Quando | Frase no ARB pt-BR |
| --- | --- | --- |
| `video_unavailable` | stderr contém `Video unavailable` ou `Private video` | Este vídeo não está disponível. |
| `extractor_challenge` | `Sign in to confirm` ou bot check | O site pediu uma verificação que o yt-dlp não conseguiu passar. |
| `ffmpeg_missing` | stderr de ffmpeg não encontrado, ou a checagem inicial | O ffmpeg não foi encontrado no caminho configurado. |
| `ffprobe_missing` | sem ffprobe ao lado do ffmpeg | Falta o ffprobe na mesma pasta do ffmpeg. Sem ele o yt-dlp não fecha o arquivo e a união não roda. |
| `unsupported_url` | `Unsupported URL` | Este link não é suportado pelo yt-dlp. |
| `http_rejected` | HTTP 403 ou 429 | O site recusou o download. Tente de novo mais tarde. |
| `probe_timeout` | timeout da sondagem | A sondagem passou do tempo. |
| `entry_url_unresolved` | entrada flat sem URL canônica | Não deu para achar o link deste item da lista. |
| `output_dest_missing` | `dest:` ausente ou repetido | O yt-dlp terminou sem informar um único arquivo de saída. |
| `output_outside_destination` | contenção falhou | O arquivo de saída ficou fora da pasta do perfil. |
| `process_group_failed` | não houve grupo ou job object | Não foi possível isolar o processo para cancelar com segurança. |
| `spawn_failed` | `posix_spawn` ou `CreateProcess` falhou, ou o reencode nem chegou a spawnar porque a linha de comando do Windows passou de 32766 caracteres ou de 100 partes | Não foi possível iniciar o processo. No reencode do Windows, a lista de arquivos não cabe na linha de comando. Unir com stream copy não tem esse teto. |
| `playlist_too_large` | acima de 500 itens ou de 8 MiB | Esta playlist é grande demais para enfileirar de uma vez. |
| `queue_full` | teto de 500 não terminais | A fila já está no limite. |
| `join_skipped` | nota de sucesso, não é `failed`; `join.state` fica `done` se o exit foi 0 | A união deixou de fora: 2 — Nome da aula; 5 — Outro título. |
| `join_interrupted` | `join.state` estava `running` no load | A união foi interrompida quando o app fechou. |
| `join_partial_left` | não deu para apagar o arquivo parcial | Sobrou um arquivo incompleto da união. Ele não conta como pronto. |
| `join_target_exists` | nomes ocupados | Já existe um arquivo unido com esse nome. |
| `extractor_failed` | qualquer outro exit ruim | O yt-dlp não conseguiu concluir este item. |

Cancelamento pedido pela pessoa é estado `cancelled`, não código de erro.

### Camadas e pastas

Alinhado ao `AGENTS.md`. Domínio não importa Flutter nem Riverpod.

```text
l10n.yaml
lib/l10n/app_pt.arb
lib/
  main.dart
  app/
    bootstrap.dart
    router.dart
    window.dart
  design/
    tokens.dart
    theme.dart
    sidebar.dart
    toolbar.dart
    banner.dart
  core/
    app_paths.dart
    clock.dart
    log.dart
    result.dart
    media_source.dart
    limits.dart
  features/
    probe/
      domain/
      application/probe_url.dart
      infrastructure/yt_dlp_probe.dart
      presentation/
    downloads/
      domain/          # Job, PlaylistGroup, FormatSelector, JoinPlan, contenção
      application/     # enqueue, cancel, retry, reveal, join
      infrastructure/  # ProcessTree, parser, jobs json
      presentation/
    profiles/
      domain/
      application/
      infrastructure/
      presentation/
    settings/
      domain/
      application/
      infrastructure/
      presentation/
```

Widget chama um caso de uso exposto por provider. O caso de uso recebe portas no construtor. Infra implementa a porta. Não criamos interface extra para tipo com um único chamador e sem fake de teste.

```mermaid
flowchart LR
  ui["presentation"] --> uc["application"]
  uc --> domain["domain"]
  uc --> ports["portas"]
  infra["infrastructure"] --> ports
  ui --> riverpod["providers Riverpod"]
  riverpod --> uc
  riverpod --> infra
```

### Portas

```dart
abstract interface class Clock {
  DateTime now();
}

abstract interface class ClipboardPort {
  Future<String?> readText();
  Future<int?> readChangeCount();
}

abstract interface class FileReveal {
  Future<void> reveal(String filePath);
}

abstract interface class Log {
  void info(String message);
  void error(String message, {Object? cause});
}

abstract interface class SettingsStore {
  Future<AppSettings> loadSettings();
  Future<void> saveSettings(AppSettings settings);
  Future<ProfileDocument> loadProfiles();
  Future<void> saveProfiles(ProfileDocument document);
  Future<JobDocument> loadJobs();
  Future<void> saveJobs(JobDocument document);
}

abstract interface class ProcessTree {
  Future<RunningProcess> start(SpawnRequest request);
}

final class SpawnRequest {
  final String executable;
  final List<String> arguments;
  final String workingDirectory;
  final Map<String, String> environment;
  final Duration? timeout;
}

abstract interface class YtDlp {
  Future<YtDlpDump> dumpJson(List<String> args, {required Duration timeout});
  Stream<YtDlpEvent> run(String jobId, List<String> args);
  Future<void> cancel(String jobId);
  Future<String> version(String binaryPath);
}
```

`YtDlp.run` recebe a lista já snapshotted e injeta binário e `--ffmpeg-location` atuais. O widget não vê a lista. `YtDlpEvent` é `Progress`, `Postprocess`, `Destination`, `LogLine` ou `Exit`.

`cancel(jobId)` é seguro se o pid ainda não existe: arma a flag e, se o spawn ainda não começou, não começa.

`FileReveal`:

- macOS: `open`, `-R`, caminho do arquivo.
- Windows: `explorer.exe`, `/select,`, caminho, um elemento só.
- Linux: `xdg-open` na pasta pai. Selecionar o arquivo via D-Bus não é confiável; abrir a pasta é o contrato da fase 1 no Linux.

Revelar só é oferecido com `outputPath` que passou na contenção, no filho ou na união.

### Estado com Riverpod

`ProviderScope` na raiz de `main.dart`. Overrides no teste trocam `ytDlpProvider`, `processTreeProvider`, `clipboardPortProvider`, `clockProvider`, `settingsStoreProvider`.

Notifiers:

- `probeControllerProvider`: ocioso, sondando, relatório, erro. Um relatório corrente.
- `queueProvider`: grupos e jobs. Única fonte da fila.
- `profilesProvider`, `settingsProvider`.
- `clipboardOfferProvider`: a oferta atual ou nula. A widget test cobre este provider com clipboard falso.

Não usamos `setState` para nada que viva fora da animação local de um controle. O contador sai com o arquivo inteiro.

Injeção é o grafo de providers. GetIt não entra.

### Companheiro localhost, só como costura

Não construir agora. Quando existir, um processo separado escuta `127.0.0.1` numa porta fixa alta, exige um segredo de 32 bytes gerado no primeiro arranque e guardado no diretório de suporte com permissão 0600, e traduz POST em chamadas aos mesmos casos de uso (`ProbeUrl`, `EnqueueDownload`, `CancelJob`, `JoinPlaylistGroup`). Sem bind em `0.0.0.0`. Sem conta. Sem fila na nuvem. A UI web, se um dia existir, é outro cliente dessa API. O browser continua sem yt-dlp.

### Referência curta de produtos parecidos

Olhamos a interação, não o escopo.

- **yt-dlp** é a fonte dos flags. O app não reimplementa extrator.
- **yt-dlp-gui / Open Video Downloader** mostram tabela de formatos e fila. A tabela completa assusta para a dor de idioma; ficamos nos chips de faixa e no preset.
- **Parabolic** tem fila polida em GTK e opções demais para a fase 1.
- **Downie**, no macOS, é a referência de compositor mais cartão mais ação primária calma. Não copiamos loja, assinatura nem player.

SponsorBlock, fila na nuvem e conversão embutida desses produtos ficam de fora. A união da playlist não copia o estúdio deles: é uma ação, num grupo, com os arquivos que o próprio grupo baixou.

### Riscos

| Severidade | Risco | Mitigação |
| --- | --- | --- |
| Alta | Sandbox do macOS bloqueia o yt-dlp do sistema e a pasta escolhida | Desligar App Sandbox na v1. Mac App Store fica fora. |
| Alta | `language` ou `format_id` suja o `-f` | Allow-list. Rótulo cru no chip. Fallback `bv*` / `ba`. |
| Alta | Sinal no grupo errado mata o app | `setpgroup(0)`. Filho que já saiu (`waitpid` `WNOHANG`) não é falha de grupo. Sinal só com pgid novo e start time igual. |
| Média | JSON de canal enorme | Teto 8 MiB, teto 500 itens, teto 500 jobs não terminais. Parse fora da UI só entre 256 KiB e 8 MiB. |
| Média | Template de progresso com `NA` ou `postprocess` sem newline | Parser com fixture, inclusive `}{` e CR. |
| Média | Template ou symlink escapa da pasta | Contenção por caminho real e relativo, não por prefixo. |
| Média | `yt-dlp -U` falha em pacote do sistema | Mostrar stderr. Versão continua a de `--version`. |
| Média | FFI é código sensível | PR só dele. Fake nos testes de fila. Passe manual: cancelar durante o merge e ver o ffmpeg morto. |
| Média | PATH de app gráfico não vê o Homebrew | Busca confirma `/opt/homebrew/bin` e `/usr/local/bin`, sem executar antes. |
| Média | Dois downloads saturam disco | Default 2, teto 4. |
| Média | Reencode acidental na união | Sem divergência, `-c copy`. Com divergência, diálogo. |
| Média | Reencode de playlist longa estoura `CreateProcess` no Windows | Gráfico em `-filter_complex_script`. Teto de 100 partes e de 32766 caracteres na linha quotada. Acima disso, `spawn_failed` sem spawn. Stream copy não entra nesse teto. |
| Baixa | Faixa de clipboard irrita | Dedupe de sessão, Esc, interruptor global. |
| Baixa | Licença da Inter | OFL no repositório ao lado da fonte. |

Metas de sensação, não SLA de servidor: sondagem de vídeo típico do YouTube em geral 0,5–3 s; a UI mostra ocupado antes de 100 ms. App de um usuário, dois processos yt-dlp, cada um pode ter um ffmpeg filho. A união é um ffmpeg a mais, só enquanto a pessoa pede. JSON de suporte: ajustes e perfis abaixo de 100 KiB; 500 jobs na ordem de 1 MiB, agora com argv. Log no teto de 6 MiB (2 MiB × 3).

## Mudanças de API e de interface

Não há API pública. O que muda é a superfície interna e a dependência do `pubspec.yaml`.

Dependências, versões travadas no PR que as introduzir:

- `flutter_riverpod`, no PR 2, linha estável com `Notifier` / `AsyncNotifier`.
- `path_provider` e `path`, no PR 2.
- `file_selector`, no PR 2, para pasta e executável.
- `win32`, no PR do `ProcessTree`, só para o Job Object e `CreateProcess`. POSIX fica em `dart:ffi`.
- `window_manager`, no PR da faixa, para foco. Tamanho mínimo é nativo e não depende dele.
- `desktop_drop`, no PR da faixa. Se a versão do Flutter desse PR já tiver alvo de drop de primeira parte equivalente, usar esse e não adicionar o pacote.

Saem de uso: `cupertino_icons`, o tema roxo, `MyHomePage`. O PR 1 não tenta fazer o contador analisar.

`main.dart` passa a ser o arranque, arquivo novo:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureWindow();
  runApp(const ProviderScope(child: DesktopApp()));
}
```

| Caso de uso | Efeito |
| --- | --- |
| `ClassifyInput` | `RemoteUrl`, `LocalFile` ou código `not_a_download` |
| `ProbeUrl` | `ProbeReport` ou código de erro |
| `EnqueueDownload` | Um job, ou um grupo mais N jobs, com argv snapshotted |
| `CancelJob` | Árvore morta, estado `cancelled`, seguro se o pid ainda não existe |
| `RetryJob` | `failed` ou `interrupted` voltam a `queued` com o mesmo argv |
| `JoinPlaylistGroup` | Plano copy ou reencode; ffmpeg só depois das regras da união |
| `RevealOutput` | `FileReveal`, só com caminho contido |
| `SaveProfile` / `DeleteProfile` | JSON de perfis |
| `UpdateSettings` | JSON de ajustes |
| `CheckDependencies` | Versões, symlink resolvido, ffprobe |
| `UpdateYtDlp` | Roda `-U` e relê `--version` |
| `ConsiderClipboard` | Oferta ou silêncio |

`ProbeReport` carrega só o que a UI precisa. O JSON cru do último erro pode ir para o log daquele job, não para o documento da fila.

## Mudanças no modelo de dados

Três documentos no diretório que `getApplicationSupportDirectory()` devolver naquele SO. Esse retorno é o contrato. Os caminhos abaixo são exemplos para o passe manual confirmar, não para o código montar na mão:

- macOS, com o plugin atual de foundation: em geral `~/Library/Application Support/marcussoftware.info.dvMaxEasy`, a partir do bundle id.
- Linux: o plugin pode usar o nome do executável e ignorar `APPLICATION_ID` `marcussoftware.info.dv_max_easy` de `linux/CMakeLists.txt`. Não “corrigir” o id criando um segundo diretório.
- Windows: `path_provider` costuma aninhar `CompanyName` e `ProductName`. No `windows/runner/Runner.rc` isso é `marcussoftware.info` e `dv_max_easy`, sob `%APPDATA%`. Não achatar para só o nome do executável.

Não misturar com a pasta de downloads da pessoa.

Por que não Drift: a fase 1 não consulta fila por índice, não faz join de tabela e não passa dos tetos acima. Um arquivo por agregado é inspecionável. A porta `SettingsStore` esconde o formato. Migração é um `switch` no `schemaVersion`. Versão desconhecida: não apagar; renomear para `*.bak-<epoch>` e subir documento vazio, com aviso na UI de que a cópia foi preservada. Esse comportamento nasce no PR 2, com o helper de JSON, não num PR tardio.

### `settings.json`

`uiLanguage` entra no schema v1 porque o `gen-l10n` já existe. O único valor que a UI aplica é `pt-BR`. Outro valor é ignorado e a interface continua em pt-BR. Não há seletor de segundo idioma. `shareAutoStart` não entra neste arquivo na fase 1.

```json
{
  "schemaVersion": 1,
  "defaultDownloadFolder": "/Users/me/Movies",
  "uiLanguage": "pt-BR",
  "ytDlpPath": "/opt/homebrew/bin/yt-dlp",
  "ffmpegPath": "/opt/homebrew/bin/ffmpeg",
  "maxConcurrentDownloads": 2,
  "clipboardPromptEnabled": true,
  "redactUrlsInLog": true,
  "selectedProfileId": "7c9e6679-7425-40de-944b-e07fc1f90ae7"
}
```

`selectedProfileId` no semeio é o id de Filmes. Não há preset de altura, idioma de áudio nem template aqui.

### `profiles.json`

```json
{
  "schemaVersion": 1,
  "profiles": [
    {
      "id": "a31c0b52-6d4e-4a1f-9c88-2f0b6e5d7a10",
      "name": "Música",
      "destinationFolder": null,
      "mediaKind": "audio",
      "container": "mp3",
      "preset": "audio",
      "preferredAudioLanguages": [],
      "audioFallback": "any",
      "subtitleLanguages": [],
      "subtitleMode": "none",
      "includeAutoSubtitles": false,
      "maxBitrateKbps": null,
      "rateLimit": null,
      "concurrentFragments": null,
      "filenameTemplate": "%(title)s [%(id)s].%(ext)s"
    },
    {
      "id": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
      "name": "Filmes",
      "destinationFolder": null,
      "mediaKind": "video",
      "container": "mkv",
      "preset": "h1080",
      "preferredAudioLanguages": ["ja", "pt"],
      "audioFallback": "any",
      "subtitleLanguages": ["pt"],
      "subtitleMode": "embed",
      "includeAutoSubtitles": false,
      "maxBitrateKbps": null,
      "rateLimit": null,
      "concurrentFragments": null,
      "filenameTemplate": "%(title)s [%(id)s].%(ext)s"
    }
  ]
}
```

`preset`: `best` | `h1080` | `h720` | `audio`. `container`: `mkv` | `mp4` | `m4a` | `mp3`. `audioFallback`: `any` | `none`. `subtitleMode`: `none` | `embed` | `file`. `rateLimit` nulo ou, antes de gravar, normalizado para `^[0-9]+(\.[0-9]+)?[KMG]?$` com sufixo maiúsculo. A entrada aceita `k`, `m` e `g` em qualquer caixa (`2m` vira `2M`), porque o `-r` do yt-dlp aceita. `concurrentFragments` é nulo ou um inteiro de 1 a 16. Nulo omite `-N`. `destinationFolder` nulo usa a pasta global no enqueue, e o caminho absoluto fica no argv do job.

O exemplo é o documento que o primeiro arranque grava. Filmes é o selecionado. O argv de exemplo do job não leva `-N` porque esse perfil tem `concurrentFragments` nulo. Se a pessoa gravar 4, o snapshot ganha `-N` e `4`, e o retry repete esse par.

### `jobs.json`

```json
{
  "schemaVersion": 1,
  "groups": [
    {
      "id": "group-1",
      "title": "Nome da playlist",
      "sourceUrl": "https://www.youtube.com/playlist?list=EXAMPLE",
      "profileId": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
      "profileName": "Filmes",
      "destinationFolder": "/Users/me/Movies",
      "container": "mkv",
      "maxBitrateKbps": null,
      "maxHeight": 1080,
      "joinOfferDismissed": false,
      "join": {
        "state": "idle",
        "outputPath": null,
        "partialPath": null,
        "startedAt": null,
        "skipped": [],
        "errorCode": null
      }
    }
  ],
  "jobs": [
    {
      "id": "3b6f1a0e-1d2c-4f55-9a11-0c2d9e8f7a61",
      "groupId": "group-1",
      "playlistIndex": 1,
      "sourceUrl": "https://www.youtube.com/watch?v=EXAMPLE",
      "profileId": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
      "profileName": "Filmes",
      "state": "queued",
      "title": "Título da entrada flat",
      "destinationFolder": "/Users/me/Movies",
      "argv": [
        "--no-warnings",
        "--newline",
        "--progress",
        "--progress-delta",
        "0.5",
        "--progress-template",
        "download:{\"event\":\"download\",\"status\":\"%(progress.status)s\",\"downloaded\":\"%(progress.downloaded_bytes|)s\",\"total\":\"%(progress.total_bytes|)s\",\"total_estimate\":\"%(progress.total_bytes_estimate|)s\",\"speed\":\"%(progress.speed|)s\",\"eta\":\"%(progress.eta|)s\",\"id\":\"%(info.id)s\"}",
        "--progress-template",
        "postprocess:{\"event\":\"postprocess\",\"status\":\"%(progress.status)s\",\"postprocessor\":\"%(progress.postprocessor|)s\"}",
        "-P",
        "/Users/me/Movies",
        "-o",
        "%(title)s [%(id)s].%(ext)s",
        "-f",
        "bv*[height<=1080]+ba[language^=ja]/bv*[height<=1080]+ba/b[height<=1080]",
        "--embed-subs",
        "--sub-langs",
        "pt.*,-live_chat",
        "--convert-subs",
        "srt",
        "-r",
        "2M",
        "--no-mtime",
        "--print",
        "after_move:dest:%(filepath)s",
        "https://www.youtube.com/watch?v=EXAMPLE"
      ],
      "outputPath": null,
      "bytesDownloaded": 0,
      "bytesTotal": null,
      "speedBps": null,
      "etaSeconds": null,
      "errorCode": null,
      "attempt": 1,
      "createdAt": "2026-10-10T12:00:00.000Z",
      "updatedAt": "2026-10-10T12:00:00.000Z"
    }
  ]
}
```

Vídeo único tem `groupId` e `playlistIndex` nulos e não tem grupo. O argv de exemplo omite `--ffmpeg-location` de propósito e inclui os dois `--progress-template`, que o retry repete. `join.state`: `idle` | `running` | `failed` | `done`. `skipped` é a lista da última união, cada item com `index` 1-based e `title`. `outputPath` é só a última união concluída.

O relógio da porta `Clock` preenche os timestamps.

## Alternativas consideradas

### Estado: Riverpod contra Bloc e contra ChangeNotifier

**Riverpod (escolhido).** O `AGENTS.md` já manda. `ProviderScope(overrides:)` é o fake de porta sem container global. `Notifier` cobre fila e ajustes sem classe de evento para cada clique.

**Bloc.** Previsível, mas cada ação vira evento e cada tela um `Bloc`. Para sondar, editar perfil e andar a fila, o boilerplate não paga. Também seria desvio do `AGENTS.md`.

**ChangeNotifier na mão.** Menos dependência, e o contador já ensina `setState`. O grafo fica implícito, override em teste vira singleton, e estado de fila misturado com widget é o que a arquitetura proíbe.

### Persistência: JSON contra Drift e contra um arquivo só

**Três JSON versionados (escolhido).** Volume pequeno, diff legível, sem gerador. Escrita atômica por documento. O de jobs agora guarda grupos e argv; ainda assim é lista, não consulta.

**Drift/SQLite.** Justo quando houver filtro por host, busca no histórico ou muitas milhares de jobs. Até lá é dependência para um problema que `List.where` resolve.

**Um JSON monolítico.** Um crash no meio da gravação da fila corromperia ajustes. Documentos separados limitam o estrago.

### Áudio de um URL: seletor do yt-dlp contra merge nosso

**Seletor e `--audio-multistreams` (escolhido).** O yt-dlp já sabe baixar, juntar faixas e chamar ffmpeg. Um pipeline nosso duplicaria codec e erro de mux. A união de playlist não reabre essa alternativa: ela concatena arquivos prontos, não faz mux de faixas de um URL.

**Baixar faixas com `-f id` e muxar com ffmpeg direto.** Mais controle e mais jeito de divergir do extrator. O yt-dlp consegue expressar a escolha de faixa. Rejeitado.

**`-S lang:ja` sozinho, sem id.** A pessoa não vê qual faixa vai sair. O sort pode ser fallback interno; a escolha visível do vídeo único continua sendo a faixa sondada.

### Playlist: um processo contra um job por item

**Um job por item, mais união explícita no pai (escolhido, decisão da pessoa).** Cancelar o item 12 de 40 não mata o restante. A ordem da lista fica no `playlistIndex`. A concatenação é outra ação, com ffmpeg, quando a pessoa pede. Playlists mistas não viram um arquivo só por acidente.

**Um processo yt-dlp com o URL da playlist.** Mais rápido, progresso e cancelamento grosseiros, e a junção deixa de ser explícita. Rejeitado.

**Concatenar sozinho quando o último filho termina.** Economiza um clique e destrói a escolha de manter as partes. O `AGENTS.md` diz que não há junção automática. Rejeitado.

### Como matar a árvore do processo

**FFI no processo do app (escolhido).** `posix_spawn` com `setpgroup(0)` e pipes via file actions; no Windows, `package:win32` com Job Object e `TerminateJobObject`. O controle dos pipes e do grupo fica no mesmo lugar. O custo é o binding, então ele mora num PR só, antes do cartão e antes da fila. Testes de seletor e de máquina de estados continuam no fake.

**Executável auxiliar de algumas dezenas de linhas que faz `setpgid` e `exec`.** Mais fácil de ler em C, e mais fácil de errar no empacote: três sistemas de build e, no macOS, mais um binário para assinar. O risco de prazo muda de código para release. Não vale na v1.

**Só matar o pid, ou `taskkill /T` como caminho único.** Menor, e perde neto se o ffmpeg ainda não nasceu, ou mata pid reusado. Rejeitado como mecanismo principal. `taskkill` com checagem de creation time fica apenas no fallback em que o Job Object não aceitou o processo.

### Clipboard: faixa contra modal e contra polling

**Faixa no foco e no arranque (escolhido).** Não trava a janela, não grava histórico, não acorda o processo em timer.

**Modal.** Impede usar a fila até dispensar. Contraria o `AGENTS.md`. O diálogo de reencode da união é exceção consciente: a pessoa acabou de pedir uma ação cara.

**Polling a cada segundo.** Lê clipboard o tempo todo. Mais privacidade perdida, sem ganho num app que a pessoa abre para baixar.

### Distribuição do binário

**Sistema, não empacotado (escolhido).** Atualização e tamanho. O estado bloqueante deixa a ausência óbvia. A busca confirma prefixos de Homebrew porque o PATH gráfico não os tem.

**Empacotar yt-dlp e ffmpeg.** Abre e funciona no primeiro clique, e quebra quando o YouTube muda, além do peso do ffmpeg. Fora da v1.

## Segurança e privacidade

Ameaças relevantes para um app local de um usuário. Não há conta, não há servidor nosso, não há segredo de terceiros.

| Ameaça | Tratamento |
| --- | --- |
| Injeção de shell via URL, template ou caminho | Lista de argumentos. Sem `bash -c`. |
| `language` ou `format_id` reescrevendo o `-f` | Allow-list na seção do montador. Fora dela, termo genérico. |
| Executar binário que o clipboard apontou | Caminho só do seletor ou da busca confirmada. Seguir symlink e ainda recusar Downloads, temporário e pasta de destino. |
| Log de clipboard ou de query sensível | Clipboard nunca entra no log. Com `redactUrlsInLog` true (default), a URL perde userinfo (`user:pass@`), perde o fragmento e troca a query por `?…`. Sobram scheme, host e path. |
| SSRF | O app não busca a URL de mídia em Dart. Quem fala com a rede do vídeo é o yt-dlp. Miniatura: só `https` que seja exatamente uma URL de `thumbnails` daquele probe, via `Image.network`, sem segundo cliente. Redirecionamento do widget de imagem é aceito e está escrito aqui para não divergir do cartão. |
| Escape de caminho pelo template, por symlink ou por título `..` | Validação do template, `-P`, e a contenção por caminho real. No download, exit 0 sem `dest:` único não é sucesso. Na união, o caminho é o do argv; qualquer componente `..` no relativo falha. |
| Lista concat apontando para arquivo arbitrário | O app escreve o arquivo de lista só com `outputPath` já contido. `-safe 0` não recebe caminho digitado. |
| Matar processo a mais | Grupo novo ou Job Object nosso. Sem varrer a tabela de processos pelo nome `ffmpeg`. Fallback `taskkill` só com creation time igual. |
| Sandbox macOS | Desligado na v1 nos dois entitlements. Sem isso o desenho não roda. O app tem o mesmo poder do usuário. Aceitável para ferramenta local fora da Mac App Store. Não adicionar `disable-library-validation` para “manter o sandbox”: isso não autoriza executar o Homebrew. |
| Atualizar yt-dlp | `-U` só no binário configurado, a partir do botão. |
| Arquivos JSON | Diretório de suporte. A URL crua no `jobs.json` é escolha explícita: a fila precisa dela para o argv. Não é log. |
| Companheiro futuro | Fora da v1. Loopback e segredo local. |

## Observabilidade

Sem telemetria, sem crash reporter remoto, sem identificador de instalação na v1.

A porta `Log` existe desde o PR 2, antes de qualquer processo. `print` continua proibido. Rotação de arquivo pode esperar o PR de histórico: até lá o logger pode ser em memória mais o buffer de `LogLine` por job, que já alimenta “copiar log”. Quando o arquivo entrar: `logs/app.log` no diretório de suporte, 2 MiB, três arquivos. Cada job pode ter `logs/jobs/<id>.log` com stdout e stderr já redigidos. Apagar o job do histórico apaga esse arquivo.

Linhas úteis: arranque, transição de estado, exit code, falha de parse, exit da união. Não logar argv com URL crua quando a redação está ligada. Nível único na v1.

Não há métrica para servidor. Alerta é a frase do código de erro e o estado bloqueante de binário ausente.

Privacidade do log: default redige query, userinfo e fragmento. Um interruptor nos Ajustes desliga a redação para depurar extrator. Mesmo desligado, clipboard não é logado.

## Plano de entrega

Uma pessoa, três desktops, sem serviço de feature flag. A fase é a entrega.

1. PRs na ordem da seção seguinte. Cada um verde em `flutter analyze` e nos testes daquele corte. O primeiro já substitui o `lib/main.dart` que não analisa.
2. Passe manual antes de chamar a fase 1 pronta, nos três SO se houver máquina; no mínimo macOS mais um entre Linux e Windows, e o terceiro anotado como não visto. Roteiro: binário ausente, apontar o symlink do Homebrew, ver o ffprobe exigido, colar vídeo com duas línguas, escolher a que não é a default, baixar, revelar, cancelar outro no meio do merge e confirmar que o ffmpeg morreu, retry depois de editar o perfil sem mudar o `-f`, playlist curta vira grupo na ordem, unir com stream copy, unir de novo com uma parte de codec diferente só depois do diálogo e conferir que o argv tem `-filter_complex_script` e não `-f concat` nem `-filter_complex`, dispensar a faixa, soltar um mp3 local e ler a mensagem de fase 2, reiniciar com job `running` e ver `interrupted`, reiniciar com `join.state` `running` e ver `failed` sem um ffmpeg novo, e ver um `queued` antigo ocupar vaga. Confirmar no passe o diretório real de `getApplicationSupportDirectory()` nos três SO.
3. Rollback é `git revert` do PR. `schemaVersion` 1 não tem migração anterior. Versão desconhecida vira `.bak`, não parse forçado.
4. `android/`, `ios/` e `web/` permanecem no repositório. Nenhum PR da fase 1 muda comportamento neles.
5. Versão de usuário continua `1.0.0+1` até alguém cortar um release. O título DV Max não muda o bundle id nem o nome do pacote.

Não há auto-update do app Flutter na fase 1.

## Decisões principais

1. **Desktop só na v1.** Alvos: macOS, Linux, Windows. Telefone fora. Web não recebe porte do CLI. A única ponte futura é um companheiro em `127.0.0.1` reusando casos de uso, e ela não será construída agora.
2. **Visual de desktop no espírito do HIG, não Cupertino.** `MaterialApp` restilizado. Sem controle de iPhone. Fonte de sistema no macOS, Inter nos outros. Grade 8, raio 10–12, um acento, claro/escuro da plataforma. Janela mínima 960 × 640, gravada nos três runners no primeiro PR.
3. **yt-dlp e ffmpeg do sistema, não empacotados.** Estado bloqueante se faltarem. ffprobe tem de estar ao lado do ffmpeg. `yt-dlp -U` é explícito e pode falhar em pacote de distro. Symlink de Homebrew é aceito se o alvo for arquivo regular executável.
4. **Sandbox do macOS desligado na v1.** Os entitlements atuais impedem executar o binário do sistema e gravar na pasta escolhida. Mac App Store não é alvo. É desvio consciente do default do template, não do `AGENTS.md`.
5. **Na fase 1, faixa de clipboard, sem histórico, sem polling e sem download disparado por ela ao abrir.** Nenhum PR da fase 1 implementa share. A fase 2 já está decidida à parte: o share de entrada só baixa sem faixa se `shareAutoStart` estiver ligado, e o default é desligado. A fase 1 não cria essa chave nem o interruptor.
6. **Idioma de áudio de um URL via seletor do yt-dlp.** `format_id` e `language` da sondagem, com allow-list, `--audio-multistreams` só com duas ou mais faixas. O app não muxa faixas de um URL. ffmpeg entra aí só como filho do yt-dlp.
7. **URL de mídia é download. Arquivo local é fase 2.** O tipo `MediaSource` guarda a diferença. A fase 1 mostra “Conversão ainda não disponível” para caminho local.
8. **Playlist é grupo expansível, um processo por filho, união só no pai.** Decisão da pessoa, alinhada ao `AGENTS.md` atual. Ordem da lista, sem concatenação automática, partes originais conservadas, stream copy se a lista inteira de streams casa, reencode só depois de confirmar e por filtro `concat` (não pelo demuxer), capítulos com o título de cada parte. Isso é fase 1 e não é o estúdio de conversão.
9. **Riverpod, pastas por feature, JSON no application support.** Sem GetIt, sem Drift, sem Bloc. Perfis são donos das escolhas de mídia e de destino. Ajustes globais não as duplicam. O diretório é o que `getApplicationSupportDirectory()` devolver.
10. **Retry usa o argv gravado no enqueue.** Só o binário do yt-dlp e o `--ffmpeg-location` são relidos dos ajustes. Editar o perfil não muda job já criado.
11. **Job que estava em execução não continua sozinho.** No arranque, `running` e `postprocessing` viram `interrupted` e esperam retry. Job que já estava `queued` ocupa vaga assim que houver slot. Isso não é auto-start de clipboard.
12. **Processo novo em grupo próprio ou Job Object, com pipes, e cancelamento que não sinaliza o app.** FFI no PR dedicado. `taskkill` só como fallback com checagem de creation time. Parse de JSON grande fora da UI, com teto de bytes que recusa a leva.
13. **Qualidade é uma escada (melhor, 1080p, 720p, só áudio) mais três campos opcionais separados:** bitrate máximo, limite `-r` e fragmentos `-N` (inteiro de 1 a 16, omitido quando nulo). No só áudio o bitrate vira `--audio-quality 192K`, não uma nota de 0 a 10. `-N` não se mistura com os outros dois.
14. **Sem telemetria.** Log atrás de porta desde o PR 2. URL redigida por default, inclusive userinfo e fragmento.
15. **Perfis por host ficam na fase 1.5** e não entram no schema v1.
16. **O título visível é DV Max.** Pacote `dv_max_easy` e bundle id `marcussoftware.info.dvMaxEasy` não mudam.
17. **Cópia visível em ARB pt-BR desde o PR 1.** Um locale só. `uiLanguage` default `pt-BR`.
18. **O primeiro arranque semeia Música e Filmes, com Filmes selecionado.**

### Decisões do usuário em 2026-10-10

1. O título da janela é **DV Max**. O pacote continua `dv_max_easy`. O bundle id continua `marcussoftware.info.dvMaxEasy`. `AppIdentity.displayName` é `DV Max`, não o nome do pacote.
2. A localização usa `gen-l10n` desde o PR 1. O único locale embarcado é pt-BR. A cópia visível fica em ARB. Os casos de uso devolvem código; o ARB traduz o código. `settings.json` guarda `uiLanguage`, default `pt-BR`. Não há segundo idioma.
3. “Taxa” são três campos de perfil, separados: bitrate máximo, limite de download (`-r`) e fragmentos concorrentes (`-N`). `-N` é inteiro de 1 a 16. Nulo omite o flag, e o yt-dlp usa o default dele. O valor vai no argv gravado no job.
4. O share de entrada da fase 2 só pode baixar sem faixa se um interruptor de ajuste estiver ligado. O default é desligado. A fase 1 não implementa share, nem o interruptor, nem auto-start. A faixa de clipboard continua pedindo confirmação e não baixa em silêncio.
5. O primeiro arranque semeia **Música** e **Filmes**, com os campos da tabela deste documento. Filmes começa selecionado, porque um URL avulso é mais vezes vídeo do que extração de áudio. Se a pessoa apagar um perfil semeado, o botão correspondente restaura aquele modelo.

## Perguntas em aberto

As cinco perguntas abaixo foram respondidas em 2026-10-10. Não voltam para debate. A união da playlist já estava decidida e não entra nesta lista.

1. **Nome de vitrine. Resolvida.** O título da janela é DV Max. O pacote continua `dv_max_easy`. O bundle id continua `marcussoftware.info.dvMaxEasy`. `AppIdentity.displayName` é `DV Max`.
2. **Idioma da UI. Resolvida.** `gen-l10n` no PR 1, só pt-BR. Frases no ARB. Códigos de erro nos casos de uso. `uiLanguage` no schema v1, default `pt-BR`. Sem segundo idioma.
3. **O que “taxa” quer dizer. Resolvida.** Os três: bitrate máximo, `-r` e `-N`. Campos separados. `-N` de 1 a 16, omitido quando nulo, gravado no argv do job.
4. **Share da fase 2 sem faixa. Resolvida.** Só se o interruptor `shareAutoStart` estiver ligado. Default desligado. A fase 1 não implementa share nem o interruptor. A clipboard da fase 1 continua com faixa.
5. **Semear perfis. Resolvida.** O primeiro arranque grava Música e Filmes. Filmes é o perfil selecionado. O botão de restaurar recria o modelo se ele for apagado.

Pergunta extra, só se a distribuição mudar: se a v1 precisar entrar na Mac App Store, o desenho de binário do sistema cai e este documento tem de ser refeito. Não é o plano atual.

## Referências

- `AGENTS.md` na raiz: fases, união explícita da playlist, UI, portas, JSON, processo sem shell.
- `lib/main.dart`: contador que não analisa (`colorScheme: .fromSeed`, `mainAxisAlignment: .center`), substituído por inteiro no PR 1.
- `pubspec.yaml`: `dv_max_easy`, SDK `^3.13.5`, `publish_to: none`, `cupertino_icons` a aposentar, `flutter_lints` ^6.
- `analysis_options.yaml`: `flutter_lints`, plataformas excluídas do analyzer.
- `macos/Runner/DebugProfile.entitlements`, `macos/Runner/Release.entitlements`, e os `CODE_SIGN_ENTITLEMENTS` no `project.pbxproj`.
- `macos/Runner/Configs/AppInfo.xcconfig`: `PRODUCT_NAME` e bundle id.
- `linux/CMakeLists.txt`: `APPLICATION_ID` `marcussoftware.info.dv_max_easy`.
- `windows/runner/Runner.rc`: `CompanyName` `marcussoftware.info`, `ProductName` `dv_max_easy`.
- yt-dlp: `-J`, `--flat-playlist`, `--no-playlist`, `--newline`, `--progress-template`, `--progress-delta`, `--audio-multistreams`, `--embed-subs`, `--write-subs`, `--sub-langs`, `--convert-subs`, `-x`, `--audio-format`, `--audio-quality`, `--ffmpeg-location`, `-P`, `-o`, `-r`, `-N`, `-U`, `--print after_move:TEMPLATE`.
- yt-dlp issue 7193: template `postprocess` e `--newline`.
- Discussão yt-dlp 4846: por que multistreams é flag explícito.
- ffmpeg: concat demuxer, `-c copy`, FFMETADATA chapters, ffprobe `-show_entries`.
- Inter, SIL Open Font License 1.1, se o asset for empacotado.
- Produtos só como referência de interação: Downie, Parabolic, Open Video Downloader, interfaces gráficas em volta do yt-dlp.

## Plano de pull requests

Cada PR compila, passa em `flutter analyze` e não deixa teste vermelho. Nenhum implementa fase 2. O estúdio de conversão não aparece. A união da playlist aparece no PR 8, como ação do grupo.

### PR 1 — Casca desktop, tamanho mínimo e atalhos

- **Título:** `Casca desktop com tokens, DV Max, gen-l10n e atalhos`
- **Arquivos / componentes:** `lib/main.dart` (arquivo novo, o contador sai inteiro), `lib/app/` (`AppIdentity.displayName` = `DV Max`), `lib/design/`, `l10n.yaml`, `lib/l10n/app_pt.arb`, `test/widget_test.dart` (substituído), `pubspec.yaml` (`flutter: generate: true`, Inter, remover `cupertino_icons` se já não houver uso), `macos/Runner/MainFlutterWindow.swift`, `macos/Runner/Info.plist` (`CFBundleDisplayName` = `DV Max`), `linux/runner/my_application.cc`, `windows/runner/win32_window.cpp`, `macos/Runner/DebugProfile.entitlements`, `macos/Runner/Release.entitlements`, `OFL.txt`.
- **Depende de:** nenhum.
- **Mudança:** Apaga o contador sem remendar `.fromSeed` nem `.center`. Tema claro/escuro, lateral persistente com quatro seções vazias, mínimo 960 × 640 nos três runners, título da janela `DV Max`. Pacote e bundle id intactos. `gen-l10n` com um único ARB pt-BR. Cópias visíveis saem de `AppLocalizations`, não de um `strings.dart`. `Shortcuts` / `CallbackShortcuts` para a tabela de atalhos; handler de baixar e cancelar fica no-op até o PR da fila. Sem processo e sem JSON. Smoke test da lateral, procurando o título DV Max.

### PR 2 — Log, JSON atômico, ajustes e binários

- **Título:** `Porta de log, store JSON e checagem de yt-dlp e ffmpeg`
- **Arquivos / componentes:** `lib/core/` (`Log`, caminhos, relógio, limites), `lib/features/settings/`, `lib/app/bootstrap.dart`, `pubspec.yaml` (`flutter_riverpod`, `path_provider`, `path`, `file_selector`).
- **Depende de:** PR 1.
- **Mudança:** Porta `Log` já usada no lugar de `print`. Helper de escrita atômica. `schemaVersion` desconhecida renomeia para `*.bak-<epoch>`, com teste. `settings.json` schema 1 com `uiLanguage` default `pt-BR` e `selectedProfileId`. Sem seletor de outro idioma e sem chave de share. Tela de ajustes e estado bloqueante. Symlink seguido até arquivo regular executável; script com `+x` passa; link quebrado, diretório, Downloads e temporário não passam. Busca no PATH mais `/opt/homebrew/bin`, `/usr/local/bin` e os equivalentes Windows, gravando só após confirmar. ffmpeg só com ffprobe no mesmo diretório. Teste do validador de caminho com symlink falso e com prefixo `Movies-evil` ainda não é a contenção de saída; é a checagem do binário.

### PR 3 — Perfis

- **Título:** `Perfis semeados, com -r e -N separados`
- **Arquivos / componentes:** `lib/features/profiles/`.
- **Depende de:** PR 2.
- **Mudança:** CRUD em `profiles.json`. Formulário com a escada e os três campos de taxa separados. `rateLimit` aceita `2m` e grava `2M`. `concurrentFragments` aceita nulo ou inteiro de 1 a 16. Se `profiles.json` não existe, grava Música e Filmes com a tabela deste documento e seleciona Filmes. Se a pessoa apagou um nome, o botão restaura aquele modelo e não recria no arranque. Validação de template, de legenda só áudio e de contêiner. Testes do semeio, do não-recriar e do intervalo de `-N`. Sem download. Sem PR de share.

### PR 4 — Árvore de processo

- **Título:** `Spawn com grupo de processo e cancelamento seguro`
- **Arquivos / componentes:** `lib/features/downloads/infrastructure/process_tree_posix.dart`, `process_tree_windows.dart`, `process_tree.dart`, `pubspec.yaml` (`win32`). Domínio não importa FFI.
- **Depende de:** PR 2.
- **Mudança:** O contrato de spawn desta documento: `posix_spawnattr_setpgroup(attr, 0)`, pipes com `adddup2`, ambiente herdado, cwd, timeout, flag de cancelar antes do pid, recusa de sinalizar o grupo do Flutter. Windows: `CreateJobObject`, `SetInformationJobObject`, `CreateProcess` suspenso, `AssignProcessToJobObject`, `ResumeThread`, `TerminateJobObject`. Fallback `taskkill` com caminho de `GetSystemDirectory` e creation time. Teste da corrida cancel-before-pid com um fake do spawn, mais um teste de que pgid igual ao do pai não gera sinal negativo (o binding real não roda no CI). Sem cartão e sem fila. Critério manual de “ffmpeg morreu” fica no PR 6, quando existe merge de verdade.

### PR 5 — Sondagem e seletor

- **Título:** `Sondagem -J, classificação de entrada e seletor de formato`
- **Arquivos / componentes:** `lib/features/probe/`, `lib/core/media_source.dart`, `lib/features/downloads/domain/format_selector.dart`.
- **Depende de:** PR 3 e PR 4.
- **Mudança:** `ClassifyInput` com a tabela deste documento, inclusive drop múltiplo que não enfileira. Comando flat e comando `-J` com `--no-playlist`. Parse fora da UI acima de 256 KiB. Cartão, miniatura só `https` listada no relatório, chips. Baixar ainda não grava job; mostra o argv que seria snapshotted. Testes do montador: 1080p + japonês, só áudio com `--audio-quality 0`, só áudio com `192K`, duas faixas ligando `audioMultistreams`, idioma e `format_id` fora da allow-list, template com `..`. Fixture de playlist flat com duas entradas, de `www.youtube.com` com id cru em `url`, e de playlist com uma entrada (a segunda chamada leva `--no-playlist` na URL do item). Fake de `YtDlp`, sem rede.

### PR 6 — Fila, grupo e parser

- **Título:** `Fila com snapshot de argv, grupo de playlist e parser de progresso`
- **Arquivos / componentes:** `lib/features/downloads/` de aplicação, domínio de job e grupo, parser, `jobs.json`.
- **Depende de:** PR 5.
- **Mudança:** Máquina de estados, inclusive `running`/`postprocessing` → `interrupted` no load, `join.state == running` → `failed` sem spawn, e `queued` livre para ocupar vaga no arranque. Concorrência default 2. Argv snapshotted; retry não vê edição de perfil, com teste que ainda acha `--newline`, `--progress`, `--progress-delta`, os dois `--progress-template` e, quando o perfil tinha fragmentos, o par `-N`. Ausência de `-N` também é assertada quando o campo era nulo. Confirmação de playlist, teto de 500 itens, teto de 8 MiB, teto de 500 não terminais, um job por item na ordem, filho `entry_url_unresolved` sem processo. Parser com as fixtures listadas na seção do parser. Contenção de caminho com os testes do prefixo, do symlink, do `dest:` ausente, do título `..` e de `ok/../../fora.mkv`. Erros por código; copiar log lê o buffer de `LogLine` em memória. Grupo expansível na UI, ainda sem o botão de unir. Critério de saída manual: cancelar no meio do merge do ffmpeg e ver o filho morto.

### PR 7 — Faixa de clipboard e drop

- **Título:** `Faixa de clipboard e soltar URL ou arquivo`
- **Arquivos / componentes:** apresentação da faixa e do drop, `ClipboardPort`, `window_manager`, `desktop_drop` se ainda for necessário.
- **Depende de:** PR 5. Não depende da fila para existir: a faixa só oferece sondar. Com o PR 6 já entrado, continua sem enfileirar sozinha.
- **Mudança:** Leitura no arranque e no foco, dedupe de sessão, hash para não-URL, nenhum log de clipboard, caminho local com a mensagem de conversão, URL de mídia como download. Interruptor dos ajustes passa a valer. Teste de widget: URL nova mostra a faixa; a mesma URL não mostra de novo; texto que não é URL não mostra; modo desligado não mostra; dois URLs soltos não criam dois jobs.

### PR 8 — Unir na ordem da playlist

- **Título:** `Unir partes concluídas da playlist com ffmpeg`
- **Arquivos / componentes:** `JoinPlan` no domínio de downloads, `JoinPlaylistGroup`, apresentação do pai do grupo, argv de ffprobe e ffmpeg na infra. Sem feature nova de conversão.
- **Depende de:** PR 6.
- **Mudança:** Oferta quando a leva está terminal, `join.state` não é `running`, e há pelo menos dois `completed`. Dispensar não remove o menu. Ordem por `playlistIndex`. Pula falhos e cancelados e a nota cita índice e título, com `join.state` `done` se o exit for 0. Partes originais ficam. Arquivo novo na pasta do grupo. Contenção da união olha o caminho do argv, não uma linha `dest:`. Stream copy com concat demuxer, lista em barras `/` e FFMETADATA. Divergência da lista de streams abre o diálogo e só então usa `-filter_complex_script` com o gráfico em arquivo UTF-8 (`concat=n=` dentro do arquivo), sem `-filter_complex` e sem `-f concat`. No Windows, mais de 100 partes ou linha quotada acima de 32766 caracteres devolve `spawn_failed` sem spawn. Capítulo com o título da parte em mkv/mp4/m4a; mp3 avisa que capítulo não fica. `out_time_ms` é dividido por 1000. Cancelar ou falhar apaga o parcial desta tentativa. O caminho unido aparece no pai; o botão de revelar esse arquivo espera o PR 9 e só revela `join.outputPath`. Testes do plano puro: ordem diferente da ordem de término; pulados com título e estado `done`; streams iguais geram `-c copy`; divergência confirmada gera `-filter_complex_script` e não o demuxer; 100 caminhos Windows ficam abaixo de 32767 caracteres e 101 devolve `spawn_failed`; caminho Windows com `\` vira `/` na lista; um único concluído não oferece; filho ainda `running` não oferece; load com `join.state` `running` não spawna.

### PR 9 — Revelar, histórico, rotação e atualização

- **Título:** `Revelar arquivo, histórico, log em disco e yt-dlp -U`
- **Arquivos / componentes:** `FileReveal`, seção Concluídos, botão revelar no pai do grupo e no filho, botão `-U` nos ajustes, logger em arquivo.
- **Depende de:** PR 6 e PR 8.
- **Mudança:** Revelar no Finder, Explorer ou `xdg-open` da pasta, só com caminho contido, tanto a saída do filho quanto `join.outputPath`. Concluídos com teto de 500. Rotação de log e redação de userinfo, query e fragmento. `yt-dlp -U` com a saída visível. Sem share de entrada, sem estúdio de conversão, sem Drift, sem perfil por host. Atalhos não voltam para este PR: nasceram no PR 1.
