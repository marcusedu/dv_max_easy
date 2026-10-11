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
}
