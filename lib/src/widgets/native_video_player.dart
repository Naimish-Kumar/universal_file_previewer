import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'video_player_controller.dart';

/// Callback invoked when the native platform view is created.
typedef VideoControllerCallback = void Function(NativeVideoController controller);

/// Embeds a native video player view (AndroidView / UiKitView).
///
/// On creation, the platform view loads the video at [path] and
/// calls [onCreated] with a [NativeVideoController] for playback control.
class NativeVideoPlayer extends StatelessWidget {
  /// Absolute path to the local video file.
  final String path;

  /// Called when the platform view is ready.
  final VideoControllerCallback onCreated;

  const NativeVideoPlayer({
    super.key,
    required this.path,
    required this.onCreated,
  });

  @override
  Widget build(BuildContext context) {
    const String viewType = 'universal_file_previewer_video_view';
    final Map<String, dynamic> creationParams = <String, dynamic>{
      'path': path,
    };

    if (Platform.isAndroid) {
      return AndroidView(
        viewType: viewType,
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: viewType,
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return const Center(
      child: Text(
        'Video playback not supported on this platform',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  void _onPlatformViewCreated(int id) {
    onCreated(NativeVideoController(id));
  }
}
