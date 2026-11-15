import 'package:material_ui/material_ui.dart';
import 'package:memno/logic/theme/app_settings.dart';
import 'package:provider/provider.dart';

/// An app bar whose back button fires a light haptic before popping, used
/// across the mobile screens.
///
/// Behaves like a plain [AppBar] otherwise: [title], [backgroundColor],
/// [foregroundColor], and [surfaceTintColor] pass through, and a back
/// button appears only when [implyLeading] is set and navigation can pop.
class HapticAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Centered title widget; omit for a title-less bar.
  final Widget? title;

  /// Custom leading widget; when null, a haptic back button is supplied
  /// whenever [implyLeading] is set and the route can pop.
  final Widget? leading;

  /// Bar background color; null uses the theme default.
  final Color? backgroundColor;

  /// Bar foreground (icon) color; null uses the theme default.
  final Color? foregroundColor;

  /// Elevation tint color; null uses the theme default.
  final Color? surfaceTintColor;

  /// Whether the automatic back button should be supplied when [leading]
  /// is null and the route can pop.
  final bool implyLeading;

  /// Creates the bar; all parameters are optional because some screens
  /// render a bare colored bar.
  const HapticAppBar({
    super.key,
    this.title,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
    this.surfaceTintColor,
    this.implyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      surfaceTintColor: surfaceTintColor,
      automaticallyImplyLeading: false,
      leading:
          leading ??
          ((implyLeading && Navigator.canPop(context))
              ? BackButton(
                  color: foregroundColor,
                  onPressed: () {
                    Provider.of<AppSettings>(
                      context,
                      listen: false,
                    ).triggerHaptic();
                    Navigator.of(context).maybePop();
                  },
                )
              : null),
    );
  }

  /// Height of the bar: the standard toolbar height.
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
