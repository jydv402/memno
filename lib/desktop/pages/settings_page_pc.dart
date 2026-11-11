import 'package:flutter/material.dart';
import 'package:memno/desktop/components/desktop_notification.dart';
import 'package:memno/logic/functionality/code_gen.dart';
import 'package:memno/logic/functionality/import_export.dart';
import 'package:memno/logic/functionality/note_operations.dart';
import 'package:memno/logic/functionality/preview_map.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:memno/logic/theme/app_settings.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Desktop-optimized settings page with a two-column layout.
///
/// Left column shows section headers; right column contains the controls.
/// No OTA update section — desktop doesn't need it.
class DesktopSettingsPage extends StatelessWidget {
  const DesktopSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);

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

                const _Section(
                  sectionTitle: 'Appearance',
                  child: _AppearanceCard(),
                ),
                const SizedBox(height: 24),

                const _Section(
                  sectionTitle: 'Dock Layout',
                  child: _DockPlacementCard(),
                ),
                const SizedBox(height: 24),

                const _Section(sectionTitle: 'Data', child: _DataCard()),
                const SizedBox(height: 24),

                const _Section(
                  sectionTitle: 'Storage',
                  child: _StorageSection(),
                ),
                const SizedBox(height: 24),

                const _Section(sectionTitle: 'About', child: _AboutCard()),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-column settings row: section title on the left, controls on the right.
class _Section extends StatelessWidget {
  const _Section({required this.sectionTitle, required this.child});

  final String sectionTitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Expanded(child: child),
      ],
    );
  }
}

/// Rounded card container used for every settings control group.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
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
}

/// Icon + label outlined button with the settings page's shared style.
class _SettingsButton extends StatelessWidget {
  const _SettingsButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.verticalPadding = 12,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// Whether the button is in its selected (accent) state.
  final bool selected;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'GoogleSans',
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? Colors.black : colors.textClr,
        backgroundColor: selected ? colors.accnt : Colors.transparent,
        side: BorderSide(color: selected ? colors.accnt : colors.pill),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: verticalPadding,
        ),
      ),
    );
  }
}

/// Row with a title on the left and a control on the right.
class _TitleControlRow extends StatelessWidget {
  const _TitleControlRow({required this.title, required this.control});

  final String title;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'GoogleSans',
              fontSize: 16,
              color: colors.textClr,
            ),
          ),
        ),
        control,
      ],
    );
  }
}

/// Theme cycle card: shows the current mode and cycles on tap.
class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);

    final IconData modeIcon;
    final String modeLabel;
    switch (settings.themeMode) {
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

    return _SettingsCard(
      child: _TitleControlRow(
        title: 'Theme',
        control: _SettingsButton(
          icon: modeIcon,
          label: modeLabel,
          onPressed: settings.cycleThemeMode,
        ),
      ),
    );
  }
}

/// Dock placement card: bottom / top / left / right choice buttons.
class _DockPlacementCard extends StatelessWidget {
  const _DockPlacementCard();

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    final settings = Provider.of<AppSettings>(context);
    final placement = settings.dockPlacement;

    return _SettingsCard(
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
              _SettingsButton(
                icon: Icons.border_bottom_rounded,
                label: 'Bottom',
                selected: placement == 'bottom',
                onPressed: () => settings.setDockPlacement('bottom'),
              ),
              _SettingsButton(
                icon: Icons.border_top_rounded,
                label: 'Top',
                selected: placement == 'top',
                onPressed: () => settings.setDockPlacement('top'),
              ),
              _SettingsButton(
                icon: Icons.border_left_rounded,
                label: 'Left',
                selected: placement == 'left',
                onPressed: () => settings.setDockPlacement('left'),
              ),
              _SettingsButton(
                icon: Icons.border_right_rounded,
                label: 'Right',
                selected: placement == 'right',
                onPressed: () => settings.setDockPlacement('right'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Export / import JSON backup card.
class _DataCard extends StatelessWidget {
  const _DataCard();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      child: Row(
        children: [
          Expanded(
            child: _SettingsButton(
              icon: Icons.arrow_upward_rounded,
              label: 'Export to JSON',
              verticalPadding: 14,
              onPressed: () => ImportExport().exportToJSON(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SettingsButton(
              icon: Icons.arrow_downward_rounded,
              label: 'Import from JSON',
              verticalPadding: 14,
              onPressed: () => ImportExport().importFromJSON(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// The three storage cards: clear-all, save-previews switch, preview cache.
class _StorageSection extends StatelessWidget {
  const _StorageSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      spacing: 12,
      children: [_ClearAllCard(), _SavePreviewsCard(), _PreviewCacheCard()],
    );
  }
}

/// Clear-all card: wipes the entire database after an explicit confirmation.
class _ClearAllCard extends StatelessWidget {
  const _ClearAllCard();

  Future<void> _confirmAndClear(BuildContext context) async {
    final colors = Provider.of<AppColors>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.box,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.pill.withValues(alpha: 0.3)),
        ),
        title: Text(
          'Clear All Codes & Links',
          style: TextStyle(
            fontFamily: 'GoogleSans',
            fontWeight: FontWeight.bold,
            color: colors.textClr,
          ),
        ),
        content: Text(
          'This permanently deletes every note page, entry, and link. '
          'This cannot be undone.',
          style: TextStyle(
            fontFamily: 'GoogleSans',
            color: colors.textClr.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'GoogleSans',
                color: colors.textClr.withValues(alpha: 0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.dangerClr,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'GoogleSans',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final codeGen = context.read<CodeGen>();
    final previewMap = context.read<PreviewMap>();
    await clearAllWithPreviews(codeGen, previewMap);
    if (context.mounted) {
      showDesktopNotification(context, 'All codes and links cleared');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      child: _TitleControlRow(
        title: 'Clear All Codes & Links',
        control: _SettingsButton(
          icon: Icons.delete_sweep_rounded,
          label: 'Clear',
          onPressed: () => _confirmAndClear(context),
        ),
      ),
    );
  }
}

/// Save-previews-locally switch card.
class _SavePreviewsCard extends StatelessWidget {
  const _SavePreviewsCard();

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    final settings = Provider.of<AppSettings>(context);
    return _SettingsCard(
      child: _TitleControlRow(
        title: 'Save Previews Locally',
        control: Switch(
          value: settings.saveImagesLocally,
          onChanged: settings.setSaveImagesLocally,
          activeThumbColor: colors.accnt,
          activeTrackColor: colors.accnt.withValues(alpha: 0.3),
          inactiveThumbColor: colors.thumbClr,
          trackOutlineColor: WidgetStateProperty.all(
            colors.switchTrackOutlineClr,
          ),
        ),
      ),
    );
  }
}

/// Preview-cache card: shows the used size and clears the cache.
///
/// The size future is owned by this State and refreshed whenever
/// [PreviewMap] notifies — it is never re-created inside build().
class _PreviewCacheCard extends StatefulWidget {
  const _PreviewCacheCard();

  @override
  State<_PreviewCacheCard> createState() => _PreviewCacheCardState();
}

class _PreviewCacheCardState extends State<_PreviewCacheCard> {
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
    final colors = Provider.of<AppColors>(context);
    return FutureBuilder<double>(
      future: _sizeFuture,
      builder: (context, snapshot) {
        final size = snapshot.data ?? 0.0;
        return _SettingsCard(
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
              _SettingsButton(
                icon: Icons.delete_sweep_rounded,
                label: 'Clear',
                onPressed: () async {
                  final previewMap = context.read<PreviewMap>();
                  await previewMap.clearImageCache();
                  if (context.mounted) {
                    showDesktopNotification(context, 'Preview cache cleared');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// GitHub link card.
class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      child: _TitleControlRow(
        title: 'Find Memno on GitHub',
        control: _SettingsButton(
          icon: Icons.arrow_outward_rounded,
          label: 'Open',
          onPressed: () {
            launchUrl(Uri.parse('https://github.com/jydv402/memno'));
          },
        ),
      ),
    );
  }
}
