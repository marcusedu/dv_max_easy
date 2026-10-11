import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('pt')];

  /// Título da janela
  ///
  /// In pt, this message translates to:
  /// **'DV Max'**
  String get appTitle;

  /// No description provided for @navQueue.
  ///
  /// In pt, this message translates to:
  /// **'Fila'**
  String get navQueue;

  /// No description provided for @navDone.
  ///
  /// In pt, this message translates to:
  /// **'Concluídos'**
  String get navDone;

  /// No description provided for @navProfiles.
  ///
  /// In pt, this message translates to:
  /// **'Perfis'**
  String get navProfiles;

  /// No description provided for @navSettings.
  ///
  /// In pt, this message translates to:
  /// **'Ajustes'**
  String get navSettings;

  /// No description provided for @queueEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Cole ou solte um link para baixar.'**
  String get queueEmpty;

  /// No description provided for @downloadStart.
  ///
  /// In pt, this message translates to:
  /// **'Baixar'**
  String get downloadStart;

  /// No description provided for @activeProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil ativo'**
  String get activeProfile;

  /// No description provided for @queueSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Baixe vídeos e áudios de redes sociais com facilidade.'**
  String get queueSubtitle;

  /// No description provided for @dropTitle.
  ///
  /// In pt, this message translates to:
  /// **'Arraste um link ou cole aqui'**
  String get dropTitle;

  /// No description provided for @dropSupport.
  ///
  /// In pt, this message translates to:
  /// **'Suporta YouTube, Instagram, TikTok, X (Twitter) e mais.'**
  String get dropSupport;

  /// No description provided for @downloadsHeading.
  ///
  /// In pt, this message translates to:
  /// **'Downloads'**
  String get downloadsHeading;

  /// No description provided for @clearFinished.
  ///
  /// In pt, this message translates to:
  /// **'Limpar concluídos'**
  String get clearFinished;

  /// No description provided for @mediaVideo.
  ///
  /// In pt, this message translates to:
  /// **'Vídeo'**
  String get mediaVideo;

  /// No description provided for @mediaAudio.
  ///
  /// In pt, this message translates to:
  /// **'Áudio'**
  String get mediaAudio;

  /// No description provided for @moreActions.
  ///
  /// In pt, this message translates to:
  /// **'Mais'**
  String get moreActions;

  /// No description provided for @statusDownloading.
  ///
  /// In pt, this message translates to:
  /// **'Baixando… {detail}'**
  String statusDownloading(String detail);

  /// No description provided for @statusRemaining.
  ///
  /// In pt, this message translates to:
  /// **'{time} restante'**
  String statusRemaining(String time);

  /// No description provided for @downloadStarting.
  ///
  /// In pt, this message translates to:
  /// **'Começando o download…'**
  String get downloadStarting;

  /// No description provided for @downloadDone.
  ///
  /// In pt, this message translates to:
  /// **'Download concluído.'**
  String get downloadDone;

  /// No description provided for @downloadFailed.
  ///
  /// In pt, this message translates to:
  /// **'O yt-dlp não concluiu este item.'**
  String get downloadFailed;

  /// No description provided for @downloadCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Download cancelado.'**
  String get downloadCancelled;

  /// No description provided for @downloadCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get downloadCancel;

  /// No description provided for @downloadRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar de novo'**
  String get downloadRetry;

  /// No description provided for @clipboardOffer.
  ///
  /// In pt, this message translates to:
  /// **'Tem um link copiado'**
  String get clipboardOffer;

  /// No description provided for @clipboardDismiss.
  ///
  /// In pt, this message translates to:
  /// **'Agora não'**
  String get clipboardDismiss;

  /// No description provided for @errFilename.
  ///
  /// In pt, this message translates to:
  /// **'O nome do arquivo passou do limite do sistema. Tente de novo para baixar com o nome encurtado.'**
  String get errFilename;

  /// No description provided for @errPrivate.
  ///
  /// In pt, this message translates to:
  /// **'Esse vídeo é privado.'**
  String get errPrivate;

  /// No description provided for @errUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Esse vídeo não está disponível.'**
  String get errUnavailable;

  /// No description provided for @errLogin.
  ///
  /// In pt, this message translates to:
  /// **'O site pediu login ou uma confirmação no navegador.'**
  String get errLogin;

  /// No description provided for @errUnsupported.
  ///
  /// In pt, this message translates to:
  /// **'Esse endereço não é suportado.'**
  String get errUnsupported;

  /// No description provided for @errForbidden.
  ///
  /// In pt, this message translates to:
  /// **'O site recusou o download.'**
  String get errForbidden;

  /// No description provided for @errExtract.
  ///
  /// In pt, this message translates to:
  /// **'Não deu para ler os dados desse link.'**
  String get errExtract;

  /// No description provided for @errFfmpeg.
  ///
  /// In pt, this message translates to:
  /// **'O FFmpeg não conseguiu fechar o arquivo.'**
  String get errFfmpeg;

  /// No description provided for @errNetwork.
  ///
  /// In pt, this message translates to:
  /// **'A rede falhou no meio do download.'**
  String get errNetwork;

  /// No description provided for @errInterrupted.
  ///
  /// In pt, this message translates to:
  /// **'O download parou porque o app foi fechado.'**
  String get errInterrupted;

  /// No description provided for @statusDone.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get statusDone;

  /// No description provided for @statusFailed.
  ///
  /// In pt, this message translates to:
  /// **'Falhou'**
  String get statusFailed;

  /// No description provided for @statusCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Cancelado'**
  String get statusCancelled;

  /// No description provided for @fileOpen.
  ///
  /// In pt, this message translates to:
  /// **'Abrir'**
  String get fileOpen;

  /// No description provided for @fileCopy.
  ///
  /// In pt, this message translates to:
  /// **'Copiar'**
  String get fileCopy;

  /// No description provided for @fileReveal.
  ///
  /// In pt, this message translates to:
  /// **'Abrir pasta'**
  String get fileReveal;

  /// No description provided for @fileShare.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar'**
  String get fileShare;

  /// No description provided for @fileCopied.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo copiado'**
  String get fileCopied;

  /// No description provided for @downloadNeedFolder.
  ///
  /// In pt, this message translates to:
  /// **'Escolha a pasta padrão em Ajustes antes de baixar.'**
  String get downloadNeedFolder;

  /// No description provided for @downloadNeedBinary.
  ///
  /// In pt, this message translates to:
  /// **'Aponte o yt-dlp e o FFmpeg em Ajustes.'**
  String get downloadNeedBinary;

  /// No description provided for @urlHint.
  ///
  /// In pt, this message translates to:
  /// **'Cole um link de vídeo ou publicação'**
  String get urlHint;

  /// No description provided for @dropHint.
  ///
  /// In pt, this message translates to:
  /// **'Solte um link aqui'**
  String get dropHint;

  /// No description provided for @doneEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nada concluído ainda.'**
  String get doneEmpty;

  /// No description provided for @profilesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Os perfis entram no próximo passo.'**
  String get profilesEmpty;

  /// No description provided for @settingsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Os ajustes entram no próximo passo.'**
  String get settingsEmpty;

  /// No description provided for @binariesPending.
  ///
  /// In pt, this message translates to:
  /// **'yt-dlp e FFmpeg ainda não foram verificados.'**
  String get binariesPending;

  /// No description provided for @binariesReady.
  ///
  /// In pt, this message translates to:
  /// **'yt-dlp {version}'**
  String binariesReady(String version);

  /// No description provided for @setupTitle.
  ///
  /// In pt, this message translates to:
  /// **'Para baixar, aponte o yt-dlp e o FFmpeg.'**
  String get setupTitle;

  /// No description provided for @setupHintMac.
  ///
  /// In pt, this message translates to:
  /// **'No macOS: brew install yt-dlp ffmpeg'**
  String get setupHintMac;

  /// No description provided for @setupHintWindows.
  ///
  /// In pt, this message translates to:
  /// **'No Windows: winget install yt-dlp.yt-dlp Gyan.FFmpeg'**
  String get setupHintWindows;

  /// No description provided for @setupHintLinux.
  ///
  /// In pt, this message translates to:
  /// **'No Linux: instale yt-dlp e ffmpeg pelo pacote da distro.'**
  String get setupHintLinux;

  /// No description provided for @ytDlpPathLabel.
  ///
  /// In pt, this message translates to:
  /// **'yt-dlp'**
  String get ytDlpPathLabel;

  /// No description provided for @ffmpegPathLabel.
  ///
  /// In pt, this message translates to:
  /// **'FFmpeg'**
  String get ffmpegPathLabel;

  /// No description provided for @folderLabel.
  ///
  /// In pt, this message translates to:
  /// **'Pasta padrão'**
  String get folderLabel;

  /// No description provided for @folderEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma pasta escolhida'**
  String get folderEmpty;

  /// No description provided for @binaryEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum arquivo escolhido'**
  String get binaryEmpty;

  /// No description provided for @chooseFile.
  ///
  /// In pt, this message translates to:
  /// **'Escolher arquivo'**
  String get chooseFile;

  /// No description provided for @chooseFolder.
  ///
  /// In pt, this message translates to:
  /// **'Escolher pasta'**
  String get chooseFolder;

  /// No description provided for @searchPath.
  ///
  /// In pt, this message translates to:
  /// **'Procurar'**
  String get searchPath;

  /// No description provided for @confirmPath.
  ///
  /// In pt, this message translates to:
  /// **'Usar este caminho'**
  String get confirmPath;

  /// No description provided for @foundPath.
  ///
  /// In pt, this message translates to:
  /// **'Encontrado: {path}'**
  String foundPath(String path);

  /// No description provided for @concurrentLabel.
  ///
  /// In pt, this message translates to:
  /// **'Downloads ao mesmo tempo'**
  String get concurrentLabel;

  /// No description provided for @clipboardLabel.
  ///
  /// In pt, this message translates to:
  /// **'Avisar quando houver um link copiado'**
  String get clipboardLabel;

  /// No description provided for @redactLabel.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar endereços no log'**
  String get redactLabel;

  /// No description provided for @errBrokenLink.
  ///
  /// In pt, this message translates to:
  /// **'O caminho é um atalho quebrado.'**
  String get errBrokenLink;

  /// No description provided for @errNotFile.
  ///
  /// In pt, this message translates to:
  /// **'O caminho não é um arquivo.'**
  String get errNotFile;

  /// No description provided for @errNotExecutable.
  ///
  /// In pt, this message translates to:
  /// **'O arquivo não tem permissão de execução.'**
  String get errNotExecutable;

  /// No description provided for @errForbiddenDir.
  ///
  /// In pt, this message translates to:
  /// **'Esse arquivo está numa pasta que o app não executa.'**
  String get errForbiddenDir;

  /// No description provided for @errVersion.
  ///
  /// In pt, this message translates to:
  /// **'O programa não respondeu com a versão.'**
  String get errVersion;

  /// No description provided for @errFfprobe.
  ///
  /// In pt, this message translates to:
  /// **'Falta o ffprobe na mesma pasta do ffmpeg. Sem ele o yt-dlp não fecha o arquivo e a união não roda.'**
  String get errFfprobe;

  /// No description provided for @errNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Não encontrei o programa nesses caminhos.'**
  String get errNotFound;

  /// No description provided for @profileNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo perfil'**
  String get profileNew;

  /// No description provided for @restoreMusic.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar Música'**
  String get restoreMusic;

  /// No description provided for @restoreFilms.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar Filmes'**
  String get restoreFilms;

  /// No description provided for @profileName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get profileName;

  /// No description provided for @presetLabel.
  ///
  /// In pt, this message translates to:
  /// **'Qualidade'**
  String get presetLabel;

  /// No description provided for @containerLabel.
  ///
  /// In pt, this message translates to:
  /// **'Contêiner'**
  String get containerLabel;

  /// No description provided for @profileRate.
  ///
  /// In pt, this message translates to:
  /// **'Taxa'**
  String get profileRate;

  /// No description provided for @profileFolder.
  ///
  /// In pt, this message translates to:
  /// **'Pasta deste perfil'**
  String get profileFolder;

  /// No description provided for @presetBest.
  ///
  /// In pt, this message translates to:
  /// **'Melhor'**
  String get presetBest;

  /// No description provided for @preset1080.
  ///
  /// In pt, this message translates to:
  /// **'1080p'**
  String get preset1080;

  /// No description provided for @preset720.
  ///
  /// In pt, this message translates to:
  /// **'720p'**
  String get preset720;

  /// No description provided for @presetAudio.
  ///
  /// In pt, this message translates to:
  /// **'Só áudio'**
  String get presetAudio;

  /// No description provided for @rateLimitLabel.
  ///
  /// In pt, this message translates to:
  /// **'Velocidade'**
  String get rateLimitLabel;

  /// No description provided for @rateLimitHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: 2M ou 500K. Vazio não limita.'**
  String get rateLimitHint;

  /// No description provided for @fragmentsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Fragmentos'**
  String get fragmentsLabel;

  /// No description provided for @fragmentsHint.
  ///
  /// In pt, this message translates to:
  /// **'De 1 a 16 ao mesmo tempo.'**
  String get fragmentsHint;

  /// No description provided for @bitrateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Bitrate máximo'**
  String get bitrateLabel;

  /// No description provided for @bitrateHint.
  ///
  /// In pt, this message translates to:
  /// **'Em kbps. Vazio não limita.'**
  String get bitrateHint;

  /// No description provided for @profileSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar perfil'**
  String get profileSave;

  /// No description provided for @profileDelete.
  ///
  /// In pt, this message translates to:
  /// **'Apagar'**
  String get profileDelete;

  /// No description provided for @errNameEmpty.
  ///
  /// In pt, this message translates to:
  /// **'O perfil precisa de um nome.'**
  String get errNameEmpty;

  /// No description provided for @errAudioEmbed.
  ///
  /// In pt, this message translates to:
  /// **'Só áudio não embute legenda.'**
  String get errAudioEmbed;

  /// No description provided for @errContainer.
  ///
  /// In pt, this message translates to:
  /// **'Esse contêiner não combina com o tipo.'**
  String get errContainer;

  /// No description provided for @errBitrate.
  ///
  /// In pt, this message translates to:
  /// **'O bitrate precisa ser um número maior que zero.'**
  String get errBitrate;

  /// No description provided for @errRate.
  ///
  /// In pt, this message translates to:
  /// **'O limite de velocidade não está num formato aceito.'**
  String get errRate;

  /// No description provided for @errFragments.
  ///
  /// In pt, this message translates to:
  /// **'Os fragmentos ficam entre 1 e 16.'**
  String get errFragments;

  /// No description provided for @errTemplate.
  ///
  /// In pt, this message translates to:
  /// **'O nome do arquivo não pode sair da pasta.'**
  String get errTemplate;

  /// No description provided for @schemaReset.
  ///
  /// In pt, this message translates to:
  /// **'As configurações antigas foram guardadas em {name} e o app começou de novo.'**
  String schemaReset(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
