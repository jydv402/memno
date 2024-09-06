import 'package:flutter/material.dart';
import 'package:memno/theme/app_colors.dart';
import 'package:provider/provider.dart';

class InnerPageButton extends StatelessWidget {
  const InnerPageButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.btnClr,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16),
        ),
        onPressed: onPressed,
        child: Icon(icon, color: colors.btnIcon));
  }
}
