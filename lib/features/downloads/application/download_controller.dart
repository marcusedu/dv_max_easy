import 'dart:convert';
import 'dart:io';

import 'package:dv_max_easy/features/downloads/domain/download_plan.dart';
import 'package:dv_max_easy/features/profiles/domain/profile.dart';
import 'package:dv_max_easy/features/profiles/infrastructure/json_profile_store.dart';
import 'package:dv_max_easy/features/settings/application/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final downloadControllerProvider =
    NotifierProvider<DownloadController, List<DownloadJob>>(
      DownloadController.new,
    );

/// Fila já existente ao abrir. O app deixa vazia; o teste injeta um item.
final initialDownloadsProvider = Provider<List<DownloadJob>>((ref) => const []);

final class DownloadJob {
  const DownloadJob({
    required this.id,
    required this.url,
    required this.profileName,
    required this.running,
    this.fraction,
    this.detail,
    this.outputPath,
    this.error,
    this.audio = false,
    this.qualityLabel,
    this.containerLabel = '',
    this.destination,
    this.downloaded,
    this.total,
    this.speed,
    this.eta,
    this.thumbnailUrl,
  });

  final String id;
  final String url;
  final String profileName;
  final bool running;
  final double? fraction;
  final String? detail;
  final String? outputPath;
  final String? error;
  final bool audio;
  final String? qualityLabel;
  final String containerLabel;
  final String? destination;
  final int? downloaded;
  final int? total;
  final double? speed;
  final int? eta;
  final String? thumbnailUrl;

  DownloadJob copyWith({
    bool? running,
    double? fraction,
    bool clearFraction = false,
    String? detail,
    String? outputPath,
    String? error,
    bool clearError = false,
    int? downloaded,
    int? total,
    double? speed,
    int? eta,
    String? thumbnailUrl,
  }) {
    return DownloadJob(
      id: id,
      url: url,
      profileName: profileName,
      running: running ?? this.running,
      fraction: clearFraction ? null : fraction ?? this.fraction,
      detail: detail ?? this.detail,
      outputPath: outputPath ?? this.outputPath,
      error: clearError ? null : error ?? this.error,
      audio: audio,
      qualityLabel: qualityLabel,
      containerLabel: containerLabel,
      destination: destination,
      downloaded: downloaded ?? this.downloaded,
      total: total ?? this.total,
      speed: speed ?? this.speed,
      eta: eta ?? this.eta,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }
}

final class DownloadController extends Notifier<List<DownloadJob>> {
  final Map<String, Process> _processes = {};

  @override
  List<DownloadJob> build() => ref.watch(initialDownloadsProvider);

  Future<void> enqueue(String raw) async {
    final url = raw.trim();
    if (!isHttpUrl(url)) {
      return;
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
    state = [job, ...state];
    final args = downloadArguments(
      profile: profile,
      destination: destination,
      ffmpegPath: ffmpeg,
      url: url,
    );
    try {
      final process = await Process.start(ytDlp, args);
      _processes[id] = process;
      _listen(id, process.stdout);
      _listen(id, process.stderr);
      final code = await process.exitCode;
      _processes.remove(id);
      final current = _job(id);
      if (current == null || !current.running) {
        return;
      }
      _replace(
        current.copyWith(
          running: false,
          error: code == 0 ? null : 'exit_$code',
          clearError: code == 0,
          detail: code == 0 ? 'done' : current.detail,
        ),
      );
    } on Object catch (error) {
      _processes.remove(id);
      final current = _job(id);
      if (current == null) {
        return;
      }
      _replace(current.copyWith(running: false, error: '$error'));
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

  void clearFinished() {
    state = [
      for (final job in state)
        if (job.running || job.error != null) job,
    ];
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
    _replace(current.copyWith(running: false, detail: 'cancelled'));
  }

  void _addFailed(String url, String profileName, String error) {
    state = [
      DownloadJob(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        url: url,
        profileName: profileName,
        running: false,
        error: error,
      ),
      ...state,
    ];
  }

  DownloadJob? _job(String id) {
    for (final job in state) {
      if (job.id == id) {
        return job;
      }
    }
    return null;
  }

  void _replace(DownloadJob job) {
    state = [
      for (final current in state)
        if (current.id == job.id) job else current,
    ];
  }
}
