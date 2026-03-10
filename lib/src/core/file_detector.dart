import 'dart:io';
import 'dart:typed_data';
import 'file_type.dart';

/// Detects file type using magic bytes (file signatures) and extension fallback.
/// Never trust extensions alone — always read the actual bytes.
class FileDetector {
  // Magic byte signatures for common formats
  static const Map<FileType, List<int>> _signatures = {
    FileType.jpeg:  [0xFF, 0xD8, 0xFF],
    FileType.png:   [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
    FileType.gif:   [0x47, 0x49, 0x46, 0x38],
    FileType.webp:  [0x52, 0x49, 0x46, 0x46], // RIFF (also check offset 8 for WEBP)
    FileType.bmp:   [0x42, 0x4D],
    FileType.pdf:   [0x25, 0x50, 0x44, 0x46],
    FileType.mp3:   [0xFF, 0xFB],
    FileType.mp4:   [0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70],
    FileType.glb:   [0x67, 0x6C, 0x54, 0x46],
    FileType.sevenZ:[0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C],
    FileType.gz:    [0x1F, 0x8B],
    FileType.flac:  [0x66, 0x4C, 0x61, 0x43],
    FileType.ogg:   [0x4F, 0x67, 0x67, 0x53],
    // ZIP signature — DOCX/XLSX/PPTX are also ZIP
    FileType.zip:   [0x50, 0x4B, 0x03, 0x04],
  };

  // Extension map fallback
  static const Map<String, FileType> _extensionMap = {
    // Images
    'jpg':  FileType.jpeg,
    'jpeg': FileType.jpeg,
    'png':  FileType.png,
    'gif':  FileType.gif,
    'webp': FileType.webp,
    'bmp':  FileType.bmp,
    'svg':  FileType.svg,
    'heic': FileType.heic,
    'heif': FileType.heic,
    'tiff': FileType.tiff,
    'tif':  FileType.tiff,
    // Video
    'mp4':  FileType.mp4,
    'mov':  FileType.mov,
    'avi':  FileType.avi,
    'mkv':  FileType.mkv,
    'webm': FileType.webm,
    'm4v':  FileType.mp4,
    // Audio
    'mp3':  FileType.mp3,
    'wav':  FileType.wav,
    'aac':  FileType.aac,
    'flac': FileType.flac,
    'ogg':  FileType.ogg,
    'm4a':  FileType.aac,
    // Documents
    'pdf':  FileType.pdf,
    'docx': FileType.docx,
    'doc':  FileType.doc,
    'xlsx': FileType.xlsx,
    'xls':  FileType.xls,
    'pptx': FileType.pptx,
    'ppt':  FileType.ppt,
    // Code
    'dart': FileType.code,
    'py':   FileType.code,
    'js':   FileType.code,
    'ts':   FileType.code,
    'kt':   FileType.code,
    'java': FileType.code,
    'cpp':  FileType.code,
    'c':    FileType.code,
    'h':    FileType.code,
    'cs':   FileType.code,
    'go':   FileType.code,
    'rs':   FileType.code,
    'rb':   FileType.code,
    'php':  FileType.code,
    'sh':   FileType.code,
    'swift':FileType.code,
    // Text / Data
    'txt':  FileType.txt,
    'md':   FileType.markdown,
    'markdown': FileType.markdown,
    'csv':  FileType.csv,
    'json': FileType.json,
    'xml':  FileType.xml,
    'html': FileType.html,
    'htm':  FileType.html,
    'yaml': FileType.code,
    'yml':  FileType.code,
    'log':  FileType.txt,
    'ini':  FileType.txt,
    'conf': FileType.txt,
    // Archives
    'zip':  FileType.zip,
    'rar':  FileType.rar,
    'tar':  FileType.tar,
    'gz':   FileType.gz,
    '7z':   FileType.sevenZ,
    // 3D
    'glb':  FileType.glb,
    'gltf': FileType.gltf,
    'obj':  FileType.obj,
    'stl':  FileType.stl,
  };

  /// Detect file type from a [File] object.
  /// Reads magic bytes first, falls back to extension.
  static Future<FileType> detect(File file) async {
    try {
      final header = await _readHeader(file, 16);
      final type = _detectFromBytes(header);

      if (type == FileType.zip) {
        return _resolveZipFormat(file);
      }
      if (type == FileType.webp) {
        return _resolveRiffFormat(header);
      }
      if (type != FileType.unknown) return type;
    } catch (_) {}

    return _detectByExtension(file.path);
  }

  /// Detect file type from raw bytes (e.g. from network or memory).
  static FileType detectFromBytes(Uint8List bytes, {String? fileName}) {
    final type = _detectFromBytes(bytes.toList());
    if (type != FileType.unknown) return type;
    if (fileName != null) return _detectByExtension(fileName);
    return FileType.unknown;
  }

  static FileType _detectFromBytes(List<int> bytes) {
    for (final entry in _signatures.entries) {
      if (_matches(bytes, entry.value)) {
        return entry.key;
      }
    }

    // SVG starts with <?xml or <svg
    final head = String.fromCharCodes(bytes.take(32).toList());
    if (head.contains('<svg') || head.contains('<?xml')) {
      if (head.contains('svg')) return FileType.svg;
      return FileType.xml;
    }

    return FileType.unknown;
  }

  static bool _matches(List<int> bytes, List<int> signature) {
    if (bytes.length < signature.length) return false;
    for (int i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return false;
    }
    return true;
  }

  /// DOCX, XLSX, PPTX are ZIP files — resolve by extension
  static FileType _resolveZipFormat(File file) {
    final ext = _extension(file.path);
    return switch (ext) {
      'docx' || 'docm' => FileType.docx,
      'xlsx' || 'xlsm' => FileType.xlsx,
      'pptx' || 'pptm' => FileType.pptx,
      'apk'            => FileType.zip,
      _                => FileType.zip,
    };
  }

  /// RIFF container: could be WEBP or WAV
  static FileType _resolveRiffFormat(List<int> bytes) {
    if (bytes.length >= 12) {
      final subtype = String.fromCharCodes(bytes.sublist(8, 12));
      if (subtype == 'WEBP') return FileType.webp;
      if (subtype == 'WAVE') return FileType.wav;
    }
    return FileType.unknown;
  }

  static FileType _detectByExtension(String path) {
    final ext = _extension(path);
    return _extensionMap[ext] ?? FileType.unknown;
  }

  static String _extension(String path) =>
      path.split('.').last.toLowerCase();

  static Future<List<int>> _readHeader(File file, int count) async {
    final raf = await file.open();
    try {
      final bytes = await raf.read(count);
      return bytes.toList();
    } finally {
      await raf.close();
    }
  }
}
