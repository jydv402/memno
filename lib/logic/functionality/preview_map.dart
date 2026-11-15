import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:memno/logic/database/preview_data.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Manages caching, downloading, and persistence of link preview data and
/// preview images.
///
/// [PreviewMap] layers three stores: an in-memory [cache] of parsed
/// [LinkPreviewData] for instant rebuilds, the Hive box `previewsBox` of
/// [PreviewDataModel] records for cold starts, and an optional directory of
/// downloaded images for offline use (governed by the user's
/// "Save Previews Locally" preference).
class PreviewMap extends ChangeNotifier {
  /// In-memory preview records keyed by the exact link string the UI asked
  /// for. Cleared only by [deletePreviewForLink]; the entries survive
  /// [clearImageCache] because metadata remains useful without images.
  final Map<String, LinkPreviewData> cache = {};

  /// Local file paths for downloaded preview images, keyed by the same
  /// link strings as [cache]; entries are removed by [deletePreviewForLink]
  /// and cleared when the image cache is wiped; the preview metadata
  /// records are intentionally kept.
  final Map<String, String> localImagePaths = {};

  Box<PreviewDataModel>? _previewBox;
  bool _isInit = false;
  String? _previewsDirPath;

  /// Creates the provider and starts opening the `previewsBox` and the
  /// image directory in the background.
  PreviewMap() {
    _init();
  }

  /// Returns the Hive key for [link]: the link itself when it fits within
  /// Hive's 255-byte key limit, otherwise its SHA-256 digest.
  ///
  /// The 255 cap exists because Hive rejects longer keys; hashing keeps
  /// very long URLs addressable while short ones stay human-greppable.
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

  /// Saves the fetched preview [data] for [link] to Hive and the in-memory
  /// [cache], optionally downloading the image to disk when [saveLocally]
  /// is set.
  ///
  /// A failed image download downgrades gracefully: the metadata is still
  /// stored, only `localImagePath` stays null. Every failure path is caught
  /// and logged so a flaky network can never crash a rebuild.
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

  /// Downloads the image at [url] into the previews directory and returns
  /// the file path, or null on any failure.
  ///
  /// The file name is the SHA-256 digest of [link], so repeated saves of
  /// the same link overwrite their own file instead of accumulating
  /// duplicates, and the name never collides with another link's image.
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

  // Storage management operations

  /// Returns the total size of the preview image directory in megabytes as
  /// a decimal fraction (1 MB is exactly 1048576 bytes).
  ///
  /// Recomputed from disk on every call; the owning widget caches the
  /// returned future rather than calling this from build.
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

  /// Deletes everything cached for [link]: the Hive record, its local
  /// image file, and both in-memory entries.
  ///
  /// Callers should only delete a preview when no surviving note still
  /// references the link; the delete cascade in `note_operations.dart`
  /// owns that decision. Safe to call for a link with no cached data.
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

  /// Deletes every image file in the previews directory and nulls out the
  /// `localImagePath` of each Hive record so the metadata keeps working
  /// from the network while the disk space is reclaimed.
  ///
  /// In-memory [localImagePaths] is cleared with the files. Preview
  /// metadata records are intentionally kept; use [deletePreviewForLink]
  /// to remove a single link's record entirely.
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
