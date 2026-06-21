import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:memno/logic/database/toggles_data.dart';

enum AppThemeMode { system, light, dark }

class AppColors extends ChangeNotifier with WidgetsBindingObserver {
  late Box<TogglesData> _togglesBox;

  AppThemeMode _currentThemeMode = AppThemeMode.system;
  bool _isCompactHeader = false;
  bool _saveImagesLocally = true;
  String _dockPlacement = 'left';

  AppColors() {
    init();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangePlatformBrightness() {
    if (_currentThemeMode == AppThemeMode.system) {
      notifyListeners();
    }
    super.didChangePlatformBrightness();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> init() async {
    _togglesBox = await Hive.openBox<TogglesData>('togglesData');

    TogglesData? togglesData = _togglesBox.get(0);

    if (togglesData == null) {
      // Default to system
      _currentThemeMode = AppThemeMode.system;
      _saveImagesLocally = true;
      _dockPlacement = 'left';
      await _togglesBox.put(
        0,
        TogglesData(
          darkMode: false,
          compactHeader: _isCompactHeader,
          themeMode: 0,
          saveImagesLocally: true,
          dockPlacement: 'left',
        ),
      );
    } else {
      _isCompactHeader = togglesData.compactHeader;
      _saveImagesLocally = togglesData.saveImagesLocally;
      _dockPlacement = togglesData.dockPlacement;

      // Migration and Load logic
      if (togglesData.themeMode != null) {
        _currentThemeMode = AppThemeMode.values[togglesData.themeMode!];
      } else {
        // Migrate from old darkMode boolean
        _currentThemeMode = togglesData.darkMode
            ? AppThemeMode.dark
            : AppThemeMode.light;

        // Save the migrated value
        togglesData.themeMode = _currentThemeMode.index;
        await togglesData.save();
      }
    }
    notifyListeners();
  }

  AppThemeMode get themeMode => _currentThemeMode;
  bool get isDarkMode {
    if (_currentThemeMode == AppThemeMode.system) {
      return PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    }
    return _currentThemeMode == AppThemeMode.dark;
  }

  // Getters for application properties
  bool get isCompactHeader => _isCompactHeader;
  bool get saveImagesLocally => _saveImagesLocally;
  String get dockPlacement => _dockPlacement;

  Future<void> setDockPlacement(String placement) async {
    _dockPlacement = placement;
    TogglesData? togglesData = _togglesBox.get(0);
    if (togglesData != null) {
      togglesData.dockPlacement = placement;
      await togglesData.save();
    }
    notifyListeners();
  }

  final _light = LightColors();
  final _dark = DarkColors();

  Future<void> setThemeMode(AppThemeMode mode) async {
    _currentThemeMode = mode;
    TogglesData? togglesData = _togglesBox.get(0);
    if (togglesData != null) {
      togglesData.themeMode = mode.index;
      await togglesData.save();
    }
    notifyListeners();
  }

  Future<void> setSaveImagesLocally(bool value) async {
    _saveImagesLocally = value;
    TogglesData? togglesData = _togglesBox.get(0);
    if (togglesData != null) {
      togglesData.saveImagesLocally = value;
      await togglesData.save();
    }
    notifyListeners();
  }

  Future<void> cycleThemeMode() async {
    final nextIndex =
        (_currentThemeMode.index + 1) % AppThemeMode.values.length;
    await setThemeMode(AppThemeMode.values[nextIndex]);
  }

  Future<void> toggleCompactHeader() async {
    _isCompactHeader = !_isCompactHeader;
    TogglesData? togglesData = _togglesBox.get(0);
    if (togglesData != null) {
      togglesData.compactHeader = _isCompactHeader;
      await togglesData.save();
    }
    notifyListeners();
  }

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
