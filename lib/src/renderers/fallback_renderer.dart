import 'dart:io';
import 'package:flutter/material.dart';
import '../core/file_type.dart';
import '../core/preview_config.dart';

/// Shown for unknown or unsupported file types.
/// Displays file metadata: name, size, type, modified date.
class FallbackRenderer extends StatefulWidget {
  final File file;
  final FileType fileType;
  final PreviewConfig config;

  const FallbackRenderer({
    super.key,
    required this.file,
    required this.fileType,
    required this.config,
  });

  @override
  State<FallbackRenderer> createState() => _FallbackRendererState();
}

class _FallbackRendererState extends State<FallbackRenderer> {
  FileStat? _stat;

  @override
  void initState() {
    super.initState();
    widget.file.stat().then((s) {
      if (mounted) {
        setState(() => _stat = s);
      }
    });
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1048576) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    if (bytes < 1073741824) {
      return '${(bytes / 1048576).toStringAsFixed(2)} MB';
    }
    return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.file.path.split('/').last;
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toUpperCase()
        : '?';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // File icon
            Container(
              width: 100,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.insert_drive_file,
                      size: 80, color: Colors.grey),
                  Positioned(
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        ext,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // File name
            Text(
              fileName,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Metadata table
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _row('Type', widget.fileType == FileType.unknown
                      ? 'Unknown ($ext)'
                      : widget.fileType.label),
                  _divider(),
                  _row('Size', _stat != null
                      ? _formatSize(_stat!.size)
                      : 'Loading...'),
                  _divider(),
                  _row('Modified', _stat != null
                      ? _formatDate(_stat!.modified)
                      : 'Loading...'),
                  _divider(),
                  _row('Path', widget.file.path),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Preview not available for this file type.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, color: Colors.grey[300]);

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
