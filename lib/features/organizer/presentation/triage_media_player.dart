import 'dart:async';
import 'dart:io';

import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/gallery/presentation/gallery_format.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class TriageMediaPlayer extends StatefulWidget {
  const TriageMediaPlayer({
    required this.path,
    required this.name,
    required this.isVideo,
    super.key,
  });

  final String path;
  final String name;
  final bool isVideo;

  @override
  State<TriageMediaPlayer> createState() => _TriageMediaPlayerState();
}

class _TriageMediaPlayerState extends State<TriageMediaPlayer> {
  Player? _player;
  VideoController? _videoController;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<bool>? _playingSub;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _controlsHovered = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(TriageMediaPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _loadMedia(widget.path);
    }
  }

  void _initPlayer() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }

    try {
      final player = Player();
      _player = player;
      if (widget.isVideo) {
        _videoController = VideoController(player);
      }

      _posSub = player.stream.position.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });
      _durSub = player.stream.duration.listen((dur) {
        if (mounted) setState(() => _duration = dur);
      });
      _playingSub = player.stream.playing.listen((playing) {
        if (mounted) setState(() => _playing = playing);
      });

      _loadMedia(widget.path);
    } catch (_) {
      _player = null;
      _videoController = null;
    }
  }

  Future<void> _loadMedia(String path) async {
    final player = _player;
    if (player == null) return;

    try {
      await player.open(Media(path), play: true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _playingSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final player = _player;
    if (player == null) return;
    if (_playing) {
      player.pause();
    } else {
      player.play();
    }
  }

  void _seek(Duration target) {
    _player?.seek(target);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (Platform.environment.containsKey('FLUTTER_TEST') || _player == null) {
      return _buildFallback(scheme);
    }

    if (widget.isVideo) {
      return _buildVideoPlayer(scheme);
    } else {
      return _buildAudioPlayer(scheme);
    }
  }

  Widget _buildVideoPlayer(ColorScheme scheme) {
    final video = _videoController;
    if (video == null) {
      return _buildFallback(scheme);
    }

    final totalMs = _duration.inMilliseconds;
    final currentMs = _position.inMilliseconds.clamp(0, totalMs > 0 ? totalMs : 0);
    final progress = totalMs > 0 ? currentMs / totalMs : 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _controlsHovered = true),
      onExit: (_) => setState(() => _controlsHovered = false),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Superfície de renderização de vídeo nativa via media_kit
          Video(
            controller: video,
            fit: BoxFit.contain,
            fill: Colors.black,
            controls: NoVideoControls,
          ),

          // Botão central grande de Play quando pausado
          if (!_playing)
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 54,
                  color: Colors.white,
                ),
              ),
            ),

          // Overlay de clique para play/pause na tela inteira
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _togglePlay,
            ),
          ),

          // Barra de controles inferior em hover ou pausado
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedOpacity(
              duration: AppMotion.fast,
              curve: AppMotion.easeOut,
              opacity: (_controlsHovered || !_playing) ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: _togglePlay,
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Text(
                      formatGalleryClock(_position),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                          trackHeight: 3,
                          activeTrackColor: scheme.primary,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: scheme.primary,
                        ),
                        child: Slider(
                          value: progress.clamp(0.0, 1.0),
                          onChanged: (val) {
                            if (totalMs > 0) {
                              _seek(Duration(milliseconds: (val * totalMs).toInt()));
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Text(
                      formatGalleryClock(_duration),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer(ColorScheme scheme) {
    final totalMs = _duration.inMilliseconds;
    final currentMs = _position.inMilliseconds.clamp(0, totalMs > 0 ? totalMs : 0);
    final progress = totalMs > 0 ? currentMs / totalMs : 0.0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.l),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone animado / Disco de vinil estilizado
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.purple.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.audiotrack_rounded,
                  size: 48,
                  color: Colors.purple.shade300,
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                widget.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.l),

              // Barra de progresso e timestamps
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  trackHeight: 4,
                  activeTrackColor: Colors.purple,
                  inactiveTrackColor: scheme.outlineVariant,
                  thumbColor: Colors.purple,
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (val) {
                    if (totalMs > 0) {
                      _seek(Duration(milliseconds: (val * totalMs).toInt()));
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatGalleryClock(_position),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      formatGalleryClock(_duration),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              // Controles de Playback
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Voltar ao início',
                    icon: const Icon(Icons.replay_rounded, size: 20),
                    onPressed: () => _seek(Duration.zero),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  PressableScale(
                    scaleDown: 0.94,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        iconSize: 32,
                        color: Colors.white,
                        icon: Icon(
                          _playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        onPressed: _togglePlay,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  IconButton(
                    tooltip: _playing ? 'Pausar' : 'Reproduzir',
                    icon: Icon(
                      _playing
                          ? Icons.volume_up_rounded
                          : Icons.volume_mute_rounded,
                      size: 20,
                    ),
                    onPressed: _togglePlay,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(ColorScheme scheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          widget.isVideo ? Icons.movie_outlined : Icons.audiotrack_rounded,
          size: 56,
          color: widget.isVideo ? scheme.primary : Colors.purple,
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          widget.name,
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
