import 'dart:io';
import 'package:flutter/material.dart';
import 'package:native_pdf_renderer/native_pdf_renderer.dart' as renderer;
import '../core/preview_config.dart';
import '../core/preview_controller.dart';

/// Renders PDF files page-by-page using the native_pdf_renderer plugin.
/// Supports Android, iOS, macOS, Windows, and Web.
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
  renderer.PdfDocument? _document;
  int _totalPages = 0;
  int _currentPage = 0;
  final Map<int, renderer.PdfPageImage> _pageCache = {};
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
      final doc = await renderer.PdfDocument.openFile(widget.file.path);
      if (mounted) {
        setState(() {
          _document = doc;
          _totalPages = doc.pagesCount;
          _loading = false;
        });
        widget.controller?.setTotalPages(doc.pagesCount);
        widget.controller?.setLoading(false);
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

  Future<renderer.PdfPageImage?> _loadPage(int pageIndex) async {
    if (_pageCache.containsKey(pageIndex)) return _pageCache[pageIndex];
    if (_document == null) return null;

    try {
      final page = await _document!.getPage(pageIndex + 1); // 1-indexed
      final pageImage = await page.render(
        width: page.width * 2, // higher quality
        height: page.height * 2,
        format: renderer.PdfPageFormat.JPEG,
      );
      await page.close();
      if (pageImage != null && mounted) {
        setState(() => _pageCache[pageIndex] = pageImage);
      }
      return pageImage;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _document?.close();
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
            Text(_error!, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
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
            },
            itemBuilder: (ctx, page) {
              return FutureBuilder<renderer.PdfPageImage?>(
                future: _loadPage(page),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: Center(
                        child: Image.memory(
                          snapshot.data!.bytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error loading page: ${snapshot.error}'));
                  }
                  return const Center(child: CircularProgressIndicator());
                },
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
