import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/downloads/domain/cut_plan.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/file_actions.dart';
import 'package:dv_max_easy/features/settings/application/settings_controller.dart';
import 'package:dv_max_easy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;

class CutEditorPage extends ConsumerStatefulWidget {
  const CutEditorPage({
    required this.path,
    @visibleForTesting this.initialFacts,
    super.key,
  });

  final String path;
  final MediaFacts? initialFacts;

  @override
  ConsumerState<CutEditorPage> createState() => _CutEditorPageState();
}

class _CutEditorPageState extends ConsumerState<CutEditorPage> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _fromFocus = FocusNode();
  final _toFocus = FocusNode();
  final _keyboardFocus = FocusNode();
  final _removed = <Span>[];

  Duration? _duration;
  bool _audio = false;
  bool _probeError = false;
  bool _saving = false;
  double? _progress;
  String? _error;
  String? _ffmpeg;
  Process? _process;
  RangeValues _rangeValues = const RangeValues(0, 0);

  // Player state
  Player? _player;
  VideoController? _videoController;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<bool>? _playingSub;
  Duration _currentPos = Duration.zero;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _playingSelection = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    if (widget.initialFacts != null) {
      final facts = widget.initialFacts!;
      _duration = facts.duration;
      _audio = facts.audio;
      final maxMs = facts.duration.inMilliseconds.toDouble();
      _rangeValues = RangeValues(0, maxMs);
      _from.text = formatSpan(Duration.zero);
      _to.text = formatSpan(facts.duration);
    } else {
      _probe();
    }
  }

  void _initPlayer() {
    try {
      final player = Player();
      final controller = VideoController(player);
      _player = player;
      _videoController = controller;

      _posSub = player.stream.position.listen((pos) {
        if (!mounted) return;
        setState(() {
          _currentPos = pos;
        });

        // Se estiver reproduzindo trecho, pausar ao atingir o fim da seleção
        if (_playingSelection) {
          final span = _typedSpan();
          if (span != null && pos >= span.end) {
            _playingSelection = false;
            player.pause();
          }
        }
      });

      _playingSub = player.stream.playing.listen((playing) {
        if (!mounted) return;
        setState(() {
          _isPlaying = playing;
        });
      });

      player.open(Media(widget.path), play: false);
    } catch (_) {
      // Ambiente headless de teste ou sem libmpv
      _player = null;
      _videoController = null;
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _playingSub?.cancel();
    final player = _player;
    _player = null;
    _videoController = null;
    player?.dispose();

    final process = _process;
    _process = null;
    if (process != null) {
      try {
        process.kill();
      } on Object {
        // O processo já tinha terminado.
      }
    }
    _fromFocus.dispose();
    _toFocus.dispose();
    _keyboardFocus.dispose();
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
        final maxMs = facts.duration.inMilliseconds.toDouble();
        _rangeValues = RangeValues(0, maxMs);
        _from.text = formatSpan(Duration.zero);
        _to.text = formatSpan(facts.duration);
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

  void _onRangeSliderChanged(RangeValues values) {
    if (_saving) return;
    final oldStart = _rangeValues.start;
    final newStart = values.start;
    final newEnd = values.end;

    setState(() {
      _rangeValues = values;
      _from.text = formatSpan(Duration(milliseconds: newStart.round()));
      _to.text = formatSpan(Duration(milliseconds: newEnd.round()));
      _error = null;
    });

    // Seek player para o ponto que o usuário está ajustando
    if ((newStart - oldStart).abs() > 1.0) {
      _player?.seek(Duration(milliseconds: newStart.round()));
    } else {
      _player?.seek(Duration(milliseconds: newEnd.round()));
    }
  }

  void _onTimeInputChanged() {
    final start = parseClock(_from.text);
    final end = parseClock(_to.text);
    final duration = _duration;
    if (start != null && end != null && duration != null) {
      final startMs = start.inMilliseconds.toDouble();
      final endMs = end.inMilliseconds.toDouble();
      final maxMs = duration.inMilliseconds.toDouble();
      if (startMs >= 0 && startMs <= endMs && endMs <= maxMs) {
        setState(() {
          _rangeValues = RangeValues(startMs, endMs);
        });
      }
    }
  }

  void _nudge(bool isStart, Duration delta) {
    final duration = _duration;
    if (duration == null || _saving) return;
    final current = _typedSpan() ??
        Span(
          Duration(milliseconds: _rangeValues.start.round()),
          Duration(milliseconds: _rangeValues.end.round()),
        );

    if (isStart) {
      var newStart = current.start + delta;
      if (newStart < Duration.zero) newStart = Duration.zero;
      if (newStart >= current.end) {
        newStart = current.end - const Duration(seconds: 1);
        if (newStart < Duration.zero) newStart = Duration.zero;
      }
      _from.text = formatSpan(newStart);
      _player?.seek(newStart);
    } else {
      var newEnd = current.end + delta;
      if (newEnd > duration) newEnd = duration;
      if (newEnd <= current.start) {
        newEnd = current.start + const Duration(seconds: 1);
        if (newEnd > duration) newEnd = duration;
      }
      _to.text = formatSpan(newEnd);
      _player?.seek(newEnd);
    }
    _onTimeInputChanged();
  }

  void _setStart(Duration time) {
    if (_saving) return;
    _from.text = formatSpan(time);
    _player?.seek(time);
    _onTimeInputChanged();
  }

  void _setEnd(Duration time) {
    if (_saving) return;
    _to.text = formatSpan(time);
    _player?.seek(time);
    _onTimeInputChanged();
  }

  void _togglePlay() {
    final player = _player;
    if (player == null) return;
    player.playOrPause();
  }

  void _toggleMute() {
    final player = _player;
    if (player == null) return;
    setState(() {
      _isMuted = !_isMuted;
      player.setVolume(_isMuted ? 0.0 : 100.0);
    });
  }

  void _playSelection() {
    final player = _player;
    final span = _typedSpan();
    if (player == null || span == null) return;

    _playingSelection = true;
    player.seek(span.start);
    player.play();
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

  void _clearCuts() {
    if (_saving) return;
    setState(() {
      _removed.clear();
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

    _player?.pause();

    setState(() {
      _saving = true;
      _error = null;
      _progress = 0;
    });
    final total = totalSpanDuration(kept);
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

  RangeValues _clampedRange(Duration duration) {
    final max = duration.inMilliseconds.toDouble();
    if (max <= 0) return const RangeValues(0, 0);
    final start = _rangeValues.start.clamp(0.0, max);
    final end = _rangeValues.end.clamp(start, max);
    return RangeValues(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final duration = _duration;
    final kept = duration == null ? null : keptAfterCuts(duration, _removed);
    final keptDuration = kept == null ? Duration.zero : totalSpanDuration(kept);
    final removedDuration = duration == null
        ? Duration.zero
        : (duration > keptDuration ? duration - keptDuration : Duration.zero);

    final canSave = !_saving &&
        duration != null &&
        kept != null &&
        cutsChangeTheFile(duration, kept);

    final suggestedOutput = suggestCutPath(
      widget.path,
      (path) => File(path).existsSync(),
    );

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: KeyboardListener(
          focusNode: _keyboardFocus,
          autofocus: true,
          onKeyEvent: (event) {
            if (event is! KeyDownEvent) return;
            // Se algum campo de texto estiver focado, não interceptar teclas normais
            if (_fromFocus.hasFocus || _toFocus.hasFocus) return;

            if (event.logicalKey == LogicalKeyboardKey.space) {
              _togglePlay();
            } else if (event.logicalKey == LogicalKeyboardKey.keyI) {
              _setStart(_currentPos);
            } else if (event.logicalKey == LogicalKeyboardKey.keyO) {
              _setEnd(_currentPos);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _nudge(true, const Duration(seconds: -1));
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _nudge(true, const Duration(seconds: 1));
            }
          },
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.l, 12, AppSpacing.l, 32),
                children: [
                  // 1. Top Bar
                  Row(
                    children: [
                      PressableScale(
                        child: IconButton(
                          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                          onPressed: _saving ? null : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.cutTitle,
                          style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (_removed.isNotEmpty)
                        PressableScale(
                          child: TextButton.icon(
                            onPressed: _saving ? null : _clearCuts,
                            icon: const Icon(Icons.restart_alt_rounded, size: 16),
                            label: Text(l10n.cutClearAll),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // 2. Video Player / Preview Box
                  if (_videoController != null)
                    _VideoPlayerBox(
                      videoController: _videoController!,
                      isPlaying: _isPlaying,
                      isMuted: _isMuted,
                      currentPos: _currentPos,
                      duration: duration ?? Duration.zero,
                      onPlayPause: _togglePlay,
                      onToggleMute: _toggleMute,
                      onSetStart: () => _setStart(_currentPos),
                      onSetEnd: () => _setEnd(_currentPos),
                      onPlaySelection: _playSelection,
                    )
                  else
                    // Fallback para ambiente de testes ou sem libmpv
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                            ),
                            child: Icon(Icons.movie_outlined, color: scheme.primary, size: 24),
                          ),
                          const SizedBox(width: AppSpacing.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileTitle(widget.path, widget.path),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.titleMedium?.copyWith(fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Tooltip(
                                  message: widget.path,
                                  child: Text(
                                    widget.path,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.m),
                          if (duration != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: scheme.outlineVariant),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.schedule, size: 14, color: scheme.onSurfaceVariant),
                                  const SizedBox(width: 5),
                                  Text(
                                    formatSpan(duration),
                                    style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: scheme.outlineVariant),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _audio ? Icons.audiotrack : Icons.volume_off,
                                    size: 14,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _audio ? l10n.cutWithAudio : l10n.cutWithoutAudio,
                                    style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),

                  // Atalhos de teclado helper banner
                  Row(
                    children: [
                      Icon(Icons.keyboard_outlined, size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.cutKeyboardHelp,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),

                  if (_probeError)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                        border: Border.all(color: scheme.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: scheme.error),
                          const SizedBox(width: AppSpacing.m),
                          Expanded(
                            child: Text(
                              l10n.cutNoProbe,
                              style: text.bodyMedium?.copyWith(color: scheme.error),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (duration == null) ...[
                    const SizedBox(height: 32),
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Carregando informações do vídeo…',
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ] else ...[
                    // 3. Interactive Visual Timeline Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.tune_rounded, size: 18, color: scheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                l10n.cutTimelineTitle,
                                style: text.titleMedium?.copyWith(fontSize: 15),
                              ),
                              const Spacer(),
                              _LegendItem(color: scheme.primary, label: l10n.cutTimelineLegendKept),
                              const SizedBox(width: 14),
                              _LegendItem(
                                color: scheme.error.withValues(alpha: 0.7),
                                label: l10n.cutTimelineLegendRemoved,
                              ),
                              const SizedBox(width: 14),
                              _LegendItem(
                                color: scheme.tertiary,
                                label: l10n.cutTimelineLegendSelection,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.m),

                          // Visual Custom Timeline Bar com Playhead Needle
                          _CutTimeline(
                            duration: duration,
                            kept: kept ?? const [],
                            selection: _typedSpan(),
                            playhead: _currentPos,
                          ),
                          const SizedBox(height: 8),

                          // Interactive Range Slider
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: scheme.primary,
                              inactiveTrackColor: scheme.outlineVariant.withValues(alpha: 0.4),
                              thumbColor: scheme.primary,
                              overlayColor: scheme.primary.withValues(alpha: 0.16),
                              trackHeight: 6,
                              rangeThumbShape: const RoundRangeSliderThumbShape(
                                enabledThumbRadius: 8,
                                elevation: 2,
                              ),
                              showValueIndicator: ShowValueIndicator.onDrag,
                            ),
                            child: RangeSlider(
                              values: _clampedRange(duration),
                              min: 0,
                              max: duration.inMilliseconds.toDouble(),
                              labels: RangeLabels(
                                formatSpan(Duration(milliseconds: _rangeValues.start.round())),
                                formatSpan(Duration(milliseconds: _rangeValues.end.round())),
                              ),
                              onChanged: _saving ? null : _onRangeSliderChanged,
                            ),
                          ),

                          // Time Ticks
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '00:00',
                                  style: text.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  formatSpan(duration ~/ 4),
                                  style: text.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  formatSpan(duration ~/ 2),
                                  style: text.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  formatSpan(Duration(milliseconds: (duration.inMilliseconds * 0.75).round())),
                                  style: text.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  formatSpan(duration),
                                  style: text.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // 4. Fine-Tuning Steppers (Start & End)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _TimeStepperBox(
                            title: l10n.cutFrom,
                            icon: Icons.play_arrow_outlined,
                            controller: _from,
                            focusNode: _fromFocus,
                            enabled: !_saving,
                            hintText: l10n.timeHint,
                            onChanged: (_) => _onTimeInputChanged(),
                            onQuickStart: () => _setStart(Duration.zero),
                            onNudgeMinus5: () => _nudge(true, const Duration(seconds: -5)),
                            onNudgeMinus1: () => _nudge(true, const Duration(seconds: -1)),
                            onNudgePlus1: () => _nudge(true, const Duration(seconds: 1)),
                            onNudgePlus5: () => _nudge(true, const Duration(seconds: 5)),
                            quickLabel: l10n.cutQuickStart,
                            isStart: true,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: _TimeStepperBox(
                            title: l10n.cutTo,
                            icon: Icons.stop_outlined,
                            controller: _to,
                            focusNode: _toFocus,
                            enabled: !_saving,
                            hintText: l10n.timeHint,
                            onChanged: (_) => _onTimeInputChanged(),
                            onQuickEnd: () => _setEnd(duration),
                            onNudgeMinus5: () => _nudge(false, const Duration(seconds: -5)),
                            onNudgeMinus1: () => _nudge(false, const Duration(seconds: -1)),
                            onNudgePlus1: () => _nudge(false, const Duration(seconds: 1)),
                            onNudgePlus5: () => _nudge(false, const Duration(seconds: 5)),
                            quickLabel: l10n.cutQuickEnd,
                            isStart: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // 5. Actions: Add Cut vs Keep Only
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        PressableScale(
                          child: FilledButton.tonalIcon(
                            onPressed: _saving ? null : _addRemoval,
                            icon: const Icon(Icons.content_cut_rounded, size: 16),
                            label: Text(l10n.cutRemove),
                          ),
                        ),
                        PressableScale(
                          child: OutlinedButton.icon(
                            onPressed: _saving ? null : _keepOnly,
                            icon: const Icon(Icons.crop_rounded, size: 16),
                            label: Text(l10n.cutKeepOnly),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.l),

                    // 6. Removed Segments Section
                    AnimatedSize(
                      duration: AppMotion.fast,
                      curve: AppMotion.easeOut,
                      child: _removed.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.m),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                                border: Border.all(color: scheme.outlineVariant),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 18, color: scheme.onSurfaceVariant),
                                  const SizedBox(width: AppSpacing.m),
                                  Expanded(
                                    child: Text(
                                      l10n.cutNoCutsAdded,
                                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(AppSpacing.m),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
                                border: Border.all(color: scheme.outlineVariant),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.content_cut, size: 16, color: scheme.error),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.cutRemovedSegmentsTitle(_removed.length),
                                        style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      const Spacer(),
                                      PressableScale(
                                        child: TextButton(
                                          onPressed: _saving ? null : _clearCuts,
                                          child: Text(l10n.cutClearAll),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _removed.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                                    itemBuilder: (context, index) {
                                      final cut = _removed[index];
                                      final cutDuration = cut.end - cut.start;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: scheme.surfaceContainerLow,
                                          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                                          border: Border.all(color: scheme.outlineVariant),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: scheme.error.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Icon(Icons.content_cut, size: 14, color: scheme.error),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                '${formatSpan(cut.start)}  →  ${formatSpan(cut.end)}',
                                                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: scheme.errorContainer.withValues(alpha: 0.5),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '-${formatSpan(cutDuration)}',
                                                style: text.bodySmall?.copyWith(
                                                  color: scheme.error,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            PressableScale(
                                              child: IconButton(
                                                tooltip: l10n.profileDelete,
                                                iconSize: 18,
                                                onPressed: _saving
                                                    ? null
                                                    : () => setState(() => _removed.removeAt(index)),
                                                icon: const Icon(Icons.delete_outline),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // 7. Comparison / Impact Stats Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatItem(
                                  label: l10n.cutOriginalDuration,
                                  value: formatSpan(duration),
                                ),
                              ),
                              Container(width: 1, height: 36, color: scheme.outlineVariant),
                              Expanded(
                                child: _StatItem(
                                  label: l10n.cutRemovedDuration,
                                  value: removedDuration > Duration.zero
                                    ? '-${formatSpan(removedDuration)}'
                                    : '00:00',
                                  valueColor: removedDuration > Duration.zero
                                      ? scheme.error
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                              Container(width: 1, height: 36, color: scheme.outlineVariant),
                              Expanded(
                                child: _StatItem(
                                  label: l10n.cutFinalDuration,
                                  value: formatSpan(keptDuration),
                                  valueColor: scheme.primary,
                                  bold: true,
                                ),
                              ),
                            ],
                          ),
                          if (kept != null && cutsChangeTheFile(duration, kept)) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.auto_awesome, size: 14, color: scheme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${l10n.cutSummaryParts(kept.length)}: ${describeKept(kept)}',
                                      style: text.bodySmall?.copyWith(
                                        color: scheme.onSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Error Banner
                    AnimatedSize(
                      duration: AppMotion.fast,
                      curve: AppMotion.easeOut,
                      child: _error == null
                          ? const SizedBox.shrink()
                          : Container(
                              margin: const EdgeInsets.only(top: AppSpacing.m),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.m,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.errorContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                                border: Border.all(color: scheme.error.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 18, color: scheme.error),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: text.bodySmall?.copyWith(color: scheme.error),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.l),

                    // 8. Output Preview & Save Section
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
                        border: Border.all(
                          color: canSave
                              ? scheme.primary.withValues(alpha: 0.3)
                              : scheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.output_rounded, size: 18, color: scheme.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Text(
                                l10n.cutOutputLabel,
                                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  suggestedOutput != null ? p.basename(suggestedOutput) : '',
                                  style: text.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.cutPreserveOriginal,
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          if (_saving) ...[
                            const SizedBox(height: AppSpacing.m),
                            SmoothProgressIndicator(value: _progress),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(l10n.cutSaving, style: text.bodySmall),
                                const Spacer(),
                                if (_progress != null)
                                  Text(
                                    '${(_progress! * 100).toInt()}%',
                                    style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                              ],
                            ),
                          ],
                          const SizedBox(height: AppSpacing.m),
                          Align(
                            alignment: Alignment.centerRight,
                            child: PressableScale(
                              child: FilledButton.icon(
                                onPressed: canSave ? _save : null,
                                icon: const Icon(Icons.save_alt_rounded, size: 18),
                                label: Text(l10n.cutSave),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoPlayerBox extends StatelessWidget {
  const _VideoPlayerBox({
    required this.videoController,
    required this.isPlaying,
    required this.isMuted,
    required this.currentPos,
    required this.duration,
    required this.onPlayPause,
    required this.onToggleMute,
    required this.onSetStart,
    required this.onSetEnd,
    required this.onPlaySelection,
  });

  final VideoController videoController;
  final bool isPlaying;
  final bool isMuted;
  final Duration currentPos;
  final Duration duration;
  final VoidCallback onPlayPause;
  final VoidCallback onToggleMute;
  final VoidCallback onSetStart;
  final VoidCallback onSetEnd;
  final VoidCallback onPlaySelection;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Video Canvas
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Video(
                controller: videoController,
                controls: NoVideoControls,
              ),
            ),
          ),
          // Player Controls Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: scheme.surfaceContainerHighest,
            child: Row(
              children: [
                // Play / Pause
                PressableScale(
                  child: IconButton(
                    tooltip: isPlaying ? l10n.cutPause : l10n.cutPlay,
                    onPressed: onPlayPause,
                    icon: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: scheme.primary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Clock
                Text(
                  '${formatSpan(currentPos)} / ${formatSpan(duration)}',
                  style: text.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 20, color: scheme.outlineVariant),
                const SizedBox(width: 12),

                // Set Start here (I)
                PressableScale(
                  child: OutlinedButton.icon(
                    onPressed: onSetStart,
                    icon: const Icon(Icons.arrow_right_alt_rounded, size: 16),
                    label: Text(l10n.cutSetStartHere),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 28),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Set End here (O)
                PressableScale(
                  child: OutlinedButton.icon(
                    onPressed: onSetEnd,
                    icon: const Icon(Icons.keyboard_tab_rounded, size: 16),
                    label: Text(l10n.cutSetEndHere),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 28),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Play selection
                PressableScale(
                  child: TextButton.icon(
                    onPressed: onPlaySelection,
                    icon: const Icon(Icons.volume_up_outlined, size: 16),
                    label: Text(l10n.cutPlaySelection),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 28),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const Spacer(),

                // Mute / Unmute
                PressableScale(
                  child: IconButton(
                    tooltip: isMuted ? l10n.cutUnmute : l10n.cutMute,
                    onPressed: onToggleMute,
                    icon: Icon(
                      isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      size: 20,
                      color: isMuted ? scheme.error : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeStepperBox extends StatelessWidget {
  const _TimeStepperBox({
    required this.title,
    required this.icon,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.hintText,
    required this.onChanged,
    required this.onNudgeMinus5,
    required this.onNudgeMinus1,
    required this.onNudgePlus1,
    required this.onNudgePlus5,
    required this.quickLabel,
    required this.isStart,
    this.onQuickStart,
    this.onQuickEnd,
  });

  final String title;
  final IconData icon;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onNudgeMinus5;
  final VoidCallback onNudgeMinus1;
  final VoidCallback onNudgePlus1;
  final VoidCallback onNudgePlus5;
  final VoidCallback? onQuickStart;
  final VoidCallback? onQuickEnd;
  final String quickLabel;
  final bool isStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(AppSpacing.controlRadius),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (isStart && onQuickStart != null)
                _StepButton(label: quickLabel, onPressed: enabled ? onQuickStart : null),
              _StepButton(label: '-5s', onPressed: enabled ? onNudgeMinus5 : null),
              _StepButton(label: '-1s', onPressed: enabled ? onNudgeMinus1 : null),
              _StepButton(label: '+1s', onPressed: enabled ? onNudgePlus1 : null),
              _StepButton(label: '+5s', onPressed: enabled ? onNudgePlus5 : null),
              if (!isStart && onQuickEnd != null)
                _StepButton(label: quickLabel, onPressed: enabled ? onQuickEnd : null),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PressableScale(
      child: SizedBox(
        height: 28,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(36, 28),
            side: BorderSide(color: scheme.outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: text.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: text.titleMedium?.copyWith(
            color: valueColor ?? scheme.onSurface,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _CutTimeline extends StatelessWidget {
  const _CutTimeline({
    required this.duration,
    required this.kept,
    required this.selection,
    required this.playhead,
  });

  final Duration duration;
  final List<Span> kept;
  final Span? selection;
  final Duration playhead;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 32,
      width: double.infinity,
      child: CustomPaint(
        painter: _CutPainter(
          duration: duration,
          kept: kept,
          selection: selection,
          playhead: playhead,
          keptColor: scheme.primary.withValues(alpha: 0.85),
          removedColor: scheme.error.withValues(alpha: 0.35),
          trackColor: scheme.outlineVariant,
          selectionColor: scheme.tertiary,
          playheadColor: Colors.white,
        ),
      ),
    );
  }
}

class _CutPainter extends CustomPainter {
  _CutPainter({
    required this.duration,
    required this.kept,
    required this.selection,
    required this.playhead,
    required this.keptColor,
    required this.removedColor,
    required this.trackColor,
    required this.selectionColor,
    required this.playheadColor,
  });

  final Duration duration;
  final List<Span> kept;
  final Span? selection;
  final Duration playhead;
  final Color keptColor;
  final Color removedColor;
  final Color trackColor;
  final Color selectionColor;
  final Color playheadColor;

  @override
  void paint(Canvas canvas, Size size) {
    final total = duration.inMilliseconds;
    if (total <= 0) {
      return;
    }

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );
    canvas.save();
    canvas.clipRRect(rrect);

    // 1. Base track / removed background
    canvas.drawRect(Offset.zero & size, Paint()..color = removedColor);

    // 2. Kept spans
    final keptPaint = Paint()..color = keptColor;
    for (final span in kept) {
      final left = (size.width * span.start.inMilliseconds / total).clamp(0.0, size.width);
      final right = (size.width * span.end.inMilliseconds / total).clamp(0.0, size.width);
      if (right > left) {
        canvas.drawRect(Rect.fromLTRB(left, 0, right, size.height), keptPaint);
      }
    }

    // 3. Selection overlay highlight
    final sel = selection;
    if (sel != null && sel.valid) {
      final selLeft = (size.width * sel.start.inMilliseconds / total).clamp(0.0, size.width);
      final selRight = (size.width * sel.end.inMilliseconds / total).clamp(0.0, size.width);
      if (selRight > selLeft) {
        final selRect = Rect.fromLTRB(selLeft, 0, selRight, size.height);
        canvas.drawRect(
          selRect,
          Paint()..color = selectionColor.withValues(alpha: 0.22),
        );
        canvas.drawRect(
          selRect,
          Paint()
            ..color = selectionColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    // 4. Playhead Needle (Agulha de reprodução)
    if (playhead.inMilliseconds > 0 && playhead <= duration) {
      final playX = (size.width * playhead.inMilliseconds / total).clamp(0.0, size.width);
      final needlePaint = Paint()
        ..color = playheadColor
        ..strokeWidth = 2.0;
      canvas.drawLine(Offset(playX, 0), Offset(playX, size.height), needlePaint);

      // Pip indicador no topo e na base
      final pipPaint = Paint()..color = playheadColor;
      canvas.drawCircle(Offset(playX, 3), 3, pipPaint);
      canvas.drawCircle(Offset(playX, size.height - 3), 3, pipPaint);
    }

    canvas.restore();

    // 5. Border around the timeline
    final borderPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(_CutPainter oldDelegate) {
    if (oldDelegate.duration != duration ||
        oldDelegate.kept.length != kept.length ||
        oldDelegate.selection != selection ||
        oldDelegate.playhead != playhead ||
        oldDelegate.keptColor != keptColor ||
        oldDelegate.removedColor != removedColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.selectionColor != selectionColor ||
        oldDelegate.playheadColor != playheadColor) {
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
