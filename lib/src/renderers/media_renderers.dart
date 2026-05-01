import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../core/preview_config.dart';
import '../platform/platform_channel.dart';
import '../widgets/native_video_player.dart';

// ─────────────────────────────────────────────────────────
// Video Renderer
// ─────────────────────────────────────────────────────────

/// Shows a video with native playback and custom controls.
class VideoRenderer extends StatefulWidget {
  final File file;
  final PreviewConfig config;

  const VideoRenderer({super.key, required this.file, required this.config});

  @override
  State<VideoRenderer> createState() => _VideoRendererState();
}

class _VideoRendererState extends State<VideoRenderer> {
  Uint8List? _thumbnail;
  VideoPlayerController? _controller;
  bool _showControls = true;
  Timer? _hideTimer;
  bool _initialized = false;
  bool _isSeeking = false;
  double _seekValue = 0;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.removeListener(_onControllerUpdate);
    // Note: VideoPlayerController is disposed by NativeVideoPlayer widget
    super.dispose();
  }

  Future<void> _loadThumbnail() async {
    try {
      final thumb =
          await FilePreviewerChannel.generateVideoThumbnail(widget.file.path);
      if (mounted && thumb != null) {
        setState(() {
          _thumbnail = thumb;
        });
      }
    } catch (_) {}
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller?.value.isPlaying == true) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    }
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    if (!_initialized && _controller!.value.isInitialized) {
      setState(() => _initialized = true);
    }
    if (!_isSeeking) {
      setState(() {});
    }
  }

  String _formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControls,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video Player
            Positioned.fill(
              child: NativeVideoPlayer(
                path: widget.file.path,
                onCreated: (controller) {
                  _controller = controller;
                  _controller!.addListener(_onControllerUpdate);
                },
              ),
            ),

            // Thumbnail placeholder
            if (!_initialized && _thumbnail != null)
              Positioned.fill(
                child: Image.memory(
                  _thumbnail!,
                  fit: BoxFit.contain,
                ),
              ),

            // Loading indicator
            if (!_initialized && _controller?.value.hasError != true)
              const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              ),

            // Error state
            if (_controller?.value.hasError == true)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Playback Error',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _controller!.value.errorDescription ?? 'Unknown error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

            // Controls Overlay
            if (_initialized &&
                _controller?.value.hasError != true &&
                (_showControls || _controller?.value.isPlaying != true))
              _buildControlsOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    final value = _controller?.value;
    final isPlaying = value?.isPlaying ?? false;
    final duration = value?.duration ?? Duration.zero;
    final position = value?.position ?? Duration.zero;

    final maxMs = duration.inMilliseconds.toDouble();
    final clampedPositionMs = position.inMilliseconds.toDouble().clamp(0.0, maxMs > 0 ? maxMs : 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
      ),
      child: Column(
        children: [
          const Spacer(),
          // Play/Pause button
          GestureDetector(
            onTap: () {
              if (isPlaying) {
                _controller?.pause();
              } else {
                _controller?.play();
                _startHideTimer();
              }
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          const Spacer(),
          // Bottom controls bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Seek bar
                SliderTheme(
                  data: const SliderThemeData(
                    trackHeight: 2,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: _isSeeking ? _seekValue : clampedPositionMs,
                    min: 0,
                    max: maxMs > 0 ? maxMs : 1.0,
                    onChangeStart: (v) {
                      _isSeeking = true;
                      _seekValue = v;
                    },
                    onChanged: (v) {
                      setState(() => _seekValue = v);
                    },
                    onChangeEnd: (v) {
                      _isSeeking = false;
                      _controller?.seekTo(Duration(milliseconds: v.toInt()));
                      _startHideTimer();
                    },
                  ),
                ),
                // Time labels
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Text(
                        _isSeeking
                            ? _formatDuration(Duration(milliseconds: _seekValue.toInt()))
                            : _formatDuration(position),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const Spacer(),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────
// Audio Renderer
// ─────────────────────────────────────────────────────────

/// Audio file renderer with a waveform placeholder and playback controls.
/// Actual playback is via native platform channel.
class AudioRenderer extends StatefulWidget {
  final File file;
  final PreviewConfig config;

  const AudioRenderer({super.key, required this.file, required this.config});

  @override
  State<AudioRenderer> createState() => _AudioRendererState();
}

class _AudioRendererState extends State<AudioRenderer>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _initialized = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _init();
  }

  Future<void> _init() async {
    if (kIsWeb) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.file.path));
    } else {
      _controller = VideoPlayerController.file(widget.file);
    }

    try {
      await _controller.initialize();
      if (mounted) {
        setState(() => _initialized = true);
        _controller.addListener(() => setState(() {}));
      }
    } catch (e) {
      debugPrint('Audio initialization error: $e');
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.file.path.split('/').last;
    final ext = fileName.split('.').last.toUpperCase();
    final value = _controller.value;
    final isPlaying = value.isPlaying;
    final duration = value.duration;
    final position = value.position;

    return Container(
      color: const Color(0xFF1A1A2E),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Album art placeholder
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3F3D56)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.music_note, size: 56, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(ext,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // File name
              Text(
                fileName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 32),

              // Animated waveform bars
              AnimatedBuilder(
                animation: _waveController,
                builder: (ctx, _) {
                  return _WaveformWidget(
                    progress: _waveController.value,
                    isPlaying: isPlaying,
                  );
                },
              ),

              const SizedBox(height: 24),

              // Progress bar
              if (_initialized)
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: const Color(0xFF6C63FF),
                    inactiveTrackColor: Colors.grey[800],
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: position.inMilliseconds.toDouble(),
                    min: 0,
                    max: duration.inMilliseconds.toDouble() > 0 
                        ? duration.inMilliseconds.toDouble() 
                        : 1.0,
                    onChanged: (v) {
                      _controller.seekTo(Duration(milliseconds: v.toInt()));
                    },
                  ),
                ),

              if (_initialized)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position),
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(_formatDuration(duration),
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Playback controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                    onPressed: _initialized 
                        ? () => _controller.seekTo(position - const Duration(seconds: 10)) 
                        : null,
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      if (!_initialized) return;
                      if (isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6C63FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                    onPressed: _initialized 
                        ? () => _controller.seekTo(position + const Duration(seconds: 10)) 
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveformWidget extends StatelessWidget {
  final double progress;
  final bool isPlaying;

  const _WaveformWidget({required this.progress, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    const barCount = 32;
    const heights = [
      0.4, 0.6, 0.8, 0.5, 0.9, 0.7, 0.3, 0.8, 0.6, 0.4, 0.9, 0.5,
      0.7, 0.8, 0.4, 0.6, 0.9, 0.3, 0.7, 0.5, 0.8, 0.6, 0.4, 0.9,
      0.5, 0.7, 0.3, 0.8, 0.6, 0.4, 0.9, 0.5,
    ];

    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (i) {
          final base = heights[i % heights.length];
          final animated = isPlaying
              ? base +
                  (0.3 * (0.5 + 0.5 * _wave(i, progress)))
              : base;
          final h = (animated * 40).clamp(4.0, 40.0);
          return Container(
            width: 3,
            height: h,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.7 + 0.3 * base),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  double _wave(int index, double t) {
    final phase = (index / 32.0 + t) % 1.0;
    return (phase * 2 * 3.14159).abs() % 2 < 1
        ? phase * 2
        : 2 - phase * 2;
  }
}
