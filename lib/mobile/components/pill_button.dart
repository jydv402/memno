import 'package:material_ui/material_ui.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:memno/logic/theme/app_settings.dart';
import 'package:provider/provider.dart';

/// A stadium-shaped elevated button with an icon and optional label, used
/// across the mobile entry tiles.
///
/// Every press fires a light haptic through [AppSettings] before the
/// callback, so callers never need to trigger haptics themselves. Colors
/// default to the app palette's pill and text colors and can be overridden
/// per button for special cases such as the black tag badge.
class PillButton extends StatelessWidget {
  /// Creates the button; [icon] is always shown while [label] is optional.
  const PillButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.iconColor,
  });

  /// Icon shown at the leading edge of the pill.
  final IconData icon;

  /// Action performed after the haptic fires.
  final VoidCallback onPressed;

  /// Optional text label after the icon; omit for an icon-only pill.
  final String? label;

  /// Pill background color; defaults to the palette's pill color.
  final Color? backgroundColor;

  /// Label text color; defaults to the palette's text color.
  final Color? foregroundColor;

  /// Icon color; defaults to the palette's text color.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    final settings = Provider.of<AppSettings>(context, listen: false);
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? colors.pill,
        foregroundColor: foregroundColor ?? colors.textClr,
        shape: const StadiumBorder(),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 0,
      ),
      onPressed: () {
        settings.triggerHaptic();
        onPressed();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor ?? colors.textClr, size: 16),
          if (label != null) ...[
            const SizedBox(width: 8),
            Text(
              label!,
              style: const TextStyle(
                fontFamily: 'GoogleSans',
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
