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

  /// No description provided for @navLists.
  ///
  /// In pt, this message translates to:
  /// **'Listas'**
  String get navLists;

  /// No description provided for @navConvert.
  ///
  /// In pt, this message translates to:
  /// **'Converter'**
  String get navConvert;

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

  /// No description provided for @errFormat.
  ///
  /// In pt, this message translates to:
  /// **'Esse vídeo não tem o formato do perfil. Tente de novo para baixar o melhor disponível.'**
  String get errFormat;

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

  /// No description provided for @queuePreviewHint.
  ///
  /// In pt, this message translates to:
  /// **'A fila mostra os 10 mais recentes. O restante está em Concluídos.'**
  String get queuePreviewHint;

  /// No description provided for @doneSearch.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar por nome ou link'**
  String get doneSearch;

  /// No description provided for @filterSource.
  ///
  /// In pt, this message translates to:
  /// **'Fonte'**
  String get filterSource;

  /// No description provided for @filterProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get filterProfile;

  /// No description provided for @filterType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get filterType;

  /// No description provided for @filterDisk.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo'**
  String get filterDisk;

  /// No description provided for @filterAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get filterAll;

  /// No description provided for @diskPresent.
  ///
  /// In pt, this message translates to:
  /// **'Na pasta'**
  String get diskPresent;

  /// No description provided for @diskMissing.
  ///
  /// In pt, this message translates to:
  /// **'Fora da pasta'**
  String get diskMissing;

  /// No description provided for @diskScheduled.
  ///
  /// In pt, this message translates to:
  /// **'Com prazo'**
  String get diskScheduled;

  /// No description provided for @diskPurged.
  ///
  /// In pt, this message translates to:
  /// **'Apagados'**
  String get diskPurged;

  /// No description provided for @fileMissing.
  ///
  /// In pt, this message translates to:
  /// **'O arquivo não está mais na pasta em que foi salvo.'**
  String get fileMissing;

  /// No description provided for @filePurged.
  ///
  /// In pt, this message translates to:
  /// **'O app apagou este arquivo. O histórico fica.'**
  String get filePurged;

  /// No description provided for @downloadAgain.
  ///
  /// In pt, this message translates to:
  /// **'Baixar de novo'**
  String get downloadAgain;

  /// No description provided for @keepFile.
  ///
  /// In pt, this message translates to:
  /// **'Manter este arquivo'**
  String get keepFile;

  /// No description provided for @resumeRetention.
  ///
  /// In pt, this message translates to:
  /// **'Voltar a apagar no prazo'**
  String get resumeRetention;

  /// No description provided for @deletesIn.
  ///
  /// In pt, this message translates to:
  /// **'Apaga em {when}'**
  String deletesIn(String when);

  /// No description provided for @downloadedAt.
  ///
  /// In pt, this message translates to:
  /// **'Baixado em {when}'**
  String downloadedAt(String when);

  /// No description provided for @whenMinute.
  ///
  /// In pt, this message translates to:
  /// **'1 minuto'**
  String get whenMinute;

  /// No description provided for @whenMinutes.
  ///
  /// In pt, this message translates to:
  /// **'{count} minutos'**
  String whenMinutes(int count);

  /// No description provided for @whenHour.
  ///
  /// In pt, this message translates to:
  /// **'1 hora'**
  String get whenHour;

  /// No description provided for @whenHours.
  ///
  /// In pt, this message translates to:
  /// **'{count} horas'**
  String whenHours(int count);

  /// No description provided for @whenDay.
  ///
  /// In pt, this message translates to:
  /// **'1 dia'**
  String get whenDay;

  /// No description provided for @whenDays.
  ///
  /// In pt, this message translates to:
  /// **'{count} dias'**
  String whenDays(int count);

  /// No description provided for @alreadyDownloaded.
  ///
  /// In pt, this message translates to:
  /// **'Este link já foi baixado'**
  String get alreadyDownloaded;

  /// No description provided for @seeCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Ver nos concluídos'**
  String get seeCompleted;

  /// No description provided for @duplicateDismiss.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get duplicateDismiss;

  /// No description provided for @retentionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Apagar o arquivo'**
  String get retentionLabel;

  /// No description provided for @retentionNever.
  ///
  /// In pt, this message translates to:
  /// **'Nunca'**
  String get retentionNever;

  /// No description provided for @retentionTwo.
  ///
  /// In pt, this message translates to:
  /// **'2 dias'**
  String get retentionTwo;

  /// No description provided for @retentionThirty.
  ///
  /// In pt, this message translates to:
  /// **'30 dias'**
  String get retentionThirty;

  /// No description provided for @retentionCustom.
  ///
  /// In pt, this message translates to:
  /// **'Personalizado'**
  String get retentionCustom;

  /// No description provided for @retentionDays.
  ///
  /// In pt, this message translates to:
  /// **'Dias'**
  String get retentionDays;

  /// No description provided for @retentionHint.
  ///
  /// In pt, this message translates to:
  /// **'Ao abrir, o app apaga o arquivo depois desse prazo. O histórico permanece.'**
  String get retentionHint;

  /// No description provided for @errRetention.
  ///
  /// In pt, this message translates to:
  /// **'O prazo precisa ser um número de dias maior que zero.'**
  String get errRetention;

  /// No description provided for @storageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Armazenamento'**
  String get storageTitle;

  /// No description provided for @storageHistory.
  ///
  /// In pt, this message translates to:
  /// **'{count} no histórico'**
  String storageHistory(int count);

  /// No description provided for @storageOnDisk.
  ///
  /// In pt, this message translates to:
  /// **'{count} arquivos ainda na pasta'**
  String storageOnDisk(int count);

  /// No description provided for @storageSize.
  ///
  /// In pt, this message translates to:
  /// **'{size} no disco'**
  String storageSize(String size);

  /// No description provided for @purgeNow.
  ///
  /// In pt, this message translates to:
  /// **'Apagar os que já venceram'**
  String get purgeNow;

  /// No description provided for @doneEmptyFilter.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum download combina com esses filtros.'**
  String get doneEmptyFilter;

  /// No description provided for @openLink.
  ///
  /// In pt, this message translates to:
  /// **'Abrir no navegador'**
  String get openLink;

  /// No description provided for @statusIdle.
  ///
  /// In pt, this message translates to:
  /// **'Nada baixando'**
  String get statusIdle;

  /// No description provided for @statusFileCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{0 arquivos} =1{1 arquivo} other{{count} arquivos}}'**
  String statusFileCount(int count);

  /// No description provided for @statusRunningCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 baixando} other{{count} baixando}}'**
  String statusRunningCount(int count);

  /// No description provided for @statusFree.
  ///
  /// In pt, this message translates to:
  /// **'{size} livres'**
  String statusFree(String size);

  /// No description provided for @statusUsed.
  ///
  /// In pt, this message translates to:
  /// **'{size} usados'**
  String statusUsed(String size);

  /// No description provided for @cutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cortar vídeo'**
  String get cutTitle;

  /// No description provided for @cutOpen.
  ///
  /// In pt, this message translates to:
  /// **'Cortar'**
  String get cutOpen;

  /// No description provided for @cutHelp.
  ///
  /// In pt, this message translates to:
  /// **'Selecione trechos na linha do tempo para remover ou isolar. O que sobrar é unido na ordem sem perda desnecessária.'**
  String get cutHelp;

  /// No description provided for @cutRemove.
  ///
  /// In pt, this message translates to:
  /// **'Tirar trecho'**
  String get cutRemove;

  /// No description provided for @cutFrom.
  ///
  /// In pt, this message translates to:
  /// **'De'**
  String get cutFrom;

  /// No description provided for @cutTo.
  ///
  /// In pt, this message translates to:
  /// **'Até'**
  String get cutTo;

  /// No description provided for @cutKeepOnly.
  ///
  /// In pt, this message translates to:
  /// **'Ficar só com este trecho'**
  String get cutKeepOnly;

  /// No description provided for @cutKept.
  ///
  /// In pt, this message translates to:
  /// **'Vai ficar: {parts}'**
  String cutKept(String parts);

  /// No description provided for @cutSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar novo vídeo'**
  String get cutSave;

  /// No description provided for @cutSaving.
  ///
  /// In pt, this message translates to:
  /// **'Processando corte com FFmpeg…'**
  String get cutSaving;

  /// No description provided for @cutSaved.
  ///
  /// In pt, this message translates to:
  /// **'Corte salvo com sucesso ao lado do original.'**
  String get cutSaved;

  /// No description provided for @cutNeedRange.
  ///
  /// In pt, this message translates to:
  /// **'Informe um início e um fim válidos. O fim precisa ser depois do início.'**
  String get cutNeedRange;

  /// No description provided for @cutNothing.
  ///
  /// In pt, this message translates to:
  /// **'Nada muda se o vídeo ficar inteiro.'**
  String get cutNothing;

  /// No description provided for @cutEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Esse corte remove o vídeo inteiro.'**
  String get cutEmpty;

  /// No description provided for @cutFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível cortar o vídeo.'**
  String get cutFailed;

  /// No description provided for @cutNoProbe.
  ///
  /// In pt, this message translates to:
  /// **'O ffprobe não está ao lado do FFmpeg, então a duração não pôde ser identificada.'**
  String get cutNoProbe;

  /// No description provided for @timeHint.
  ///
  /// In pt, this message translates to:
  /// **'00:00 ou 01:23:45'**
  String get timeHint;

  /// No description provided for @cutOriginalDuration.
  ///
  /// In pt, this message translates to:
  /// **'Duração original'**
  String get cutOriginalDuration;

  /// No description provided for @cutFinalDuration.
  ///
  /// In pt, this message translates to:
  /// **'Duração final'**
  String get cutFinalDuration;

  /// No description provided for @cutRemovedDuration.
  ///
  /// In pt, this message translates to:
  /// **'Removido'**
  String get cutRemovedDuration;

  /// No description provided for @cutClearAll.
  ///
  /// In pt, this message translates to:
  /// **'Limpar cortes'**
  String get cutClearAll;

  /// No description provided for @cutPreserveOriginal.
  ///
  /// In pt, this message translates to:
  /// **'O arquivo original permanecerá intacto.'**
  String get cutPreserveOriginal;

  /// No description provided for @cutSelection.
  ///
  /// In pt, this message translates to:
  /// **'Trecho selecionado'**
  String get cutSelection;

  /// No description provided for @cutQuickStart.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get cutQuickStart;

  /// No description provided for @cutQuickEnd.
  ///
  /// In pt, this message translates to:
  /// **'Fim'**
  String get cutQuickEnd;

  /// No description provided for @cutWithAudio.
  ///
  /// In pt, this message translates to:
  /// **'Com áudio'**
  String get cutWithAudio;

  /// No description provided for @cutWithoutAudio.
  ///
  /// In pt, this message translates to:
  /// **'Sem áudio'**
  String get cutWithoutAudio;

  /// No description provided for @cutTimelineTitle.
  ///
  /// In pt, this message translates to:
  /// **'Linha do tempo'**
  String get cutTimelineTitle;

  /// No description provided for @cutTimelineLegendKept.
  ///
  /// In pt, this message translates to:
  /// **'Mantido'**
  String get cutTimelineLegendKept;

  /// No description provided for @cutTimelineLegendRemoved.
  ///
  /// In pt, this message translates to:
  /// **'Removido'**
  String get cutTimelineLegendRemoved;

  /// No description provided for @cutTimelineLegendSelection.
  ///
  /// In pt, this message translates to:
  /// **'Seleção'**
  String get cutTimelineLegendSelection;

  /// No description provided for @cutRemovedSegmentsTitle.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 trecho a remover} other{{count} trechos a remover}}'**
  String cutRemovedSegmentsTitle(int count);

  /// No description provided for @cutNoCutsAdded.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum trecho marcado para remoção.'**
  String get cutNoCutsAdded;

  /// No description provided for @cutSummaryParts.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 parte resultante} other{{count} partes unidas}}'**
  String cutSummaryParts(int count);

  /// No description provided for @cutOutputLabel.
  ///
  /// In pt, this message translates to:
  /// **'Salvar como'**
  String get cutOutputLabel;

  /// No description provided for @cutPlay.
  ///
  /// In pt, this message translates to:
  /// **'Reproduzir'**
  String get cutPlay;

  /// No description provided for @cutPause.
  ///
  /// In pt, this message translates to:
  /// **'Pausar'**
  String get cutPause;

  /// No description provided for @cutPlaySelection.
  ///
  /// In pt, this message translates to:
  /// **'Ouvir trecho'**
  String get cutPlaySelection;

  /// No description provided for @cutMute.
  ///
  /// In pt, this message translates to:
  /// **'Silenciar'**
  String get cutMute;

  /// No description provided for @cutUnmute.
  ///
  /// In pt, this message translates to:
  /// **'Ativar som'**
  String get cutUnmute;

  /// No description provided for @cutSetStartHere.
  ///
  /// In pt, this message translates to:
  /// **'Marcar início aqui'**
  String get cutSetStartHere;

  /// No description provided for @cutSetEndHere.
  ///
  /// In pt, this message translates to:
  /// **'Marcar fim aqui'**
  String get cutSetEndHere;

  /// No description provided for @cutKeyboardHelp.
  ///
  /// In pt, this message translates to:
  /// **'Espaço: Play/Pause  ·  I: Marcar início  ·  O: Marcar fim  ·  ← / →: ±1s'**
  String get cutKeyboardHelp;

  /// No description provided for @cutPlayerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pré-visualização'**
  String get cutPlayerTitle;

  /// No description provided for @listsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma lista salva. Guarde links para baixar de novo.'**
  String get listsEmpty;

  /// No description provided for @listsNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova lista'**
  String get listsNew;

  /// No description provided for @listsName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get listsName;

  /// No description provided for @listsAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get listsAdd;

  /// No description provided for @listsUrlHint.
  ///
  /// In pt, this message translates to:
  /// **'https://'**
  String get listsUrlHint;

  /// No description provided for @listsDownloadAll.
  ///
  /// In pt, this message translates to:
  /// **'Baixar todos'**
  String get listsDownloadAll;

  /// No description provided for @listsRemove.
  ///
  /// In pt, this message translates to:
  /// **'Tirar'**
  String get listsRemove;

  /// No description provided for @listsDelete.
  ///
  /// In pt, this message translates to:
  /// **'Apagar lista'**
  String get listsDelete;

  /// No description provided for @listsBadUrl.
  ///
  /// In pt, this message translates to:
  /// **'Este texto não é um link http ou https.'**
  String get listsBadUrl;

  /// No description provided for @listsDuplicate.
  ///
  /// In pt, this message translates to:
  /// **'Esse link já está na lista.'**
  String get listsDuplicate;

  /// No description provided for @listsFull.
  ///
  /// In pt, this message translates to:
  /// **'Essa lista chegou ao limite.'**
  String get listsFull;

  /// No description provided for @listsTooMany.
  ///
  /// In pt, this message translates to:
  /// **'O limite de listas foi atingido.'**
  String get listsTooMany;

  /// No description provided for @listsEmptyName.
  ///
  /// In pt, this message translates to:
  /// **'A lista precisa de um nome.'**
  String get listsEmptyName;

  /// No description provided for @listsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 link} other{{count} links}}'**
  String listsCount(int count);

  /// No description provided for @localOffer.
  ///
  /// In pt, this message translates to:
  /// **'Tem um arquivo de mídia copiado'**
  String get localOffer;

  /// No description provided for @convertHelp.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um arquivo local e o formato de saída. O original permanece. O novo arquivo fica na mesma pasta.'**
  String get convertHelp;

  /// No description provided for @convertPick.
  ///
  /// In pt, this message translates to:
  /// **'Escolher arquivo'**
  String get convertPick;

  /// No description provided for @convertNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum arquivo escolhido.'**
  String get convertNone;

  /// No description provided for @convertSave.
  ///
  /// In pt, this message translates to:
  /// **'Converter'**
  String get convertSave;

  /// No description provided for @convertSaving.
  ///
  /// In pt, this message translates to:
  /// **'Convertendo…'**
  String get convertSaving;

  /// No description provided for @convertSaved.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo convertido ao lado do original.'**
  String get convertSaved;

  /// No description provided for @convertFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível converter o arquivo.'**
  String get convertFailed;

  /// No description provided for @convertNeedVideo.
  ///
  /// In pt, this message translates to:
  /// **'Esse arquivo não tem vídeo. Escolha MP3 ou M4A.'**
  String get convertNeedVideo;

  /// No description provided for @convertNoBinary.
  ///
  /// In pt, this message translates to:
  /// **'Aponte o FFmpeg em Ajustes.'**
  String get convertNoBinary;

  /// No description provided for @installAction.
  ///
  /// In pt, this message translates to:
  /// **'Instalar yt-dlp e FFmpeg'**
  String get installAction;

  /// No description provided for @installPackageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Instalar com {tool}'**
  String installPackageTitle(String tool);

  /// No description provided for @installPackageBody.
  ///
  /// In pt, this message translates to:
  /// **'O DV Max vai executar, com a sua permissão:\n{command}'**
  String installPackageBody(String command);

  /// No description provided for @installDownloadTitle.
  ///
  /// In pt, this message translates to:
  /// **'Baixar os binários oficiais'**
  String get installDownloadTitle;

  /// No description provided for @installDownloadBody.
  ///
  /// In pt, this message translates to:
  /// **'O gerenciador não está disponível ou não deixou os programas prontos. O DV Max pode baixar o yt-dlp e o FFmpeg oficiais para a pasta do aplicativo.'**
  String get installDownloadBody;

  /// No description provided for @installConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Instalar'**
  String get installConfirm;

  /// No description provided for @installCancel.
  ///
  /// In pt, this message translates to:
  /// **'Agora não'**
  String get installCancel;

  /// No description provided for @installRunning.
  ///
  /// In pt, this message translates to:
  /// **'Instalando yt-dlp e FFmpeg…'**
  String get installRunning;

  /// No description provided for @installFailed.
  ///
  /// In pt, this message translates to:
  /// **'A instalação não terminou. Você pode escolher os arquivos manualmente.'**
  String get installFailed;

  /// No description provided for @batchImport.
  ///
  /// In pt, this message translates to:
  /// **'Importar .txt'**
  String get batchImport;

  /// No description provided for @batchImportTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Importar arquivo .txt com links para download (yt-dlp batch)'**
  String get batchImportTooltip;

  /// No description provided for @batchImportSuccess.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 link importado para a fila.} other{{count} links importados para a fila.}}'**
  String batchImportSuccess(int count);

  /// No description provided for @batchImportEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum link encontrado no arquivo selecionado.'**
  String get batchImportEmpty;

  /// No description provided for @batchFileOffer.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo de links copiado'**
  String get batchFileOffer;

  /// No description provided for @batchFileImport.
  ///
  /// In pt, this message translates to:
  /// **'Importar links'**
  String get batchFileImport;

  /// No description provided for @jobRemove.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get jobRemove;

  /// No description provided for @jobRemoveTitle.
  ///
  /// In pt, this message translates to:
  /// **'Remover download'**
  String get jobRemoveTitle;

  /// No description provided for @jobRemoveMessage.
  ///
  /// In pt, this message translates to:
  /// **'Deseja remover este download da lista? Você pode manter o arquivo no computador ou apagá-lo.'**
  String get jobRemoveMessage;

  /// No description provided for @jobRemoveOnlyList.
  ///
  /// In pt, this message translates to:
  /// **'Remover apenas da lista'**
  String get jobRemoveOnlyList;

  /// No description provided for @jobDeleteFile.
  ///
  /// In pt, this message translates to:
  /// **'Deletar arquivo'**
  String get jobDeleteFile;

  /// No description provided for @convertAction.
  ///
  /// In pt, this message translates to:
  /// **'Converter'**
  String get convertAction;

  /// No description provided for @convertModeConvert.
  ///
  /// In pt, this message translates to:
  /// **'Converter'**
  String get convertModeConvert;

  /// No description provided for @convertModeExtract.
  ///
  /// In pt, this message translates to:
  /// **'Extrair Áudio'**
  String get convertModeExtract;

  /// No description provided for @convertModeJoin.
  ///
  /// In pt, this message translates to:
  /// **'Juntar Arquivos'**
  String get convertModeJoin;

  /// No description provided for @convertPresetBalanced.
  ///
  /// In pt, this message translates to:
  /// **'Equilibrado (Recomendado)'**
  String get convertPresetBalanced;

  /// No description provided for @convertPresetHighQuality.
  ///
  /// In pt, this message translates to:
  /// **'Alta Qualidade'**
  String get convertPresetHighQuality;

  /// No description provided for @convertPresetWeb.
  ///
  /// In pt, this message translates to:
  /// **'Otimizado para Web'**
  String get convertPresetWeb;

  /// No description provided for @convertPresetLight.
  ///
  /// In pt, this message translates to:
  /// **'Tamanho Reduzido'**
  String get convertPresetLight;

  /// No description provided for @convertQualityOriginal.
  ///
  /// In pt, this message translates to:
  /// **'Original'**
  String get convertQualityOriginal;

  /// No description provided for @convertAddFiles.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar arquivos'**
  String get convertAddFiles;

  /// No description provided for @convertClearList.
  ///
  /// In pt, this message translates to:
  /// **'Limpar lista'**
  String get convertClearList;

  /// No description provided for @convertFilesSelected.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 arquivo selecionado} other{{count} arquivos selecionados}}'**
  String convertFilesSelected(int count);

  /// No description provided for @convertDragHint.
  ///
  /// In pt, this message translates to:
  /// **'Arraste e solte vídeos ou áudios aqui'**
  String get convertDragHint;

  /// No description provided for @convertDragSubhint.
  ///
  /// In pt, this message translates to:
  /// **'ou clique no botão abaixo para escolher do seu computador'**
  String get convertDragSubhint;

  /// No description provided for @convertExtractBitrate.
  ///
  /// In pt, this message translates to:
  /// **'Taxa de áudio (Bitrate)'**
  String get convertExtractBitrate;

  /// No description provided for @convertExtractHint.
  ///
  /// In pt, this message translates to:
  /// **'Extrai somente a trilha de som preservando a duração.'**
  String get convertExtractHint;

  /// No description provided for @convertJoinHint.
  ///
  /// In pt, this message translates to:
  /// **'Une todos os arquivos da lista em sequência num único arquivo final.'**
  String get convertJoinHint;

  /// No description provided for @convertJoinNeedMultiple.
  ///
  /// In pt, this message translates to:
  /// **'Adicione pelo menos 2 arquivos para juntar.'**
  String get convertJoinNeedMultiple;

  /// No description provided for @convertJoinOutput.
  ///
  /// In pt, this message translates to:
  /// **'Nome do arquivo unido'**
  String get convertJoinOutput;

  /// No description provided for @convertProgressBatch.
  ///
  /// In pt, this message translates to:
  /// **'Processando {current} de {total}…'**
  String convertProgressBatch(int current, int total);

  /// No description provided for @convertSuccessBatch.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 arquivo convertido com sucesso!} other{{count} arquivos convertidos com sucesso!}}'**
  String convertSuccessBatch(int count);

  /// No description provided for @convertSuccessJoin.
  ///
  /// In pt, this message translates to:
  /// **'Arquivos unidos com sucesso!'**
  String get convertSuccessJoin;

  /// No description provided for @convertOpenResult.
  ///
  /// In pt, this message translates to:
  /// **'Abrir arquivo'**
  String get convertOpenResult;

  /// No description provided for @convertRevealResult.
  ///
  /// In pt, this message translates to:
  /// **'Abrir pasta'**
  String get convertRevealResult;

  /// No description provided for @convertNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova conversão'**
  String get convertNew;

  /// No description provided for @convertCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar processo'**
  String get convertCancel;

  /// No description provided for @convertUp.
  ///
  /// In pt, this message translates to:
  /// **'Mover para cima'**
  String get convertUp;

  /// No description provided for @convertDown.
  ///
  /// In pt, this message translates to:
  /// **'Mover para baixo'**
  String get convertDown;

  /// No description provided for @convertRemove.
  ///
  /// In pt, this message translates to:
  /// **'Tirar da lista'**
  String get convertRemove;
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
