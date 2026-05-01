import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_file_previewer/universal_file_previewer.dart';

void main() {
  group('Remaining Real File Detection', () {
    final dir = Directory('real_samples');

    void check(String name, FileType expected) {
      test('detects $name as $expected', () async {
        final file = File('${dir.path}/$name');
        if (!file.existsSync()) {
          print('Skipping $name (not downloaded)');
          return;
        }
        final type = await FileDetector.detect(file);
        print('DEBUG: Detected $type for $name');
        expect(type, expected);
      });
    }

    // Images
    check('sample.gif', FileType.gif);
    check('sample.webp', FileType.webp);
    check('sample.bmp', FileType.bmp);
    check('sample.tif', FileType.tiff);

    // Audio
    check('sample.wav', FileType.wav);
    check('sample.ogg', FileType.ogg);

    // Data / Text
    check('sample.json', FileType.json);
    check('sample.csv', FileType.csv);
    check('sample.js', FileType.code);
    check('sample.gradle', FileType.code);

    // Docs
    check('sample.docx', FileType.docx);
    check('sample.xlsx', FileType.xlsx);
    check('sample.pptx', FileType.pptx);
  });
}
