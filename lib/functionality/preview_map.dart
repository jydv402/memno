import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' show PreviewData;

class PreviewMap extends ChangeNotifier {
  Map<String, PreviewData> _cache = {};

  Map<String, PreviewData> get cache => _cache;

  void storePreview(String url, PreviewData previewData) {
    if (!_cache.containsKey(url)) {
      _cache = {..._cache, url: previewData};
    }
    notifyListeners();
  }
}
