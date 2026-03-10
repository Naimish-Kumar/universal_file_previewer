import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_file_previewer/universal_file_previewer.dart';

void main() {
  group('FileDetector', () {
    test('detects JPEG from magic bytes', () {
      final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);
      final type = FileDetector.detectFromBytes(bytes, fileName: 'photo.jpg');
      expect(type, FileType.jpeg);
    });

    test('detects PNG from magic bytes', () {
      final bytes = Uint8List.fromList(
          [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00]);
      final type = FileDetector.detectFromBytes(bytes);
      expect(type, FileType.png);
    });

    test('detects PDF from magic bytes', () {
      final bytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]);
      final type = FileDetector.detectFromBytes(bytes, fileName: 'doc.pdf');
      expect(type, FileType.pdf);
    });

    test('falls back to extension for TXT', () {
      final bytes = Uint8List.fromList([0x48, 0x65, 0x6C, 0x6C, 0x6F]);
      final type = FileDetector.detectFromBytes(bytes, fileName: 'readme.txt');
      expect(type, FileType.txt);
    });

    test('detects markdown by extension', () {
      final bytes = Uint8List.fromList([0x23, 0x20, 0x48, 0x65, 0x6C]);
      final type = FileDetector.detectFromBytes(bytes, fileName: 'README.md');
      expect(type, FileType.markdown);
    });

    test('returns unknown for unrecognized format', () {
      final bytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
      final type = FileDetector.detectFromBytes(bytes, fileName: 'file.xyz');
      expect(type, FileType.unknown);
    });
  });

  group('FileType extensions', () {
    test('isImage returns true for image types', () {
      expect(FileType.jpeg.isImage, isTrue);
      expect(FileType.png.isImage, isTrue);
      expect(FileType.pdf.isImage, isFalse);
    });

    test('isVideo returns true for video types', () {
      expect(FileType.mp4.isVideo, isTrue);
      expect(FileType.mp3.isVideo, isFalse);
    });

    test('isArchive returns true for archive types', () {
      expect(FileType.zip.isArchive, isTrue);
      expect(FileType.txt.isArchive, isFalse);
    });

    test('label returns uppercase name', () {
      expect(FileType.pdf.label, 'PDF');
      expect(FileType.jpeg.label, 'JPEG');
    });
  });
}
