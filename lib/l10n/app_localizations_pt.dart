// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'DV Max';

  @override
  String get navQueue => 'Fila';

  @override
  String get navDone => 'Concluídos';

  @override
  String get navLists => 'Listas';

  @override
  String get navConvert => 'Converter';

  @override
  String get navProfiles => 'Perfis';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get queueEmpty => 'Cole ou solte um link para baixar.';

  @override
  String get downloadStart => 'Baixar';

  @override
  String get activeProfile => 'Perfil ativo';

  @override
  String get queueSubtitle =>
      'Baixe vídeos e áudios de redes sociais com facilidade.';

  @override
  String get dropTitle => 'Arraste um link ou cole aqui';

  @override
  String get dropSupport =>
      'Suporta YouTube, Instagram, TikTok, X (Twitter) e mais.';

  @override
  String get downloadsHeading => 'Downloads';

  @override
  String get clearFinished => 'Limpar concluídos';

  @override
  String get mediaVideo => 'Vídeo';

  @override
  String get mediaAudio => 'Áudio';

  @override
  String get moreActions => 'Mais';

  @override
  String statusDownloading(String detail) {
    return 'Baixando… $detail';
  }

  @override
  String statusRemaining(String time) {
    return '$time restante';
  }

  @override
  String get downloadStarting => 'Começando o download…';

  @override
  String get downloadDone => 'Download concluído.';

  @override
  String get downloadFailed => 'O yt-dlp não concluiu este item.';

  @override
  String get downloadCancelled => 'Download cancelado.';

  @override
  String get downloadCancel => 'Cancelar';

  @override
  String get downloadRetry => 'Tentar de novo';

  @override
  String get clipboardOffer => 'Tem um link copiado';

  @override
  String get clipboardDismiss => 'Agora não';

  @override
  String get errFilename =>
      'O nome do arquivo passou do limite do sistema. Tente de novo para baixar com o nome encurtado.';

  @override
  String get errPrivate => 'Esse vídeo é privado.';

  @override
  String get errUnavailable => 'Esse vídeo não está disponível.';

  @override
  String get errLogin => 'O site pediu login ou uma confirmação no navegador.';

  @override
  String get errUnsupported => 'Esse endereço não é suportado.';

  @override
  String get errForbidden => 'O site recusou o download.';

  @override
  String get errExtract => 'Não deu para ler os dados desse link.';

  @override
  String get errFormat =>
      'Esse vídeo não tem o formato do perfil. Tente de novo para baixar o melhor disponível.';

  @override
  String get errFfmpeg => 'O FFmpeg não conseguiu fechar o arquivo.';

  @override
  String get errNetwork => 'A rede falhou no meio do download.';

  @override
  String get errInterrupted => 'O download parou porque o app foi fechado.';

  @override
  String get statusDone => 'Concluído';

  @override
  String get statusFailed => 'Falhou';

  @override
  String get statusCancelled => 'Cancelado';

  @override
  String get fileOpen => 'Abrir';

  @override
  String get fileCopy => 'Copiar';

  @override
  String get fileReveal => 'Abrir pasta';

  @override
  String get fileShare => 'Compartilhar';

  @override
  String get fileCopied => 'Arquivo copiado';

  @override
  String get downloadNeedFolder =>
      'Escolha a pasta padrão em Ajustes antes de baixar.';

  @override
  String get downloadNeedBinary => 'Aponte o yt-dlp e o FFmpeg em Ajustes.';

  @override
  String get urlHint => 'Cole um link de vídeo ou publicação';

  @override
  String get dropHint => 'Solte um link aqui';

  @override
  String get doneEmpty => 'Nada concluído ainda.';

  @override
  String get profilesEmpty => 'Os perfis entram no próximo passo.';

  @override
  String get settingsEmpty => 'Os ajustes entram no próximo passo.';

  @override
  String get binariesPending => 'yt-dlp e FFmpeg ainda não foram verificados.';

  @override
  String binariesReady(String version) {
    return 'yt-dlp $version';
  }

  @override
  String get setupTitle => 'Para baixar, aponte o yt-dlp e o FFmpeg.';

  @override
  String get setupHintMac => 'No macOS: brew install yt-dlp ffmpeg';

  @override
  String get setupHintWindows =>
      'No Windows: winget install yt-dlp.yt-dlp Gyan.FFmpeg';

  @override
  String get setupHintLinux =>
      'No Linux: instale yt-dlp e ffmpeg pelo pacote da distro.';

  @override
  String get ytDlpPathLabel => 'yt-dlp';

  @override
  String get ffmpegPathLabel => 'FFmpeg';

  @override
  String get folderLabel => 'Pasta padrão';

  @override
  String get folderEmpty => 'Nenhuma pasta escolhida';

  @override
  String get binaryEmpty => 'Nenhum arquivo escolhido';

  @override
  String get chooseFile => 'Escolher arquivo';

  @override
  String get chooseFolder => 'Escolher pasta';

  @override
  String get searchPath => 'Procurar';

  @override
  String get confirmPath => 'Usar este caminho';

  @override
  String foundPath(String path) {
    return 'Encontrado: $path';
  }

  @override
  String get concurrentLabel => 'Downloads ao mesmo tempo';

  @override
  String get clipboardLabel => 'Avisar quando houver um link copiado';

  @override
  String get redactLabel => 'Ocultar endereços no log';

  @override
  String get errBrokenLink => 'O caminho é um atalho quebrado.';

  @override
  String get errNotFile => 'O caminho não é um arquivo.';

  @override
  String get errNotExecutable => 'O arquivo não tem permissão de execução.';

  @override
  String get errForbiddenDir =>
      'Esse arquivo está numa pasta que o app não executa.';

  @override
  String get errVersion => 'O programa não respondeu com a versão.';

  @override
  String get errFfprobe =>
      'Falta o ffprobe na mesma pasta do ffmpeg. Sem ele o yt-dlp não fecha o arquivo e a união não roda.';

  @override
  String get errNotFound => 'Não encontrei o programa nesses caminhos.';

  @override
  String get profileNew => 'Novo perfil';

  @override
  String get restoreMusic => 'Restaurar Música';

  @override
  String get restoreFilms => 'Restaurar Filmes';

  @override
  String get profileName => 'Nome';

  @override
  String get presetLabel => 'Qualidade';

  @override
  String get containerLabel => 'Contêiner';

  @override
  String get profileRate => 'Taxa';

  @override
  String get profileFolder => 'Pasta deste perfil';

  @override
  String get presetBest => 'Melhor';

  @override
  String get preset1080 => '1080p';

  @override
  String get preset720 => '720p';

  @override
  String get presetAudio => 'Só áudio';

  @override
  String get rateLimitLabel => 'Velocidade';

  @override
  String get rateLimitHint => 'Ex.: 2M ou 500K. Vazio não limita.';

  @override
  String get fragmentsLabel => 'Fragmentos';

  @override
  String get fragmentsHint => 'De 1 a 16 ao mesmo tempo.';

  @override
  String get bitrateLabel => 'Bitrate máximo';

  @override
  String get bitrateHint => 'Em kbps. Vazio não limita.';

  @override
  String get profileSave => 'Salvar perfil';

  @override
  String get profileDelete => 'Apagar';

  @override
  String get errNameEmpty => 'O perfil precisa de um nome.';

  @override
  String get errAudioEmbed => 'Só áudio não embute legenda.';

  @override
  String get errContainer => 'Esse contêiner não combina com o tipo.';

  @override
  String get errBitrate => 'O bitrate precisa ser um número maior que zero.';

  @override
  String get errRate => 'O limite de velocidade não está num formato aceito.';

  @override
  String get errFragments => 'Os fragmentos ficam entre 1 e 16.';

  @override
  String get errTemplate => 'O nome do arquivo não pode sair da pasta.';

  @override
  String schemaReset(String name) {
    return 'As configurações antigas foram guardadas em $name e o app começou de novo.';
  }

  @override
  String get queuePreviewHint =>
      'A fila mostra os 10 mais recentes. O restante está em Concluídos.';

  @override
  String get doneSearch => 'Pesquisar por nome ou link';

  @override
  String get filterSource => 'Fonte';

  @override
  String get filterProfile => 'Perfil';

  @override
  String get filterType => 'Tipo';

  @override
  String get filterDisk => 'Arquivo';

  @override
  String get filterAll => 'Todos';

  @override
  String get diskPresent => 'Na pasta';

  @override
  String get diskMissing => 'Fora da pasta';

  @override
  String get diskScheduled => 'Com prazo';

  @override
  String get diskPurged => 'Apagados';

  @override
  String get fileMissing =>
      'O arquivo não está mais na pasta em que foi salvo.';

  @override
  String get filePurged => 'O app apagou este arquivo. O histórico fica.';

  @override
  String get downloadAgain => 'Baixar de novo';

  @override
  String get keepFile => 'Manter este arquivo';

  @override
  String get resumeRetention => 'Voltar a apagar no prazo';

  @override
  String deletesIn(String when) {
    return 'Apaga em $when';
  }

  @override
  String downloadedAt(String when) {
    return 'Baixado em $when';
  }

  @override
  String get whenMinute => '1 minuto';

  @override
  String whenMinutes(int count) {
    return '$count minutos';
  }

  @override
  String get whenHour => '1 hora';

  @override
  String whenHours(int count) {
    return '$count horas';
  }

  @override
  String get whenDay => '1 dia';

  @override
  String whenDays(int count) {
    return '$count dias';
  }

  @override
  String get alreadyDownloaded => 'Este link já foi baixado';

  @override
  String get seeCompleted => 'Ver nos concluídos';

  @override
  String get duplicateDismiss => 'Fechar';

  @override
  String get retentionLabel => 'Apagar o arquivo';

  @override
  String get retentionNever => 'Nunca';

  @override
  String get retentionTwo => '2 dias';

  @override
  String get retentionThirty => '30 dias';

  @override
  String get retentionCustom => 'Personalizado';

  @override
  String get retentionDays => 'Dias';

  @override
  String get retentionHint =>
      'Ao abrir, o app apaga o arquivo depois desse prazo. O histórico permanece.';

  @override
  String get errRetention =>
      'O prazo precisa ser um número de dias maior que zero.';

  @override
  String get storageTitle => 'Armazenamento';

  @override
  String storageHistory(int count) {
    return '$count no histórico';
  }

  @override
  String storageOnDisk(int count) {
    return '$count arquivos ainda na pasta';
  }

  @override
  String storageSize(String size) {
    return '$size no disco';
  }

  @override
  String get purgeNow => 'Apagar os que já venceram';

  @override
  String get doneEmptyFilter => 'Nenhum download combina com esses filtros.';

  @override
  String get openLink => 'Abrir no navegador';

  @override
  String get statusIdle => 'Nada baixando';

  @override
  String statusFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos',
      one: '1 arquivo',
      zero: '0 arquivos',
    );
    return '$_temp0';
  }

  @override
  String statusRunningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count baixando',
      one: '1 baixando',
    );
    return '$_temp0';
  }

  @override
  String statusFree(String size) {
    return '$size livres';
  }

  @override
  String statusUsed(String size) {
    return '$size usados';
  }

  @override
  String get cutTitle => 'Cortar vídeo';

  @override
  String get cutOpen => 'Cortar';

  @override
  String get cutHelp =>
      'Tire um trecho do começo, do fim ou do meio. O que sobrar é juntado na ordem. Ou marque um pedaço e fique só com ele.';

  @override
  String get cutRemove => 'Tirar trecho';

  @override
  String get cutFrom => 'De';

  @override
  String get cutTo => 'Até';

  @override
  String get cutKeepOnly => 'Ficar só com este pedaço';

  @override
  String cutKept(String parts) {
    return 'Vai ficar: $parts';
  }

  @override
  String get cutSave => 'Juntar e salvar';

  @override
  String get cutSaving => 'Juntando…';

  @override
  String get cutSaved => 'Corte salvo ao lado do original.';

  @override
  String get cutNeedRange =>
      'Informe um início e um fim. O fim precisa ser depois do início.';

  @override
  String get cutNothing => 'Nada muda se o vídeo ficar inteiro.';

  @override
  String get cutEmpty => 'Esse corte apaga o vídeo inteiro.';

  @override
  String get cutFailed => 'Não foi possível cortar o vídeo.';

  @override
  String get cutNoProbe =>
      'O ffprobe não está ao lado do FFmpeg, então a duração não foi lida.';

  @override
  String get timeHint => '5, 0:20 ou 1:02:03';

  @override
  String get listsEmpty =>
      'Nenhuma lista salva. Guarde links para baixar de novo.';

  @override
  String get listsNew => 'Nova lista';

  @override
  String get listsName => 'Nome';

  @override
  String get listsAdd => 'Adicionar';

  @override
  String get listsUrlHint => 'https://';

  @override
  String get listsDownloadAll => 'Baixar todos';

  @override
  String get listsRemove => 'Tirar';

  @override
  String get listsDelete => 'Apagar lista';

  @override
  String get listsBadUrl => 'Este texto não é um link http ou https.';

  @override
  String get listsDuplicate => 'Esse link já está na lista.';

  @override
  String get listsFull => 'Essa lista chegou ao limite.';

  @override
  String get listsTooMany => 'O limite de listas foi atingido.';

  @override
  String get listsEmptyName => 'A lista precisa de um nome.';

  @override
  String listsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count links',
      one: '1 link',
    );
    return '$_temp0';
  }

  @override
  String get localOffer => 'Tem um arquivo de mídia copiado';

  @override
  String get convertHelp =>
      'Escolha um arquivo local e o formato de saída. O original permanece. O novo arquivo fica na mesma pasta.';

  @override
  String get convertPick => 'Escolher arquivo';

  @override
  String get convertNone => 'Nenhum arquivo escolhido.';

  @override
  String get convertSave => 'Converter';

  @override
  String get convertSaving => 'Convertendo…';

  @override
  String get convertSaved => 'Arquivo convertido ao lado do original.';

  @override
  String get convertFailed => 'Não foi possível converter o arquivo.';

  @override
  String get convertNeedVideo =>
      'Esse arquivo não tem vídeo. Escolha MP3 ou M4A.';

  @override
  String get convertNoBinary => 'Aponte o FFmpeg em Ajustes.';

  @override
  String get installAction => 'Instalar yt-dlp e FFmpeg';

  @override
  String installPackageTitle(String tool) {
    return 'Instalar com $tool';
  }

  @override
  String installPackageBody(String command) {
    return 'O DV Max vai executar, com a sua permissão:\n$command';
  }

  @override
  String get installDownloadTitle => 'Baixar os binários oficiais';

  @override
  String get installDownloadBody =>
      'O gerenciador não está disponível ou não deixou os programas prontos. O DV Max pode baixar o yt-dlp e o FFmpeg oficiais para a pasta do aplicativo.';

  @override
  String get installConfirm => 'Instalar';

  @override
  String get installCancel => 'Agora não';

  @override
  String get installRunning => 'Instalando yt-dlp e FFmpeg…';

  @override
  String get installFailed =>
      'A instalação não terminou. Você pode escolher os arquivos manualmente.';
}
