import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/preview_config.dart';
import '../platform/platform_channel.dart';

// ─────────────────────────────────────────────────────────
// Video Renderer
// ─────────────────────────────────────────────────────────

/// Shows a video thumbnail with metadata.
/// Full playback requires integrating with native video player
/// via the platform channel.
class VideoRenderer extends StatefulWidget {
  final File file;
  final PreviewConfig config;

  const VideoRenderer({super.key, required this.file, required this.config});

  @override
  State<VideoRenderer> createState() => _VideoRendererState();
}

class _VideoRendererState extends State<VideoRenderer> {
  Uint8List? _thumbnail;
  Map<String, dynamic>? _info;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final thumb =
          await FilePreviewerChannel.generateVideoThumbnail(widget.file.path);
      final info = await FilePreviewerChannel.getVideoInfo(widget.file.path);
      if (mounted) {
        setState(() {
          _thumbnail = thumb;
          _info = info;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _formatDuration(int ms) {
    final d = Duration(milliseconds: ms);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Thumbnail / play area
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_thumbnail != null)
                  SizedBox.expand(
                    child: Image.memory(
                      _thumbnail!,
                      fit: BoxFit.contain,
                    ),
                  )
                else
                  const Center(
                    child: Icon(Icons.videocam, size: 80, color: Colors.grey),
                  ),
                // Play button overlay
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 42),
                ),
              ],
            ),
          ),

          // Info bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.file.path.split('/').last,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_info?['duration'] != null) ...[
                      const Icon(Icons.access_time,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(_info!['duration'] as int),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (_info?['width'] != null &&
                        _info?['height'] != null) ...[
                      const Icon(Icons.aspect_ratio,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${_info!['width']}×${_info!['height']}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Native video playback is handled via platform channel.\nIntegrate with your preferred video player plugin.',
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 11, height: 1.4),
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
  bool _playing = false;
  double _progress = 0.0;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.file.path.split('/').last;
    final ext = fileName.split('.').last.toUpperCase();

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
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.music_note,
                        size: 56, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
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
                    isPlaying: _playing,
                  );
                },
              ),

              const SizedBox(height: 24),

              // Progress bar
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: const Color(0xFF6C63FF),
                  inactiveTrackColor: Colors.grey[800],
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: _progress,
                  onChanged: (v) => setState(() => _progress = v),
                ),
              ),

              // Playback controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10,
                        color: Colors.white, size: 32),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => setState(() => _playing = !_playing),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6C63FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _playing ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.forward_10,
                        color: Colors.white, size: 32),
                    onPressed: () {},
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Text(
                'Connect native audio via platform channel for real playback',
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
                textAlign: TextAlign.center,
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
