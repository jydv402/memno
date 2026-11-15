import 'package:material_ui/material_ui.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:update_checker_bottom_sheet/update_checker_bottom_sheet.dart';

/// Holds the two static update-sheet themes and mirrors the app palette.
///
/// The accent colors are read from [LightColors] and [DarkColors] directly
/// rather than duplicated as literals, so restyling the accent in
/// `app_colors.dart` restyles the update sheet in the same build.
class AppUpdateTheme {
  /// Update-sheet theme matching the app's light palette.
  static final UpdateCheckerThemeData lightTheme = UpdateCheckerThemeData(
    backgroundColor: Colors.white,
    textColor: Colors.black,
    secondaryTextColor: Colors.black.withValues(alpha: 0.6),
    accentColor: LightColors().accnt,
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

  /// Update-sheet theme matching the app's dark palette.
  static final UpdateCheckerThemeData darkTheme = UpdateCheckerThemeData(
    backgroundColor: Colors.grey[900]!,
    textColor: Colors.white,
    secondaryTextColor: Colors.white.withValues(alpha: 0.6),
    accentColor: DarkColors().accnt,
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

/// Checks the GitHub repository for a newer release and opens the update
/// sheet when one is available.
///
/// The sheet theme is selected from [AppUpdateTheme] using the caller's
/// current dark-mode state, read from [AppColors] without subscribing.
/// Set [showIfUpToDate] to true to also surface the "already up to date"
/// confirmation, which is useful when the user triggers the check from
/// settings. The check itself is delegated to `UpdateChecker.check`.
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
