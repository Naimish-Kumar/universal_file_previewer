import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_file_previewer/universal_file_previewer.dart';
import 'package:universal_file_previewer/src/renderers/pdf_renderer.dart';
import 'package:universal_file_previewer/src/renderers/media_renderers.dart';
import 'package:universal_file_previewer/src/renderers/text_renderers.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory('test_assets_temp');
    if (!tempDir.existsSync()) {
      await tempDir.create();
    }
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  File createTestFile(String name) {
    final file = File('${tempDir.path}/$name');
    file.writeAsBytesSync([0, 0, 0, 0]); // dummy content
    return file;
  }

  testWidgets('FilePreviewWidget builds PdfRenderer for .pdf files', (WidgetTester tester) async {
    final file = createTestFile('test.pdf');
    
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FilePreviewWidget(file: file),
      ),
    ));

    await tester.runAsync(() async {
      for (int i = 0; i < 50; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      }
    });
    
    expect(find.byType(PdfRenderer), findsOneWidget);
  });

  testWidgets('FilePreviewWidget builds VideoRenderer for .mp4 files', (WidgetTester tester) async {
    final file = createTestFile('test.mp4');
    
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FilePreviewWidget(file: file),
      ),
    ));

    await tester.runAsync(() async {
      for (int i = 0; i < 50; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      }
    });
    expect(find.byType(VideoRenderer), findsOneWidget);
  });

  testWidgets('FilePreviewWidget builds AudioRenderer for .mp3 files', (WidgetTester tester) async {
    final file = createTestFile('test.mp3');
    
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FilePreviewWidget(file: file),
      ),
    ));

    await tester.runAsync(() async {
      for (int i = 0; i < 50; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      }
    });
    expect(find.byType(AudioRenderer), findsOneWidget);
  });

  testWidgets('FilePreviewWidget builds CodeRenderer for .dart files', (WidgetTester tester) async {
    final file = createTestFile('test.dart');
    
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FilePreviewWidget(file: file),
      ),
    ));

    await tester.runAsync(() async {
      for (int i = 0; i < 50; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      }
    });
    expect(find.byType(CodeRenderer), findsOneWidget);
  });
}
