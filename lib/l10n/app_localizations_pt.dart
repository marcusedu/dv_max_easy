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
  String get urlHint => 'Cole um link';

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
  String get errVersion => 'O programa não respondeu a --version.';

  @override
  String get errFfprobe =>
      'Falta o ffprobe na mesma pasta do ffmpeg. Sem ele o yt-dlp não fecha o arquivo e a união não roda.';

  @override
  String get errNotFound => 'Não encontrei o programa nesses caminhos.';

  @override
  String schemaReset(String name) {
    return 'As configurações antigas foram guardadas em $name e o app começou de novo.';
  }
}
