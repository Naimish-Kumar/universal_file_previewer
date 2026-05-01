import 'dart:io';

Future<void> download(String url, String filename) async {
  print('Downloading $filename from $url...');
  try {
    final request = await HttpClient().getUrl(Uri.parse(url));
    request.followRedirects = true;
    final response = await request.close();
    if (response.statusCode == 200) {
      final file = File(filename);
      await response.pipe(file.openWrite());
      print('Saved $filename');
    } else {
      print('Failed to download $filename: ${response.statusCode}');
    }
  } catch (e) {
    print('Error downloading $filename: $e');
  }
}

void main() async {
  final dir = Directory('real_samples');
  if (!dir.existsSync()) dir.createSync();

  final samples = {
    'sample.docx': 'https://raw.githubusercontent.com/python-openxml/python-docx/master/tests/test_files/simple.docx',
    'sample.xlsx': 'https://raw.githubusercontent.com/sheetjs/sheetjs/master/test_files/pivot_table_named_range.xlsx',
    'sample.pptx': 'https://raw.githubusercontent.com/scanny/python-pptx/master/tests/test_files/simple-pptx.pptx',
    'sample.json': 'https://raw.githubusercontent.com/nlohmann/json/master/package.json',
    'sample.tif': 'https://github.com/mathiasbynens/small/raw/master/tiff.tif',
  };

  for (final entry in samples.entries) {
    await download(entry.value, '${dir.path}/${entry.key}');
  }
}
