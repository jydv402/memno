import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:memno/logic/database/preview_data.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Manages caching, downloading, and persistence of link preview data and preview images.
class PreviewMap extends ChangeNotifier {
  final Map<String, LinkPreviewData> cache = {};
  final Map<String, String> localImagePaths = {};

  Box<PreviewDataModel>? _previewBox;
  bool _isInit = false;
  String? _previewsDirPath;

  PreviewMap() {
    _init();
  }

  /// Returns Hive-safe key for the given link.
  String _hiveKey(String link) {
    if (link.length <= 255) return link;
    return sha256.convert(utf8.encode(link)).toString();
  }

  Future<void> _init() async {
    try {
      if (!Hive.isBoxOpen('previewsBox')) {
        _previewBox = await Hive.openBox<PreviewDataModel>('previewsBox');
      } else {
        _previewBox = Hive.box<PreviewDataModel>('previewsBox');
      }

      final appDocDir = await getApplicationDocumentsDirectory();
      _previewsDirPath = p.join(appDocDir.path, 'previews');
      final previewsDir = Directory(_previewsDirPath!);
      if (!await previewsDir.exists()) {
        await previewsDir.create(recursive: true);
      }

      _isInit = true;
    } catch (e, st) {
      debugPrint('PreviewMap init error: $e\n$st');
      _previewBox = null;
    }
    notifyListeners();
  }

  /// Saves preview data and caches image locally if enabled.
  Future<void> savePreview({
    required String link,
    required LinkPreviewData data,
    bool saveLocally = true,
  }) async {
    try {
      if (!_isInit) await _init();
      if (_previewBox == null) return;

      String? localPath;

      if (saveLocally && data.image?.url != null) {
        localPath = await _downloadAndSaveImage(link, data.image!.url);
      }

      final model = PreviewDataModel(
        title: data.title,
        description: data.description,
        link: data.link,
        image: data.image?.url,
        imageHeight: data.image?.height,
        imageWidth: data.image?.width,
        localImagePath: localPath,
      );

      await _previewBox!.put(_hiveKey(link), model);
      cache[link] = data;
      if (localPath != null) {
        localImagePaths[link] = localPath;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('savePreview error: $e');
    }
  }

  Future<String?> _downloadAndSaveImage(String link, String url) async {
    try {
      if (_previewsDirPath == null) await _init();
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final fileName = '${sha256.convert(utf8.encode(link))}.jpg';
        final filePath = p.join(_previewsDirPath!, fileName);
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      }
    } catch (e) {
      debugPrint('Error downloading image: $e');
    }
    return null;
  }

  /// Loads a preview synchronously from Hive cache.
  LinkPreviewData? loadPreviewSync(String link, {bool saveLocally = true}) {
    try {
      if (_previewBox != null && _previewBox!.isOpen) {
        final model = _previewBox!.get(_hiveKey(link));
        if (model == null) return null;

        // If we should be saving locally but the image is missing, return null to force re-fetch
        if (saveLocally &&
            model.image != null &&
            model.localImagePath == null) {
          return null;
        }

        if (model.localImagePath != null) {
          localImagePaths[link] = model.localImagePath!;
        }

        final preview = LinkPreviewData(
          title: model.title,
          description: model.description,
          link: model.link ?? link,
          image: model.image != null
              ? ImagePreviewData(
                  url: model.image!,
                  height: model.imageHeight ?? 0,
                  width: model.imageWidth ?? 0,
                )
              : null,
        );
        cache[link] = preview;
        return preview;
      }
    } catch (e) {
      debugPrint('loadPreviewSync error: $e');
    }
    return null;
  }

  /// Loads a preview asynchronously, initializing database if needed.
  Future<LinkPreviewData?> loadPreview(
    String link, {
    bool saveLocally = true,
  }) async {
    try {
      if (!_isInit) await _init();
      return loadPreviewSync(link, saveLocally: saveLocally);
    } catch (e) {
      debugPrint('loadPreview error: $e');
      return null;
    }
  }

  // Storage management operations
  Future<double> getTotalCacheSizeMB() async {
    try {
      if (_previewsDirPath == null) await _init();
      final dir = Directory(_previewsDirPath!);
      if (!await dir.exists()) return 0.0;

      int totalSize = 0;
      await for (var file in dir.list(recursive: true)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      return totalSize / (1024 * 1024);
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      return 0.0;
    }
  }

  Future<void> deletePreviewForLink(String link) async {
    try {
      if (!_isInit) await _init();
      final key = _hiveKey(link);

      if (_previewBox != null && _previewBox!.isOpen) {
        final model = _previewBox!.get(key);
        if (model != null && model.localImagePath != null) {
          final file = File(model.localImagePath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
        await _previewBox!.delete(key);
      }
      cache.remove(link);
      localImagePaths.remove(link);
      notifyListeners();
    } catch (e) {
      debugPrint('deletePreviewForLink error: $e');
    }
  }

  Future<void> clearImageCache() async {
    try {
      if (_previewsDirPath == null) await _init();
      final dir = Directory(_previewsDirPath!);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
      }

      // Updates Hive models to remove local paths
      if (_previewBox != null && _previewBox!.isOpen) {
        for (var key in _previewBox!.keys) {
          final model = _previewBox!.get(key);
          if (model != null && model.localImagePath != null) {
            final updatedModel = PreviewDataModel(
              title: model.title,
              description: model.description,
              link: model.link,
              image: model.image,
              imageHeight: model.imageHeight,
              imageWidth: model.imageWidth,
              localImagePath: null,
            );
            await _previewBox!.put(key, updatedModel);
          }
        }
      }

      localImagePaths.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }
  }
}
