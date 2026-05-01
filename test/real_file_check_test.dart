import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_file_previewer/universal_file_previewer.dart';

void main() {
  group('Real File Detection', () {
    final dir = Directory('real_samples');

    void check(String name, FileType expected) {
      test('detects $name as $expected', () async {
        final file = File('${dir.path}/$name');
        if (!file.existsSync()) {
          print('Skipping $name (not downloaded)');
          return;
        }
        final type = await FileDetector.detect(file);
        expect(type, expected);
      });
    }

    check('sample.pdf', FileType.pdf);
    check('sample.jpg', FileType.jpeg);
    check('sample.png', FileType.png);
    check('sample.mp4', FileType.mp4);
    check('sample.md', FileType.markdown);
    check('sample.zip', FileType.zip);
    check('sample.dart', FileType.code);
    check('sample.txt', FileType.txt);
  });
}
