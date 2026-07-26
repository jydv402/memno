import 'package:flutter/material.dart';
import 'package:memno/desktop/components/desktop_notification.dart';
import 'package:memno/logic/functionality/code_gen.dart';
import 'package:memno/logic/functionality/import_export.dart';
import 'package:memno/logic/functionality/preview_map.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:memno/logic/theme/app_settings.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Implements the settings page interface customized for the desktop platform.
/// Uses a responsive two-column layout with section titles on the left and controls on the right.
/// Configuration options include theme cycling, dock layout/placement, data backup/restore,
/// local preview storage configuration, cache management, and application info.
///
/// Desktop-optimized settings page with a two-column layout.
///
/// Left column shows section headers; right column contains the controls.
/// No OTA update section — desktop doesn't need it.
class DesktopSettingsPage extends StatelessWidget {
  const DesktopSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    final settings = Provider.of<AppSettings>(context);

    return Scaffold(
      backgroundColor: colors.bgClr,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page title
                Text(
                  'Settings',
                  style: TextStyle(
                    fontFamily: 'GoogleSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: colors.textClr,
                  ),
                ),
                const SizedBox(height: 32),

                //  Appearance
                _buildSection(
                  colors: colors,
                  sectionTitle: 'Appearance',
                  child: _buildAppearanceSection(context, colors, settings),
                ),

                const SizedBox(height: 24),

                // Dock Layout
                _buildSection(
                  colors: colors,
                  sectionTitle: 'Dock Layout',
                  child: _buildDockLayoutSection(context, colors, settings),
                ),

                const SizedBox(height: 24),

                //  Data
                _buildSection(
                  colors: colors,
                  sectionTitle: 'Data',
                  child: _buildDataSection(context, colors),
                ),

                const SizedBox(height: 24),

                //  Storage
                _buildSection(
                  colors: colors,
                  sectionTitle: 'Storage',
                  child: _buildStorageSection(context, colors, settings),
                ),

                const SizedBox(height: 24),

                //  About
                _buildSection(
                  colors: colors,
                  sectionTitle: 'About',
                  child: _buildAboutSection(context, colors),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Section Wrapper (two-column row)

  Widget _buildSection({
    required AppColors colors,
    required String sectionTitle,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column — section title
        SizedBox(
          width: 200,
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              sectionTitle,
              style: TextStyle(
                fontFamily: 'GoogleSans',
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: colors.textClr,
              ),
            ),
          ),
        ),

        // Right column — controls
        Expanded(child: child),
      ],
    );
  }

  // Rounded Card Container

  Widget _settingsCard(AppColors colors, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.box,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  // Appearance

  Widget _buildAppearanceSection(
    BuildContext context,
    AppColors colors,
    AppSettings settings,
  ) {
    final themeMode = settings.themeMode;

    IconData modeIcon;
    String modeLabel;

    switch (themeMode) {
      case AppThemeMode.system:
        modeIcon = Icons.brightness_auto_rounded;
        modeLabel = 'System';
      case AppThemeMode.light:
        modeIcon = Icons.light_mode_rounded;
        modeLabel = 'Light';
      case AppThemeMode.dark:
        modeIcon = Icons.dark_mode_rounded;
        modeLabel = 'Dark';
    }

    return _settingsCard(
      colors,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Theme',
              style: TextStyle(
                fontFamily: 'GoogleSans',
                fontSize: 16,
                color: colors.textClr,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => settings.cycleThemeMode(),
            icon: Icon(modeIcon, size: 18),
            label: Text(
              modeLabel,
              style: const TextStyle(
                fontFamily: 'GoogleSans',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textClr,
              side: BorderSide(color: colors.pill),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Dock Layout

  Widget _buildDockLayoutSection(
    BuildContext context,
    AppColors colors,
    AppSettings settings,
  ) {
    final placement = settings.dockPlacement;

    Widget buildPlacementButton(String value, String label, IconData icon) {
      final isSelected = placement == value;
      return OutlinedButton.icon(
        onPressed: () => settings.setDockPlacement(value),
        icon: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.black : colors.textClr,
        ),
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'GoogleSans',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isSelected ? Colors.black : colors.textClr,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? colors.accnt : Colors.transparent,
          side: BorderSide(color: isSelected ? colors.accnt : colors.pill),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    }

    return _settingsCard(
      colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose where to place the floating dock on your screen.',
            style: TextStyle(
              fontFamily: 'GoogleSans',
              fontSize: 14,
              color: colors.textClr.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              buildPlacementButton(
                'bottom',
                'Bottom',
                Icons.border_bottom_rounded,
              ),
              buildPlacementButton('top', 'Top', Icons.border_top_rounded),
              buildPlacementButton('left', 'Left', Icons.border_left_rounded),
              buildPlacementButton(
                'right',
                'Right',
                Icons.border_right_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Data

  Widget _buildDataSection(BuildContext context, AppColors colors) {
    return _settingsCard(
      colors,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => ImportExport().exportToJSON(context),
              icon: const Icon(Icons.arrow_upward_rounded, size: 18),
              label: const Text(
                'Export to JSON',
                style: TextStyle(
                  fontFamily: 'GoogleSans',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textClr,
                side: BorderSide(color: colors.pill),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => ImportExport().importFromJSON(context),
              icon: const Icon(Icons.arrow_downward_rounded, size: 18),
              label: const Text(
                'Import from JSON',
                style: TextStyle(
                  fontFamily: 'GoogleSans',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textClr,
                side: BorderSide(color: colors.pill),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Storage

  Widget _buildStorageSection(
    BuildContext context,
    AppColors colors,
    AppSettings settings,
  ) {
    return Column(
      spacing: 12,
      children: [
        _settingsCard(
          colors,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Clear All Codes & Links',
                  style: TextStyle(
                    fontFamily: 'GoogleSans',
                    fontSize: 16,
                    color: colors.textClr,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final codeGen = Provider.of<CodeGen>(context, listen: false);
                  await codeGen.clearAll();
                  if (context.mounted) {
                    showDesktopNotification(
                      context,
                      'All codes and links cleared',
                    );
                  }
                },
                icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                label: const Text(
                  'Clear',
                  style: TextStyle(
                    fontFamily: 'GoogleSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textClr,
                  side: BorderSide(color: colors.pill),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        _settingsCard(
          colors,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Save Previews Locally',
                  style: TextStyle(
                    fontFamily: 'GoogleSans',
                    fontSize: 16,
                    color: colors.textClr,
                  ),
                ),
              ),
              Switch(
                value: settings.saveImagesLocally,
                onChanged: (val) async {
                  await settings.setSaveImagesLocally(val);
                },
                activeThumbColor: colors.accnt,
                activeTrackColor: colors.accnt.withValues(alpha: 0.3),
                inactiveThumbColor: colors.thumbClr,
                trackOutlineColor: WidgetStateProperty.all(
                  colors.switchTrackOutlineClr,
                ),
              ),
            ],
          ),
        ),

        // Clear Preview Cache
        Consumer<PreviewMap>(
          builder: (context, previewMap, _) {
            return FutureBuilder<double>(
              future: previewMap.getTotalCacheSizeMB(),
              builder: (context, snapshot) {
                final size = snapshot.data ?? 0.0;
                return _settingsCard(
                  colors,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preview Cache',
                              style: TextStyle(
                                fontFamily: 'GoogleSans',
                                fontSize: 16,
                                color: colors.textClr,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Used: ${size.toStringAsFixed(2)} MB',
                              style: TextStyle(
                                fontFamily: 'GoogleSans',
                                fontSize: 13,
                                color: colors.textClr.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await previewMap.clearImageCache();
                          if (context.mounted) {
                            showDesktopNotification(
                              context,
                              'Preview cache cleared',
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                        label: const Text(
                          'Clear',
                          style: TextStyle(
                            fontFamily: 'GoogleSans',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.textClr,
                          side: BorderSide(color: colors.pill),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // About

  Widget _buildAboutSection(BuildContext context, AppColors colors) {
    return _settingsCard(
      colors,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Find Memno on GitHub',
              style: TextStyle(
                fontFamily: 'GoogleSans',
                fontSize: 16,
                color: colors.textClr,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              launchUrl(Uri.parse('https://github.com/jydv402/memno'));
            },
            icon: const Icon(Icons.arrow_outward_rounded, size: 18),
            label: const Text(
              'Open',
              style: TextStyle(
                fontFamily: 'GoogleSans',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textClr,
              side: BorderSide(color: colors.pill),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
