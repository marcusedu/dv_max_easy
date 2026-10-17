final class AppSettings {
  const AppSettings({
    this.defaultDownloadFolder,
    this.uiLanguage = 'pt-BR',
    this.ytDlpPath,
    this.ffmpegPath,
    this.maxConcurrentDownloads = 2,
    this.clipboardPromptEnabled = true,
    this.redactUrlsInLog = true,
    this.selectedProfileId,
    this.galleryEnd = 'stay',
    this.galleryScrollInverted = false,
  });

  final String? defaultDownloadFolder;
  final String uiLanguage;
  final String? ytDlpPath;
  final String? ffmpegPath;
  final int maxConcurrentDownloads;
  final bool clipboardPromptEnabled;
  final bool redactUrlsInLog;
  final String? selectedProfileId;
  final String galleryEnd;
  final bool galleryScrollInverted;

  static const schemaVersion = 1;

  AppSettings copyWith({
    String? defaultDownloadFolder,
    bool clearFolder = false,
    String? uiLanguage,
    String? ytDlpPath,
    bool clearYtDlp = false,
    String? ffmpegPath,
    bool clearFfmpeg = false,
    int? maxConcurrentDownloads,
    bool? clipboardPromptEnabled,
    bool? redactUrlsInLog,
    String? selectedProfileId,
    bool clearProfile = false,
    String? galleryEnd,
    bool? galleryScrollInverted,
  }) {
    return AppSettings(
      defaultDownloadFolder: clearFolder
          ? null
          : defaultDownloadFolder ?? this.defaultDownloadFolder,
      uiLanguage: uiLanguage ?? this.uiLanguage,
      ytDlpPath: clearYtDlp ? null : ytDlpPath ?? this.ytDlpPath,
      ffmpegPath: clearFfmpeg ? null : ffmpegPath ?? this.ffmpegPath,
      maxConcurrentDownloads:
          maxConcurrentDownloads ?? this.maxConcurrentDownloads,
      clipboardPromptEnabled:
          clipboardPromptEnabled ?? this.clipboardPromptEnabled,
      redactUrlsInLog: redactUrlsInLog ?? this.redactUrlsInLog,
      selectedProfileId: clearProfile
          ? null
          : selectedProfileId ?? this.selectedProfileId,
      galleryEnd: galleryEnd ?? this.galleryEnd,
      galleryScrollInverted:
          galleryScrollInverted ?? this.galleryScrollInverted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'defaultDownloadFolder': defaultDownloadFolder,
      'uiLanguage': uiLanguage,
      'ytDlpPath': ytDlpPath,
      'ffmpegPath': ffmpegPath,
      'maxConcurrentDownloads': maxConcurrentDownloads,
      'clipboardPromptEnabled': clipboardPromptEnabled,
      'redactUrlsInLog': redactUrlsInLog,
      'selectedProfileId': selectedProfileId,
      'galleryEnd': galleryEnd,
      'galleryScrollInverted': galleryScrollInverted,
    };
  }

  static AppSettings fromJson(Map<String, dynamic> json) {
    final concurrent = json['maxConcurrentDownloads'];
    final parsed = concurrent is int ? concurrent : 2;
    return AppSettings(
      defaultDownloadFolder: _string(json['defaultDownloadFolder']),
      uiLanguage: _string(json['uiLanguage']) ?? 'pt-BR',
      ytDlpPath: _string(json['ytDlpPath']),
      ffmpegPath: _string(json['ffmpegPath']),
      maxConcurrentDownloads: parsed.clamp(1, 4),
      clipboardPromptEnabled: json['clipboardPromptEnabled'] != false,
      redactUrlsInLog: json['redactUrlsInLog'] != false,
      selectedProfileId: _string(json['selectedProfileId']),
      galleryEnd: _galleryEnd(json['galleryEnd']),
      galleryScrollInverted: json['galleryScrollInverted'] == true,
    );
  }

  static String _galleryEnd(Object? value) {
    if (value == 'repeat' || value == 'next' || value == 'stay') {
      return value as String;
    }
    return 'stay';
  }

  static String? _string(Object? value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }
}
