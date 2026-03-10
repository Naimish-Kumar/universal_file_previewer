import 'dart:typed_data';
import 'package:flutter/services.dart';

/// Communicates with native platform code (Android/iOS) for
/// operations that require system APIs: PDF rendering, video thumbnails, etc.
class FilePreviewerChannel {
  static const MethodChannel _channel =
      MethodChannel('universal_file_previewer');

  /// Render a single PDF page to raw PNG bytes.
  /// [path]  — absolute path to the PDF file
  /// [page]  — zero-indexed page number
  /// [width] — desired output width in pixels
  static Future<Uint8List?> renderPdfPage({
    required String path,
    required int page,
    required int width,
  }) async {
    try {
      final result = await _channel.invokeMethod<Uint8List>('renderPdfPage', {
        'path': path,
        'page': page,
        'width': width,
      });
      return result;
    } on PlatformException catch (e) {
      throw FilePreviewerException('PDF render failed: ${e.message}');
    }
  }

  /// Get total page count of a PDF file.
  static Future<int> getPdfPageCount(String path) async {
    try {
      final result = await _channel.invokeMethod<int>('getPdfPageCount', {
        'path': path,
      });
      return result ?? 0;
    } on PlatformException catch (e) {
      throw FilePreviewerException('PDF page count failed: ${e.message}');
    }
  }

  /// Generate a thumbnail image for a video file.
  /// Returns PNG bytes of the thumbnail.
  static Future<Uint8List?> generateVideoThumbnail(String path) async {
    try {
      final result = await _channel
          .invokeMethod<Uint8List>('generateVideoThumbnail', {'path': path});
      return result;
    } on PlatformException catch (e) {
      throw FilePreviewerException('Video thumbnail failed: ${e.message}');
    }
  }

  /// Get video metadata (duration, width, height).
  static Future<Map<String, dynamic>> getVideoInfo(String path) async {
    try {
      final result = await _channel
          .invokeMethod<Map>('getVideoInfo', {'path': path});
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      throw FilePreviewerException('Video info failed: ${e.message}');
    }
  }

  /// Convert HEIC image to JPEG bytes (iOS/Android native conversion).
  static Future<Uint8List?> convertHeicToJpeg(String path) async {
    try {
      final result = await _channel
          .invokeMethod<Uint8List>('convertHeicToJpeg', {'path': path});
      return result;
    } on PlatformException catch (e) {
      throw FilePreviewerException('HEIC conversion failed: ${e.message}');
    }
  }

  /// Check if platform channel is available (plugin properly registered).
  static Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('ping');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}

/// Exception thrown by platform channel operations.
class FilePreviewerException implements Exception {
  final String message;
  const FilePreviewerException(this.message);

  @override
  String toString() => 'FilePreviewerException: $message';
}
