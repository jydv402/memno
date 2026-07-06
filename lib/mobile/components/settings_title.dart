import 'package:flutter/material.dart';

class SettingsTitle extends StatelessWidget {
  final String title;
  final Color textClr;
  const SettingsTitle({super.key, required this.title, required this.textClr});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 0, 16),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'GoogleSans',
          fontSize: 28,
          color: textClr,
        ),
      ),
    );
  }
}
