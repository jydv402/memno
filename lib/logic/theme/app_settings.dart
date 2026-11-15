import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:memno/logic/database/toggles_data.dart';

/// Theme-following strategy selected by the user.
///
/// The values double as persisted storage indexes in [TogglesData.themeMode];
/// the order is frozen because existing boxes store the index numerically.
enum AppThemeMode {
  /// Follows the OS light/dark setting live.
  system,

  /// Forces the light palette.
  light,

  /// Forces the dark palette.
  dark,
}

/// Manages and persists user preferences for the whole app.
///
/// [AppSettings] is a [ChangeNotifier] backed by the single-row Hive box
/// `togglesData` (key 0, typed [TogglesData]). Every setter writes the
/// in-memory value first, then persists, then notifies, so listeners always
/// observe a value that is already committed or at worst uncommitted but
/// consistent with what was shown.
class AppSettings extends ChangeNotifier {
  /// Preferences box holding exactly one record under key 0.
  late Box<TogglesData> _togglesBox;

  /// Whether [init] has finished; read by consumers that must not touch the
  /// box before it is opened.
  bool _isInit = false;

  AppThemeMode _currentThemeMode = AppThemeMode.system;
  bool _saveImagesLocally = true;
  String _dockPlacement = 'left';
  bool _enableHaptics = true;

  /// Creates the provider and kicks off asynchronous loading of the stored
  /// preferences; [isInit] flips once the box content has been applied.
  AppSettings() {
    init();
  }

  /// Loads the preferences box and applies the stored record, or writes the
  /// defaults when the box is empty.
  ///
  /// Defaults on first launch: system theme, save previews locally, dock on
  /// the left, haptics on. A legacy record without a [TogglesData.themeMode]
  /// is migrated from the old boolean `darkMode` flag on the fly. Notifies
  /// listeners exactly once at the end so the first frame sees the final
  /// state.
  Future<void> init() async {
    _togglesBox = await Hive.openBox<TogglesData>('togglesData');
    TogglesData? togglesData = _togglesBox.get(0);

    if (togglesData == null) {
      _currentThemeMode = AppThemeMode.system;
      _saveImagesLocally = true;
      _dockPlacement = 'left';
      _enableHaptics = true;
      await _togglesBox.put(
        0,
        TogglesData(
          darkMode: false,
          compactHeader: true, // Deprecated but initialized for safety
          themeMode: 0,
          saveImagesLocally: true,
          dockPlacement: 'left',
          enableHaptics: true,
        ),
      );
    } else {
      _saveImagesLocally = togglesData.saveImagesLocally;
      _dockPlacement = togglesData.dockPlacement;
      _enableHaptics = togglesData.enableHaptics;

      if (togglesData.themeMode != null) {
        _currentThemeMode = AppThemeMode.values[togglesData.themeMode!];
      } else {
        // Migration: records written before themeMode existed store only the
        // boolean darkMode flag; backfill it so the legacy field is read once.
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

  /// Whether [init] has finished loading and applying the stored preferences.
  bool get isInit => _isInit;

  /// The currently active theme-following strategy.
  AppThemeMode get themeMode => _currentThemeMode;

  /// Whether fetched link preview images are also stored on disk.
  bool get saveImagesLocally => _saveImagesLocally;

  /// Dock edge as one of the strings `'bottom'`, `'top'`, `'left'`, or
  /// `'right'`; consumed directly by the dock layout code.
  String get dockPlacement => _dockPlacement;

  /// Whether light haptic feedback should fire on commit interactions.
  bool get enableHaptics => _enableHaptics;

  /// Fires a light haptic pulse on the platform channel if the user has
  /// haptics enabled; a no-op otherwise.
  ///
  /// Call this on the commit frame of a user action, never inside animation
  /// callbacks, so a single interaction produces a single pulse.
  void triggerHaptic() {
    if (_enableHaptics) {
      HapticFeedback.lightImpact();
    }
  }

  /// Persists [value] as the haptics preference and notifies listeners.
  Future<void> setEnableHaptics(bool value) async {
    _enableHaptics = value;
    TogglesData? togglesData = _togglesBox.get(0);
    if (togglesData != null) {
      togglesData.enableHaptics = value;
      await togglesData.save();
    }
    notifyListeners();
  }

  /// Persists [mode] as the theme strategy and notifies listeners so both
  /// the material theme and the app palette flip together.
  Future<void> setThemeMode(AppThemeMode mode) async {
    _currentThemeMode = mode;
    TogglesData? togglesData = _togglesBox.get(0);
    if (togglesData != null) {
      togglesData.themeMode = mode.index;
      await togglesData.save();
    }
    notifyListeners();
  }

  /// Advances the theme strategy to the next value of [AppThemeMode],
  /// wrapping from dark back to system, and persists it.
  Future<void> cycleThemeMode() async {
    final nextIndex =
        (_currentThemeMode.index + 1) % AppThemeMode.values.length;
    await setThemeMode(AppThemeMode.values[nextIndex]);
  }

  /// Persists [placement] as the dock edge; callers must pass one of
  /// `'bottom'`, `'top'`, `'left'`, or `'right'`.
  Future<void> setDockPlacement(String placement) async {
    _dockPlacement = placement;
    TogglesData? togglesData = _togglesBox.get(0);
    if (togglesData != null) {
      togglesData.dockPlacement = placement;
      await togglesData.save();
    }
    notifyListeners();
  }

  /// Persists [value] as the local preview-image preference and notifies
  /// listeners; the preview layer consults it on every fetch and load.
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
