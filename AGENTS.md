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

## Filosofia de interface

Aparência no espírito do HIG da Apple, em desktop, nos três sistemas. Isso significa hierarquia calma, muito espaço, barra lateral e barra de ferramentas, atalhos de teclado, movimento curto e um acento só.

Não usar `CupertinoApp` nem controles de iPhone. Eles quebram densidade de ponteiro, menu e janela no Windows e no Linux.

SF Pro não pode ser redistribuída. No macOS, fonte do sistema. Nos outros, uma fonte neutra empacotada (Inter ou equivalente), com a mesma escala.

Tema claro e escuro seguem o sistema. Grade de 8. Raio dos painéis entre 10 e 12. Estado vazio explica o que fazer. Erro do yt-dlp aparece em linguagem simples, com o log copiável.

Um link na área de transferência gera uma faixa no topo, não um diálogo que trava a janela. Download silencioso ao abrir fica desligado. Playlists grandes pedem confirmação da quantidade antes de entrar na fila.

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
