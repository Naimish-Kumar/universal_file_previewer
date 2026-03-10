import 'dart:io';
import 'package:flutter/material.dart';
import '../core/preview_config.dart';
import '../parsers/zip_parser.dart';

/// Displays the contents of a ZIP archive as a browsable file tree.
class ZipRenderer extends StatefulWidget {
  final File file;
  final PreviewConfig config;

  const ZipRenderer({super.key, required this.file, required this.config});

  @override
  State<ZipRenderer> createState() => _ZipRendererState();
}

class _ZipRendererState extends State<ZipRenderer> {
  List<ZipEntry>? _entries;
  String? _error;
  String _currentPath = '';
  final List<String> _pathStack = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await ZipParser.listEntries(widget.file);
      if (mounted) setState(() => _entries = entries);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  List<ZipEntry> get _visibleEntries {
    if (_entries == null) return [];
    return _entries!.where((e) {
      if (_currentPath.isEmpty) {
        // Root level: no slash in name (or first segment only)
        final parts =
            e.name.split('/').where((s) => s.isNotEmpty).toList();
        return parts.length == 1 || (e.isDirectory && parts.length == 1);
      }
      // Inside a folder
      if (!e.name.startsWith(_currentPath)) return false;
      final relative = e.name.substring(_currentPath.length);
      final parts = relative.split('/').where((s) => s.isNotEmpty).toList();
      return parts.length == 1 || (e.isDirectory && parts.length == 1);
    }).toList();
  }

  void _enterFolder(ZipEntry entry) {
    _pathStack.add(_currentPath);
    setState(() => _currentPath = entry.name);
  }

  void _goBack() {
    if (_pathStack.isEmpty) return;
    setState(() => _currentPath = _pathStack.removeLast());
  }

  String _formatSize(int bytes) {
    if (bytes == 0) return '—';
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }

  IconData _iconFor(ZipEntry e) {
    if (e.isDirectory) return Icons.folder;
    final ext = e.extension;
    return switch (ext) {
      'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' => Icons.image,
      'mp4' || 'mov' || 'avi' || 'mkv'            => Icons.videocam,
      'mp3' || 'wav' || 'aac' || 'flac'           => Icons.audiotrack,
      'pdf'                                        => Icons.picture_as_pdf,
      'dart' || 'py' || 'js' || 'ts' || 'kt'      => Icons.code,
      'txt' || 'md' || 'log'                       => Icons.article,
      'json' || 'xml' || 'yaml' || 'yml'           => Icons.data_object,
      'zip' || 'rar' || 'tar' || 'gz'             => Icons.folder_zip,
      'docx' || 'doc'                              => Icons.description,
      'xlsx' || 'xls'                              => Icons.table_chart,
      'pptx' || 'ppt'                              => Icons.slideshow,
      _                                            => Icons.insert_drive_file,
    };
  }

  Color _colorFor(ZipEntry e) {
    if (e.isDirectory) return Colors.amber;
    final ext = e.extension;
    return switch (ext) {
      'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' => Colors.purple,
      'mp4' || 'mov' || 'avi'                      => Colors.red,
      'mp3' || 'wav' || 'aac'                      => Colors.orange,
      'pdf'                                        => Colors.red[800]!,
      'dart' || 'py' || 'js'                       => Colors.blue,
      'json' || 'xml'                              => Colors.teal,
      'zip' || 'rar'                               => Colors.brown,
      _                                            => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Failed to parse archive: $_error'),
          ],
        ),
      );
    }

    if (_entries == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final visible = _visibleEntries;
    final totalFiles = _entries!.where((e) => !e.isDirectory).length;
    final totalSize = _entries!.fold<int>(0, (s, e) => s + e.uncompressedSize);

    return Column(
      children: [
        // Header bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.grey[100],
          child: Row(
            children: [
              if (_pathStack.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  onPressed: _goBack,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.folder_zip, size: 20, color: Colors.brown),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentPath.isEmpty
                      ? '${widget.file.path.split('/').last} — $totalFiles files, ${_formatSize(totalSize)}'
                      : _currentPath,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // File list
        Expanded(
          child: visible.isEmpty
              ? const Center(child: Text('Empty folder'))
              : ListView.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 56),
                  itemBuilder: (ctx, i) {
                    final entry = visible[i];
                    return ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _colorFor(entry).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _iconFor(entry),
                          color: _colorFor(entry),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        entry.displayName,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        entry.isDirectory
                            ? 'Folder'
                            : '${_formatSize(entry.uncompressedSize)}'
                              '${entry.compressionRatio > 0 ? ' — ${entry.compressionRatio.toStringAsFixed(0)}% saved' : ''}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      trailing: entry.isDirectory
                          ? const Icon(Icons.chevron_right, color: Colors.grey)
                          : null,
                      onTap: entry.isDirectory ? () => _enterFolder(entry) : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
