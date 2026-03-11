import 'dart:io';
import 'dart:typed_data';

/// Pure Dart ZIP file parser.
/// Reads the ZIP local file headers without any external packages.
/// Based on PKWARE ZIP spec: https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT
class ZipParser {
  static const int _localFileHeaderSig = 0x04034b50;
  static const int _headerSize = 30;

  /// List all entries inside a ZIP file.
  static Future<List<ZipEntry>> listEntries(File file) async {
    final bytes = await file.readAsBytes();
    return _parseEntries(bytes);
  }

  /// List entries from raw bytes.
  static List<ZipEntry> listEntriesFromBytes(Uint8List bytes) {
    return _parseEntries(bytes);
  }

  static List<ZipEntry> _parseEntries(Uint8List bytes) {
    final entries = <ZipEntry>[];
    int offset = 0;

    while (offset + _headerSize <= bytes.length) {
      // Check for local file header signature (PK\x03\x04)
      final sig = _readUint32(bytes, offset);
      if (sig != _localFileHeaderSig) {
        // Try to find the next header
        offset++;
        continue;
      }

      // Parse local file header
      // Offset  Length  Contents
      // 0       4       Local file header signature = 0x04034b50
      // 4       2       Version needed to extract
      // 6       2       General purpose bit flag
      // 8       2       Compression method
      // 10      2       Last mod file time
      // 12      2       Last mod file date
      // 14      4       CRC-32
      // 18      4       Compressed size
      // 22      4       Uncompressed size
      // 26      2       File name length
      // 28      2       Extra field length
      // 30      (n)     File name
      // 30+n    (m)     Extra field
      // 30+n+m  (c)     File data

      final compressedSize   = _readUint32(bytes, offset + 18);
      final uncompressedSize = _readUint32(bytes, offset + 22);
      final fileNameLen      = _readUint16(bytes, offset + 26);
      final extraFieldLen    = _readUint16(bytes, offset + 28);

      if (offset + _headerSize + fileNameLen > bytes.length) {
        break;
      }

      final nameBytes = bytes.sublist(
        offset + _headerSize,
        offset + _headerSize + fileNameLen,
      );

      String fileName;
      try {
        fileName = String.fromCharCodes(nameBytes);
      } catch (_) {
        fileName = 'unknown_${entries.length}';
      }

      final compressionMethod = _readUint16(bytes, offset + 8);
      final lastModTime       = _readUint16(bytes, offset + 10);
      final lastModDate       = _readUint16(bytes, offset + 12);

      entries.add(ZipEntry(
        name:              fileName,
        compressedSize:   compressedSize,
        uncompressedSize: uncompressedSize,
        compressionMethod: compressionMethod,
        isDirectory:      fileName.endsWith('/') || fileName.endsWith('\\'),
        dataOffset:       offset + _headerSize + fileNameLen + extraFieldLen,
        modifiedDate:     _dosDateTimeToDateTime(lastModDate, lastModTime),
      ));

      offset += _headerSize + fileNameLen + extraFieldLen + compressedSize;
    }

    return entries;
  }

  static int _readUint16(Uint8List b, int o) =>
      b[o] | (b[o + 1] << 8);

  static int _readUint32(Uint8List b, int o) =>
      b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24);

  static DateTime _dosDateTimeToDateTime(int date, int time) {
    try {
      final year   = ((date >> 9) & 0x7F) + 1980;
      final month  = (date >> 5) & 0x0F;
      final day    = date & 0x1F;
      final hour   = (time >> 11) & 0x1F;
      final minute = (time >> 5) & 0x3F;
      final second = (time & 0x1F) * 2;
      return DateTime(year, month, day, hour, minute, second);
    } catch (_) {
      return DateTime.now();
    }
  }
}

/// Represents a single entry (file or directory) inside a ZIP archive.
class ZipEntry {
  final String name;
  final int compressedSize;
  final int uncompressedSize;
  final int compressionMethod;
  final bool isDirectory;
  final int dataOffset;
  final DateTime modifiedDate;

  const ZipEntry({
    required this.name,
    required this.compressedSize,
    required this.uncompressedSize,
    required this.compressionMethod,
    required this.isDirectory,
    required this.dataOffset,
    required this.modifiedDate,
  });

  /// Short display name (last component of path)
  String get displayName => name.split('/').where((s) => s.isNotEmpty).last;

  /// Parent directory path
  String get parentPath {
    final parts = name.split('/').where((s) => s.isNotEmpty).toList();
    if (parts.length <= 1) {
      return '';
    }
    return parts.take(parts.length - 1).join('/');
  }

  /// File extension
  String get extension => isDirectory
      ? ''
      : name.split('.').last.toLowerCase();

  double get compressionRatio => uncompressedSize == 0
      ? 0
      : (1 - compressedSize / uncompressedSize) * 100;

  bool get isStored => compressionMethod == 0;
  bool get isDeflated => compressionMethod == 8;
}
