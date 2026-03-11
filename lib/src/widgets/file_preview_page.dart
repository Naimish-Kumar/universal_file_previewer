import 'dart:io';
import 'package:flutter/material.dart';
import '../core/file_type.dart';
import '../core/preview_config.dart';
import '../core/preview_controller.dart';
import 'file_preview_widget.dart';

/// A full-screen page that wraps [FilePreviewWidget] with an AppBar,
/// file name, and optional share/info actions.
///
/// Usage:
/// ```dart
/// // Navigate to it
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => FilePreviewPage(file: myFile),
/// ));
///
/// // Or use the convenience method
/// FilePreviewPage.open(context, file: myFile);
/// ```
class FilePreviewPage extends StatefulWidget {
  final File file;
  final PreviewConfig config;
  final PreviewController? controller;
  final String? title;
  final List<Widget>? actions;

  const FilePreviewPage({
    super.key,
    required this.file,
    this.config = const PreviewConfig(),
    this.controller,
    this.title,
    this.actions,
  });

  /// Convenience method to push this page onto the navigator.
  static Future<void> open(
    BuildContext context, {
    required File file,
    PreviewConfig config = const PreviewConfig(),
    PreviewController? controller,
    String? title,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FilePreviewPage(
          file: file,
          config: config,
          controller: controller,
          title: title,
        ),
      ),
    );
  }

  @override
  State<FilePreviewPage> createState() => _FilePreviewPageState();
}

class _FilePreviewPageState extends State<FilePreviewPage> {
  FileType? _detectedType;
  late PreviewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PreviewController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  String get _displayTitle {
    if (widget.title != null) {
      return widget.title!;
    }
    final name = widget.file.path.split('/').last;
    return name.length > 30 ? '...${name.substring(name.length - 28)}' : name;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1048576) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  void _showInfo() async {
    final stat = await widget.file.stat();
    if (!mounted) {
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('File Info',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _infoRow('Name', widget.file.path.split('/').last),
            _infoRow('Type',
                _detectedType?.label ?? 'Unknown'),
            _infoRow('Size', _formatSize(stat.size)),
            _infoRow('Modified',
                stat.modified.toString().substring(0, 19)),
            _infoRow('Path', widget.file.path),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.config.showToolbar
          ? AppBar(
              title: Text(
                _displayTitle,
                style: widget.config.titleStyle,
              ),
              centerTitle: false,
              actions: [
                if (widget.config.showFileInfo)
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: _showInfo,
                    tooltip: 'File info',
                  ),
                ...?widget.actions,
              ],
            )
          : null,
      body: FilePreviewWidget(
        file: widget.file,
        config: widget.config,
        controller: _controller,
        onTypeDetected: (type) {
          setState(() => _detectedType = type);
        },
      ),
    );
  }
}
