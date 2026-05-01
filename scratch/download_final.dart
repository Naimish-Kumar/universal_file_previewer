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
    'sample.glb': 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Duck/glTF-Binary/Duck.glb',
    'sample.gltf': 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Duck/glTF/Duck.gltf',
    'sample.obj': 'https://raw.githubusercontent.com/alecjacobson/common-3d-test-models/master/data/bunny.obj',
    'sample.stl': 'https://raw.githubusercontent.com/alecjacobson/common-3d-test-models/master/data/bunny.stl',
    'sample.mkv': 'https://raw.githubusercontent.com/Matroska-Org/matroska-test-files/master/test_files/test1.mkv',
    'sample.webm': 'https://raw.githubusercontent.com/webmproject/webm-test-data/master/vp80-00-compmb-337.webm',
    'sample.flac': 'https://github.com/rafaelreis-hotmart/Audio-Sample-files/raw/master/sample.flac',
    'sample.mov': 'https://github.com/the-m-v-p/Sample-Files/raw/master/Video/MOV/sample.mov',
    'sample.avi': 'https://github.com/the-m-v-p/Sample-Files/raw/master/Video/AVI/sample.avi',
    'sample.mp3': 'https://github.com/the-m-v-p/Sample-Files/raw/master/Audio/MP3/sample.mp3',
    'sample.aac': 'https://github.com/the-m-v-p/Sample-Files/raw/master/Audio/AAC/sample.aac',
    'sample.7z': 'https://github.com/the-m-v-p/Sample-Files/raw/master/Archive/7Z/sample.7z',
    'sample.tar': 'https://github.com/the-m-v-p/Sample-Files/raw/master/Archive/TAR/sample.tar',
    'sample.py': 'https://raw.githubusercontent.com/python/cpython/main/Lib/os.py',
    'sample.java': 'https://raw.githubusercontent.com/spring-projects/spring-boot/main/spring-boot-project/spring-boot/src/main/java/org/springframework/boot/SpringApplication.java',
    'sample.kt': 'https://raw.githubusercontent.com/JetBrains/kotlin/master/compiler/frontend/src/org/jetbrains/kotlin/resolve/BindingContext.kt',
  };

  for (final entry in samples.entries) {
    await download(entry.value, '${dir.path}/${entry.key}');
  }
}
