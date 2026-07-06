import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:memno/logic/database/toggles_data.dart';

enum AppThemeMode { system, light, dark }

/// Manages and persists user preferences and configuration.
class AppSettings extends ChangeNotifier {
  late Box<TogglesData> _togglesBox;
  bool _isInit = false;

  AppThemeMode _currentThemeMode = AppThemeMode.system;
  bool _saveImagesLocally = true;
  String _dockPlacement = 'left';

  AppSettings() {
    init();
  }

  /// Initializes the Hive preferences box.
  Future<void> init() async {
    _togglesBox = await Hive.openBox<TogglesData>('togglesData');
    TogglesData? togglesData = _togglesBox.get(0);

    if (togglesData == null) {
      _currentThemeMode = AppThemeMode.system;
      _saveImagesLocally = true;
      _dockPlacement = 'left';
      await _togglesBox.put(
        0,
        TogglesData(
          darkMode: false,
          compactHeader: true, // Deprecated but initialized for safety
          themeMode: 0,
          saveImagesLocally: true,
          dockPlacement: 'left',
        ),
      );
    } else {
      _saveImagesLocally = togglesData.saveImagesLocally;
      _dockPlacement = togglesData.dockPlacement;

      if (togglesData.themeMode != null) {
        _currentThemeMode = AppThemeMode.values[togglesData.themeMode!];
      } else {
        _currentThemeMode = togglesData.darkMode
            ? AppThemeMode.dark
            : AppThemeMode.light;
        togglesData.themeMode = _currentThemeMode.index;
        await togglesData.save();
      }
    }
    _isInit = true;
    notifyListeners();
  }

  bool get isInit => _isInit;
  AppThemeMode get themeMode => _currentThemeMode;
  bool get saveImagesLocally => _saveImagesLocally;
  String get dockPlacement => _dockPlacement;

  Future<void> setThemeMode(AppThemeMode mode) async {
    _currentThemeMode = mode;
    TogglesData? togglesData = _togglesBox.get(0);
    if (togglesData != null) {
      togglesData.themeMode = mode.index;
      await togglesData.save();
    }
    notifyListeners();
  }

  Future<void> cycleThemeMode() async {
    final nextIndex =
        (_currentThemeMode.index + 1) % AppThemeMode.values.length;
    await setThemeMode(AppThemeMode.values[nextIndex]);
  }

  Future<void> setDockPlacement(String placement) async {
    _dockPlacement = placement;
    TogglesData? togglesData = _togglesBox.get(0);
    if (togglesData != null) {
      togglesData.dockPlacement = placement;
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
}
