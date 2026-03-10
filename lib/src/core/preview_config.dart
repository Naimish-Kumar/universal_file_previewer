import 'package:flutter/material.dart';

/// Configuration for the file previewer appearance and behavior.
class PreviewConfig {
  /// Show the top toolbar with file name, share, and other actions.
  final bool showToolbar;

  /// Show file metadata (size, type, dimensions) in the toolbar subtitle.
  final bool showFileInfo;

  /// Enable pinch-to-zoom on image and PDF renderers.
  final bool enableZoom;

  /// Background color of the preview area.
  final Color? backgroundColor;

  /// Text style for the file name in the toolbar.
  final TextStyle? titleStyle;

  /// Error widget builder — override the default error view.
  final Widget Function(Object error)? errorBuilder;

  /// Loading widget builder — override the default loading indicator.
  final Widget Function()? loadingBuilder;

  /// Maximum file size (in bytes) to load into memory for text renderers.
  /// Files larger than this show a "file too large" message.
  /// Defaults to 5 MB.
  final int maxTextFileSizeBytes;

  /// Theme for code syntax highlighting.
  final CodeTheme codeTheme;

  const PreviewConfig({
    this.showToolbar = true,
    this.showFileInfo = true,
    this.enableZoom = true,
    this.backgroundColor,
    this.titleStyle,
    this.errorBuilder,
    this.loadingBuilder,
    this.maxTextFileSizeBytes = 5 * 1024 * 1024,
    this.codeTheme = CodeTheme.dark,
  });

  PreviewConfig copyWith({
    bool? showToolbar,
    bool? showFileInfo,
    bool? enableZoom,
    Color? backgroundColor,
    TextStyle? titleStyle,
    int? maxTextFileSizeBytes,
    CodeTheme? codeTheme,
  }) {
    return PreviewConfig(
      showToolbar: showToolbar ?? this.showToolbar,
      showFileInfo: showFileInfo ?? this.showFileInfo,
      enableZoom: enableZoom ?? this.enableZoom,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      titleStyle: titleStyle ?? this.titleStyle,
      maxTextFileSizeBytes: maxTextFileSizeBytes ?? this.maxTextFileSizeBytes,
      codeTheme: codeTheme ?? this.codeTheme,
    );
  }
}

/// Code syntax highlighting theme
enum CodeTheme {
  dark,
  light,
  dracula,
  monokai,
}

extension CodeThemeExtension on CodeTheme {
  Color get background => switch (this) {
    CodeTheme.dark    => const Color(0xFF1E1E1E),
    CodeTheme.light   => const Color(0xFFF5F5F5),
    CodeTheme.dracula => const Color(0xFF282A36),
    CodeTheme.monokai => const Color(0xFF272822),
  };

  Color get defaultText => switch (this) {
    CodeTheme.dark    => const Color(0xFFD4D4D4),
    CodeTheme.light   => const Color(0xFF1E1E1E),
    CodeTheme.dracula => const Color(0xFFF8F8F2),
    CodeTheme.monokai => const Color(0xFFF8F8F2),
  };

  Color get keyword => switch (this) {
    CodeTheme.dark    => const Color(0xFF569CD6),
    CodeTheme.light   => const Color(0xFF0000FF),
    CodeTheme.dracula => const Color(0xFFFF79C6),
    CodeTheme.monokai => const Color(0xFFF92672),
  };

  Color get string => switch (this) {
    CodeTheme.dark    => const Color(0xFFCE9178),
    CodeTheme.light   => const Color(0xFFA31515),
    CodeTheme.dracula => const Color(0xFFF1FA8C),
    CodeTheme.monokai => const Color(0xFFE6DB74),
  };

  Color get comment => switch (this) {
    CodeTheme.dark    => const Color(0xFF6A9955),
    CodeTheme.light   => const Color(0xFF008000),
    CodeTheme.dracula => const Color(0xFF6272A4),
    CodeTheme.monokai => const Color(0xFF75715E),
  };

  Color get number => switch (this) {
    CodeTheme.dark    => const Color(0xFFB5CEA8),
    CodeTheme.light   => const Color(0xFF098658),
    CodeTheme.dracula => const Color(0xFFBD93F9),
    CodeTheme.monokai => const Color(0xFFAE81FF),
  };

  Color get className => switch (this) {
    CodeTheme.dark    => const Color(0xFF4EC9B0),
    CodeTheme.light   => const Color(0xFF267F99),
    CodeTheme.dracula => const Color(0xFF8BE9FD),
    CodeTheme.monokai => const Color(0xFF66D9EF),
  };
}
