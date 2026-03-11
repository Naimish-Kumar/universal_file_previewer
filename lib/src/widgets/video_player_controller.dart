import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Controller that bridges Flutter and the native video platform view.
///
/// Created automatically by [NativeVideoPlayer] when the platform view
/// is ready. Use [addListener] to react to state changes.
class NativeVideoController extends ChangeNotifier {
  final int viewId;
  late final MethodChannel _channel;
  bool _disposed = false;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  Duration _position = Duration.zero;
  Duration get position => _position;

  Size _videoSize = Size.zero;
  Size get videoSize => _videoSize;

  String? _error;
  String? get error => _error;

  NativeVideoController(this.viewId) {
    _channel = MethodChannel('universal_file_previewer_video_$viewId');
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<void> _handleMethod(MethodCall call) async {
    if (_disposed) return;
    switch (call.method) {
      case 'onPrepared':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        _duration = Duration(milliseconds: args['duration'] as int);
        _videoSize = Size(
          (args['width'] as int).toDouble(),
          (args['height'] as int).toDouble(),
        );
        _isInitialized = true;
        notifyListeners();
        break;
      case 'onProgress':
        final ms = call.arguments as int;
        _position = Duration(milliseconds: ms);
        notifyListeners();
        break;
      case 'onCompletion':
        _isPlaying = false;
        _position = _duration;
        notifyListeners();
        break;
      case 'onError':
        _error = call.arguments?.toString() ?? 'Unknown playback error';
        notifyListeners();
        break;
    }
  }

  /// Start or resume video playback.
  Future<void> play() async {
    if (_disposed) return;
    await _channel.invokeMethod('play');
    _isPlaying = true;
    notifyListeners();
  }

  /// Pause video playback.
  Future<void> pause() async {
    if (_disposed) return;
    await _channel.invokeMethod('pause');
    _isPlaying = false;
    notifyListeners();
  }

  /// Seek to a specific [position] in the video.
  Future<void> seekTo(Duration position) async {
    if (_disposed) return;
    await _channel.invokeMethod('seekTo', {'ms': position.inMilliseconds});
    _position = position;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _channel.setMethodCallHandler(null);
    super.dispose();
  }
}
