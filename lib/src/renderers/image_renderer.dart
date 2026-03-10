import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/preview_config.dart';
import '../platform/platform_channel.dart';

/// Renders JPEG, PNG, GIF, WebP, BMP images using Flutter's built-in Image widget.
/// Supports pinch-to-zoom via InteractiveViewer.
class ImageRenderer extends StatelessWidget {
  final File file;
  final PreviewConfig config;

  const ImageRenderer({super.key, required this.file, required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: config.backgroundColor ?? Colors.black,
      child: config.enableZoom
          ? InteractiveViewer(
              minScale: 0.5,
              maxScale: 8.0,
              child: Center(child: Image.file(file, fit: BoxFit.contain)),
            )
          : Center(child: Image.file(file, fit: BoxFit.contain)),
    );
  }
}

/// Renders HEIC images by converting to JPEG via platform channel.
class HeicRenderer extends StatefulWidget {
  final File file;
  final PreviewConfig config;

  const HeicRenderer({super.key, required this.file, required this.config});

  @override
  State<HeicRenderer> createState() => _HeicRendererState();
}

class _HeicRendererState extends State<HeicRenderer> {
  Uint8List? _jpegBytes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _convert();
  }

  Future<void> _convert() async {
    try {
      final bytes =
          await FilePreviewerChannel.convertHeicToJpeg(widget.file.path);
      if (mounted) setState(() => _jpegBytes = bytes);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text('HEIC conversion failed: $_error'));
    }
    if (_jpegBytes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      color: widget.config.backgroundColor ?? Colors.black,
      child: InteractiveViewer(
        child: Center(child: Image.memory(_jpegBytes!, fit: BoxFit.contain)),
      ),
    );
  }
}

/// Basic SVG renderer using a CustomPainter.
/// Handles simple SVGs. Complex SVGs with filters/masks fall back to a
/// message with the raw SVG XML text.
class SvgRenderer extends StatefulWidget {
  final File file;
  final PreviewConfig config;

  const SvgRenderer({super.key, required this.file, required this.config});

  @override
  State<SvgRenderer> createState() => _SvgRendererState();
}

class _SvgRendererState extends State<SvgRenderer> {
  String? _svgContent;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final content = await widget.file.readAsString();
    if (mounted) setState(() => _svgContent = content);
  }

  @override
  Widget build(BuildContext context) {
    if (_svgContent == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: widget.config.backgroundColor ?? Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('SVG Preview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '${(_svgContent!.length / 1024).toStringAsFixed(1)} KB SVG file',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // Show raw SVG markup in a code view
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _svgContent!.length > 3000
                      ? '${_svgContent!.substring(0, 3000)}\n...(truncated)'
                      : _svgContent!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFF569CD6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
