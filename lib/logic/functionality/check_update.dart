import 'package:flutter/material.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:update_checker_bottom_sheet/update_checker_bottom_sheet.dart';

/// Manages application update themes and checks for updates on GitHub.
class AppUpdateTheme {
  static final UpdateCheckerThemeData lightTheme = UpdateCheckerThemeData(
    backgroundColor: Colors.white,
    textColor: Colors.black,
    secondaryTextColor: Colors.black.withValues(alpha: 0.6),
    accentColor: const Color(0xFFdafc08),
    accentTextColor: Colors.black,
    pillColor: Colors.grey[300]!,
    boxColor: Colors.grey[100]!,
    borderRadius: 35.0,
    buttonBorderRadius: 50.0,
    titleStyle: const TextStyle(
      fontFamily: 'GoogleSans',
      fontWeight: FontWeight.bold,
      color: Colors.black,
      fontSize: 32,
    ),
    versionStyle: const TextStyle(
      fontFamily: 'GoogleSans',
      color: Colors.black,
    ),
    whatsNewStyle: const TextStyle(
      fontFamily: 'GoogleSans',
      fontWeight: FontWeight.w600,
      color: Colors.black,
      fontSize: 24,
    ),
    contentStyle: const TextStyle(
      fontFamily: 'GoogleSans',
      color: Colors.black,
    ),
    buttonTextStyle: const TextStyle(
      fontFamily: 'GoogleSans',
      fontWeight: FontWeight.w600,
      fontSize: 18,
    ),
    showBorder: true,
    showHandle: true,
  );

  static final UpdateCheckerThemeData darkTheme = UpdateCheckerThemeData(
    backgroundColor: Colors.grey[900]!,
    textColor: Colors.white,
    secondaryTextColor: Colors.white.withValues(alpha: 0.6),
    accentColor: const Color(0xFFdafc08),
    accentTextColor: Colors.black,
    pillColor: Colors.grey[800]!,
    boxColor: Colors.grey[900]!,
    borderRadius: 35.0,
    buttonBorderRadius: 50.0,
    titleStyle: const TextStyle(
      fontFamily: 'GoogleSans',
      fontWeight: FontWeight.bold,
      color: Colors.white,
      fontSize: 32,
    ),
    versionStyle: const TextStyle(
      fontFamily: 'GoogleSans',
      color: Colors.white,
    ),
    whatsNewStyle: const TextStyle(
      fontFamily: 'GoogleSans',
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontSize: 24,
    ),
    contentStyle: const TextStyle(
      fontFamily: 'GoogleSans',
      color: Colors.white,
    ),
    buttonTextStyle: const TextStyle(
      fontFamily: 'GoogleSans',
      fontWeight: FontWeight.w600,
      fontSize: 18,
    ),
    showBorder: true,
    showHandle: true,
  );
}

/// Checks and triggers the update checker flow.
Future<void> checkAppUpdate(
  BuildContext context,
  bool showIfUpToDate,
  UpdateCheckerStyle updateCheckerStyle,
) async {
  final colors = Provider.of<AppColors>(context, listen: false);

  UpdateChecker.theme = colors.isDarkMode
      ? AppUpdateTheme.darkTheme
      : AppUpdateTheme.lightTheme;

  await UpdateChecker.check(
    context,
    githubRepo: "jydv402/memno",
    showIfUpToDate: showIfUpToDate,
    style: updateCheckerStyle,
  );
}
