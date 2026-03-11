import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../core/preview_config.dart';
import '../parsers/markdown_parser.dart';
import '../parsers/syntax_tokenizer.dart';

// ─────────────────────────────────────────────────────────
// Plain Text Renderer
// ─────────────────────────────────────────────────────────

class TextRenderer extends StatelessWidget {
  final File file;
  final PreviewConfig config;

  const TextRenderer({super.key, required this.file, required this.config});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _loadText(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            snap.data ?? '',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        );
      },
    );
  }

  Future<String> _loadText() async {
    final stat = await file.stat();
    if (stat.size > config.maxTextFileSizeBytes) {
      final raf = await file.open();
      final bytes = await raf.read(config.maxTextFileSizeBytes);
      await raf.close();
      return '${utf8.decode(bytes, allowMalformed: true)}\n\n[File truncated — showing first ${config.maxTextFileSizeBytes ~/ 1024} KB]';
    }
    return file.readAsString();
  }
}

// ─────────────────────────────────────────────────────────
// Markdown Renderer
// ─────────────────────────────────────────────────────────

class MarkdownRenderer extends StatefulWidget {
  final File file;
  final PreviewConfig config;

  const MarkdownRenderer({super.key, required this.file, required this.config});

  @override
  State<MarkdownRenderer> createState() => _MarkdownRendererState();
}

class _MarkdownRendererState extends State<MarkdownRenderer> {
  List<MarkdownNode>? _nodes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final text = await widget.file.readAsString();
    final nodes = MarkdownParser.parse(text);
    if (mounted) {
      setState(() => _nodes = nodes);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_nodes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _nodes!.length,
      itemBuilder: (ctx, i) => _buildNode(_nodes![i], context),
    );
  }

  Widget _buildNode(MarkdownNode node, BuildContext ctx) {
    final theme = Theme.of(ctx);
    switch (node.type) {
      case NodeType.heading:
        final styles = [
          theme.textTheme.headlineLarge,
          theme.textTheme.headlineMedium,
          theme.textTheme.headlineSmall,
        ];
        return Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(node.text, style: styles[node.level - 1]),
        );

      case NodeType.paragraph:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: _buildInline(node.text, theme),
        );

      case NodeType.bullet:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 4, right: 8),
                child: Text('•', style: TextStyle(fontSize: 16)),
              ),
              Expanded(child: _buildInline(node.text, theme)),
            ],
          ),
        );

      case NodeType.numbered:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _buildInline(node.text, theme),
        );

      case NodeType.blockquote:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: BoxDecoration(
            border: const Border(
              left: BorderSide(color: Colors.blue, width: 4),
            ),
            color: Colors.blue.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(node.text,
              style: const TextStyle(fontStyle: FontStyle.italic)),
        );

      case NodeType.codeBlock:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(6),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              node.text,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Color(0xFFD4D4D4),
              ),
            ),
          ),
        );

      case NodeType.divider:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(),
        );

      case NodeType.spacer:
        return const SizedBox(height: 8);
    }
  }

  Widget _buildInline(String text, ThemeData theme) {
    final segments = MarkdownParser.parseInline(text);
    if (segments.every((s) => s.type == InlineType.plain)) {
      return SelectableText(text);
    }
    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium,
        children: segments.map((s) {
          switch (s.type) {
            case InlineType.bold:
              return TextSpan(
                  text: s.text,
                  style: const TextStyle(fontWeight: FontWeight.bold));
            case InlineType.italic:
              return TextSpan(
                  text: s.text,
                  style: const TextStyle(fontStyle: FontStyle.italic));
            case InlineType.code:
              return TextSpan(
                text: s.text,
                style: TextStyle(
                  fontFamily: 'monospace',
                  backgroundColor: Colors.grey[200],
                  color: Colors.red[700],
                ),
              );
            case InlineType.link:
              return TextSpan(
                text: s.text,
                style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline),
              );
            default:
              return TextSpan(text: s.text);
          }
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// JSON Renderer (tree view)
// ─────────────────────────────────────────────────────────

class JsonRenderer extends StatefulWidget {
  final File file;
  final PreviewConfig config;

  const JsonRenderer({super.key, required this.file, required this.config});

  @override
  State<JsonRenderer> createState() => _JsonRendererState();
}

class _JsonRendererState extends State<JsonRenderer> {
  dynamic _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final text = await widget.file.readAsString();
      final data = jsonDecode(text);
      if (mounted) {
        setState(() => _data = data);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text('Invalid JSON: $_error'));
    }
    if (_data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _JsonNode(value: _data, depth: 0),
    );
  }
}

class _JsonNode extends StatefulWidget {
  final dynamic value;
  final int depth;
  final String? keyName;

  const _JsonNode({required this.value, required this.depth, this.keyName});

  @override
  State<_JsonNode> createState() => _JsonNodeState();
}

class _JsonNodeState extends State<_JsonNode> {
  bool _expanded = true;

  static const _colors = [
    Color(0xFF569CD6),
    Color(0xFF4EC9B0),
    Color(0xFF9CDCFE),
    Color(0xFFDCDCAA),
  ];

  Color get _depthColor => _colors[widget.depth % _colors.length];

  @override
  Widget build(BuildContext context) {
    final val = widget.value;

    if (val is Map) {
      return _buildMap(val);
    }
    if (val is List) {
      return _buildList(val);
    }
    return _buildPrimitive(val);
  }

  Widget _buildMap(Map map) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(children: [
            if (widget.keyName != null) ...[
              Text('"${widget.keyName}": ',
                  style: TextStyle(color: _depthColor)),
            ],
            Icon(_expanded ? Icons.expand_more : Icons.chevron_right,
                size: 16, color: Colors.grey),
            Text('{${_expanded ? '' : '${map.length} keys...}'}',
                style: const TextStyle(color: Colors.grey)),
          ]),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: map.entries.map((e) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _JsonNode(
                  value: e.value,
                  depth: widget.depth + 1,
                  keyName: e.key.toString(),
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildList(List list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(children: [
            if (widget.keyName != null)
              Text('"${widget.keyName}": ',
                  style: TextStyle(color: _depthColor)),
            Icon(_expanded ? Icons.expand_more : Icons.chevron_right,
                size: 16, color: Colors.grey),
            Text('[${_expanded ? '' : '${list.length} items...]'}',
                style: const TextStyle(color: Colors.grey)),
          ]),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: list.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _JsonNode(
                  value: e.value,
                  depth: widget.depth + 1,
                  keyName: e.key.toString(),
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildPrimitive(dynamic val) {
    Color valColor;
    String display;
    if (val == null) {
      valColor = Colors.grey;
      display = 'null';
    } else if (val is bool) {
      valColor = const Color(0xFF569CD6);
      display = val.toString();
    } else if (val is num) {
      valColor = const Color(0xFFB5CEA8);
      display = val.toString();
    } else {
      valColor = const Color(0xFFCE9178);
      display = '"$val"';
    }

    return RichText(
      text: TextSpan(children: [
        if (widget.keyName != null)
          TextSpan(
              text: '"${widget.keyName}": ',
              style: TextStyle(color: _depthColor)),
        TextSpan(text: display, style: TextStyle(color: valColor)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────
// CSV Renderer
// ─────────────────────────────────────────────────────────

class CsvRenderer extends StatefulWidget {
  final File file;
  final PreviewConfig config;

  const CsvRenderer({super.key, required this.file, required this.config});

  @override
  State<CsvRenderer> createState() => _CsvRendererState();
}

class _CsvRendererState extends State<CsvRenderer> {
  List<List<String>>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final text = await widget.file.readAsString();
      final rows = text.trim().split('\n').map((line) {
        // Basic CSV parsing — handles quoted fields
        return _parseCsvLine(line);
      }).toList();
      if (mounted) {
        setState(() => _rows = rows);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    var current = '';
    var inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        fields.add(current.trim());
        current = '';
      } else {
        current += ch;
      }
    }
    fields.add(current.trim());
    return fields;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text('CSV Error: $_error'));
    }
    if (_rows == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final headers = _rows!.isNotEmpty ? _rows![0] : [];
    final dataRows = _rows!.length > 1 ? _rows!.sublist(1) : [];

    return Column(
      children: [
        // Stats bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[100],
          child: Row(children: [
            const Icon(Icons.table_chart, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text('${dataRows.length} rows × ${headers.length} columns',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
        ),
        // Table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
                border: TableBorder.all(color: Colors.grey[300]!, width: 0.5),
                columns: headers
                    .map((h) => DataColumn(
                          label: Text(h,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ))
                    .toList(),
                rows: dataRows
                    .take(500) // cap at 500 for performance
                    .map((row) => DataRow(
                          cells: List.generate(
                            headers.length,
                            (i) => DataCell(Text(
                                i < row.length ? row[i] : '',
                                style: const TextStyle(fontSize: 13))),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
        if (dataRows.length > 500)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text('Showing 500 of ${dataRows.length} rows',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Code Renderer (syntax highlighted)
// ─────────────────────────────────────────────────────────

class CodeRenderer extends StatefulWidget {
  final File file;
  final PreviewConfig config;

  const CodeRenderer({super.key, required this.file, required this.config});

  @override
  State<CodeRenderer> createState() => _CodeRendererState();
}

class _CodeRendererState extends State<CodeRenderer> {
  String? _code;
  List<TextSpan>? _spans;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final code = await widget.file.readAsString();
      final ext = widget.file.path.split('.').last.toLowerCase();
      final spans =
          SyntaxTokenizer.tokenize(code, ext, widget.config.codeTheme);
      if (mounted) {
        setState(() {
          _code = code;
          _spans = spans;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _code = 'Error loading file: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.config.codeTheme;

    if (_spans == null && _code == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: theme.background,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _spans != null
              ? SelectableText.rich(
                  TextSpan(
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.6,
                        color: theme.defaultText),
                    children: _spans,
                  ),
                )
              : Text(_code ?? '',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: theme.defaultText)),
        ),
      ),
    );
  }
}
