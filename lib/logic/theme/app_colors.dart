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
  /// Notifies listeners *only* if the dark mode state actually toggles.
  void update(AppSettings settings) {
    final oldDarkMode = isDarkMode;
    _settings = settings;
    if (isDarkMode != oldDarkMode) {
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
  Color get btnClr => isDarkMode ? _dark.btnClr : _light.btnClr;
  Color get btnIcon => isDarkMode ? _dark.btnIcon : _light.btnIcon;
  Color get pill => isDarkMode ? _dark.pill : _light.pill;
  Color get toastBg => isDarkMode ? _dark.toastBg : _light.toastBg;
  Color get toastText => isDarkMode ? _dark.toastText : _light.toastText;
  Color get thumbClr => isDarkMode ? _dark.thumbClr : _light.thumbClr;
  Color get switchTrackOutlineClr =>
      isDarkMode ? _dark.switchTrackOutlineClr : _light.switchTrackOutlineClr;
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
  final Color btnClr = Colors.black;
  final Color btnIcon = Colors.white;
  final Color pill = Colors.grey[300]!;
  final Color toastBg = Colors.grey[900]!;
  final Color toastText = Colors.white;
  final Color thumbClr = Colors.black54;
  final Color switchTrackOutlineClr = Colors.black54;
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
  final Color btnClr = Colors.grey[800]!.withValues(alpha: 0.5);
  final Color btnIcon = Colors.white;
  final Color pill = Colors.grey[800]!;
  final Color toastBg = Colors.grey[100]!;
  final Color toastText = Colors.black;
  final Color thumbClr = Colors.white;
  final Color switchTrackOutlineClr = Colors.transparent;
}
