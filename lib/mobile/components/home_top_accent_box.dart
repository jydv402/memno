import 'package:flutter/material.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:memno/mobile/home.dart';

class TopAccentBox extends StatelessWidget {
  const TopAccentBox({
    super.key,
    required this.colors,
    required this.length,
    required this.filter,
    required this.customToggle,
  });

  final AppColors colors;
  final int length;
  final Filters filter;
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
