import 'package:flutter/foundation.dart';

/// Controller to programmatically control the file preview.
class PreviewController extends ChangeNotifier {
  int _currentPage = 0;
  int _totalPages = 1;
  double _zoomLevel = 1.0;
  bool _isLoading = true;
  String? _error;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  double get zoomLevel => _zoomLevel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasMultiplePages => _totalPages > 1;

  /// Jump to a specific page (zero-indexed).
  void goToPage(int page) {
    if (page < 0 || page >= _totalPages) return;
    _currentPage = page;
    notifyListeners();
  }

  void nextPage() => goToPage(_currentPage + 1);
  void previousPage() => goToPage(_currentPage - 1);

  void setZoom(double level) {
    _zoomLevel = level.clamp(0.5, 5.0);
    notifyListeners();
  }

  void zoomIn() => setZoom(_zoomLevel + 0.25);
  void zoomOut() => setZoom(_zoomLevel - 0.25);
  void resetZoom() => setZoom(1.0);

  // Internal setters used by renderers
  void setTotalPages(int pages) {
    _totalPages = pages;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _currentPage = 0;
    _totalPages = 1;
    _zoomLevel = 1.0;
    _isLoading = true;
    _error = null;
    notifyListeners();
  }
}
