import 'dart:ui_web' as ui;
import 'dart:html' as html;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:flutter/services.dart';

/// Web implementation of the universal_file_previewer plugin.
class FilePreviewerWeb {
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'universal_file_previewer',
      const StandardMethodCodec(),
      registrar,
    );

    final pluginInstance = FilePreviewerWeb();
    channel.setMethodCallHandler(pluginInstance.handleMethodCall);

    // Register factories for native web views
    _registerViewFactories();
  }

  static void _registerViewFactories() {
    // PDF View Factory
    ui.platformViewRegistry.registerViewFactory(
      'universal_file_previewer_pdf_view',
      (int viewId, {Object? params}) {
        final String path = (params as Map)['path'] as String;
        return html.IFrameElement()
          ..src = path
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
      },
    );

    // Video View Factory
    ui.platformViewRegistry.registerViewFactory(
      'universal_file_previewer_video_view',
      (int viewId, {Object? params}) {
        final String path = (params as Map)['path'] as String;
        return html.VideoElement()
          ..src = path
          ..controls = true
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = 'black';
      },
    );

    // Audio View Factory
    ui.platformViewRegistry.registerViewFactory(
      'universal_file_previewer_audio_view',
      (int viewId, {Object? params}) {
        final String path = (params as Map)['path'] as String;
        return html.AudioElement()
          ..src = path
          ..controls = true
          ..style.width = '100%';
      },
    );
  }

  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'ping':
        return true;
      case 'renderPdfPage':
      case 'getPdfPageCount':
        // Web uses direct iframe rendering, so these are not needed for full-file view
        return null;
      case 'generateVideoThumbnail':
        // Could be implemented using canvas, but for now return null to use placeholder
        return null;
      case 'getVideoInfo':
        return {'duration': 0, 'width': 1280, 'height': 720};
      case 'convertHeicToJpeg':
        // Browsers generally don't support HEIC natively yet
        return null;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'universal_file_previewer for web doesn\'t implement \'${call.method}\'',
        );
    }
  }
}
