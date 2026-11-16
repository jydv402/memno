import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';

import 'code_data.dart';

/// Hive key (in `syncBox`) recording that the legacy-frame migration has
/// completed on this device, so it never runs again.
const String legacyMigrationDoneKey = 'legacy_sync_fields_migrated';

/// One-time migration for the `codeData` box: records written by the
/// abandoned sync prototype of August 2026 carried extra fields —
/// concretely a String record id at slot 5 — that the current schema's
/// `int?` slot cannot read, so the generated adapter throws on box open
/// and the app cannot start.
///
/// The prototype's extra metadata is meaningless under the current design
/// (which keys records by code and derives ordering stamps), so it is
/// dropped; the user content in slots 0-4 is always preserved. The
/// migration reads every frame tolerantly, rewrites only the frames that
/// carried legacy values in the canonical nine-slot layout, and is a
/// no-op on boxes that are already conformant.
class LegacyCodeDataAdapter extends TypeAdapter<CodeData> {
  /// Creates the adapter; [onLegacyFrame] is called once for every frame
  /// that carried unexpected legacy values, with the record built from it.
  LegacyCodeDataAdapter({required this.onLegacyFrame});

  /// Invoked for each frame whose values did not match the current schema.
  final void Function(CodeData record) onLegacyFrame;

  @override
  final int typeId = 0;

  @override
  CodeData read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < count; i++) reader.readByte(): reader.read(),
    };

    var legacy = false;

    /// Returns [value] when it matches [T], flagging the frame as legacy
    /// and returning [fallback] otherwise; a null value never flags
    /// because every optional slot reads as unset.
    T typed<T>(Object? value, T fallback) {
      if (value is T) return value;
      legacy = true;
      return fallback;
    }

    final record = CodeData(
      fields[0] as int,
      _linksOf(fields[1], () => legacy = true),
      typed(fields[2], ''),
      typed(fields[3], false),
      typed(fields[4], ''),
      updatedAt: typed(fields[5], null),
      updatedBy: typed(fields[6], null),
      rev: typed(fields[7], null),
      deleted: typed(fields[8], null),
    );
    if (legacy) onLegacyFrame(record);
    return record;
  }

  /// Returns [value] as an entry list; a plain list is cast element-wise,
  /// anything else is flagged as legacy and replaced with an empty list.
  List<String> _linksOf(Object? value, void Function() flagLegacy) {
    if (value is List<String>) return value;
    if (value is List) return value.whereType<String>().toList();
    flagLegacy();
    return const <String>[];
  }

  @override
  void write(BinaryWriter writer, CodeData obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.code)
      ..writeByte(1)
      ..write(obj.links)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.liked)
      ..writeByte(4)
      ..write(obj.head)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.updatedBy)
      ..writeByte(7)
      ..write(obj.rev)
      ..writeByte(8)
      ..write(obj.deleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegacyCodeDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Opens the `codeData` box with the tolerant [LegacyCodeDataAdapter],
/// rewrites every legacy frame in the canonical layout, and closes the box
/// again; the caller must restore the generated adapter and open the box
/// itself afterwards.
///
/// The function is a no-op on an already-open box (another owner opened it
/// first) and must run before any typed open, because letting the strict
/// generated adapter hit a legacy frame would trigger Hive's crash
/// recovery, which truncates the file at the first unreadable frame —
/// silent data loss. Callers flag-guard via [legacyMigrationDoneKey].
Future<void> migrateLegacyCodeData() async {
  if (Hive.isBoxOpen('codeData')) return;
  final legacyRecords = <CodeData>{};
  Hive.registerAdapter(
    LegacyCodeDataAdapter(onLegacyFrame: legacyRecords.add),
    override: true,
  );
  try {
    final box = await Hive.openBox<CodeData>('codeData');
    try {
      if (legacyRecords.isEmpty) return;
      debugPrint(
        'Migrating ${legacyRecords.length} legacy codeData frame(s) '
        'written by the abandoned sync prototype.',
      );
      await box.putAll({
        for (final record in legacyRecords) record.code: record,
      });
      // Hive files are append-only: without compaction the legacy frames
      // stay first in the file and any later open would still read them
      // first. Compaction rewrites the file with only the newest frames.
      await box.compact();
    } finally {
      await box.close();
    }
  } finally {
    Hive.registerAdapter(CodeDataAdapter(), override: true);
  }
}
