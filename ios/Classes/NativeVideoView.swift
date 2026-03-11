import Flutter
import UIKit
import AVFoundation

class NativeVideoView: NSObject, FlutterPlatformView {
    private var _view: VideoContainerView
    private var _player: AVPlayer?
    private var _playerLayer: AVPlayerLayer?
    private var _channel: FlutterMethodChannel
    private var _timeObserver: Any?
    private var _statusObservation: NSKeyValueObservation?

    init(frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?, messenger: FlutterBinaryMessenger) {
        _view = VideoContainerView(frame: frame)
        _view.backgroundColor = .black
        _channel = FlutterMethodChannel(name: "universal_file_previewer_video_\(viewId)", binaryMessenger: messenger)
        
        super.init()
        
        _channel.setMethodCallHandler(self.handle)
        
        if let params = args as? [String: Any], let path = params["path"] as? String {
            loadVideo(path: path)
        }
    }

    func view() -> UIView {
        return _view
    }

    private func loadVideo(path: String) {
        // Clean up previous player if reloading
        cleanupPlayer()

        let url = URL(fileURLWithPath: path)
        let playerItem = AVPlayerItem(url: url)
        _player = AVPlayer(playerItem: playerItem)
        
        _playerLayer = AVPlayerLayer(player: _player)
        _playerLayer?.frame = _view.bounds
        _playerLayer?.videoGravity = .resizeAspect
        if let layer = _playerLayer {
            _view.layer.addSublayer(layer)
            _view.playerLayer = layer  // Allow the container to resize it
        }
        
        // Completion observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        // Status observer using modern KVO
        _statusObservation = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self = self else { return }
            if item.status == .readyToPlay {
                let duration = Int(item.duration.seconds * 1000)
                let size = item.presentationSize
                DispatchQueue.main.async {
                    self._channel.invokeMethod("onPrepared", arguments: [
                        "duration": duration,
                        "width": Int(size.width),
                        "height": Int(size.height)
                    ])
                }
            } else if item.status == .failed {
                DispatchQueue.main.async {
                    self._channel.invokeMethod("onError", arguments: item.error?.localizedDescription ?? "Unknown error")
                }
            }
        }
        
        // Progress observer (every 500ms)
        _timeObserver = _player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            self?._channel.invokeMethod("onProgress", arguments: Int(time.seconds * 1000))
        }
    }

    @objc func playerDidFinishPlaying() {
        _channel.invokeMethod("onCompletion", arguments: nil)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "play":
            _player?.play()
            result(nil)
        case "pause":
            _player?.pause()
            result(nil)
        case "seekTo":
            if let args = call.arguments as? [String: Any], let ms = args["ms"] as? Int {
                let time = CMTime(value: Int64(ms), timescale: 1000)
                _player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
            }
            result(nil)
        case "getPosition":
            if let time = _player?.currentTime() {
                result(Int(time.seconds * 1000))
            } else {
                result(0)
            }
        case "isPlaying":
            result(_player?.rate != 0 && _player?.error == nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func cleanupPlayer() {
        if let observer = _timeObserver {
            _player?.removeTimeObserver(observer)
            _timeObserver = nil
        }
        _statusObservation?.invalidate()
        _statusObservation = nil
        NotificationCenter.default.removeObserver(self)
        _playerLayer?.removeFromSuperlayer()
        _playerLayer = nil
        _player = nil
    }

    deinit {
        cleanupPlayer()
        _channel.setMethodCallHandler(nil)
    }
}

/// A UIView subclass that automatically resizes its AVPlayerLayer on layout changes.
class VideoContainerView: UIView {
    var playerLayer: AVPlayerLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
}
