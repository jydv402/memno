import 'dart:ui';

import 'package:flutter/material.dart';
import 'app_settings.dart';

export 'app_settings.dart' show AppThemeMode;

/// Provides theme colors for the application.
/// Depends on [AppSettings] to determine when the dark mode layout should be active.
class AppColors extends ChangeNotifier with WidgetsBindingObserver {
  AppSettings? _settings;

  AppColors() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangePlatformBrightness() {
    if (_settings?.themeMode == AppThemeMode.system) {
      notifyListeners();
    }
    super.didChangePlatformBrightness();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Updates the internal settings reference.
  /// Notifies listeners if the dark mode state or theme mode setting changes.
  void update(AppSettings settings) {
    final oldDarkMode = isDarkMode;
    final oldThemeMode = _settings?.themeMode;
    _settings = settings;
    if (isDarkMode != oldDarkMode || settings.themeMode != oldThemeMode) {
      notifyListeners();
    }
  }

  bool get isDarkMode {
    if (_settings == null) {
      return PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    }
    if (_settings!.themeMode == AppThemeMode.system) {
      return PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    }
    return _settings!.themeMode == AppThemeMode.dark;
  }

  final _light = LightColors();
  final _dark = DarkColors();

  Color get bgClr => isDarkMode ? _dark.bgClr : _light.bgClr;
  Color get fgClr => isDarkMode ? _dark.fgClr : _light.fgClr;
  Color get box => isDarkMode ? _dark.box : _light.box;
  Color get search => isDarkMode ? _dark.search : _light.search;
  Color get accnt => isDarkMode ? _dark.accnt : _light.accnt;
  Color get accntPill => isDarkMode ? _dark.accntPill : _light.accntPill;
  Color get accntText => isDarkMode ? _dark.accntText : _light.accntText;
  Color get textClr => isDarkMode ? _dark.textClr : _light.textClr;
  Color get iconClr => isDarkMode ? _dark.iconClr : _light.iconClr;
  Color get pill => isDarkMode ? _dark.pill : _light.pill;
  Color get toastBg => isDarkMode ? _dark.toastBg : _light.toastBg;
  Color get toastText => isDarkMode ? _dark.toastText : _light.toastText;
  Color get thumbClr => isDarkMode ? _dark.thumbClr : _light.thumbClr;
  Color get switchTrackOutlineClr =>
      isDarkMode ? _dark.switchTrackOutlineClr : _light.switchTrackOutlineClr;
  Color get likeClr => isDarkMode ? _dark.likeClr : _light.likeClr;
  Color get dangerClr => isDarkMode ? _dark.dangerClr : _light.dangerClr;
  Color get linkClr => isDarkMode ? _dark.linkClr : _light.linkClr;
  Color get successClr => isDarkMode ? _dark.successClr : _light.successClr;
  Color get infoClr => isDarkMode ? _dark.infoClr : _light.infoClr;
  Color get warningClr => isDarkMode ? _dark.warningClr : _light.warningClr;
}

class LightColors {
  final Color bgClr = Colors.white;
  final Color fgClr = Colors.black;
  final Color box = Colors.grey[100]!;
  final Color search = Colors.black;
  final Color accnt = const Color(0xFFdafc08);
  final Color accntPill = const Color(0xFFf6fec2);
  final Color accntText = Colors.black;
  final Color textClr = Colors.black;
  final Color iconClr = Colors.black;
  final Color pill = Colors.grey[300]!;
  final Color toastBg = Colors.grey[900]!;
  final Color toastText = Colors.white;
  final Color thumbClr = Colors.black54;
  final Color switchTrackOutlineClr = Colors.black54;

  /// Heart/favorite red.
  final Color likeClr = Colors.red;

  /// Destructive-action red (delete buttons, confirm dialogs).
  final Color dangerClr = Colors.redAccent;

  /// Hyperlink blue used by link previews and link text.
  final Color linkClr = const Color(0xFF4A90D9);

  /// Confirm-button green for the add-entry mode.
  final Color successClr = const Color(0xFF4CAF50);

  /// Confirm-button blue for the edit-entry mode.
  final Color infoClr = const Color(0xFF2196F3);

  /// Confirm-button orange for the edit-title mode.
  final Color warningClr = const Color(0xFFFF9800);
}

class DarkColors {
  final Color bgClr = Colors.black;
  final Color fgClr = Colors.white;
  final Color box = Colors.grey[900]!;
  final Color search = const Color(0xFFdafc08);
  final Color accnt = const Color(0xFFdafc08);
  final Color accntPill = Colors.black;
  final Color accntText = Colors.white;
  final Color textClr = Colors.white;
  final Color iconClr = Colors.white;
  final Color pill = Colors.grey[800]!;
  final Color toastBg = Colors.grey[100]!;
  final Color toastText = Colors.black;
  final Color thumbClr = Colors.white;
  final Color switchTrackOutlineClr = Colors.transparent;

  /// Heart/favorite red.
  final Color likeClr = Colors.red;

  /// Destructive-action red (delete buttons, confirm dialogs).
  final Color dangerClr = Colors.redAccent;

  /// Hyperlink blue used by link previews and link text.
  final Color linkClr = const Color(0xFF4A90D9);

  /// Confirm-button green for the add-entry mode.
  final Color successClr = const Color(0xFF4CAF50);

  /// Confirm-button blue for the edit-entry mode.
  final Color infoClr = const Color(0xFF2196F3);

  /// Confirm-button orange for the edit-title mode.
  final Color warningClr = const Color(0xFFFF9800);
}
