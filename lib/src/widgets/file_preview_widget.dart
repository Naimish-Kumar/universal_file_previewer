import 'dart:io';
import 'package:flutter/material.dart';
import '../core/file_detector.dart';
import '../core/file_type.dart';
import '../core/preview_config.dart';
import '../core/preview_controller.dart';
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
class FilePreviewWidget extends StatefulWidget {
  /// The file to preview.
  final File file;

  /// Configuration for appearance and behavior.
  final PreviewConfig config;

  /// Optional controller for programmatic page navigation, zoom, etc.
  final PreviewController? controller;

  /// Called when the file type has been detected.
  final void Function(FileType type)? onTypeDetected;

  const FilePreviewWidget({
    super.key,
    required this.file,
    this.config = const PreviewConfig(),
    this.controller,
    this.onTypeDetected,
  });

  @override
  State<FilePreviewWidget> createState() => _FilePreviewWidgetState();
}

class _FilePreviewWidgetState extends State<FilePreviewWidget> {
  FileType? _fileType;
  bool _detecting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _detect();
  }

  @override
  void didUpdateWidget(FilePreviewWidget old) {
    super.didUpdateWidget(old);
    if (old.file.path != widget.file.path) {
      setState(() {
        _fileType = null;
        _detecting = true;
        _error = null;
      });
      _detect();
    }
  }

  Future<void> _detect() async {
    try {
      final type = await FileDetector.detect(widget.file);
      if (mounted) {
        setState(() {
          _fileType = type;
          _detecting = false;
        });
        widget.onTypeDetected?.call(type);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _detecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_detecting) {
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
                Text('Failed to detect file type: $_error'),
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
        ImageRenderer(file: widget.file, config: widget.config),

      FileType.svg =>
        SvgRenderer(file: widget.file, config: widget.config),

      FileType.heic =>
        HeicRenderer(file: widget.file, config: widget.config),

      // ── PDF ───────────────────────────────────────────────
      FileType.pdf =>
        PdfRenderer(
          file: widget.file,
          config: widget.config,
          controller: widget.controller,
        ),

      // ── Video ─────────────────────────────────────────────
      FileType.mp4  ||
      FileType.mov  ||
      FileType.avi  ||
      FileType.mkv  ||
      FileType.webm =>
        VideoRenderer(file: widget.file, config: widget.config),

      // ── Audio ─────────────────────────────────────────────
      FileType.mp3  ||
      FileType.wav  ||
      FileType.aac  ||
      FileType.flac ||
      FileType.ogg  =>
        AudioRenderer(file: widget.file, config: widget.config),

      // ── Documents (DOCX, XLSX, PPTX) ─────────────────────
      FileType.docx ||
      FileType.doc  ||
      FileType.xlsx ||
      FileType.xls  ||
      FileType.pptx ||
      FileType.ppt  =>
        FallbackRenderer(
          file: widget.file,
          fileType: type,
          config: widget.config,
        ),

      // ── Code ──────────────────────────────────────────────
      FileType.code =>
        CodeRenderer(file: widget.file, config: widget.config),

      // ── Text & Data ───────────────────────────────────────
      FileType.txt =>
        TextRenderer(file: widget.file, config: widget.config),

      FileType.markdown =>
        MarkdownRenderer(file: widget.file, config: widget.config),

      FileType.json =>
        JsonRenderer(file: widget.file, config: widget.config),

      FileType.csv =>
        CsvRenderer(file: widget.file, config: widget.config),

      FileType.xml  ||
      FileType.html =>
        TextRenderer(file: widget.file, config: widget.config),

      // ── Archives ──────────────────────────────────────────
      FileType.zip =>
        ZipRenderer(file: widget.file, config: widget.config),

      FileType.rar  ||
      FileType.tar  ||
      FileType.gz   ||
      FileType.sevenZ =>
        FallbackRenderer(
          file: widget.file,
          fileType: type,
          config: widget.config,
        ),

      // ── 3D & Unknown ──────────────────────────────────────
      _ =>
        FallbackRenderer(
          file: widget.file,
          fileType: type,
          config: widget.config,
        ),
    };
  }
}
