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
}
