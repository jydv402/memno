import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:memno/logic/database/code_data.dart';

/// Manages code and entry database operations using Hive.
/// Coordinates generating unique codes, saving entries/links, updating titles,
/// managing favorite status, and notifying listeners of database updates.
class CodeGen extends ChangeNotifier {
  late Box<CodeData> _codeBox;
  bool _isReady = false;

  CodeGen() {
    init();
  }

  /// Initializes Hive database box and migrates legacy auto-increment keys
  /// to use the unique 6-digit code as the key.
  Future<void> init() async {
    _codeBox = await Hive.openBox<CodeData>('codeData');

    // Migration: ensure all keys are the code itself
    try {
      final keys = List.from(_codeBox.keys);
      bool migrated = false;
      for (final key in keys) {
        final value = _codeBox.get(key);
        if (value != null && key != value.code) {
          await _codeBox.delete(key);
          await _codeBox.put(value.code, value);
          migrated = true;
        }
      }
      if (migrated) {
        debugPrint(
          'Migration completed: All Hive keys are now the unique 6-digit codes.',
        );
      }
    } catch (e, st) {
      debugPrint('CodeGen Migration error: $e\n$st');
    }

    _isReady = true;
    notifyListeners();
  }

  bool get isReady => _isReady;

  List<int> get codeList {
    return _codeBox.keys.cast<int>().toList();
  }

  /// Generates unique 6-digit note page code.
  Future<int> generateCode() async {
    var rnd = Random();
    int code;
    do {
      code = 100000 + (rnd.nextInt(900000));
    } while (_codeBox.containsKey(code));

    await _codeBox.put(
      code,
      CodeData(code, [], DateTime.now().toString(), false, "Untitled"),
    );
    notifyListeners();
    return code;
  }

  /// Deletes a specific note page code and its contents.
  Future<void> clearList(int code) async {
    await _codeBox.delete(code);
    notifyListeners();
  }

  /// Returns the length of the link/entry list for a code.
  int getLinkListLength(int code) {
    return _codeBox.get(code)?.links.length ?? 0;
  }

  /// Returns the date string for a code.
  String getDateForCode(int code) {
    return _codeBox.get(code)?.date ?? "";
  }

  /// Returns the liked/favorite status for a code.
  bool getLikeForCode(int code) {
    return _codeBox.get(code)?.liked ?? false;
  }

  /// Toggles the liked/favorite status for a code.
  Future<void> toggleLike(int code) async {
    final codeData = _codeBox.get(code);
    if (codeData == null) return;
    codeData.liked = !codeData.liked;
    await codeData.save();
    notifyListeners();
  }

  /// Returns the list of links/entries for a code.
  List<String> getLinksForCode(int code) {
    return _codeBox.get(code)?.links ?? [];
  }

  /// Updates heading/title text for a code.
  Future<void> addHead(int code, String head) async {
    final codeData = _codeBox.get(code);
    if (codeData == null) return;
    codeData.head = head;
    codeData.date = DateTime.now().toString();
    await codeData.save();
    notifyListeners();
  }

  /// Returns the heading/title text for a code.
  String getHeadForCode(int code) {
    return _codeBox.get(code)?.head ?? "Untitled";
  }

  /// Adds a link/entry to a specific note code.
  Future<void> addLink(int code, String link) async {
    final codeData = _codeBox.get(code);
    if (codeData == null) return;
    codeData.links.add(link);
    codeData.date = DateTime.now().toString();
    await codeData.save();
    notifyListeners();
  }

  /// Edits a link/entry at a given index within a specific note code.
  Future<void> editLink(int code, int index, String newLink) async {
    final codeData = _codeBox.get(code);
    if (codeData == null) return;
    if (codeData.links.length > index) {
      codeData.links[index] = newLink;
      codeData.date = DateTime.now().toString();
      await codeData.save();
      notifyListeners();
    }
  }

  /// Deletes a link/entry at a given index within a specific note code.
  Future<void> deleteLink(int code, int index) async {
    final codeData = _codeBox.get(code);
    if (codeData == null) return;
    if (codeData.links.length > index) {
      codeData.links.removeAt(index);
      codeData.date = DateTime.now().toString();
      await codeData.save();
      notifyListeners();
    }
  }

  /// Clears all codes, links, and entries from the database.
  Future<void> clearAll() async {
    await _codeBox.clear();
    notifyListeners();
  }

  /// Reloads the code box from storage.
  Future<void> reloadCodeBox() async {
    _codeBox = await Hive.openBox<CodeData>('codeData');
    _isReady = true;
    notifyListeners();
  }
}
