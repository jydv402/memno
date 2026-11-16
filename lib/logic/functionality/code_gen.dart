import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:memno/logic/database/code_data.dart';
import 'package:memno/logic/database/legacy_code_data_migration.dart';
import 'package:memno/logic/sync/sync_store.dart';

/// Manages code and entry database operations using Hive.
/// Coordinates generating unique codes, saving entries/links, updating titles,
/// managing favorite status, and notifying listeners of database updates.
///
/// The controller also maintains the metadata sync needs: every mutation
/// stamps the record's UTC `updatedAt`, this device's `updatedBy`, and a
/// monotonically rising `rev`, and records the touched code in the dirty set.
/// Deletions convert records to tombstones instead of erasing them so the
/// note can be marked deleted on other devices by sync, while `codeList`
/// hides tombstones so the UI behaves exactly as it did with hard deletes.
class CodeGen extends ChangeNotifier {
  late Box<CodeData> _codeBox;
  bool _isReady = false;
  Future<void>? _initFuture;
  final SyncStore _syncStore = SyncStore();
  String _deviceId = '';
  final Set<int> _dirtyCodes = <int>{};

  /// Creates the controller and starts loading the `codeData` Hive box in
  /// the background; [isReady] flips once storage is available.
  CodeGen() {
    init();
  }

  /// Opens the `codeData` Hive box, migrates legacy auto-increment keys
  /// so every record is keyed by its own 6-digit [CodeData.code], and
  /// backfills sync metadata onto records written before the sync fields
  /// existed.
  ///
  /// Concurrent and repeated calls share one run: the work is started once
  /// and every caller awaits the same completion. The key migration is best
  /// effort: a record that fails to move stays put and the failure is only
  /// logged, because losing user data during a key rewrite would be worse
  /// than a miskeyed duplicate. Notifies listeners exactly once at the end
  /// so the first frame sees the final state.
  Future<void> init() {
    return _initFuture ??= _openAndPrepare();
  }

  /// Performs the one-time work of [init]; never called twice.
  Future<void> _openAndPrepare() async {
    // One-time legacy migration: records written by the abandoned August
    // 2026 sync prototype store a String id at field 5, which the strict
    // generated adapter cannot read — the tolerant pass rewrites such
    // frames before any typed open. Flag-guarded in the sync box, so it
    // runs at most once per device.
    try {
      if (await _syncStore.value(legacyMigrationDoneKey) == null) {
        await migrateLegacyCodeData();
        await _syncStore.setValue(legacyMigrationDoneKey, '1');
      }
    } catch (e, st) {
      debugPrint('Legacy codeData migration failed: $e\n$st');
    }

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

    try {
      _deviceId = await _syncStore.deviceId();
      await _backfillRecords();
    } catch (e, st) {
      debugPrint('CodeGen sync backfill error: $e\n$st');
    }

    _isReady = true;
    notifyListeners();
  }

  /// Stamps sync metadata onto records written before the sync fields
  /// existed: [CodeData.updatedAt] is derived from the legacy local-time
  /// [CodeData.date] string when it parses, else the Unix epoch, and
  /// [CodeData.updatedBy] is set to this device.
  ///
  /// The pass is idempotent — records that already carry a timestamp are
  /// skipped — so it can run on every open and after every import without
  /// cost.
  Future<void> _backfillRecords() async {
    for (final record in _codeBox.values) {
      if (record.updatedAt != null) continue;
      final parsed = DateTime.tryParse(record.date);
      record.updatedAt = (parsed ?? DateTime.fromMillisecondsSinceEpoch(0))
          .toUtc()
          .millisecondsSinceEpoch;
      record.updatedBy = _deviceId;
      record.rev ??= 0;
      await record.save();
    }
  }

  /// Whether [init] finished and the box can be read and written.
  bool get isReady => _isReady;

  /// Stable identifier of this device (see `SyncStore.deviceId`), stamped
  /// onto every record this device edits and used as the merge tie-breaker;
  /// empty only until [init] finishes.
  String get deviceId => _deviceId;

  /// The codes of records edited locally since the last acknowledgement, as
  /// an unmodifiable view; empty on a fresh launch until the user edits
  /// something.
  Set<int> get dirtyCodes => Set<int>.unmodifiable(_dirtyCodes);

  /// Removes [codes] — every tracked code when omitted — from the dirty
  /// set, acknowledging that they have been pushed to the remote store.
  void clearDirtyCodes([Iterable<int>? codes]) {
    if (codes == null) {
      _dirtyCodes.clear();
    } else {
      _dirtyCodes.removeAll(codes);
    }
  }

  /// Returns every record in the box, tombstones included, as a fresh list
  /// for serialization into the sync document; live records and tombstones
  /// are distinguishable via [CodeData.isDeleted].
  List<CodeData> exportRecords() => _codeBox.values.toList();

  /// Applies records already merged from the remote store into the box,
  /// keyed by [CodeData.code], and notifies listeners.
  ///
  /// Records are written as received — the caller has already decided the
  /// winners — so no timestamps are stamped and the codes are not added to
  /// [dirtyCodes]: remotely applied state is not a local edit.
  Future<void> applyRemoteRecords(List<CodeData> records) async {
    for (final record in records) {
      await _codeBox.put(record.code, record);
    }
    notifyListeners();
  }

  /// Stamps [record] as freshly edited by this device and marks its code
  /// dirty for the next sync push: UTC epoch-millisecond
  /// [CodeData.updatedAt], this device's [CodeData.updatedBy], and an
  /// incremented [CodeData.revision].
  void _stamp(CodeData record) {
    record.updatedAt = DateTime.now().toUtc().millisecondsSinceEpoch;
    record.updatedBy = _deviceId;
    record.rev = record.revision + 1;
    _dirtyCodes.add(record.code);
  }

  /// Returns the codes of live (non-tombstoned) notes in Hive key order;
  /// the list is fresh each call, so callers may sort or filter it freely.
  ///
  /// Tombstones are excluded here once, so every consumer — list filters,
  /// search, preview reference checks — automatically treats a deleted
  /// note as gone without any per-call-site filtering.
  List<int> get codeList {
    return [
      for (final record in _codeBox.values)
        if (!record.isDeleted) record.code,
    ];
  }

  /// Generates a unique 6-digit note page code in the range 100000 to
  /// 999999, persists an empty record for it, and returns the code.
  ///
  /// The new note starts with no entries, the literal title `"Untitled"`,
  /// today's date, and an unlike state. The retry loop only terminates
  /// once the random code does not collide with an existing key — tombstone
  /// keys included, so a deleted note's code is never reused; with 900000
  /// candidates collisions are vanishingly rare but the loop makes the
  /// guarantee exact.
  Future<int> generateCode() async {
    var rnd = Random();
    int code;
    do {
      code = 100000 + (rnd.nextInt(900000));
    } while (_codeBox.containsKey(code));

    final record = CodeData(
      code,
      [],
      DateTime.now().toString(),
      false,
      "Untitled",
    );
    _stamp(record);
    await _codeBox.put(code, record);
    notifyListeners();
    return code;
  }

  /// Marks note page [code] as deleted instead of erasing it: the record
  /// becomes a tombstone with fresh sync metadata and content preserved
  /// until tombstone collection, so the delete propagates to other devices
  /// and outranks their older edits.
  ///
  /// Tombstoned records stay in the box but disappear from [codeList], so
  /// the UI treats them exactly like the hard deletes this method used to
  /// perform. A no-op for an unknown or already-deleted code.
  Future<void> clearList(int code) async {
    final record = _codeBox.get(code);
    if (record == null || record.isDeleted) return;
    _stamp(record);
    record.deleted = true;
    await record.save();
    notifyListeners();
  }

  /// Returns the entry count for [code]; an unknown or deleted code counts
  /// as 0.
  int getLinkListLength(int code) {
    final record = _codeBox.get(code);
    if (record == null || record.isDeleted) return 0;
    return record.links.length;
  }

  /// Returns the stored date string for [code], or the empty string when
  /// the code is unknown or deleted; the format is whatever
  /// `DateTime.toString()` produced on the device that wrote it.
  String getDateForCode(int code) {
    final record = _codeBox.get(code);
    if (record == null || record.isDeleted) return "";
    return record.date;
  }

  /// Returns the favorite state for [code]; an unknown or deleted code
  /// reads as false.
  bool getLikeForCode(int code) {
    final record = _codeBox.get(code);
    if (record == null || record.isDeleted) return false;
    return record.liked;
  }

  /// Flips the favorite state for [code] and persists it; a no-op for an
  /// unknown code.
  Future<void> toggleLike(int code) async {
    final codeData = _codeBox.get(code);
    if (codeData == null) return;
    _stamp(codeData);
    codeData.liked = !codeData.liked;
    await codeData.save();
    notifyListeners();
  }

  /// Returns the live entry list for [code], or an empty list when the code
  /// is unknown or deleted.
  ///
  /// The returned list is the record's own backing list, so appending to it
  /// changes the record only after a save; prefer [addLink], [editLink], or
  /// [deleteLink], which save for you.
  List<String> getLinksForCode(int code) {
    final record = _codeBox.get(code);
    if (record == null || record.isDeleted) return [];
    return record.links;
  }

  /// Writes [head] as the title of [code], bumps its edit date, and
  /// persists both; a no-op for an unknown code.
  Future<void> addHead(int code, String head) async {
    final codeData = _codeBox.get(code);
    if (codeData == null) return;
    _stamp(codeData);
    codeData.head = head;
    codeData.date = DateTime.now().toString();
    await codeData.save();
    notifyListeners();
  }

  /// Returns the title of [code], or `"Untitled"` when the code is unknown,
  /// deleted, or was created without a user-supplied title.
  String getHeadForCode(int code) {
    final record = _codeBox.get(code);
    if (record == null || record.isDeleted) return "Untitled";
    return record.head;
  }

  /// Appends [link] to the entry list of [code], bumps its edit date, and
  /// persists both; a no-op for an unknown code.
  Future<void> addLink(int code, String link) async {
    final codeData = _codeBox.get(code);
    if (codeData == null) return;
    _stamp(codeData);
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
      _stamp(codeData);
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
      _stamp(codeData);
      codeData.links.removeAt(index);
      codeData.date = DateTime.now().toString();
      await codeData.save();
      notifyListeners();
    }
  }

  /// Tombstones every record in the box (see [clearList]) and notifies
  /// listeners; the records stay on disk so the deletions propagate
  /// through sync as a single pushed document.
  ///
  /// Orphaned preview files and records are not touched here; use
  /// `clearAllWithPreviews` in `note_operations.dart` for the wipe-all
  /// variant that also frees preview storage.
  Future<void> clearAll() async {
    for (final record in _codeBox.values) {
      if (record.isDeleted) continue;
      _stamp(record);
      record.deleted = true;
      await record.save();
    }
    notifyListeners();
  }

  /// Re-opens the `codeData` Hive box, backfills any records that still
  /// lack sync metadata (for example records just restored from a schema
  /// version 1 backup import), marks the controller ready, and notifies
  /// listeners; used after an import writes new records to disk.
  Future<void> reloadCodeBox() async {
    _codeBox = await Hive.openBox<CodeData>('codeData');
    try {
      await _backfillRecords();
    } catch (e, st) {
      debugPrint('CodeGen sync backfill error: $e\n$st');
    }
    _isReady = true;
    notifyListeners();
  }
}
