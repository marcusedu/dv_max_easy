import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/convert/application/convert_request.dart';
import 'package:dv_max_easy/features/convert/domain/convert_plan.dart';
import 'package:dv_max_easy/features/downloads/domain/cut_plan.dart';
import 'package:dv_max_easy/features/settings/application/settings_controller.dart';
import 'package:dv_max_easy/l10n/app_localizations.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

class ConvertPage extends ConsumerStatefulWidget {
  const ConvertPage({super.key});

  @override
  ConsumerState<ConvertPage> createState() => _ConvertPageState();
}

class _ConvertPageState extends ConsumerState<ConvertPage> {
  ConvertTarget _target = ConvertTarget.mp4;
  ConvertFacts? _facts;
  bool _probing = false;
  bool _saving = false;
  double? _progress;
  String? _error;
  String? _saved;
  Process? _process;

  @override
  void initState() {
    super.initState();
    final path = ref.read(convertRequestProvider);
    if (path != null) {
      _probe(path);
    }
  }

  @override
  void dispose() {
    final process = _process;
    _process = null;
    if (process != null) {
      try {
        process.kill();
      } on Object {
        // O processo já tinha terminado.
      }
    }
    super.dispose();
  }

  Future<void> _pick() async {
    const group = XTypeGroup(
      label: 'media',
      extensions: [
        'mp4',
        'mkv',
        'webm',
        'avi',
        'mpg',
        'mpeg',
        'mov',
        'm4v',
        'mp3',
        'm4a',
        'wav',
        'flac',
        'aac',
        'ogg',
      ],
    );
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null) {
      return;
    }
    ref.read(convertRequestProvider.notifier).open(file.path);
    await _probe(file.path);
  }

  Future<void> _probe(String path) async {
    setState(() {
      _facts = null;
      _error = null;
      _saved = null;
      _probing = true;
    });
    final ffmpeg = ref
        .read(settingsControllerProvider)
        .asData
        ?.value
        .settings
        .ffmpegPath;
    final probe = ffmpeg == null || ffmpeg.isEmpty
        ? null
        : _ffprobeBeside(ffmpeg);
    if (probe == null) {
      if (mounted) {
        setState(() => _probing = false);
      }
      return;
    }
    try {
      final result = await Process.run(probe, probeArguments(path));
      final facts = convertFactsFromProbe('${result.stdout}');
      if (!mounted) {
        return;
      }
      setState(() {
        _facts = facts;
        _probing = false;
      });
    } on Object {
      if (mounted) {
        setState(() => _probing = false);
      }
    }
  }

  String? _ffprobeBeside(String ffmpegPath) {
    final names = Platform.isWindows
        ? const ['ffprobe.exe', 'ffprobe']
        : const ['ffprobe', 'ffprobe.exe'];
    for (final name in names) {
      final candidate = p.join(p.dirname(ffmpegPath), name);
      if (File(candidate).existsSync()) {
        return candidate;
      }
    }
    return null;
  }

  Future<void> _convert(String path) async {
    final l10n = AppLocalizations.of(context);
    final ffmpeg = ref
        .read(settingsControllerProvider)
        .asData
        ?.value
        .settings
        .ffmpegPath;
    if (ffmpeg == null || ffmpeg.isEmpty) {
      setState(() => _error = l10n.convertNoBinary);
      return;
    }
    final facts = _facts;
    if (facts != null && !facts.video && !targetIsAudio(_target)) {
      setState(() => _error = l10n.convertNeedVideo);
      return;
    }
    final output = suggestConvertPath(
      path,
      _target,
      (candidate) => File(candidate).existsSync(),
    );
    if (output == null || _saving) {
      setState(() => _error = l10n.convertFailed);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _saved = null;
      _progress = facts?.duration == null ? null : 0;
    });
    try {
      final process = await Process.start(
        ffmpeg,
        convertArguments(
          input: path,
          output: output,
          target: _target,
          audio: facts?.audio ?? true,
        ),
      );
      if (!mounted) {
        process.kill();
        return;
      }
      _process = process;
      final total = facts?.duration;
      if (total != null) {
        process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) {
              final fraction = progressFraction(line, total);
              if (fraction != null && mounted) {
                setState(() => _progress = fraction);
              }
            });
      } else {
        unawaited(process.stdout.drain<void>());
      }
      unawaited(process.stderr.drain<void>());
      final code = await process.exitCode;
      if (code != 0) {
        _deleteQuiet(output);
        if (mounted) {
          setState(() {
            _saving = false;
            _progress = null;
            _process = null;
            _error = l10n.convertFailed;
          });
        }
        return;
      }
      if (!mounted) {
        return;
      }
      _process = null;
      setState(() {
        _saving = false;
        _progress = null;
        _saved = l10n.convertSaved;
      });
    } on Object {
      _deleteQuiet(output);
      if (mounted) {
        setState(() {
          _saving = false;
          _progress = null;
          _process = null;
          _error = l10n.convertFailed;
        });
      }
    }
  }

  void _deleteQuiet(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } on Object {
      // O arquivo parcial pode já ter saído.
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(convertRequestProvider, (previous, next) {
      if (next != null && next != previous && !_saving) {
        _probe(next);
      }
    });
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final path = ref.watch(convertRequestProvider);
    return ListView(
      children: [
        Text(
          l10n.convertHelp,
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.l),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _saving ? null : _pick,
            icon: const Icon(Icons.folder_open_outlined, size: 18),
            label: Text(l10n.convertPick),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          path ?? l10n.convertNone,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text.bodyMedium,
        ),
        if (_probing) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
        const SizedBox(height: AppSpacing.l),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final target in ConvertTarget.values)
              ChoiceChip(
                label: Text(target.name.toUpperCase()),
                selected: _target == target,
                onSelected: _saving
                    ? null
                    : (selected) {
                        if (selected) {
                          setState(() {
                            _target = target;
                            _error = null;
                          });
                        }
                      },
              ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: text.bodyMedium?.copyWith(color: scheme.error)),
        ],
        if (_saved != null) ...[
          const SizedBox(height: 12),
          Text(_saved!, style: text.bodyMedium),
        ],
        if (_saving) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 8),
          Text(l10n.convertSaving, style: text.bodySmall),
        ],
        const SizedBox(height: AppSpacing.l),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: path == null || _saving || _probing
                ? null
                : () => _convert(path),
            child: Text(l10n.convertSave),
          ),
        ),
      ],
    );
  }
}
