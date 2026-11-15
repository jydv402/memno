import 'package:material_ui/material_ui.dart';

/// A large section heading shown between settings groups.
class SettingsTitle extends StatelessWidget {
  /// Heading text; the full section title as displayed.
  final String title;

  /// Heading color, passed by the caller so the page controls emphasis.
  final Color textClr;

  /// Creates the heading with the required [title] and [textClr].
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
