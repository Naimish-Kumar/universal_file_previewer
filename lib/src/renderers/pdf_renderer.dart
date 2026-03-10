import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/preview_config.dart';
import '../core/preview_controller.dart';
import '../platform/platform_channel.dart';

/// Renders PDF files page-by-page using the native platform channel.
/// Android uses PdfRenderer API. iOS uses PDFKit / CGPDFDocument.
class PdfRenderer extends StatefulWidget {
  final File file;
  final PreviewConfig config;
  final PreviewController? controller;

  const PdfRenderer({
    super.key,
    required this.file,
    required this.config,
    this.controller,
  });

  @override
  State<PdfRenderer> createState() => _PdfRendererState();
}

class _PdfRendererState extends State<PdfRenderer> {
  int _totalPages = 0;
  int _currentPage = 0;
  final Map<int, Uint8List> _pageCache = {};
  bool _loading = true;
  String? _error;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _init();
  }

  Future<void> _init() async {
    try {
      final count =
          await FilePreviewerChannel.getPdfPageCount(widget.file.path);
      if (mounted) {
        setState(() {
          _totalPages = count;
          _loading = false;
        });
        widget.controller?.setTotalPages(count);
        widget.controller?.setLoading(false);
        // Preload first page
        _loadPage(0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
        widget.controller?.setError(e.toString());
      }
    }
  }

  Future<void> _loadPage(int page) async {
    if (_pageCache.containsKey(page)) return;
    final width =
        (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio)
            .toInt();
    try {
      final bytes = await FilePreviewerChannel.renderPdfPage(
        path: widget.file.path,
        page: page,
        width: width,
      );
      if (bytes != null && mounted) {
        setState(() => _pageCache[page] = bytes);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
            const SizedBox(height: 12),
            Text('Failed to load PDF', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Page view
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _totalPages,
            onPageChanged: (page) {
              setState(() => _currentPage = page);
              widget.controller?.goToPage(page);
              _loadPage(page);
              if (page + 1 < _totalPages) _loadPage(page + 1);
            },
            itemBuilder: (ctx, page) {
              final bytes = _pageCache[page];
              if (bytes == null) {
                _loadPage(page);
                return const Center(child: CircularProgressIndicator());
              }
              return InteractiveViewer(
                child: Center(
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              );
            },
          ),
        ),

        // Page indicator bar
        if (_totalPages > 1)
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: _currentPage > 0
                      ? () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut)
                      : null,
                ),
                Text(
                  'Page ${_currentPage + 1} of $_totalPages',
                  style: const TextStyle(color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: _currentPage < _totalPages - 1
                      ? () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
