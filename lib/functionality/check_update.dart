import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:update_checker_bottom_sheet/update_checker_bottom_sheet.dart';
import 'package:memno/theme/app_colors.dart';

/// Checks for updates and displays the update checker bottom sheet.
///
/// [showIfUpToDate] is a function that returns true if we should show the bottom sheet
/// even when the app is already on the latest version.
Future<void> checkAppUpdate(BuildContext context, bool showIfUpToDate) async {
  final colors = Provider.of<AppColors>(context, listen: false);

  await UpdateChecker.check(
    context,
    githubRepo: "jydv402/memno",
    showIfUpToDate: showIfUpToDate,
    backgroundColor: colors.isDarkMode ? Colors.grey[900] : Colors.white,
    textColor: colors.textClr,
    secondaryTextColor: colors.textClr.withValues(alpha: 0.6),
    accentColor: colors.accnt,
    accentTextColor: Colors.black,
    pillColor: colors.pill,
    boxColor: colors.box,
    borderRadius: 35.0,
    buttonBorderRadius: 50.0,
    titleStyle: TextStyle(
      fontFamily: 'GoogleSans',
      fontWeight: FontWeight.bold,
      color: colors.textClr,
      fontSize: 32,
    ),
    versionStyle: TextStyle(fontFamily: 'GoogleSans', color: colors.textClr),
    whatsNewStyle: TextStyle(
      fontFamily: 'GoogleSans',
      fontWeight: FontWeight.w600,
      color: colors.textClr,
      fontSize: 24,
    ),
    contentStyle: TextStyle(fontFamily: 'GoogleSans', color: colors.textClr),
    buttonTextStyle: TextStyle(
      fontFamily: 'GoogleSans',
      fontWeight: FontWeight.w600,
      fontSize: 18,
    ),
    showBorder: true,
    showHandle: true,
  );
}
