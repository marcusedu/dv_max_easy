import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/downloads/domain/cut_plan.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/file_actions.dart';
import 'package:dv_max_easy/features/settings/application/settings_controller.dart';
import 'package:dv_max_easy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

class CutEditorPage extends ConsumerStatefulWidget {
  const CutEditorPage({required this.path, super.key});

  final String path;

  @override
  ConsumerState<CutEditorPage> createState() => _CutEditorPageState();
}

class _CutEditorPageState extends ConsumerState<CutEditorPage> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _removed = <Span>[];
  Duration? _duration;
  bool _audio = false;
  bool _probeError = false;
  bool _saving = false;
  double? _progress;
  String? _error;
  String? _ffmpeg;
  Process? _process;

  @override
  void initState() {
    super.initState();
    _probe();
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
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  Future<void> _probe() async {
    final ffmpeg = ref
        .read(settingsControllerProvider)
        .asData
        ?.value
        .settings
        .ffmpegPath;
    if (ffmpeg == null || ffmpeg.isEmpty) {
      if (mounted) {
        setState(() => _probeError = true);
      }
      return;
    }
    _ffmpeg = ffmpeg;
    final probe = _ffprobeBeside(ffmpeg);
    if (probe == null) {
      if (mounted) {
        setState(() => _probeError = true);
      }
      return;
    }
    try {
      final result = await Process.run(probe, probeArguments(widget.path));
      final facts = mediaFactsFromProbe('${result.stdout}');
      if (!mounted) {
        return;
      }
      if (facts == null) {
        setState(() => _probeError = true);
        return;
      }
      setState(() {
        _duration = facts.duration;
        _audio = facts.audio;
      });
    } on Object {
      if (mounted) {
        setState(() => _probeError = true);
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

  Span? _typedSpan() {
    final start = parseClock(_from.text);
    final end = parseClock(_to.text);
    if (start == null || end == null) {
      return null;
    }
    final span = Span(start, end);
    return span.valid ? span : null;
  }

  void _addRemoval() {
    final l10n = AppLocalizations.of(context);
    final span = _typedSpan();
    if (span == null) {
      setState(() => _error = l10n.cutNeedRange);
      return;
    }
    setState(() {
      _removed.add(span);
      _error = null;
    });
  }

  void _keepOnly() {
    final l10n = AppLocalizations.of(context);
    final duration = _duration;
    final span = _typedSpan();
    if (duration == null || span == null) {
      setState(() => _error = l10n.cutNeedRange);
      return;
    }
    setState(() {
      _removed
        ..clear()
        ..addAll(keepOnly(duration, span));
      _error = null;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final duration = _duration;
    final ffmpeg = _ffmpeg;
    if (duration == null || ffmpeg == null || _saving) {
      return;
    }
    final kept = keptAfterCuts(duration, _removed);
    if (kept.isEmpty) {
      setState(() => _error = l10n.cutEmpty);
      return;
    }
    if (!cutsChangeTheFile(duration, kept)) {
      setState(() => _error = l10n.cutNothing);
      return;
    }
    final output = suggestCutPath(
      widget.path,
      (path) => File(path).existsSync(),
    );
    final args = output == null
        ? null
        : cutArguments(
            input: widget.path,
            output: output,
            kept: kept,
            audio: _audio,
          );
    if (output == null || args == null) {
      setState(() => _error = l10n.cutFailed);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _progress = 0;
    });
    final total = kept.fold<Duration>(
      Duration.zero,
      (sum, span) => sum + (span.end - span.start),
    );
    try {
      final process = await Process.start(ffmpeg, args);
      if (!mounted) {
        process.kill();
        return;
      }
      _process = process;
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            final fraction = progressFraction(line, total);
            if (fraction != null && mounted) {
              setState(() => _progress = fraction);
            }
          });
      unawaited(process.stderr.drain<void>());
      final code = await process.exitCode;
      if (code != 0) {
        _deleteQuiet(output);
        if (mounted) {
          setState(() {
            _saving = false;
            _progress = null;
            _process = null;
            _error = l10n.cutFailed;
          });
        }
        return;
      }
      if (!mounted) {
        return;
      }
      _process = null;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.cutSaved)));
    } on Object {
      _deleteQuiet(output);
      if (mounted) {
        setState(() {
          _saving = false;
          _progress = null;
          _process = null;
          _error = l10n.cutFailed;
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
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final duration = _duration;
    final kept = duration == null ? null : keptAfterCuts(duration, _removed);
    final summary = switch (kept) {
      null => null,
      List<Span>(isEmpty: true) => l10n.cutEmpty,
      final List<Span> parts when !cutsChangeTheFile(duration!, parts) =>
        l10n.cutNothing,
      final List<Span> parts => l10n.cutKept(describeKept(parts)),
    };
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(l10n.cutTitle, style: text.titleLarge),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  fileTitle(widget.path, widget.path),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.cutHelp,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                if (_probeError)
                  Text(
                    l10n.cutNoProbe,
                    style: text.bodyMedium?.copyWith(color: scheme.error),
                  )
                else if (duration == null)
                  const LinearProgressIndicator()
                else ...[
                  _CutTimeline(duration: duration, kept: kept ?? const []),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      formatSpan(duration),
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _timeField(l10n.cutFrom, _from)),
                      const SizedBox(width: 12),
                      Expanded(child: _timeField(l10n.cutTo, _to)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PressableScale(
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : _addRemoval,
                          icon: const Icon(Icons.content_cut, size: 16),
                          label: Text(l10n.cutRemove),
                        ),
                      ),
                      PressableScale(
                        child: OutlinedButton(
                          onPressed: _saving ? null : _keepOnly,
                          child: Text(l10n.cutKeepOnly),
                        ),
                      ),
                    ],
                  ),
                  if (_removed.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var index = 0; index < _removed.length; index++)
                          InputChip(
                            label: Text(
                              '${formatSpan(_removed[index].start)}–${formatSpan(_removed[index].end)}',
                            ),
                            onDeleted: _saving
                                ? null
                                : () =>
                                      setState(() => _removed.removeAt(index)),
                          ),
                      ],
                    ),
                  ],
                  if (summary != null) ...[
                    const SizedBox(height: 16),
                    Text(summary, style: text.bodyMedium),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: text.bodySmall?.copyWith(color: scheme.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (_saving) ...[
                    SmoothProgressIndicator(value: _progress),
                    const SizedBox(height: 8),
                    Text(l10n.cutSaving, style: text.bodySmall),
                    const SizedBox(height: 12),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PressableScale(
                      child: FilledButton(
                        onPressed:
                            _saving ||
                                kept == null ||
                                !cutsChangeTheFile(duration, kept)
                            ? null
                            : _save,
                        child: Text(l10n.cutSave),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeField(String label, TextEditingController controller) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: controller,
      enabled: !_saving,
      decoration: InputDecoration(
        labelText: label,
        hintText: l10n.timeHint,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppSpacing.controlRadius),
          ),
        ),
      ),
    );
  }
}

class _CutTimeline extends StatelessWidget {
  const _CutTimeline({required this.duration, required this.kept});

  final Duration duration;
  final List<Span> kept;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 28,
        width: double.infinity,
        child: CustomPaint(
          painter: _CutPainter(
            duration: duration,
            kept: kept,
            keptColor: scheme.primary,
            removedColor: scheme.error.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class _CutPainter extends CustomPainter {
  _CutPainter({
    required this.duration,
    required this.kept,
    required this.keptColor,
    required this.removedColor,
  });

  final Duration duration;
  final List<Span> kept;
  final Color keptColor;
  final Color removedColor;

  @override
  void paint(Canvas canvas, Size size) {
    final total = duration.inMilliseconds;
    if (total <= 0) {
      return;
    }
    canvas.drawRect(Offset.zero & size, Paint()..color = removedColor);
    final keptPaint = Paint()..color = keptColor;
    for (final span in kept) {
      final left = size.width * span.start.inMilliseconds / total;
      final right = size.width * span.end.inMilliseconds / total;
      canvas.drawRect(Rect.fromLTRB(left, 0, right, size.height), keptPaint);
    }
  }

  @override
  bool shouldRepaint(_CutPainter oldDelegate) {
    if (oldDelegate.duration != duration ||
        oldDelegate.kept.length != kept.length ||
        oldDelegate.keptColor != keptColor ||
        oldDelegate.removedColor != removedColor) {
      return true;
    }
    for (var index = 0; index < kept.length; index++) {
      if (oldDelegate.kept[index].start != kept[index].start ||
          oldDelegate.kept[index].end != kept[index].end) {
        return true;
      }
    }
    return false;
  }
}
