import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_file_previewer/universal_file_previewer.dart';

void main() {
  group('Final Real File Detection', () {
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

    // 3D
    check('sample.glb', FileType.glb);
    check('sample.gltf', FileType.gltf);
    check('sample.obj', FileType.obj);
    check('sample.stl', FileType.stl);

    // Video
    check('sample.mkv', FileType.mkv);
    check('sample.webm', FileType.webm);

    // Audio
    check('sample.flac', FileType.flac);

    // Code
    check('sample.py', FileType.code);
  });
}
