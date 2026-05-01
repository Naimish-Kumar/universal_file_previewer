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
    'sample.gif': 'https://github.com/mathiasbynens/small/raw/master/gif.gif',
    'sample.webp': 'https://github.com/mathiasbynens/small/raw/master/webp.webp',
    'sample.bmp': 'https://github.com/mathiasbynens/small/raw/master/bmp.bmp',
    'sample.tif': 'https://github.com/ianare/exif-samples/raw/master/tiff/test.tif',
    'sample.wav': 'https://github.com/rafaelreis-hotmart/Audio-Sample-files/raw/master/sample.wav',
    'sample.ogg': 'https://github.com/rafaelreis-hotmart/Audio-Sample-files/raw/master/sample.ogg',
    'sample.json': 'https://raw.githubusercontent.com/nlohmann/json/master/package.json',
    'sample.csv': 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/01-01-2021.csv',
    'sample.docx': 'https://github.com/carlosedp/example-files/raw/master/sample.docx',
    'sample.xlsx': 'https://github.com/carlosedp/example-files/raw/master/sample.xlsx',
    'sample.pptx': 'https://github.com/carlosedp/example-files/raw/master/sample.pptx',
    'sample.html': 'https://raw.githubusercontent.com/Naimish-Kumar/universal_file_previewer/main/example/web/index.html',
    'sample.xml': 'https://raw.githubusercontent.com/Naimish-Kumar/universal_file_previewer/main/example/android/app/src/main/AndroidManifest.xml',
    'sample.py': 'https://raw.githubusercontent.com/Naimish-Kumar/universal_file_previewer/main/scratch/generate_samples.dart', // using a dart file but calling it py for extension test
  };

  for (final entry in samples.entries) {
    await download(entry.value, '${dir.path}/${entry.key}');
  }
  
  // Real py/js/java/kt from some repo
  await download('https://raw.githubusercontent.com/django/django/main/setup.py', '${dir.path}/sample.py');
  await download('https://raw.githubusercontent.com/lodash/lodash/master/package.json', '${dir.path}/sample.js'); // wait this is json
  await download('https://raw.githubusercontent.com/lodash/lodash/master/lodash.js', '${dir.path}/sample.js');
  await download('https://raw.githubusercontent.com/spring-projects/spring-boot/main/build.gradle', '${dir.path}/sample.gradle');
}
