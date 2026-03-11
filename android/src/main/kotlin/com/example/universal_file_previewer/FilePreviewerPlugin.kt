package com.example.universal_file_previewer

import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.media.MediaMetadataRetriever
import android.media.ThumbnailUtils
import android.os.ParcelFileDescriptor
import android.provider.MediaStore
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayOutputStream
import java.io.File

class FilePreviewerPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "universal_file_previewer")
        channel.setMethodCallHandler(this)

        binding.platformViewRegistry.registerViewFactory(
            "universal_file_previewer_video_view",
            VideoViewFactory(binding.binaryMessenger)
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "ping" -> result.success(true)

            "renderPdfPage" -> {
                val path  = call.argument<String>("path") ?: return result.error("ARGS", "path required", null)
                val page  = call.argument<Int>("page") ?: 0
                val width = call.argument<Int>("width") ?: 1080

                try {
                    val fd = ParcelFileDescriptor.open(File(path), ParcelFileDescriptor.MODE_READ_ONLY)
                    val renderer = PdfRenderer(fd)

                    if (page >= renderer.pageCount) {
                        renderer.close()
                        fd.close()
                        return result.error("PAGE", "Page index out of bounds", null)
                    }

                    val pdfPage = renderer.openPage(page)
                    val height  = (width.toFloat() * pdfPage.height / pdfPage.width).toInt()
                    val bitmap  = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                    pdfPage.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)

                    val stream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)

                    pdfPage.close()
                    renderer.close()
                    fd.close()

                    result.success(stream.toByteArray())
                } catch (e: Exception) {
                    result.error("PDF_ERROR", e.message, null)
                }
            }

            "getPdfPageCount" -> {
                val path = call.argument<String>("path") ?: return result.error("ARGS", "path required", null)
                try {
                    val fd = ParcelFileDescriptor.open(File(path), ParcelFileDescriptor.MODE_READ_ONLY)
                    val renderer = PdfRenderer(fd)
                    val count = renderer.pageCount
                    renderer.close()
                    fd.close()
                    result.success(count)
                } catch (e: Exception) {
                    result.error("PDF_ERROR", e.message, null)
                }
            }

            "generateVideoThumbnail" -> {
                val path = call.argument<String>("path") ?: return result.error("ARGS", "path required", null)
                try {
                    @Suppress("DEPRECATION")
                    val bmp = ThumbnailUtils.createVideoThumbnail(
                        path,
                        MediaStore.Images.Thumbnails.FULL_SCREEN_KIND
                    )
                    if (bmp == null) {
                        result.success(null)
                        return
                    }
                    val stream = ByteArrayOutputStream()
                    bmp.compress(Bitmap.CompressFormat.JPEG, 85, stream)
                    result.success(stream.toByteArray())
                } catch (e: Exception) {
                    result.error("THUMB_ERROR", e.message, null)
                }
            }

            "getVideoInfo" -> {
                val path = call.argument<String>("path") ?: return result.error("ARGS", "path required", null)
                try {
                    val retriever = MediaMetadataRetriever()
                    retriever.setDataSource(path)

                    val durationMs = retriever.extractMetadata(
                        MediaMetadataRetriever.METADATA_KEY_DURATION
                    )?.toLongOrNull() ?: 0L
                    val width = retriever.extractMetadata(
                        MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH
                    )?.toIntOrNull() ?: 0
                    val height = retriever.extractMetadata(
                        MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT
                    )?.toIntOrNull() ?: 0
                    val rotation = retriever.extractMetadata(
                        MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION
                    )?.toIntOrNull() ?: 0

                    retriever.release()

                    result.success(mapOf(
                        "duration" to durationMs,
                        "width"    to width,
                        "height"   to height,
                        "rotation" to rotation,
                    ))
                } catch (e: Exception) {
                    result.error("VIDEO_INFO_ERROR", e.message, null)
                }
            }

            "convertHeicToJpeg" -> {
                // Android 10+ natively supports HEIC via ImageDecoder
                val path = call.argument<String>("path") ?: return result.error("ARGS", "path required", null)
                try {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                        val source = android.graphics.ImageDecoder.createSource(File(path))
                        val bmp    = android.graphics.ImageDecoder.decodeBitmap(source)
                        val stream = ByteArrayOutputStream()
                        bmp.compress(Bitmap.CompressFormat.JPEG, 90, stream)
                        result.success(stream.toByteArray())
                    } else {
                        result.error("UNSUPPORTED", "HEIC requires Android 9+", null)
                    }
                } catch (e: Exception) {
                    result.error("HEIC_ERROR", e.message, null)
                }
            }

            else -> result.notImplemented()
        }
    }
}
