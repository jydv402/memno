import 'package:material_ui/material_ui.dart';
import 'package:memno/logic/theme/app_colors.dart';

/// The lime header capsule of the mobile home screen: the filter toggle on
/// the left and the total note count on the right.
///
/// [TopAccentBox] renders the brand accent color at the top of the home
/// page. The toggle widget is passed in already built ([customToggle]) and
/// is scaled down to fit narrow screens; [length] drives the pluralized
/// count label.
class TopAccentBox extends StatelessWidget {
  /// Creates the header capsule with its accent palette and content.
  const TopAccentBox({
    super.key,
    required this.colors,
    required this.length,
    required this.customToggle,
  });

  /// Palette providing the accent, pill tint, and count text colors;
  /// passed explicitly rather than read from context so the widget stays
  /// cheap to test.
  final AppColors colors;

  /// Total number of visible note pages, driving the count label.
  final int length;

  /// The filter toggle (All, Liked, or Empty) rendered on the left.
  final Widget customToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(2, 0, 2, 4),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(50.0)),
        color: colors.accnt,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Toggle for All, Liked or Empty
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(fit: BoxFit.scaleDown, child: customToggle),
            ),
          ),
          const SizedBox(width: 12),
          // Total number of counts
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              color: colors.accntPill,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              length == 1 ? '$length Code' : '$length Codes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'GoogleSans',
                color: colors.accntText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
