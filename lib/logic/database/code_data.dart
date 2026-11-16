import 'package:hive/hive.dart';

part 'code_data.g.dart';

/// One persisted note page, stored in the Hive box `codeData` keyed by its
/// own [code].
///
/// A note page is a titled collection of free-form entry strings; an entry
/// usually contains a URL but may be plain text. The generated adapter in
/// `code_data.g.dart` maps the `@HiveField` slots below, so field indexes are
/// frozen and new fields must be appended rather than renumbered.
///
/// The four sync slots (5-8) are stored nullable because Hive has no column
/// defaults: records written before those fields existed hold no value, and
/// a non-nullable read would crash the adapter. The effective values are
/// exposed through the non-null getters ([updatedAtMs], [updatedByDevice],
/// [revision], [isDeleted]), and the note controller backfills legacy
/// records on open.
@HiveType(typeId: 0)
class CodeData extends HiveObject {
  /// Note page identity: a 6-digit integer in the range 100000 to 999999,
  /// unique across the box and also serving as the Hive key of this record.
  @HiveField(0)
  int code;

  /// Entry text values in insertion order, oldest first.
  ///
  /// Each entry is free-form user text that may embed a URL; index positions
  /// in this list correspond to the 0-based indexes accepted by the edit and
  /// delete methods on the note controller.
  @HiveField(1)
  List<String> links;

  /// Last-edited timestamp as the string produced by `DateTime.toString()`
  /// in the device's local time zone, rewritten on every create, title
  /// write, and entry mutation.
  @HiveField(2)
  String date;

  /// Whether the note is marked as a favorite, toggled by the controller's
  /// like method and surfaced through filters and the liked-note list.
  @HiveField(3)
  bool liked;

  /// Note title shown in lists and grids, never empty in practice: the
  /// controller writes the literal 'Untitled' when the user supplies none.
  @HiveField(4)
  String head;

  /// Last-edit time as epoch milliseconds in UTC, written by the note
  /// controller on every mutation; null on records created before the sync
  /// fields existed, until the controller backfills them.
  ///
  /// This is the ordering key for last-write-wins merge during sync, which
  /// is why it is UTC epoch milliseconds rather than the display-oriented
  /// legacy [date] string.
  @HiveField(5)
  int? updatedAt;

  /// Identifier of the device that wrote the last edit: the 32-character
  /// lowercase hex string persisted by `SyncStore`, or null on records
  /// created before the sync fields existed, until backfilled.
  ///
  /// Serves as the deterministic tie-breaker when two edits carry an
  /// identical [updatedAt].
  @HiveField(6)
  String? updatedBy;

  /// Per-record revision counter, incremented by the note controller on
  /// every local mutation; null on records created before the sync fields
  /// existed, until backfilled.
  ///
  /// Orders edits that happen within the same millisecond on one device.
  @HiveField(7)
  int? rev;

  /// Tombstone flag: true once the note has been deleted on any device,
  /// null (effectively false) on live and pre-sync records.
  ///
  /// A tombstoned record is kept in the box instead of being erased so the
  /// deletion can propagate through sync and outrank older edits from
  /// other devices; the note controller hides tombstones from `codeList`,
  /// so the UI treats them exactly like the hard deletes it used to
  /// perform.
  @HiveField(8)
  bool? deleted;

  /// Creates a record holding the five core persisted fields plus the
  /// optional sync fields; [links] is stored by reference, so callers
  /// handing over a list should not mutate it afterwards without a save.
  ///
  /// The sync fields are left null by the regular create path and filled
  /// in by the controller's stamp on first mutation; remote records built
  /// from the sync wire format pass them directly.
  CodeData(
    this.code,
    this.links,
    this.date,
    this.liked,
    this.head, {
    this.updatedAt,
    this.updatedBy,
    this.rev,
    this.deleted,
  });

  /// Effective last-edit time as UTC epoch milliseconds; 0 on records that
  /// have not been backfilled yet.
  int get updatedAtMs => updatedAt ?? 0;

  /// Effective writer device id; empty on records that have not been
  /// backfilled yet.
  String get updatedByDevice => updatedBy ?? '';

  /// Effective revision counter; 0 on records that have not been
  /// backfilled yet.
  int get revision => rev ?? 0;

  /// Whether this record is a delete tombstone rather than a live note.
  bool get isDeleted => deleted ?? false;

  /// Returns a JSON-encodable map of this record matching the schema read by
  /// [CodeData.fromJSON].
  ///
  /// The five keys (`code`, `head`, `links`, `liked`, `date`) are part of the
  /// backup envelope's `notes` entries and must stay stable so older exports
  /// remain importable; the four sync keys are deliberately omitted so
  /// backups stay on schema version 1.
  Map<String, dynamic> toJSON() {
    return {
      'code': code,
      'head': head,
      'links': links,
      'liked': liked,
      'date': date,
    };
  }

  /// Builds a record from a map written by [CodeData.toJSON].
  ///
  /// The five schema-version-1 keys are required; the four sync keys
  /// (`updatedAt`, `updatedBy`, `rev`, `deleted`) are optional and read
  /// when present, so the sync wire format can reuse this factory while
  /// plain backups keep working.
  ///
  /// Throws a [TypeError] when a required key is missing or holds the
  /// wrong type (`code` must be an int, `links` a list, `date` and `head`
  /// strings, `liked` a bool), so callers must only pass input matching the
  /// export schema; the JSON import path relies on its own catch to surface
  /// malformed files.
  factory CodeData.fromJSON(Map<String, dynamic> json) {
    return CodeData(
      json['code'] as int,
      List<String>.from(json['links'] as List),
      json['date'] as String,
      json['liked'] as bool,
      json['head'] as String,
      updatedAt: json['updatedAt'] as int?,
      updatedBy: json['updatedBy'] as String?,
      rev: json['rev'] as int?,
      deleted: json['deleted'] as bool?,
    );
  }
}
