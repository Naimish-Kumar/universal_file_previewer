import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// A utility class for downloading files from URLs.
class FileDownloader {
  /// Downloads a file from the given [url] and returns a [File] object.
  /// The file is saved in the temporary directory.
  static Future<File> download(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final tempDir = await getTemporaryDirectory();
      final fileName = _getFileNameFromUrl(url);
      final file = File(p.join(tempDir.path, fileName));
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } else {
      throw Exception('Failed to download file from $url: ${response.statusCode}');
    }
  }

  static String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final fileName = p.basename(uri.path);
      if (fileName.isEmpty) {
        return 'downloaded_file_${DateTime.now().millisecondsSinceEpoch}';
      }
      return fileName;
    } catch (_) {
      return 'downloaded_file_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
