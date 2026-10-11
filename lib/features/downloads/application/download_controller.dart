import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dv_max_easy/features/downloads/domain/download_failure.dart';
import 'package:dv_max_easy/features/downloads/domain/download_job.dart';
import 'package:dv_max_easy/features/downloads/domain/download_plan.dart';
import 'package:dv_max_easy/features/downloads/domain/library.dart';
import 'package:dv_max_easy/features/downloads/domain/retention.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/io_file_stamp.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/json_job_store.dart';
import 'package:dv_max_easy/features/profiles/domain/profile.dart';
import 'package:dv_max_easy/features/profiles/infrastructure/json_profile_store.dart';
import 'package:dv_max_easy/features/settings/application/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:dv_max_easy/features/downloads/domain/download_job.dart';

final downloadControllerProvider =
    NotifierProvider<DownloadController, List<DownloadJob>>(
      DownloadController.new,
    );

/// Fila já existente ao abrir. O app deixa vazia; o teste injeta um item.
final initialDownloadsProvider = Provider<List<DownloadJob>>((ref) => const []);

final duplicateNoticeProvider = NotifierProvider<DuplicateNotice, String?>(
  DuplicateNotice.new,
);

final class DuplicateNotice extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String jobId) => state = jobId;

  void clear() => state = null;
}

final class DownloadController extends Notifier<List<DownloadJob>> {
  final Map<String, Process> _processes = {};
  Timer? _saveTimer;

  @override
  List<DownloadJob> build() {
    ref.onDispose(() {
      _saveTimer?.cancel();
    });
    return ref.watch(initialDownloadsProvider);
  }

  Future<void> enqueue(String raw) async {
    final url = raw.trim();
    if (!isHttpUrl(url)) {
      return;
    }
    final prior = earlierSuccess(state, url);
    final notice = ref.read(duplicateNoticeProvider.notifier);
    if (prior == null) {
      notice.clear();
    } else {
      notice.show(prior.id);
    }
    final settings = ref.read(settingsControllerProvider).asData?.value;
    final ytDlp = settings?.settings.ytDlpPath;
    final ffmpeg = settings?.settings.ffmpegPath;
    if (settings == null || ytDlp == null || ffmpeg == null) {
      _addFailed(url, '', 'missing_binary');
      return;
    }
    final folder = await _folder(settings.settings.defaultDownloadFolder);
    if (folder == null) {
      _addFailed(url, '', 'missing_folder');
      return;
    }
    final document = await ref.read(profileStoreProvider).ensureLoaded();
    final profile = _profile(
      document.profiles,
      settings.settings.selectedProfileId,
    );
    final destination = profile.destinationFolder ?? folder;
    await Directory(destination).create(recursive: true);
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final job = DownloadJob(
      id: id,
      url: url,
      profileName: profile.name,
      running: true,
      detail: 'starting',
      audio: profile.isAudio,
      qualityLabel: _quality(profile),
      containerLabel: profile.container.name,
      destination: destination,
    );
    _set([job, ...state], immediate: true);
    await _spawn(
      job: job,
      ytDlp: ytDlp,
      ffmpeg: ffmpeg,
      profile: profile,
      destination: destination,
    );
  }

  Future<void> retry(String id) async {
    final existing = _job(id);
    if (existing == null || existing.running) {
      return;
    }
    final settings = ref.read(settingsControllerProvider).asData?.value;
    final ytDlp = settings?.settings.ytDlpPath;
    final ffmpeg = settings?.settings.ffmpegPath;
    if (settings == null || ytDlp == null || ffmpeg == null) {
      _replace(
        existing.copyWith(running: false, error: 'missing_binary'),
        immediate: true,
      );
      return;
    }
    final document = await ref.read(profileStoreProvider).ensureLoaded();
    final profile = _profile(
      document.profiles,
      settings.settings.selectedProfileId,
    );
    final destination =
        existing.destination ??
        profile.destinationFolder ??
        settings.settings.defaultDownloadFolder;
    if (destination == null || destination.isEmpty) {
      _replace(
        existing.copyWith(running: false, error: 'missing_folder'),
        immediate: true,
      );
      return;
    }
    final job = existing.copyWith(
      running: true,
      detail: 'starting',
      clearError: true,
      clearErrorDetail: true,
      clearFraction: true,
    );
    _replace(job, immediate: true);
    await _spawn(
      job: job,
      ytDlp: ytDlp,
      ffmpeg: ffmpeg,
      profile: profile,
      destination: destination,
    );
  }

  Future<void> _spawn({
    required DownloadJob job,
    required String ytDlp,
    required String ffmpeg,
    required Profile profile,
    required String destination,
  }) async {
    final args = downloadArguments(
      profile: profile,
      destination: destination,
      ffmpegPath: ffmpeg,
      url: job.url,
    );
    try {
      final process = await Process.start(ytDlp, args);
      _processes[job.id] = process;
      _listen(job.id, process.stdout);
      _listen(job.id, process.stderr);
      final code = await process.exitCode;
      _processes.remove(job.id);
      final current = _job(job.id);
      if (current == null || !current.running) {
        return;
      }
      final failure = code == 0
          ? null
          : classifyDownloadFailure(current.errorDetail ?? '');
      _replace(
        current.copyWith(
          running: false,
          error: failure,
          clearError: failure == null,
          detail: code == 0 ? 'done' : current.detail,
          clearErrorDetail: failure == null,
          clearPurged: failure == null,
        ),
        immediate: true,
      );
    } on Object catch (error) {
      _processes.remove(job.id);
      final current = _job(job.id);
      if (current == null) {
        return;
      }
      _replace(
        current.copyWith(
          running: false,
          error: 'failed',
          errorDetail: '$error',
        ),
        immediate: true,
      );
    }
  }

  void cancelNewest() {
    for (final job in state) {
      if (job.running) {
        _stop(job.id);
        return;
      }
    }
  }

  void cancel(String id) {
    _stop(id);
  }

  Future<int> purgeExpired() async {
    final document = await ref.read(profileStoreProvider).ensureLoaded();
    final now = ref.read(clockProvider).now();
    final reader = ref.read(fileStampReaderProvider);
    final due = dueJobs(
      jobs: state,
      profiles: document.profiles,
      now: now,
      stampOf: reader.stamp,
    );
    final purged = <String, DateTime>{};
    for (final job in due) {
      final path = job.outputPath;
      if (path == null) {
        continue;
      }
      try {
        final file = File(path);
        if (!file.existsSync() ||
            FileSystemEntity.typeSync(path) != FileSystemEntityType.file) {
          continue;
        }
        file.deleteSync();
        if (file.existsSync()) {
          continue;
        }
        purged[job.id] = now;
      } on Object {
        // O arquivo ficou no disco; o histórico também fica.
      }
    }
    if (purged.isEmpty) {
      return 0;
    }
    _set([
      for (final job in state)
        if (purged[job.id] case final at?) job.copyWith(purgedAt: at) else job,
    ], immediate: true);
    return purged.length;
  }

  void setKeepFile(String id, {required bool keep}) {
    final current = _job(id);
    if (current == null || current.keepFile == keep) {
      return;
    }
    _replace(current.copyWith(keepFile: keep), immediate: true);
  }

  void clearFinished() {
    _set([
      for (final job in state)
        if (job.running || job.error != null) job,
    ], immediate: true);
  }

  String? _quality(Profile profile) {
    return switch (profile.preset) {
      QualityPreset.h1080 => '1080p',
      QualityPreset.h720 => '720p',
      _ => null,
    };
  }

  Future<String?> _folder(String? folder) async {
    if (folder == null || folder.isEmpty) {
      return null;
    }
    return folder;
  }

  Profile _profile(List<Profile> profiles, String? selectedId) {
    for (final profile in profiles) {
      if (profile.id == selectedId) {
        return profile;
      }
    }
    return profiles.isEmpty ? filmsPreset() : profiles.first;
  }

  void _listen(String id, Stream<List<int>> stream) {
    var pending = '';
    stream.transform(utf8.decoder).listen((chunk) {
      pending += chunk;
      final parts = pending.split(RegExp(r'\r\n|\n|\r'));
      pending = parts.removeLast();
      for (final part in parts) {
        _applyLine(id, part);
      }
    });
  }

  void _applyLine(String id, String line) {
    final current = _job(id);
    if (current == null) {
      return;
    }
    final progress = parseDownloadLine(line);
    if (progress == null) {
      final note = notableErrorLine(line);
      if (note != null) {
        _replace(current.copyWith(errorDetail: note));
      }
      return;
    }
    _replace(
      current.copyWith(
        fraction: progress.fraction,
        detail: progress.outputPath != null
            ? current.detail
            : progress.detail ?? current.detail,
        outputPath: progress.outputPath,
        downloaded: progress.downloaded,
        total: progress.total,
        speed: progress.speed,
        eta: progress.eta,
        thumbnailUrl: progress.thumbnailUrl,
      ),
    );
  }

  void _stop(String id) {
    final process = _processes.remove(id);
    process?.kill();
    final current = _job(id);
    if (current == null) {
      return;
    }
    _replace(
      current.copyWith(running: false, detail: 'cancelled'),
      immediate: true,
    );
  }

  void _addFailed(String url, String profileName, String error) {
    _set([
      DownloadJob(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        url: url,
        profileName: profileName,
        running: false,
        error: error,
      ),
      ...state,
    ], immediate: true);
  }

  DownloadJob? _job(String id) {
    for (final job in state) {
      if (job.id == id) {
        return job;
      }
    }
    return null;
  }

  void _replace(DownloadJob job, {bool immediate = false}) {
    _set([
      for (final current in state)
        if (current.id == job.id) job else current,
    ], immediate: immediate);
  }

  void _set(List<DownloadJob> jobs, {required bool immediate}) {
    state = jobs;
    if (immediate) {
      _saveTimer?.cancel();
      _saveTimer = null;
      _write();
      return;
    }
    if (_saveTimer != null) {
      return;
    }
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveTimer = null;
      _write();
    });
  }

  void _write() {
    ref.read(jobStoreProvider).save(state);
  }
}
