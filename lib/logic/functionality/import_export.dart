import 'dart:convert';
import 'dart:io' show File, Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:hive/hive.dart';
import 'package:memno/desktop/components/desktop_notification.dart';
import 'package:memno/mobile/components/show_toast.dart';
import 'package:memno/logic/database/code_data.dart';
import 'package:memno/logic/functionality/code_gen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

/// Handles JSON-based backup import and export functionality for note
/// databases.
///
/// The export is a single JSON envelope carrying the app name, version,
/// schema version, UTC export timestamp, and every [CodeData] record; the
/// import reads the same envelope, merges records into the live box keyed
/// by code, and then asks the note controller to reload from disk. All
/// user-facing feedback is routed through [_showNotification], which picks
/// the platform-appropriate channel.
class ImportExport {
  late Box<CodeData>? _codeBox;

  /// Creates the helper and starts opening the `codeData` box; the first
  /// export or import call awaits the same load again, so construction is
  /// never a blocking prerequisite.
  ImportExport() {
    _loadCodeBox();
  }

  /// Opens or reuses the `codeData` Hive box, storing it in [_codeBox];
  /// failures leave the field null and are only logged.
  ///
  /// The late nullable field is the honest shape of "box loading is async
  /// and may fail": callers check for null instead of racing the future.
  Future<void> _loadCodeBox() async {
    try {
      if (!Hive.isBoxOpen('codeData')) {
        _codeBox = await Hive.openBox<CodeData>('codeData');
      } else {
        _codeBox = Hive.box<CodeData>('codeData');
      }
    } catch (e) {
      debugPrint('ImportExport _loadCodeBox error: $e');
    }
  }

  /// Exports all notes and app metadata to a JSON file chosen by the user.
  ///
  /// The envelope carries `app`, `version`, `schema_version` (fixed at 1
  /// for this format), `exported_at` (UTC ISO-8601), and `notes` (the
  /// [CodeData.toJSON] records). Tombstoned records are excluded: a backup
  /// is a restore of live content, and writing a tombstone into the
  /// schema-version-1 shape (which has no `deleted` key) would resurrect
  /// the note on import, on this or any older app version. On desktop the
  /// returned path is written to directly; other platforms rely on the
  /// picker's own save handling. Cancellation is reported as its own
  /// notification rather than an error. Every failure is caught and
  /// surfaced as a notification, so a bad picker state can never crash the
  /// settings page.
  Future<void> exportToJSON(BuildContext context) async {
    try {
      await _loadCodeBox();
      if (_codeBox == null) return;

      // Collects live notes only; tombstones must not leak into backups.
      final notes = _codeBox!.values
          .where((note) => !note.isDeleted)
          .map((note) => note.toJSON())
          .toList();

      // Retrieves app metadata
      final pkgInfo = await PackageInfo.fromPlatform();

      final appDetails = {
        "app": "Memno",
        "version": pkgInfo.version,
        "schema_version": 1,
        "exported_at": DateTime.now().toUtc().toIso8601String(),
        "notes": notes,
      };

      // Encodes app details to JSON
      final json = const JsonEncoder.withIndent('  ').convert(appDetails);
      // Converts JSON to UTF8 bytes and maps to Uint8List for storage operations
      final bytes = Uint8List.fromList(utf8.encode(json));

      // Clears temporary files
      await FilePicker.clearTemporaryFiles();

      // Retrieves save destination and writes file
      // Writes the file
      Uri? result;
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        result = await FilePicker.saveFile(
          dialogTitle: 'Export Memno Notes',
          fileName: 'memno_notes.json',
          bytes: bytes,
        );
        if (result != null) {
          final file = File(result.toFilePath());
          await file.writeAsBytes(bytes);
        }
      } else {
        result = await FilePicker.saveFile(
          dialogTitle: 'Export Memno Notes',
          fileName: 'memno_notes.json',
          bytes: bytes,
        );
      }

      // Displays cancellation message if aborted
      if (result == null) {
        if (context.mounted) {
          _showNotification(context, 'Export Cancelled');
        }
        return;
      }

      // Displays success message
      if (context.mounted) {
        _showNotification(context, 'Successfully Exported to JSON');
      }
    } catch (e) {
      debugPrint('ExportToJSON error: $e');
      if (context.mounted) {
        _showNotification(context, e.toString());
      }
    }
  }

  /// Imports notes from a JSON file picked by the user and reloads the
  /// active database so the UI reflects them.
  ///
  /// Records are merged into the live box keyed by [CodeData.code], so an
  /// import overwrites same-code notes and keeps everything else. A
  /// malformed or truncated file is caught and reported as a notification
  /// without touching storage, because the merge only starts after the
  /// whole file has decoded.
  Future<void> importFromJSON(BuildContext context) async {
    try {
      await _loadCodeBox();
      if (_codeBox == null) return;

      // Retrieves file from picker
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      // Displays cancellation message if aborted
      if (file == null) {
        if (context.mounted) {
          _showNotification(context, 'Import Cancelled');
        }
        return;
      }

      // Decodes JSON
      final bytes = await file.readAsBytes();
      final jsonString = utf8.decode(bytes);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      // Retrieves notes list
      final notes = json['notes'] as List;

      // Adds imported notes to storage
      for (final note in notes) {
        final codeData = CodeData.fromJSON(note);
        await _codeBox!.put(codeData.code, codeData);
      }

      // Reloads database box
      if (context.mounted) {
        context.read<CodeGen>().reloadCodeBox();
      }

      // Displays success message
      if (context.mounted) {
        _showNotification(context, 'Successfully Imported from JSON');
      }
    } catch (e) {
      debugPrint('ImportFromJSON error: $e');
      if (context.mounted) {
        _showNotification(context, e.toString());
      }
    }
  }

  void _showNotification(BuildContext context, String message) {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      showDesktopNotification(context, message);
    } else {
      showToastMsg(context, message);
    }
  }
}
