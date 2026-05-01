import 'dart:typed_data';
import 'package:universal_file_previewer/src/core/file_detector.dart';

void main() {
  final type = FileDetector.detectFromBytes(Uint8List(0), fileName: 'test.gradle');
  print('Detected type for test.gradle: $type');
  
  final type2 = FileDetector.detectFromBytes(Uint8List(0), fileName: 'test.pdf');
  print('Detected type for test.pdf: $type2');
}
