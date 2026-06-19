import 'package:flutter/material.dart';
import 'package:memno/mobile/components/show_toast.dart';
import 'package:memno/logic/functionality/check_update.dart';
import 'package:memno/mobile/components/update_bottom_sheet.dart';
import 'package:memno/logic/functionality/import_export.dart';
import 'package:memno/logic/functionality/preview_map.dart';

import 'package:memno/logic/theme/app_colors.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  final bool isEmbedded;
  const SettingsPage({super.key, this.isEmbedded = false});

  void _showDialog(
    BuildContext context,
    String title,
    String content,
    AppColors colors,
    VoidCallback onPressed,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.box,
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'GoogleSans',
            fontSize: 20,
            color: colors.textClr,
          ),
        ),
        content: Text(
          content,
          style: TextStyle(
            fontFamily: 'GoogleSans',
            fontSize: 18,
            color: colors.textClr,
          ),
        ),
        actions: [
          TextButton(
            onPressed: onPressed,
            child: Text(
              "OK",
              style: TextStyle(
                fontFamily: 'GoogleSans',
                fontSize: 16,
                color: colors.textClr,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          settingsTitle("Settings", colors),
          settingsContainer(
            ListTile(
              onTap: () => colors.cycleThemeMode(),
              title: Text(
                "Appearance",
                style: TextStyle(
                  fontFamily: 'GoogleSans',
                  fontSize: 18,
                  color: colors.textClr,
                ),
              ),
              trailing: Icon(
                colors.themeMode == AppThemeMode.system
                    ? Icons.brightness_auto_rounded
                    : colors.themeMode == AppThemeMode.light
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                color: colors.textClr,
              ),
            ),
            colors,
          ),
          settingsContainer(
            SwitchListTile(
              trackColor: WidgetStateProperty.all(
                colors.accnt.withValues(alpha: 0.3),
              ),
              overlayColor: WidgetStateProperty.all(colors.accnt),
              thumbColor: WidgetStateProperty.all(colors.thumbClr),
              trackOutlineColor: WidgetStateProperty.all(
                colors.switchTrackOutlineClr,
              ),
              title: Text(
                "Compact Header",
                style: TextStyle(
                  fontFamily: 'GoogleSans',
                  fontSize: 18,
                  color: colors.textClr,
                ),
              ),
              value: context.watch<AppColors>().isCompactHeader,
              onChanged: (_) async {
                await colors.toggleCompactHeader();
              },
            ),
            colors,
          ),
          // Settings for Data
          settingsTitle("Data", colors),
          settingsContainer(
            ListTile(
              onTap: () {
                ImportExport().exportToJSON(context);
              },
              title: Text(
                "Export to JSON",
                style: TextStyle(
                  fontFamily: 'GoogleSans',
                  fontSize: 18,
                  color: colors.textClr,
                ),
              ),
              trailing: Icon(Icons.arrow_upward_rounded, color: colors.textClr),
            ),
            colors,
          ),
          settingsContainer(
            ListTile(
              onTap: () {
                ImportExport().importFromJSON(context);
              },
              title: Text(
                "Import from JSON",
                style: TextStyle(
                  fontFamily: 'GoogleSans',
                  fontSize: 18,
                  color: colors.textClr,
                ),
              ),
              trailing: Icon(
                Icons.arrow_downward_rounded,
                color: colors.textClr,
              ),
            ),
            colors,
          ),
          // Settings for updates
          settingsTitle("Updates", colors),
          settingsContainer(
            ListTile(
              onTap: () async {
                final info = await PackageInfo.fromPlatform();
                final currVer = info.version; // Get current app version
                final buildNumber = info.buildNumber; // Get build number
                if (!context.mounted) return;
                if (currVer.isEmpty || buildNumber.isEmpty) {
                  _showDialog(
                    context,
                    "Version Check Failed",
                    "Could not retrieve current version.",
                    colors,
                    () {
                      Navigator.pop(context);
                    },
                  );
                  return;
                }
                // Use the new update check service
                final updateInfo = await checkUpdateAvailable();
                if (!context.mounted) return;

                if (updateInfo != null) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => UpdateBottomSheet(
                      latestVersion: updateInfo['version'],
                      downloadUrl: updateInfo['url'],
                      releaseNotes: updateInfo['notes'],
                    ),
                  );
                } else {
                  final info = await PackageInfo.fromPlatform();
                  if (!context.mounted) return;
                  _showDialog(
                    context,
                    "No Updates",
                    "You are using the latest version (${info.version}).",
                    colors,
                    () {
                      Navigator.pop(context);
                    },
                  );
                }
              },
              trailing: Icon(
                Icons.file_download_outlined,
                color: colors.textClr,
              ),
              title: Text(
                "Check for updates",
                style: TextStyle(
                  fontFamily: 'GoogleSans',
                  fontSize: 18,
                  color: colors.textClr,
                ),
              ),
            ),
            colors,
          ),
          // Storage settings
          settingsTitle("Storage", colors),
          // Settings for saving previews locally
          settingsContainer(
            SwitchListTile(
              trackColor: WidgetStateProperty.all(
                colors.accnt.withValues(alpha: 0.3),
              ),
              overlayColor: WidgetStateProperty.all(colors.accnt),
              thumbColor: WidgetStateProperty.all(colors.thumbClr),
              trackOutlineColor: WidgetStateProperty.all(
                colors.switchTrackOutlineClr,
              ),
              title: Text(
                "Save Previews Locally",
                style: TextStyle(
                  fontFamily: 'GoogleSans',
                  fontSize: 18,
                  color: colors.textClr,
                ),
              ),
              value: context.watch<AppColors>().saveImagesLocally,
              onChanged: (val) async {
                await colors.setSaveImagesLocally(val);
              },
            ),
            colors,
          ),
          // Settings for showing the storage used and to clear the cache
          Consumer<PreviewMap>(
            builder: (context, previewMap, _) {
              return FutureBuilder<double>(
                future: previewMap.getTotalCacheSizeMB(),
                builder: (context, snapshot) {
                  final size = snapshot.data ?? 0.0;
                  return settingsContainer(
                    ListTile(
                      onTap: () async {
                        await previewMap.clearImageCache();
                        if (context.mounted) {
                          showToastMsg(context, "Preview cache cleared");
                        }
                      },
                      title: Text(
                        "Clear Preview Cache",
                        style: TextStyle(
                          fontFamily: 'GoogleSans',
                          fontSize: 18,
                          color: colors.textClr,
                        ),
                      ),
                      subtitle: Text(
                        "Used: ${size.toStringAsFixed(2)} MB",
                        style: TextStyle(
                          fontFamily: 'GoogleSans',
                          fontSize: 14,
                          color: colors.textClr.withValues(alpha: 0.7),
                        ),
                      ),
                      trailing: Icon(
                        Icons.delete_sweep_rounded,
                        color: colors.textClr,
                      ),
                    ),
                    colors,
                  );
                },
              );
            },
          ),
          // About section
          settingsTitle("About", colors),
          settingsContainer(
            ListTile(
              onTap: () {
                launchUrl(Uri.parse("https://github.com/jydv402/memno"));
              },
              trailing: Icon(
                Icons.arrow_outward_rounded,
                color: colors.textClr,
              ),
              title: Text(
                "Find Memno on GitHub",
                style: TextStyle(
                  fontFamily: 'GoogleSans',
                  fontSize: 18,
                  color: colors.textClr,
                ),
              ),
            ),
            colors,
          ),
          // Bottom padding
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Padding settingsTitle(String title, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 0, 16),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'GoogleSans',
          fontSize: 28,
          color: colors.textClr,
        ),
      ),
    );
  }

  Container settingsContainer(Widget child, AppColors colors) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      margin: const EdgeInsets.fromLTRB(2, 4, 2, 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: colors.box,
      ),
      child: child,
    );
  }
}
