import 'package:flutter/material.dart';
import 'package:memno/mobile/components/settings_tile.dart';
import 'package:memno/mobile/components/settings_title.dart';
import 'package:memno/mobile/components/show_toast.dart';
import 'package:memno/logic/functionality/check_update.dart';
import 'package:memno/logic/functionality/import_export.dart';
import 'package:memno/logic/functionality/preview_map.dart';

import 'package:memno/logic/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  final bool isEmbedded;
  const SettingsPage({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return Scaffold(
      backgroundColor: colors.bgClr,
      appBar: AppBar(
        backgroundColor: colors.bgClr,
        foregroundColor: colors.fgClr,
        automaticallyImplyLeading: !isEmbedded,
      ),
      body: ListView(
        children: [
          // Settings for Appearance
          SettingsTitle(title: "Settings", textClr: colors.textClr),
          SettingsTile(
            title: "Appearance",
            onTap: () => colors.cycleThemeMode(),
            trailingIcon: colors.themeMode == AppThemeMode.system
                ? Icons.brightness_auto_rounded
                : colors.themeMode == AppThemeMode.light
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
          ),
          SettingsTile(
            title: "Compact Header",
            value: context.watch<AppColors>().isCompactHeader,
            onChanged: (_) async {
              await colors.toggleCompactHeader();
            },
          ),
          // Settings for Data
          SettingsTitle(title: "Data", textClr: colors.textClr),
          SettingsTile(
            title: "Export to JSON",
            onTap: () {
              ImportExport().exportToJSON(context);
            },
            trailingIcon: Icons.arrow_upward_rounded,
          ),
          SettingsTile(
            title: "Import from JSON",
            onTap: () {
              ImportExport().importFromJSON(context);
            },
            trailingIcon: Icons.arrow_downward_rounded,
          ),
          // Settings for updates
          SettingsTitle(title: "Updates", textClr: colors.textClr),
          SettingsTile(
            title: "Check for updates",
            onTap: () async {
              await checkAppUpdate(context, true);
            },
            trailingIcon: Icons.file_download_outlined,
          ),
          // Storage settings
          SettingsTitle(title: "Storage", textClr: colors.textClr),
          // Settings for saving previews locally
          SettingsTile(
            title: "Save Previews Locally",
            value: context.watch<AppColors>().saveImagesLocally,
            onChanged: (val) async {
              await colors.setSaveImagesLocally(val);
            },
          ),
          // Settings for showing the storage used and to clear the cache
          Consumer<PreviewMap>(
            builder: (context, previewMap, _) {
              return FutureBuilder<double>(
                future: previewMap.getTotalCacheSizeMB(),
                builder: (context, snapshot) {
                  final size = snapshot.data ?? 0.0;
                  return SettingsTile(
                    title: "Clear Preview Cache",
                    subtitle: "Used: ${size.toStringAsFixed(2)} MB",
                    onTap: () async {
                      await previewMap.clearImageCache();
                      if (context.mounted) {
                        showToastMsg(context, "Preview cache cleared");
                      }
                    },
                    trailingIcon: Icons.delete_sweep_rounded,
                  );
                },
              );
            },
          ),
          // About section
          SettingsTitle(title: "About", textClr: colors.textClr),
          SettingsTile(
            title: "Find Memno on GitHub",
            onTap: () {
              launchUrl(Uri.parse("https://github.com/jydv402/memno"));
            },
            trailingIcon: Icons.arrow_outward_rounded,
          ),
          // Bottom padding
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
