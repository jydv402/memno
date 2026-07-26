import 'package:flutter/material.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:memno/logic/theme/app_settings.dart';
import 'package:provider/provider.dart';

class SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? trailingIcon;
  final VoidCallback? onTap;

  // For Switch functionality
  final bool? value;
  final ValueChanged<bool>? onChanged;

  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.trailingIcon,
    this.onTap,
    this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context, listen: false);
    final colors = Provider.of<AppColors>(context);

    // If it's a switch tile, tapping the whole tile should toggle the switch
    final effectiveOnTap =
        onTap ??
        (onChanged != null && value != null ? () => onChanged!(!value!) : null);

    return Container(
      height: 100,
      margin: const EdgeInsets.fromLTRB(2, 4, 2, 4),
      child: Material(
        color: colors.box,
        borderRadius: BorderRadius.circular(50),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: effectiveOnTap != null
              ? () {
                  settings.triggerHaptic();
                  effectiveOnTap();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 24, 16),
            child: Row(
              children: [
                // Title and optional subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'GoogleSans',
                          fontSize: 18,
                          color: colors.textClr,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontFamily: 'GoogleSans',
                            fontSize: 14,
                            color: colors.textClr.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Trailing widget (Switch, custom widget, or Icon)
                if (value != null && onChanged != null)
                  Switch(
                    value: value!,
                    onChanged: (val) {
                      settings.triggerHaptic();
                      onChanged!(val);
                    },
                    trackColor: WidgetStateProperty.resolveWith<Color?>((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return colors.accnt;
                      }
                      return colors.pill;
                    }),
                    thumbColor: WidgetStateProperty.resolveWith<Color?>((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.black;
                      }
                      return colors.isDarkMode ? Colors.white : Colors.black;
                    }),
                    trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected) &&
                          !colors.isDarkMode) {
                        return Colors.black;
                      }
                      return colors.switchTrackOutlineClr;
                    }),
                    thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Icon(
                          Icons.check_rounded,
                          color: Color(0xFFdafc08),
                          size: 16,
                        );
                      }
                      return Icon(
                        Icons.close_rounded,
                        color: colors.isDarkMode ? Colors.black : Colors.white,
                        size: 16,
                      );
                    }),
                    overlayColor: WidgetStateProperty.all(
                      colors.accnt.withValues(alpha: 0.2),
                    ),
                  )
                else if (trailing != null)
                  trailing!
                else if (trailingIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(trailingIcon, color: colors.textClr),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
