import 'package:flutter/material.dart';

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
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16),
        ),
        onPressed: onPressed,
        child: Icon(icon, color: Theme.of(context).colorScheme.onPrimary));
  }
}
