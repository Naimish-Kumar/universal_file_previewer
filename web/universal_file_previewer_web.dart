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
  }

  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'ping':
        return true;
      case 'renderPdfPage':
      case 'getPdfPageCount':
      case 'generateVideoThumbnail':
      case 'getVideoInfo':
      case 'convertHeicToJpeg':
        // These require native APIs not easily available in a generic way on web
        // without extra dependencies. Return null or throw.
        return null;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'universal_file_previewer for web doesn\'t implement \'${call.method}\'',
        );
    }
  }
}
