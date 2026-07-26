import 'package:flutter/material.dart';
import 'package:memno/logic/theme/app_settings.dart';
import 'package:provider/provider.dart';

class HapticAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? surfaceTintColor;
  final bool implyLeading;

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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
