# universal_file_previewer

[![pub.dev](https://img.shields.io/pub/v/universal_file_previewer.svg)](https://pub.dev/packages/universal_file_previewer)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-blue)](https://pub.dev/packages/universal_file_previewer)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Preview **50+ file formats** in Flutter with **zero heavy dependencies**.  
Uses pure Dart for text-based formats and native platform channels for PDF, video, and audio.

---

## ✨ Supported Formats

| Category    | Formats                                              | Renderer         |
|-------------|------------------------------------------------------|------------------|
| **Images**  | JPG, PNG, GIF, WebP, BMP, SVG, HEIC, TIFF           | Flutter native   |
| **PDF**     | PDF                                                  | Platform channel |
| **Video**   | MP4, MOV, AVI, MKV, WebM                            | Platform channel |
| **Audio**   | MP3, WAV, AAC, FLAC, OGG                            | Platform channel |
| **Code**    | Dart, Python, JS, TS, Kotlin, Java, + more           | Pure Dart        |
| **Text**    | TXT, Markdown, CSV, JSON, XML, HTML, LOG             | Pure Dart        |
| **Archive** | ZIP (browsable file tree)                            | Pure Dart        |
| **Docs**    | DOCX, XLSX, PPTX (metadata view)                    | Fallback         |
| **Unknown** | Any file → metadata + size + type                   | Fallback         |

---

## 🚀 Installation

```yaml
dependencies:
  universal_file_previewer: ^0.1.0
```

---

## 📱 Quick Start

### Full-screen preview page

```dart
import 'package:universal_file_previewer/universal_file_previewer.dart';

// One line — opens full-screen preview with toolbar
FilePreviewPage.open(context, file: File('/path/to/document.pdf'));
```

### Inline widget

```dart
FilePreviewWidget(
  file: File('/path/to/file.md'),
  config: PreviewConfig(
    showToolbar: false,
    enableZoom: true,
    codeTheme: CodeTheme.dracula,
  ),
  onTypeDetected: (type) => print('Detected: $type'),
)
```

### With controller (PDF page navigation)

```dart
final controller = PreviewController();

// Widget
FilePreviewWidget(
  file: myPdfFile,
  controller: controller,
)

// Control programmatically
controller.nextPage();
controller.previousPage();
controller.goToPage(5);
controller.zoomIn();
controller.zoomOut();
```

### Detect file type only

```dart
final type = await FileDetector.detect(File('/path/to/file'));
print(type); // FileType.pdf

// From bytes
final type = FileDetector.detectFromBytes(bytes, fileName: 'doc.pdf');
```

---

## ⚙️ Configuration

```dart
PreviewConfig(
  showToolbar: true,          // Show AppBar (in FilePreviewPage)
  showFileInfo: true,         // Show info button in toolbar
  enableZoom: true,           // Pinch-to-zoom for images & PDF
  backgroundColor: Colors.black,
  codeTheme: CodeTheme.dark,  // dark | light | dracula | monokai
  maxTextFileSizeBytes: 5 * 1024 * 1024,  // 5 MB limit for text files
  errorBuilder: (err) => MyErrorWidget(err),
  loadingBuilder: () => MyLoadingWidget(),
)
```

---

## 🏗️ Architecture

```
FilePreviewWidget
  │
  ├── FileDetector          ← Magic bytes + extension fallback
  │     └── Pure Dart, reads first 16 bytes
  │
  ├── ImageRenderer         ← Flutter Image.file + InteractiveViewer
  ├── SvgRenderer           ← Pure Dart SVG content display
  ├── HeicRenderer          ← Platform channel → JPEG conversion
  │
  ├── PdfRenderer           ← Platform channel (PDFKit / PdfRenderer API)
  │
  ├── VideoRenderer         ← Platform channel (AVPlayer / ExoPlayer)
  ├── AudioRenderer         ← Platform channel + animated waveform UI
  │
  ├── TextRenderer          ← Pure Dart, SelectableText
  ├── MarkdownRenderer      ← Pure Dart parser, no packages
  ├── JsonRenderer          ← Pure Dart collapsible tree
  ├── CsvRenderer           ← Pure Dart DataTable
  ├── CodeRenderer          ← Pure Dart syntax tokenizer
  │
  ├── ZipRenderer           ← Pure Dart ZIP spec parser (browsable tree)
  │
  └── FallbackRenderer      ← File metadata (name, size, type, date)
```

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  # That's it. Zero external packages.
```

---

## 🔌 Platform Requirements

**Android**
- `minSdkVersion 21` (PDF rendering requires API 21+)
- `HEIC support` requires Android 9+ (API 28+)

**iOS**
- `iOS 11.0+`
- PDFKit available since iOS 11

Add to `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

---

## 🗺️ Roadmap

- [x] Image rendering (JPG, PNG, GIF, WebP, BMP)
- [x] SVG display
- [x] PDF rendering (platform channel)
- [x] Video thumbnail + metadata
- [x] Audio player UI with waveform
- [x] Markdown renderer (pure Dart)
- [x] JSON tree viewer (pure Dart)
- [x] CSV table renderer (pure Dart)
- [x] Syntax highlighted code viewer (pure Dart)
- [x] ZIP archive browser (pure Dart)
- [x] HEIC conversion (platform channel)
- [ ] DOCX → HTML conversion (pure Dart XML parser)
- [ ] XLSX spreadsheet renderer (pure Dart)
- [ ] PPTX slide viewer
- [ ] 3D model viewer (GLB/OBJ)
- [ ] RAR/7Z archive support
- [ ] Thumbnail generation API

---

## 🤝 Contributing

PRs welcome! Please read `CONTRIBUTING.md` first.

```bash
git clone https://github.com/Naimish-Kumar/universal_file_previewer
cd universal_file_previewer
flutter pub get
cd example && flutter run
```

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.
