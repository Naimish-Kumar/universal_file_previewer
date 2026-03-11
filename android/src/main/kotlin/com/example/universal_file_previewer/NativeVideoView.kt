package com.example.universal_file_previewer

import android.content.Context
import android.net.Uri
import android.view.View
import android.widget.VideoView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

class NativeVideoView(context: Context, messenger: BinaryMessenger, id: Int, creationParams: Map<String?, Any?>?) : PlatformView, MethodChannel.MethodCallHandler {
    private val videoView: VideoView = VideoView(context)
    private val methodChannel: MethodChannel = MethodChannel(messenger, "universal_file_previewer_video_$id")

    init {
        methodChannel.setMethodCallHandler(this)
        
        val path = creationParams?.get("path") as? String
        if (path != null) {
            loadVideo(path)
        }

        videoView.setOnPreparedListener { mp ->
            val duration = videoView.duration
            val width = mp.videoWidth
            val height = mp.videoHeight
            methodChannel.invokeMethod("onPrepared", mapOf(
                "duration" to duration,
                "width" to width,
                "height" to height
            ))
        }

        videoView.setOnCompletionListener {
            methodChannel.invokeMethod("onCompletion", null)
        }

        videoView.setOnErrorListener { _, what, extra ->
            methodChannel.invokeMethod("onError", "Error $what ($extra)")
            true
        }
    }

    override fun getView(): View = videoView

    override fun dispose() {
        videoView.stopPlayback()
        methodChannel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "load" -> {
                val path = call.argument<String>("path")
                if (path != null) {
                    loadVideo(path)
                    result.success(null)
                } else {
                    result.error("ARGS", "Path is null", null)
                }
            }
            "play" -> {
                videoView.start()
                result.success(null)
            }
            "pause" -> {
                videoView.pause()
                result.success(null)
            }
            "seekTo" -> {
                val ms = call.argument<Int>("ms") ?: 0
                videoView.seekTo(ms)
                result.success(null)
            }
            "getPosition" -> {
                result.success(videoView.currentPosition)
            }
            "isPlaying" -> {
                result.success(videoView.isPlaying)
            }
            else -> result.notImplemented()
        }
    }

    private fun loadVideo(path: String) {
        val file = java.io.File(path)
        val uri = if (file.exists()) {
            Uri.fromFile(file)
        } else {
            Uri.parse(path)
        }
        videoView.setVideoURI(uri)
    }
}
