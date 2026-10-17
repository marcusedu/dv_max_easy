import 'dart:async';
import 'dart:io';

import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/file_actions.dart';
import 'package:dv_max_easy/features/gallery/application/gallery_controller.dart';
import 'package:dv_max_easy/features/gallery/domain/gallery_catalog.dart';
import 'package:dv_max_easy/features/gallery/domain/gallery_rules.dart';
import 'package:dv_max_easy/features/gallery/presentation/gallery_format.dart';
import 'package:dv_max_easy/features/gallery/presentation/gallery_rail.dart';
import 'package:dv_max_easy/features/settings/application/settings_controller.dart';
import 'package:dv_max_easy/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class GalleryPage extends ConsumerStatefulWidget {
  const GalleryPage({super.key});

  @override
  ConsumerState<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends ConsumerState<GalleryPage>
    with SingleTickerProviderStateMixin {
  Player? _player;
  VideoController? _video;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<bool>? _completedSub;
  String? _openId;
  int _openGeneration = 0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  var _playing = false;
  DateTime? _wheelLock;
  DateTime? _lastRemember;
  var _resumeReady = true;
  var _reachedResume = true;
  var _panAccum = 0.0;
  var _panUsed = false;
  String? _toast;
  Timer? _toastTimer;
  late final AnimationController _slide;
  var _slideFrom = 0.0;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(vsync: this, duration: AppMotion.medium);
    HardwareKeyboard.instance.addHandler(_onKey);
    _openPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _open(ref.read(galleryControllerProvider).current);
    });
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent || !mounted) {
      return false;
    }
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      return false;
    }
    if (FocusManager.instance.primaryFocus?.context?.widget is EditableText) {
      return false;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _command(true);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _command(false);
      return true;
    }
    return false;
  }

  void _openPlayer() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    try {
      final player = Player();
      _player = player;
      _video = VideoController(player);
      _positionSub = player.stream.position.listen(_onPosition);
      _durationSub = player.stream.duration.listen(_onDuration);
      _playingSub = player.stream.playing.listen((playing) {
        if (mounted) {
          setState(() => _playing = playing);
        }
      });
      _completedSub = player.stream.completed.listen((done) {
        if (done) {
          _onCompleted();
        }
      });
    } on Object {
      _player = null;
      _video = null;
    }
  }

  GalleryEnd get _end {
    final raw = ref
        .read(settingsControllerProvider)
        .asData
        ?.value
        .settings
        .galleryEnd;
    return parseGalleryEnd(raw ?? 'stay');
  }

  bool get _inverted {
    return ref
            .read(settingsControllerProvider)
            .asData
            ?.value
            .settings
            .galleryScrollInverted ??
        false;
  }

  void _onPosition(Duration position) {
    if (!mounted) {
      return;
    }
    setState(() => _position = position);
    final id = _openId;
    if (id == null || !_resumeReady) {
      return;
    }
    final incoming = position.inMilliseconds;
    final stored = ref
        .read(galleryControllerProvider.notifier)
        .savedPositionMs(id);
    if (incoming + 1500 >= stored) {
      _reachedResume = true;
    }
    if (blocksResumeOverwrite(
      incomingMs: incoming,
      storedMs: stored,
      reached: _reachedResume,
    )) {
      return;
    }
    final now = DateTime.now();
    if (_lastRemember != null &&
        now.difference(_lastRemember!) < const Duration(seconds: 2)) {
      return;
    }
    _lastRemember = now;
    ref
        .read(galleryControllerProvider.notifier)
        .rememberPosition(
          id,
          incoming,
          _duration.inMilliseconds == 0 ? null : _duration.inMilliseconds,
        );
  }

  void _onDuration(Duration duration) {
    if (!mounted) {
      return;
    }
    setState(() => _duration = duration);
    final id = _openId;
    final item = ref.read(galleryControllerProvider).current;
    if (id == null || item == null || item.jobId != id) {
      return;
    }
    ref
        .read(galleryControllerProvider.notifier)
        .noteDuration(id, duration.inMilliseconds, item.bytes);
    _applyMode();
  }

  void _onCompleted() {
    if (finishFor(durationMs: _duration.inMilliseconds, end: _end) ==
        PlaybackFinish.advance) {
      _move(1);
    }
  }

  Future<void> _applyMode() async {
    final player = _player;
    if (player == null) {
      return;
    }
    final finish = finishFor(durationMs: _duration.inMilliseconds, end: _end);
    final loop =
        finish == PlaybackFinish.loop || finish == PlaybackFinish.repeat;
    await player.setPlaylistMode(
      loop ? PlaylistMode.single : PlaylistMode.none,
    );
  }

  Future<void> _open(GalleryItem? item) async {
    final player = _player;
    if (player == null) {
      return;
    }
    if (item == null) {
      _openId = null;
      await player.stop();
      return;
    }
    if (item.jobId == _openId) {
      return;
    }
    final generation = ++_openGeneration;
    _openId = item.jobId;
    _resumeReady = false;
    final pos = ref
        .read(galleryControllerProvider.notifier)
        .savedPositionMs(item.jobId);
    _reachedResume = pos < resumeMarginMs;
    if (mounted) {
      setState(() {
        _position = Duration.zero;
        _duration = Duration.zero;
      });
    }
    try {
      await player.open(
        Media(item.path, start: Duration(milliseconds: pos)),
        play: true,
      );
      if (!mounted || generation != _openGeneration) {
        return;
      }
      await _seekToSaved(player, pos, generation);
      await _applyMode();
    } on Object {
      // Sem libmpv, no teste ou com arquivo ilegível, o palco fica vazio.
    } finally {
      if (generation == _openGeneration) {
        _resumeReady = true;
        _lastRemember = DateTime.now();
      }
    }
  }

  Future<void> _seekToSaved(Player player, int pos, int generation) async {
    if (pos <= 0 || !mounted || generation != _openGeneration) {
      return;
    }
    await player.seek(Duration(milliseconds: pos));
    if (!mounted || generation != _openGeneration) {
      return;
    }
    try {
      await player.stream.duration
          .firstWhere((duration) => duration > Duration.zero)
          .timeout(const Duration(seconds: 2));
    } on Object {
      return;
    }
    if (!mounted || generation != _openGeneration) {
      return;
    }
    if (player.state.position.inMilliseconds + 1500 < pos) {
      await player.seek(Duration(milliseconds: pos));
    }
  }

  void _saveOpen() {
    final id = _openId;
    if (id == null || !_resumeReady) {
      return;
    }
    final live = _player?.state.position.inMilliseconds ?? 0;
    final shown = _position.inMilliseconds;
    final position = live > shown ? live : shown;
    final notifier = ref.read(galleryControllerProvider.notifier);
    final stored = notifier.savedPositionMs(id);
    if (position + 1500 >= stored) {
      _reachedResume = true;
    }
    if (blocksResumeOverwrite(
      incomingMs: position,
      storedMs: stored,
      reached: _reachedResume,
    )) {
      return;
    }
    notifier.rememberPosition(
      id,
      position,
      _duration.inMilliseconds == 0 ? null : _duration.inMilliseconds,
    );
    notifier.flush();
  }

  void _applyFeedDelta(double dy) {
    if (dy.abs() < 0.5) {
      return;
    }
    final step = scrollStep(dy: dy, inverted: _inverted);
    final direction = switch (step) {
      GalleryStep.next => 1,
      GalleryStep.previous => -1,
      GalleryStep.none => 0,
    };
    _move(direction);
  }

  void _move(int direction) {
    final state = ref.read(galleryControllerProvider);
    final next = state.index + direction;
    if (state.items.isEmpty || next < 0 || next >= state.items.length) {
      return;
    }
    _saveOpen();
    _slideFrom = direction > 0 ? 0.045 : -0.045;
    _slide.forward(from: 0);
    ref.read(galleryControllerProvider.notifier).step(direction);
  }

  void _command(bool down) {
    final step = scrollStep(dy: down ? 1 : -1, inverted: _inverted);
    final direction = switch (step) {
      GalleryStep.next => 1,
      GalleryStep.previous => -1,
      GalleryStep.none => 0,
    };
    _move(direction);
  }

  void _onWheel(PointerScrollEvent event) {
    final now = DateTime.now();
    if (_wheelLock != null && now.isBefore(_wheelLock!)) {
      return;
    }
    final dy = galleryFeedDelta(
      scrollDy: event.scrollDelta.dy,
      scrollDx: event.scrollDelta.dx,
      panDy: 0,
      panDx: 0,
    );
    if (dy.abs() < 0.5) {
      return;
    }
    _wheelLock = now.add(const Duration(milliseconds: 280));
    _applyFeedDelta(dy);
  }

  void _onPanStart(PointerPanZoomStartEvent event) {
    _panAccum = 0;
    _panUsed = false;
  }

  void _onPanUpdate(PointerPanZoomUpdateEvent event) {
    if (_panUsed) {
      return;
    }
    _panAccum += galleryFeedDelta(
      scrollDy: 0,
      scrollDx: 0,
      panDy: event.panDelta.dy,
      panDx: event.panDelta.dx,
    );
    if (_panAccum.abs() < 20) {
      return;
    }
    _panUsed = true;
    _applyFeedDelta(_panAccum);
  }

  void _onPanEnd(PointerPanZoomEndEvent event) {
    if (!_panUsed && _panAccum.abs() >= 12) {
      _applyFeedDelta(_panAccum);
    }
    _panAccum = 0;
    _panUsed = false;
  }

  Future<void> _share(GalleryItem item) async {
    try {
      await const FileActions().share(item.path);
    } on Object {
      // A folha do sistema falhou; o palco continua utilizável.
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.galleryDeleteTitle),
          content: Text(l10n.galleryDeleteBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.galleryDeleteCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.galleryDeleteConfirm),
            ),
          ],
        );
      },
    );
    if (answer != true || !mounted) {
      return;
    }
    _saveOpen();
    final error = await ref
        .read(galleryControllerProvider.notifier)
        .deleteCurrent();
    if (error != null && mounted) {
      _showToast(l10n.galleryDeleteFailed);
    }
  }

  Future<void> _showInfo(GalleryItem item) {
    final l10n = AppLocalizations.of(context);
    final duration = item.durationMs == null
        ? l10n.galleryUnknown
        : formatGalleryClock(Duration(milliseconds: item.durationMs!));
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.galleryInfoTitle),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoLine(label: l10n.galleryInfoPath, value: item.path),
                _InfoLine(label: l10n.galleryInfoUrl, value: item.url),
                _InfoLine(
                  label: l10n.galleryInfoSize,
                  value: formatGalleryBytes(item.bytes),
                ),
                _InfoLine(label: l10n.galleryInfoDuration, value: duration),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() => _toast = message);
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _toast = null);
      }
    });
  }

  void _togglePlay() {
    final player = _player;
    if (player == null) {
      return;
    }
    if (_playing) {
      player.pause();
    } else {
      player.play();
    }
  }

  void _seek(double fraction) {
    final player = _player;
    if (player == null || _duration == Duration.zero) {
      return;
    }
    final target = _duration * fraction.clamp(0, 1);
    player.seek(target);
  }

  @override
  void deactivate() {
    _saveOpen();
    super.deactivate();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playingSub?.cancel();
    _completedSub?.cancel();
    _player?.dispose();
    _slide.dispose();
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gallery = ref.watch(galleryControllerProvider);
    ref.listen(galleryControllerProvider, (previous, next) {
      final before = previous?.current?.jobId;
      final after = next.current?.jobId;
      if (before == after) {
        return;
      }
      if (before != null) {
        _saveOpen();
      }
      if (previous != null && next.current != null) {
        _slideFrom = next.index >= previous.index ? 0.045 : -0.045;
        _slide.forward(from: 0);
      }
      _open(next.current);
    });
    ref.listen(settingsControllerProvider, (previous, next) {
      _applyMode();
    });
    final item = gallery.current;
    return Listener(
      key: const Key('gallery-stage'),
      behavior: HitTestBehavior.opaque,
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _onWheel(event);
        }
      },
      onPointerPanZoomStart: _onPanStart,
      onPointerPanZoomUpdate: _onPanUpdate,
      onPointerPanZoomEnd: _onPanEnd,
      child: ColoredBox(
        color: Colors.black,
        child: item == null
            ? _EmptyGallery(message: l10n.galleryEmpty)
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        AnimatedSize(
                          duration: AppMotion.medium,
                          curve: AppMotion.easeOut,
                          child: AnimatedOpacity(
                            duration: AppMotion.medium,
                            curve: AppMotion.easeOut,
                            opacity: _toast == null ? 0 : 1,
                            child: _toast == null
                                ? const SizedBox(width: double.infinity)
                                : Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppSpacing.m,
                                    ),
                                    child: Text(
                                      _toast!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _slide,
                            builder: (context, child) {
                              final t = AppMotion.easeOut.transform(
                                _slide.value,
                              );
                              final height = MediaQuery.sizeOf(context).height;
                              return Transform.translate(
                                offset: Offset(
                                  0,
                                  _slideFrom * (1 - t) * height,
                                ),
                                child: child,
                              );
                            },
                            child: _Stage(
                              video: _video,
                              playing: _playing,
                              onToggle: _togglePlay,
                            ),
                          ),
                        ),
                        _Caption(
                          name: item.name,
                          position: _position,
                          duration: _duration,
                          onSeek: _seek,
                        ),
                      ],
                    ),
                  ),
                  GalleryRail(
                    liked: item.liked,
                    canPrevious: gallery.index > 0,
                    canNext: gallery.index < gallery.items.length - 1,
                    onPrevious: () => _move(-1),
                    onNext: () => _move(1),
                    onLike: () => ref
                        .read(galleryControllerProvider.notifier)
                        .toggleLike(),
                    onShare: () => _share(item),
                    onInfo: () => _showInfo(item),
                    onDelete: _confirmDelete,
                  ),
                ],
              ),
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({
    required this.video,
    required this.playing,
    required this.onToggle,
  });

  final VideoController? video;
  final bool playing;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final controller = video;
    return Stack(
      alignment: Alignment.center,
      children: [
        if (controller == null)
          const Icon(Icons.play_circle_outline, color: Colors.white24, size: 72)
        else
          Video(
            controller: controller,
            fit: BoxFit.contain,
            fill: Colors.black,
            controls: NoVideoControls,
          ),
        if (!playing && controller != null)
          const IgnorePointer(
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white70,
              size: 72,
            ),
          ),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({
    required this.name,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  final String name;
  final Duration position;
  final Duration duration;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    final fraction = duration.inMilliseconds == 0
        ? 0.0
        : position.inMilliseconds / duration.inMilliseconds;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.s,
        AppSpacing.s,
        AppSpacing.m,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.s),
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  onSeek(details.localPosition.dx / constraints.maxWidth);
                },
                child: SizedBox(
                  height: 18,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: fraction.clamp(0, 1),
                        minHeight: 3,
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            '${formatGalleryClock(position)} / ${formatGalleryClock(duration)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.bodySmall),
          const SizedBox(height: 4),
          SelectableText(value.isEmpty ? '—' : value, style: text.bodyMedium),
        ],
      ),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 56,
            color: Colors.white.withValues(alpha: 0.28),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(message, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
