import 'dart:io';

import 'package:dv_max_easy/core/clock.dart';
import 'package:dv_max_easy/core/log.dart';
import 'package:dv_max_easy/features/settings/domain/app_settings.dart';
import 'package:dv_max_easy/features/settings/domain/binary_path.dart';
import 'package:dv_max_easy/features/settings/domain/settings_ports.dart';
import 'package:dv_max_easy/features/settings/infrastructure/io_path_facts.dart';
import 'package:dv_max_easy/features/settings/infrastructure/process_version_probe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

final clockProvider = Provider<Clock>((ref) => SystemClock());

final logProvider = Provider<Log>((ref) => MemoryLog());

final settingsStoreProvider = Provider<SettingsStore>((ref) {
  throw StateError('settingsStoreProvider não foi configurado');
});

final pathFactsProvider = Provider<PathFactsReader>((ref) => IoPathFacts());

final versionProbeProvider = Provider<VersionProbe>(
  (ref) => ProcessVersionProbe(),
);

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, SettingsView>(
      SettingsController.new,
    );

final class SettingsView {
  const SettingsView({
    required this.settings,
    this.ytDlpVersion,
    this.ffmpegVersion,
    this.noticeCode,
    this.noticeDetail,
    this.errorCode,
    this.pendingPath,
    this.pendingKind,
  });

  final AppSettings settings;
  final String? ytDlpVersion;
  final String? ffmpegVersion;
  final String? noticeCode;
  final String? noticeDetail;
  final String? errorCode;
  final String? pendingPath;
  final BinaryKind? pendingKind;

  bool get binariesReady => ytDlpVersion != null && ffmpegVersion != null;

  SettingsView copyWith({
    AppSettings? settings,
    String? ytDlpVersion,
    bool clearYtDlpVersion = false,
    String? ffmpegVersion,
    bool clearFfmpegVersion = false,
    String? noticeCode,
    bool clearNotice = false,
    String? noticeDetail,
    String? errorCode,
    bool clearError = false,
    String? pendingPath,
    bool clearPending = false,
    BinaryKind? pendingKind,
  }) {
    return SettingsView(
      settings: settings ?? this.settings,
      ytDlpVersion: clearYtDlpVersion
          ? null
          : ytDlpVersion ?? this.ytDlpVersion,
      ffmpegVersion: clearFfmpegVersion
          ? null
          : ffmpegVersion ?? this.ffmpegVersion,
      noticeCode: clearNotice ? null : noticeCode ?? this.noticeCode,
      noticeDetail: clearNotice ? null : noticeDetail ?? this.noticeDetail,
      errorCode: clearError ? null : errorCode ?? this.errorCode,
      pendingPath: clearPending ? null : pendingPath ?? this.pendingPath,
      pendingKind: clearPending ? null : pendingKind ?? this.pendingKind,
    );
  }
}

final class SettingsController extends AsyncNotifier<SettingsView> {
  @override
  Future<SettingsView> build() async {
    final loaded = await ref.read(settingsStoreProvider).load();
    var view = SettingsView(
      settings: loaded.settings,
      noticeCode: loaded.backupPath == null ? null : 'schema_reset',
      noticeDetail: loaded.backupPath == null
          ? null
          : p.basename(loaded.backupPath!),
    );
    view = await _refreshVersions(view);
    return view;
  }

  Future<void> setFolder(String? folder) async {
    await _save(
      _current.settings.copyWith(
        defaultDownloadFolder: folder,
        clearFolder: folder == null || folder.isEmpty,
      ),
    );
  }

  Future<void> setConcurrent(int value) async {
    await _save(
      _current.settings.copyWith(maxConcurrentDownloads: value.clamp(1, 4)),
    );
  }

  Future<void> setClipboardPrompt(bool enabled) async {
    await _save(_current.settings.copyWith(clipboardPromptEnabled: enabled));
  }

  Future<void> setRedactUrls(bool enabled) async {
    await _save(_current.settings.copyWith(redactUrlsInLog: enabled));
  }

  Future<void> stageCandidate(BinaryKind kind, String path) async {
    final current = _current;
    state = AsyncData(
      current.copyWith(
        pendingPath: path,
        pendingKind: kind,
        clearError: true,
      ),
    );
  }

  Future<void> acceptPending() async {
    final pending = _current.pendingPath;
    final kind = _current.pendingKind;
    if (pending == null || kind == null) {
      return;
    }
    await acceptBinary(kind, pending);
  }

  Future<void> acceptBinary(BinaryKind kind, String path) async {
    final checked = await _check(kind, path, _current.settings);
    if (checked.errorCode != null || checked.version == null) {
      state = AsyncData(
        _current.copyWith(
          errorCode: checked.errorCode ?? 'version_failed',
          clearPending: true,
        ),
      );
      return;
    }
    final next = switch (kind) {
      BinaryKind.ytDlp => _current.settings.copyWith(ytDlpPath: path),
      BinaryKind.ffmpeg => _current.settings.copyWith(ffmpegPath: path),
    };
    var view = _current.copyWith(settings: next, clearError: true, clearPending: true);
    if (kind == BinaryKind.ytDlp) {
      view = view.copyWith(ytDlpVersion: checked.version);
    } else {
      view = view.copyWith(ffmpegVersion: checked.version);
    }
    await _persist(view);
  }

  Future<String?> search(BinaryKind kind) async {
    final names = switch (kind) {
      BinaryKind.ytDlp => Platform.isWindows
          ? ['yt-dlp.exe', 'yt-dlp']
          : ['yt-dlp'],
      BinaryKind.ffmpeg => Platform.isWindows
          ? ['ffmpeg.exe', 'ffmpeg']
          : ['ffmpeg'],
    };
    final directories = binarySearchDirectories(
      pathEnv: Platform.environment['PATH'] ?? '',
      operatingSystem: Platform.operatingSystem,
      environment: Platform.environment,
    );
    for (final directory in directories) {
      for (final name in names) {
        final candidate = p.join(directory, name);
        final facts = ref.read(pathFactsProvider).inspect(candidate);
        if (facts.kind == PathKind.file) {
          await stageCandidate(kind, candidate);
          return candidate;
        }
      }
    }
    state = AsyncData(_current.copyWith(errorCode: 'not_found'));
    return null;
  }

  SettingsView get _current {
    final value = state.asData?.value;
    if (value == null) {
      throw StateError('ajustes ainda não carregaram');
    }
    return value;
  }

  Future<void> _save(AppSettings settings) async {
    await _persist(await _refreshVersions(_current.copyWith(settings: settings)));
  }

  Future<void> _persist(SettingsView view) async {
    await ref.read(settingsStoreProvider).save(view.settings);
    ref.read(logProvider).info('ajustes gravados');
    state = AsyncData(view);
  }

  Future<SettingsView> _refreshVersions(SettingsView view) async {
    final settings = view.settings;
    String? ytVersion;
    String? ffmpegVersion;
    String? error;
    final ytPath = settings.ytDlpPath;
    if (ytPath != null) {
      final checked = await _check(BinaryKind.ytDlp, ytPath, settings);
      ytVersion = checked.version;
      error = checked.errorCode;
    }
    final ffmpegPath = settings.ffmpegPath;
    if (ffmpegPath != null) {
      final checked = await _check(BinaryKind.ffmpeg, ffmpegPath, settings);
      ffmpegVersion = checked.version;
      error ??= checked.errorCode;
    }
    return view.copyWith(
      ytDlpVersion: ytVersion,
      clearYtDlpVersion: ytVersion == null,
      ffmpegVersion: ffmpegVersion,
      clearFfmpegVersion: ffmpegVersion == null,
      errorCode: error,
      clearError: error == null,
    );
  }

  Future<({String? version, String? errorCode})> _check(
    BinaryKind kind,
    String path,
    AppSettings settings,
  ) async {
    final facts = ref.read(pathFactsProvider).inspect(path);
    final rejection = evaluateBinaryPath(
      facts: facts,
      forbiddenDirectories: _forbidden(settings),
      requireExecuteBit: !Platform.isWindows,
    );
    if (rejection != null) {
      return (version: null, errorCode: rejection);
    }
    if (kind == BinaryKind.ffmpeg) {
      final probe = _ffprobeBeside(facts.resolved!);
      if (probe == null) {
        return (version: null, errorCode: 'ffprobe_missing');
      }
      final probeFacts = ref.read(pathFactsProvider).inspect(probe);
      final probeRejection = evaluateBinaryPath(
        facts: probeFacts,
        forbiddenDirectories: _forbidden(settings),
        requireExecuteBit: !Platform.isWindows,
      );
      if (probeRejection != null) {
        return (version: null, errorCode: 'ffprobe_missing');
      }
    }
    final version = await ref.read(versionProbeProvider).readVersion(path);
    if (version == null) {
      return (version: null, errorCode: 'version_failed');
    }
    return (version: version, errorCode: null);
  }

  List<String> _forbidden(AppSettings settings) {
    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    return forbiddenBinaryDirectories(
      home: home,
      temp: Directory.systemTemp.path,
      destination: settings.defaultDownloadFolder,
    );
  }

  String? _ffprobeBeside(String ffmpegPath) {
    final directory = p.dirname(ffmpegPath);
    final names = Platform.isWindows
        ? ['ffprobe.exe', 'ffprobe']
        : ['ffprobe', 'ffprobe.exe'];
    for (final name in names) {
      final candidate = p.join(directory, name);
      final facts = ref.read(pathFactsProvider).inspect(candidate);
      if (facts.kind == PathKind.file) {
        return candidate;
      }
    }
    return null;
  }
}
