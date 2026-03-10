/// All supported file types
enum FileType {
  // Images
  jpeg,
  png,
  gif,
  webp,
  bmp,
  svg,
  heic,
  tiff,

  // Video
  mp4,
  mov,
  avi,
  mkv,
  webm,

  // Audio
  mp3,
  wav,
  aac,
  flac,
  ogg,

  // Documents
  pdf,
  docx,
  doc,
  xlsx,
  xls,
  pptx,
  ppt,

  // Code
  code,

  // Data / Text
  txt,
  markdown,
  csv,
  json,
  xml,
  html,

  // Archives
  zip,
  rar,
  tar,
  gz,
  sevenZ,

  // 3D
  glb,
  gltf,
  obj,
  stl,

  // Unknown
  unknown,
}

extension FileTypeExtension on FileType {
  bool get isImage => [
        FileType.jpeg,
        FileType.png,
        FileType.gif,
        FileType.webp,
        FileType.bmp,
        FileType.svg,
        FileType.heic,
        FileType.tiff,
      ].contains(this);

  bool get isVideo => [
        FileType.mp4,
        FileType.mov,
        FileType.avi,
        FileType.mkv,
        FileType.webm,
      ].contains(this);

  bool get isAudio => [
        FileType.mp3,
        FileType.wav,
        FileType.aac,
        FileType.flac,
        FileType.ogg,
      ].contains(this);

  bool get isDocument => [
        FileType.pdf,
        FileType.docx,
        FileType.doc,
        FileType.xlsx,
        FileType.xls,
        FileType.pptx,
        FileType.ppt,
      ].contains(this);

  bool get isCode => this == FileType.code;

  bool get isText => [
        FileType.txt,
        FileType.markdown,
        FileType.csv,
        FileType.json,
        FileType.xml,
        FileType.html,
      ].contains(this);

  bool get isArchive => [
        FileType.zip,
        FileType.rar,
        FileType.tar,
        FileType.gz,
        FileType.sevenZ,
      ].contains(this);

  bool get is3D => [
        FileType.glb,
        FileType.gltf,
        FileType.obj,
        FileType.stl,
      ].contains(this);

  String get label => name.toUpperCase();
}
