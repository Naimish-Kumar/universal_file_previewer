import 'dart:io';
import 'package:flutter/material.dart';
import 'package:universal_file_previewer/universal_file_previewer.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal File Previewer Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Sample files for demonstration
  static const _samples = [
    _Sample('README.md', 'Markdown', Icons.article, Colors.blue),
    _Sample('data.json', 'JSON Tree', Icons.data_object, Colors.teal),
    _Sample('report.pdf', 'PDF', Icons.picture_as_pdf, Colors.red),
    _Sample('photo.jpg', 'Image', Icons.image, Colors.purple),
    _Sample('archive.zip', 'ZIP Browser', Icons.folder_zip, Colors.brown),
    _Sample('main.dart', 'Code (Dart)', Icons.code, Colors.indigo),
    _Sample('data.csv', 'CSV Table', Icons.table_chart, Colors.green),
    _Sample('video.mp4', 'Video', Icons.videocam, Colors.orange),
    _Sample('song.mp3', 'Audio', Icons.audiotrack, Colors.pink),
    _Sample('unknown.xyz', 'Unknown File', Icons.help_outline, Colors.grey),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Universal File Previewer'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _samples.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final s = _samples[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: s.color.withValues(alpha: 0.15),
                child: Icon(s.icon, color: s.color),
              ),
              title: Text(s.fileName),
              subtitle: Text(s.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openPreview(ctx, s),
            ),
          );
        },
      ),
    );
  }

  void _openPreview(BuildContext context, _Sample sample) {
    // In a real app, use file_picker or path_provider to get real files.
    // Here we use a dummy path for illustration.
    final file = File('/tmp/${sample.fileName}');

    FilePreviewPage.open(
      context,
      file: file,
      config: const PreviewConfig(
        showToolbar: true,
        showFileInfo: true,
        enableZoom: true,
        codeTheme: CodeTheme.dark,
      ),
    );
  }
}

// ── Inline widget usage example ────────────────────────────────────
//
//  FilePreviewWidget(
//    file: File('/path/to/document.pdf'),
//    config: PreviewConfig(
//      showToolbar: false,
//      enableZoom: true,
//      codeTheme: CodeTheme.dracula,
//    ),
//    onTypeDetected: (type) => print('Detected: $type'),
//  )
//
// ── With controller ────────────────────────────────────────────────
//
//  final controller = PreviewController();
//
//  FilePreviewWidget(file: file, controller: controller)
//
//  controller.nextPage();
//  controller.zoomIn();
//  controller.goToPage(5);

class _Sample {
  final String fileName;
  final String label;
  final IconData icon;
  final Color color;

  const _Sample(this.fileName, this.label, this.icon, this.color);
}
