import 'dart:io';
import 'package:flutter/material.dart';
import '../core/file_detector.dart';
import '../core/file_type.dart';
import '../core/preview_config.dart';
import '../core/preview_controller.dart';
import '../core/file_downloader.dart';
import '../renderers/fallback_renderer.dart';
import '../renderers/image_renderer.dart';
import '../renderers/media_renderers.dart';
import '../renderers/pdf_renderer.dart';
import '../renderers/text_renderers.dart';
import '../renderers/zip_renderer.dart';

/// The main widget for previewing any file.
///
/// Usage:
/// ```dart
/// FilePreviewWidget(
///   file: File('/path/to/document.pdf'),
///   config: PreviewConfig(showToolbar: true),
/// )
/// ```
///
/// Or preview via URL:
/// ```dart
/// FilePreviewWidget(
///   url: 'https://example.com/document.pdf',
/// )
/// ```
class FilePreviewWidget extends StatefulWidget {
  /// The local file to preview.
  final File? file;

  /// The URL of the file to preview.
  final String? url;

  /// Configuration for appearance and behavior.
  final PreviewConfig config;

  /// Optional controller for programmatic page navigation, zoom, etc.
  final PreviewController? controller;

  /// Called when the file type has been detected.
  final void Function(FileType type)? onTypeDetected;

  const FilePreviewWidget({
    super.key,
    this.file,
    this.url,
    this.config = const PreviewConfig(),
    this.controller,
    this.onTypeDetected,
  }) : assert(file != null || url != null, 'Either file or url must be provided');

  @override
  State<FilePreviewWidget> createState() => _FilePreviewWidgetState();
}

class _FilePreviewWidgetState extends State<FilePreviewWidget> {
  FileType? _fileType;
  bool _isLoading = true;
  String? _error;
  File? _localFile;

  @override
  void initState() {
    super.initState();
    _initPreview();
  }

  @override
  void didUpdateWidget(FilePreviewWidget old) {
    super.didUpdateWidget(old);
    if (old.file?.path != widget.file?.path || old.url != widget.url) {
      _initPreview();
    }
  }

  Future<void> _initPreview() async {
    setState(() {
      _fileType = null;
      _isLoading = true;
      _error = null;
      _localFile = widget.file;
    });

    try {
      if (widget.url != null && widget.file == null) {
        _localFile = await FileDownloader.download(widget.url!);
      }

      if (_localFile != null) {
        final type = await FileDetector.detect(_localFile!);
        if (mounted) {
          setState(() {
            _fileType = type;
            _isLoading = false;
          });
          widget.onTypeDetected?.call(type);
        }
      } else {
        throw Exception('No file or URL provided');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.config.loadingBuilder?.call() ??
          const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return widget.config.errorBuilder?.call(_error!) ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Failed to load preview: $_error'),
              ],
            ),
          );
    }

    return _buildRenderer(_fileType!);
  }

  Widget _buildRenderer(FileType type) {
    return switch (type) {
      // ── Images ────────────────────────────────────────────
      FileType.jpeg ||
      FileType.png  ||
      FileType.gif  ||
      FileType.webp ||
      FileType.bmp  ||
      FileType.tiff =>
        ImageRenderer(file: _localFile!, config: widget.config),

      FileType.svg =>
        SvgRenderer(file: _localFile!, config: widget.config),

      FileType.heic =>
        HeicRenderer(file: _localFile!, config: widget.config),

      // ── PDF ───────────────────────────────────────────────
      FileType.pdf =>
        PdfRenderer(
          file: _localFile!,
          config: widget.config,
          controller: widget.controller,
        ),

      // ── Video ─────────────────────────────────────────────
      FileType.mp4  ||
      FileType.mov  ||
      FileType.avi  ||
      FileType.mkv  ||
      FileType.webm =>
        VideoRenderer(file: _localFile!, config: widget.config),

      // ── Audio ─────────────────────────────────────────────
      FileType.mp3  ||
      FileType.wav  ||
      FileType.aac  ||
      FileType.flac ||
      FileType.ogg  =>
        AudioRenderer(file: _localFile!, config: widget.config),

      // ── Documents (DOCX, XLSX, PPTX) ─────────────────────
      FileType.docx ||
      FileType.doc  ||
      FileType.xlsx ||
      FileType.xls  ||
      FileType.pptx ||
      FileType.ppt  =>
        FallbackRenderer(
          file: _localFile!,
          fileType: type,
          config: widget.config,
        ),

      // ── Code ──────────────────────────────────────────────
      FileType.code =>
        CodeRenderer(file: _localFile!, config: widget.config),

      // ── Text & Data ───────────────────────────────────────
      FileType.txt =>
        TextRenderer(file: _localFile!, config: widget.config),

      FileType.markdown =>
        MarkdownRenderer(file: _localFile!, config: widget.config),

      FileType.json =>
        JsonRenderer(file: _localFile!, config: widget.config),

      FileType.csv =>
        CsvRenderer(file: _localFile!, config: widget.config),

      FileType.xml  ||
      FileType.html =>
        TextRenderer(file: _localFile!, config: widget.config),

      // ── Archives ──────────────────────────────────────────
      FileType.zip =>
        ZipRenderer(file: _localFile!, config: widget.config),

      FileType.rar  ||
      FileType.tar  ||
      FileType.gz   ||
      FileType.sevenZ =>
        FallbackRenderer(
          file: _localFile!,
          fileType: type,
          config: widget.config,
        ),

      // ── 3D & Unknown ──────────────────────────────────────
      _ =>
        FallbackRenderer(
          file: _localFile!,
          fileType: type,
          config: widget.config,
        ),
    };
  }
}
