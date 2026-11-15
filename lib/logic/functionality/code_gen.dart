import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:memno/logic/database/code_data.dart';

/// Manages code and entry database operations using Hive.
/// Coordinates generating unique codes, saving entries/links, updating titles,
/// managing favorite status, and notifying listeners of database updates.
class CodeGen extends ChangeNotifier {
  late Box<CodeData> _codeBox;
  bool _isReady = false;

  /// Creates the controller and starts loading the `codeData` Hive box in
  /// the background; [isReady] flips once storage is available.
  CodeGen() {
    init();
  }

  /// Opens the `codeData` Hive box and migrates legacy auto-increment keys
  /// so every record is keyed by its own 6-digit [CodeData.code].
  ///
  /// The migration is best effort: a record that fails to move stays put and
  /// the failure is only logged, because losing user data during a key
  /// rewrite would be worse than a miskeyed duplicate. Notifies listeners
  /// exactly once at the end so the first frame sees the final state.
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

  /// Whether [init] finished and the box can be read and written.
  bool get isReady => _isReady;

  /// Returns every stored note code in Hive key order; the list is fresh
  /// each call, so callers may sort or filter it freely.
  List<int> get codeList {
    return _codeBox.keys.cast<int>().toList();
  }

  /// Generates a unique 6-digit note page code in the range 100000 to
  /// 999999, persists an empty record for it, and returns the code.
  ///
  /// The new note starts with no entries, the literal title `"Untitled"`,
  /// today's date, and an unlike state. The retry loop only terminates
  /// once the random code does not collide with an existing key; with
  /// 900000 candidates collisions are vanishingly rare but the loop makes
  /// the guarantee exact.
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

  /// Returns the entry count for [code]; an unknown code counts as 0.
  int getLinkListLength(int code) {
    return _codeBox.get(code)?.links.length ?? 0;
  }

  /// Returns the stored date string for [code], or the empty string when
  /// the code is unknown; the format is whatever `DateTime.toString()`
  /// produced on the device that wrote it.
  String getDateForCode(int code) {
    return _codeBox.get(code)?.date ?? "";
  }

  /// Returns the favorite state for [code]; an unknown code reads as false.
  bool getLikeForCode(int code) {
    return _codeBox.get(code)?.liked ?? false;
  }

  /// Flips the favorite state for [code] and persists it; a no-op for an
  /// unknown code.
  Future<void> toggleLike(int code) async {
    final codeData = _codeBox.get(code);
    if (codeData == null) return;
    codeData.liked = !codeData.liked;
    await codeData.save();
    notifyListeners();
  }

  /// Returns the live entry list for [code], or an empty list when the code
  /// is unknown.
  ///
  /// The returned list is the record's own backing list, so appending to it
  /// changes the record only after a save; prefer [addLink], [editLink], or
  /// [deleteLink], which save for you.
  List<String> getLinksForCode(int code) {
    return _codeBox.get(code)?.links ?? [];
  }

  /// Writes [head] as the title of [code], bumps its edit date, and
  /// persists both; a no-op for an unknown code.
  Future<void> addHead(int code, String head) async {
    final codeData = _codeBox.get(code);
    if (codeData == null) return;
    codeData.head = head;
    codeData.date = DateTime.now().toString();
    await codeData.save();
    notifyListeners();
  }

  /// Returns the title of [code], or `"Untitled"` when the code is unknown
  /// or was created without a user-supplied title.
  String getHeadForCode(int code) {
    return _codeBox.get(code)?.head ?? "Untitled";
  }

  /// Appends [link] to the entry list of [code], bumps its edit date, and
  /// persists both; a no-op for an unknown code.
  Future<void> addLink(int code, String link) async {
    final codeData = _codeBox.get(code);
    if (codeData == null) return;
    codeData.links.add(link);
    codeData.date = DateTime.now().toString();
    await codeData.save();
    notifyListeners();
  }

  /// Replaces the entry at [index] of [code] with [newLink], bumps its edit
  /// date, and persists both.
  ///
  /// [index] is 0-based and must be within the current entry list; out-of
  /// range indexes and unknown codes are silently ignored rather than
  /// throwing, so a stale UI can never crash the storage layer.
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

  /// Removes the entry at [index] of [code], bumps its edit date, and
  /// persists both.
  ///
  /// [index] is 0-based and must be within the current entry list;
  /// out-of-range indexes and unknown codes are silently ignored. This
  /// method touches only the note record; callers that also want the link's
  /// cached preview deleted must use the delete cascade in
  /// `note_operations.dart` instead.
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

  /// Removes every note record from the box and notifies listeners.
  ///
  /// Orphaned preview files and records are not touched here; use
  /// `clearAllWithPreviews` in `note_operations.dart` for the wipe-all
  /// variant that also frees preview storage.
  Future<void> clearAll() async {
    await _codeBox.clear();
    notifyListeners();
  }

  /// Re-opens the `codeData` Hive box, marks the controller ready, and
  /// notifies listeners; used after an import writes new records to disk.
  Future<void> reloadCodeBox() async {
    _codeBox = await Hive.openBox<CodeData>('codeData');
    _isReady = true;
    notifyListeners();
  }
}
