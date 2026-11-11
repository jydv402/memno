import 'dart:convert';
import 'dart:io' show File, Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:memno/desktop/components/desktop_notification.dart';
import 'package:memno/mobile/components/show_toast.dart';
import 'package:memno/logic/database/code_data.dart';
import 'package:memno/logic/functionality/code_gen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

/// Handles JSON-based backup import and export functionality for note databases.
class ImportExport {
  late Box<CodeData>? _codeBox;

  ImportExport() {
    _loadCodeBox();
  }

  /// Loads the code box if it is not already opened.
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

  /// Exports all notes and app metadata to a JSON file.
  Future<void> exportToJSON(BuildContext context) async {
    try {
      await _loadCodeBox();
      if (_codeBox == null) return;

      // Collects notes
      final notes = _codeBox!.values.map((note) => note.toJSON()).toList();

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
          type: FileType.custom,
          allowedExtensions: ['json'],
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
          type: FileType.custom,
          allowedExtensions: ['json'],
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

  /// Imports notes from a JSON file and reloads the active database.
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
