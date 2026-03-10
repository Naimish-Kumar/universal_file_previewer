import '../core/preview_config.dart';
import 'package:flutter/material.dart';

/// Pure Dart syntax tokenizer — no external packages.
/// Handles: keywords, strings, comments, numbers, class names, operators.
class SyntaxTokenizer {
  static const Map<String, List<String>> _keywords = {
    'dart': [
      'abstract', 'as', 'assert', 'async', 'await', 'base', 'break', 'case',
      'catch', 'class', 'const', 'continue', 'covariant', 'default', 'deferred',
      'do', 'dynamic', 'else', 'enum', 'export', 'extends', 'extension',
      'external', 'factory', 'false', 'final', 'finally', 'for', 'function',
      'get', 'hide', 'if', 'implements', 'import', 'in', 'interface', 'is',
      'late', 'library', 'mixin', 'new', 'null', 'of', 'on', 'operator',
      'part', 'required', 'rethrow', 'return', 'sealed', 'set', 'show',
      'static', 'super', 'switch', 'sync', 'this', 'throw', 'true', 'try',
      'typedef', 'var', 'void', 'when', 'while', 'with', 'yield',
      'String', 'int', 'double', 'bool', 'List', 'Map', 'Set', 'Future',
      'Stream', 'Widget', 'BuildContext', 'StatelessWidget', 'StatefulWidget',
    ],
    'python': [
      'and', 'as', 'assert', 'async', 'await', 'break', 'class', 'continue',
      'def', 'del', 'elif', 'else', 'except', 'False', 'finally', 'for',
      'from', 'global', 'if', 'import', 'in', 'is', 'lambda', 'None',
      'nonlocal', 'not', 'or', 'pass', 'raise', 'return', 'True', 'try',
      'while', 'with', 'yield', 'int', 'str', 'list', 'dict', 'set',
      'tuple', 'bool', 'float', 'print', 'len', 'range', 'type', 'self',
    ],
    'javascript': [
      'async', 'await', 'break', 'case', 'catch', 'class', 'const',
      'continue', 'debugger', 'default', 'delete', 'do', 'else', 'export',
      'extends', 'false', 'finally', 'for', 'function', 'if', 'import',
      'in', 'instanceof', 'let', 'new', 'null', 'of', 'return', 'static',
      'super', 'switch', 'this', 'throw', 'true', 'try', 'typeof', 'undefined',
      'var', 'void', 'while', 'with', 'yield', 'console', 'Promise',
    ],
    'kotlin': [
      'abstract', 'actual', 'annotation', 'as', 'break', 'by', 'catch',
      'class', 'companion', 'const', 'constructor', 'continue', 'crossinline',
      'data', 'do', 'dynamic', 'else', 'enum', 'expect', 'external', 'false',
      'final', 'finally', 'for', 'fun', 'get', 'if', 'import', 'in',
      'infix', 'init', 'inline', 'inner', 'interface', 'internal', 'is',
      'lateinit', 'noinline', 'null', 'object', 'open', 'operator', 'out',
      'override', 'package', 'private', 'protected', 'public', 'reified',
      'return', 'sealed', 'set', 'super', 'suspend', 'tailrec', 'this',
      'throw', 'true', 'try', 'typealias', 'typeof', 'val', 'var', 'vararg',
      'when', 'where', 'while', 'String', 'Int', 'Long', 'Double', 'Boolean',
      'List', 'Map', 'Set', 'Any', 'Unit', 'Nothing',
    ],
    'java': [
      'abstract', 'assert', 'boolean', 'break', 'byte', 'case', 'catch',
      'char', 'class', 'const', 'continue', 'default', 'do', 'double',
      'else', 'enum', 'extends', 'false', 'final', 'finally', 'float',
      'for', 'goto', 'if', 'implements', 'import', 'instanceof', 'int',
      'interface', 'long', 'native', 'new', 'null', 'package', 'private',
      'protected', 'public', 'return', 'short', 'static', 'strictfp',
      'super', 'switch', 'synchronized', 'this', 'throw', 'throws',
      'transient', 'true', 'try', 'void', 'volatile', 'while', 'String',
    ],
  };

  // Language detection from extension
  static String _languageFromExt(String ext) {
    return switch (ext.toLowerCase()) {
      'dart'             => 'dart',
      'py'               => 'python',
      'js' || 'ts' || 'jsx' || 'tsx' => 'javascript',
      'kt' || 'kts'     => 'kotlin',
      'java'             => 'java',
      _                  => 'generic',
    };
  }

  /// Tokenize [code] for syntax highlighting.
  /// [ext] is the file extension (e.g. 'dart', 'py', 'js').
  static List<TextSpan> tokenize(
    String code,
    String ext,
    CodeTheme theme,
  ) {
    final language = _languageFromExt(ext);
    final keywords = _keywords[language] ?? [];
    final spans = <TextSpan>[];

    // Tokenize using regex
    final pattern = RegExp(
      r'(//[^\n]*)'           // Single-line comment //
      r'|(#[^\n]*)'           // Python/shell comment #
      r'|(/\*[\s\S]*?\*/)'   // Block comment /* */
      r'|("(?:[^"\\]|\\.)*")' // Double-quoted string
      r"|('(?:[^'\\]|\\.)*')" // Single-quoted string
      r'|(`(?:[^`\\]|\\.)*`)' // Backtick string (JS template)
      r'|(\b\d+\.?\d*\b)'    // Numbers
      r'|(\b[A-Z][a-zA-Z0-9_]*\b)' // Class names (start with uppercase)
      r'|(\b[a-zA-Z_]\w*\b)', // Identifiers / keywords
    );

    int last = 0;

    for (final match in pattern.allMatches(code)) {
      // Plain (non-matched) text
      if (match.start > last) {
        spans.add(TextSpan(
          text: code.substring(last, match.start),
          style: TextStyle(color: theme.defaultText),
        ));
      }

      final word = match.group(0)!;
      Color color;

      if (match.group(1) != null || match.group(2) != null || match.group(3) != null) {
        // Comment
        color = theme.comment;
      } else if (match.group(4) != null || match.group(5) != null || match.group(6) != null) {
        // String
        color = theme.string;
      } else if (match.group(7) != null) {
        // Number
        color = theme.number;
      } else if (match.group(8) != null) {
        // Class name
        color = theme.className;
      } else if (keywords.contains(word)) {
        // Keyword
        color = theme.keyword;
      } else {
        color = theme.defaultText;
      }

      spans.add(TextSpan(
        text: word,
        style: TextStyle(color: color),
      ));

      last = match.end;
    }

    // Remaining text
    if (last < code.length) {
      spans.add(TextSpan(
        text: code.substring(last),
        style: TextStyle(color: theme.defaultText),
      ));
    }

    return spans;
  }
}
