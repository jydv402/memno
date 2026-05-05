import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:memno/components/show_toast.dart';
import 'package:memno/database/code_data.dart';
import 'package:memno/functionality/code_gen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class ImportExport {
  late Box<CodeData>? _codeBox;

  ImportExport() {
    _loadCodeBox();
  }

  // Load the code box
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

  // Export to JSON function
  Future<void> exportToJSON(BuildContext context) async {
    try {
      await _loadCodeBox();
      if (_codeBox == null) return;

      // Collect the notes
      final notes = _codeBox!.values.map((note) => note.toJSON()).toList();

      // Get app data
      final pkgInfo = await PackageInfo.fromPlatform();

      final appDetails = {
        "app": "Memno",
        "version": pkgInfo.version,
        "schema_version": 1,
        "exported_at": DateTime.now().toUtc().toIso8601String(),
        "notes": notes,
      };

      // Encode JSON
      final json = const JsonEncoder.withIndent('  ').convert(appDetails);
      // Convert the JSON to UTF8 bytes, returns a list of int
      // Then convert the int list to Uint8List as SAF (Storage Access Framework) demands it
      final bytes = Uint8List.fromList(utf8.encode(json));

      // Clear the temporary files
      await FilePicker.clearTemporaryFiles();

      // Get the save destination
      // Write the file
      final result = await FilePicker.saveFile(
        dialogTitle: 'Export Memno Notes',
        fileName: 'memno_notes.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      // Show cancelled message if the export is cancelled halfway
      if (result == null) {
        if (context.mounted) {
          showToastMsg(context, 'Export Cancelled');
        }
        return;
      }

      // Show success message
      if (context.mounted) {
        showToastMsg(context, 'Successfully Exported to JSON');
      }
    } catch (e) {
      debugPrint('ExportToJSON error: $e');
      if (context.mounted) {
        showToastMsg(context, e.toString());
      }
    }
  }

  // Import from JSON function
  Future<void> importFromJSON(BuildContext context) async {
    try {
      await _loadCodeBox();
      if (_codeBox == null) return;

      // Get the file
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
        allowMultiple: false,
      );
      // Show cancelled message if the import is cancelled halfway
      if (result == null) {
        if (context.mounted) {
          showToastMsg(context, 'Import Cancelled');
        }
        return;
      }

      // Decode JSON
      final bytes = result.files.first.bytes;
      if (bytes == null) {
        if (context.mounted) {
          showToastMsg(context, 'Could not read file data');
        }
        return;
      }
      final jsonString = utf8.decode(bytes);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      // Get the notes
      final notes = json['notes'] as List;

      // Add the notes to the box
      for (final note in notes) {
        final codeData = CodeData.fromJSON(note);
        await _codeBox!.put(codeData.code, codeData);
      }

      // Reload the code box
      if (context.mounted) {
        context.read<CodeGen>().reloadCodeBox();
      }

      // Show success message
      if (context.mounted) {
        showToastMsg(context, 'Successfully Imported from JSON');
      }
    } catch (e) {
      debugPrint('ImportFromJSON error: $e');
      if (context.mounted) {
        showToastMsg(context, e.toString());
      }
    }
  }
}
