import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Callback invoked when the video controller is ready.
typedef VideoControllerCallback = void Function(VideoPlayerController controller);

/// Embeds a video player using the official video_player package.
/// Supports Web, Windows, Linux, macOS, Android, and iOS.
class NativeVideoPlayer extends StatefulWidget {
  final String path;
  final VideoControllerCallback onCreated;

  const NativeVideoPlayer({
    super.key,
    required this.path,
    required this.onCreated,
  });

  @override
  State<NativeVideoPlayer> createState() => _NativeVideoPlayerState();
}

class _NativeVideoPlayerState extends State<NativeVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (kIsWeb) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.path));
    } else {
      _controller = VideoPlayerController.file(File(widget.path));
    }

    try {
      await _controller.initialize();
      if (mounted) {
        setState(() => _initialized = true);
        widget.onCreated(_controller);
      }
    } catch (e) {
      debugPrint('Video initialization error: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }
}
