import 'package:hive/hive.dart';

part 'code_data.g.dart';

/// One persisted note page, stored in the Hive box `codeData` keyed by its
/// own [code].
///
/// A note page is a titled collection of free-form entry strings; an entry
/// usually contains a URL but may be plain text. The generated adapter in
/// `code_data.g.dart` maps the `@HiveField` slots below, so field indexes are
/// frozen and new fields must be appended rather than renumbered.
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

  /// Creates a record holding all five persisted fields; [links] is stored
  /// by reference, so callers handing over a list should not mutate it
  /// afterwards without a save.
  CodeData(this.code, this.links, this.date, this.liked, this.head);

  /// Returns a JSON-encodable map of this record matching the schema read by
  /// [CodeData.fromJSON].
  ///
  /// The five keys (`code`, `head`, `links`, `liked`, `date`) are part of the
  /// backup envelope's `notes` entries and must stay stable so older exports
  /// remain importable.
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
  /// Throws a [TypeError] when any of the five keys is missing or holds the
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
    );
  }
}
