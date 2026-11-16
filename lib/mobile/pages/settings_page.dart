import 'package:material_ui/material_ui.dart';
import 'package:memno/mobile/components/settings_tile.dart';
import 'package:memno/mobile/components/settings_title.dart';
import 'package:memno/mobile/components/haptic_app_bar.dart';
import 'package:memno/mobile/components/show_toast.dart';
import 'package:memno/logic/functionality/check_update.dart';
import 'package:memno/logic/functionality/import_export.dart';
import 'package:memno/logic/functionality/preview_map.dart';
import 'package:memno/logic/sync/auth/sync_auth_controller.dart';

import 'package:memno/logic/theme/app_colors.dart';
import 'package:memno/logic/theme/app_settings.dart';
import 'package:provider/provider.dart';
import 'package:update_checker_bottom_sheet/update_checker_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mobile settings screen: appearance, haptics, data import and export,
/// cache management, and links out to updates and project pages.
///
/// [SettingsPage] is a plain list of [SettingsTile] rows grouped by
/// [SettingsTitle] headings; every row mutates its provider directly, so
/// the page is stateless and reacts purely to provider notifications.
/// It can also render embedded inside the desktop share flow, which only
/// hides the automatic back button.
class SettingsPage extends StatelessWidget {
  /// Whether the page is embedded in another surface, hiding the
  /// automatic back button when true.
  final bool isEmbedded;

  /// Creates the settings screen; embedded mode is opt-in.
  const SettingsPage({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    final settings = Provider.of<AppSettings>(context);
    return Scaffold(
      backgroundColor: colors.bgClr,
      appBar: HapticAppBar(
        backgroundColor: colors.bgClr,
        foregroundColor: colors.fgClr,
        implyLeading: !isEmbedded,
      ),
      body: ListView(
        children: [
          // Settings for Appearance
          SettingsTitle(title: "Settings", textClr: colors.textClr),
          SettingsTile(
            title: "Appearance",
            onTap: () => settings.cycleThemeMode(),
            trailingIcon: settings.themeMode == AppThemeMode.system
                ? Icons.brightness_auto_rounded
                : settings.themeMode == AppThemeMode.light
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
          ),
          // Haptic feedback toggle
          SettingsTile(
            title: "Haptic Feedback",
            value: settings.enableHaptics,
            onChanged: (val) async {
              await settings.setEnableHaptics(val);
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
          // Settings for Sync
          SettingsTitle(title: "Sync", textClr: colors.textClr),
          const _SyncTile(),
          // Settings for updates
          SettingsTitle(title: "Updates", textClr: colors.textClr),
          SettingsTile(
            title: "Check for updates",
            onTap: () async {
              await checkAppUpdate(
                context,
                true,
                UpdateCheckerStyle.bottomSheet,
              );
            },
            trailingIcon: Icons.file_download_outlined,
          ),
          // Storage settings
          SettingsTitle(title: "Storage", textClr: colors.textClr),
          // Settings for saving previews locally
          SettingsTile(
            title: "Save Previews Locally",
            value: settings.saveImagesLocally,
            onChanged: (val) async {
              await settings.setSaveImagesLocally(val);
            },
          ),
          // Settings for showing the storage used and to clear the cache
          const _CacheSizeTile(),
          // About section
          SettingsTitle(title: "Support", textClr: colors.textClr),
          SettingsTile(
            title: "Sponsor the Developer",
            onTap: () {
              launchUrl(Uri.parse("https://github.com/sponsors/jydv402"));
            },
            trailingIcon: Icons.favorite_border_rounded,
          ),
          SettingsTile(
            title: "Star Memno on GitHub",
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

/// Google sign-in tile for the Sync section: flips between sign-in and
/// sign-out through [SyncAuthController] and shows the account email as
/// the subtitle when signed in.
class _SyncTile extends StatelessWidget {
  const _SyncTile();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<SyncAuthController>(context);
    final signedIn = auth.signedIn && auth.account != null;
    return SettingsTile(
      title: signedIn ? "Sign out of Google" : "Sign in with Google",
      subtitle: signedIn
          ? "Signed in as ${auth.account!.email}"
          : "Keeps your notes in sync across your devices",
      onTap: auth.busy ? null : () => _toggle(context),
      trailingIcon: signedIn ? Icons.logout_rounded : Icons.login_rounded,
    );
  }

  Future<void> _toggle(BuildContext context) async {
    final controller = context.read<SyncAuthController>();
    final message = controller.signedIn
        ? await controller.signOut()
        : await controller.signIn();
    if (context.mounted) {
      showToastMsg(context, message);
    }
  }
}

/// "Clear Preview Cache" tile showing the used size.
///
/// The size future is owned by this State and refreshed whenever
/// [PreviewMap] notifies: it is never re-created inside build().
class _CacheSizeTile extends StatefulWidget {
  const _CacheSizeTile();

  @override
  State<_CacheSizeTile> createState() => _CacheSizeTileState();
}

class _CacheSizeTileState extends State<_CacheSizeTile> {
  Future<double>? _sizeFuture;
  PreviewMap? _watchedPreviewMap;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final previewMap = Provider.of<PreviewMap>(context);
    if (!identical(previewMap, _watchedPreviewMap)) {
      _watchedPreviewMap = previewMap;
      _sizeFuture = previewMap.getTotalCacheSizeMB();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: _sizeFuture,
      builder: (context, snapshot) {
        final size = snapshot.data ?? 0.0;
        return SettingsTile(
          title: "Clear Preview Cache",
          subtitle: "Used: ${size.toStringAsFixed(2)} MB",
          onTap: () async {
            final previewMap = context.read<PreviewMap>();
            await previewMap.clearImageCache();
            if (context.mounted) {
              showToastMsg(context, "Preview cache cleared");
            }
          },
          trailingIcon: Icons.delete_sweep_rounded,
        );
      },
    );
  }
}
