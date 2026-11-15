import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'app_settings.dart';

export 'app_settings.dart' show AppThemeMode;

/// Provides the two app palettes and resolves them by theme mode.
///
/// [AppColors] is a [ChangeNotifier] that depends on [AppSettings] to decide
/// when the dark palette should be active. Any widget can read it through
/// Provider; reading with `listen: true` rebuilds whenever the resolved mode
/// flips, for example when the user cycles themes or the OS crosses the
/// light/dark boundary while [AppThemeMode.system] is selected.
class AppColors extends ChangeNotifier with WidgetsBindingObserver {
  /// User settings consulted on every color resolution; null until the
  /// composition root wires it in via [update], in which case the OS
  /// platform brightness alone decides the palette.
  AppSettings? _settings;

  /// Creates the provider and starts observing platform brightness changes
  /// so the palette flips live while [AppThemeMode.system] is selected.
  AppColors() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Notifies listeners when the OS switches between light and dark mode and
  /// the user follows the system theme; explicit theme modes are unaffected.
  ///
  /// Re-reading [isDarkMode] after this call yields the new value, so every
  /// listening widget repaints with the other palette.
  @override
  void didChangePlatformBrightness() {
    if (_settings?.themeMode == AppThemeMode.system) {
      notifyListeners();
    }
    super.didChangePlatformBrightness();
  }

  /// Detaches from the widget bindings observer; must be called exactly once
  /// when the provider leaves the tree to avoid leaking the observer.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Wires in [settings] and notifies listeners if the palette resolution
  /// actually changed.
  ///
  /// A change is detected by comparing the dark-mode resolution and the
  /// theme mode before and after the swap, so repeated calls with an
  /// equivalent [AppSettings] never trigger spurious rebuilds.
  void update(AppSettings settings) {
    final oldDarkMode = isDarkMode;
    final oldThemeMode = _settings?.themeMode;
    _settings = settings;
    if (isDarkMode != oldDarkMode || settings.themeMode != oldThemeMode) {
      notifyListeners();
    }
  }

  /// Whether the dark palette is currently the active one.
  ///
  /// Resolution order: an explicit [AppThemeMode.light] or
  /// [AppThemeMode.dark] setting wins, otherwise the platform brightness is
  /// queried. Called on every token read, so it must stay cheap.
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

  /// App background color behind every page and dialog.
  Color get bgClr => isDarkMode ? _dark.bgClr : _light.bgClr;

  /// Foreground color for raw surfaces such as the accent top bar.
  Color get fgClr => isDarkMode ? _dark.fgClr : _light.fgClr;

  /// Card, tile, and dialog surface color sitting on top of [bgClr].
  Color get box => isDarkMode ? _dark.box : _light.box;

  /// Search-field surface color; also doubles as the accent in dark mode.
  Color get search => isDarkMode ? _dark.search : _light.search;

  /// Lime accent color for highlights, selected buttons, and thumbs.
  Color get accnt => isDarkMode ? _dark.accnt : _light.accnt;

  /// Tinted pill color for chips resting on the accent color.
  Color get accntPill => isDarkMode ? _dark.accntPill : _light.accntPill;

  /// Text color used on top of [accnt] and [accntPill] surfaces.
  Color get accntText => isDarkMode ? _dark.accntText : _light.accntText;

  /// Primary text color for regular content.
  Color get textClr => isDarkMode ? _dark.textClr : _light.textClr;

  /// Icon color; equals [textClr] in both palettes but stays a separate
  /// token so icons and text can diverge later without touching call sites.
  Color get iconClr => isDarkMode ? _dark.iconClr : _light.iconClr;

  /// Subtle filled-pill color for secondary chips and hover backgrounds.
  Color get pill => isDarkMode ? _dark.pill : _light.pill;

  /// Background color of toasts and tooltips.
  Color get toastBg => isDarkMode ? _dark.toastBg : _light.toastBg;

  /// Text color on [toastBg] surfaces.
  Color get toastText => isDarkMode ? _dark.toastText : _light.toastText;

  /// Switch thumb color in its unselected state.
  Color get thumbClr => isDarkMode ? _dark.thumbClr : _light.thumbClr;

  /// Outline color drawn around a switch track in its unselected state.
  Color get switchTrackOutlineClr =>
      isDarkMode ? _dark.switchTrackOutlineClr : _light.switchTrackOutlineClr;

  /// Heart red for favorite markers and the like action.
  Color get likeClr => isDarkMode ? _dark.likeClr : _light.likeClr;

  /// Red for destructive actions such as delete buttons and confirm dialogs.
  Color get dangerClr => isDarkMode ? _dark.dangerClr : _light.dangerClr;

  /// Hyperlink blue for link text, underline decorations, and link previews.
  Color get linkClr => isDarkMode ? _dark.linkClr : _light.linkClr;

  /// Green confirm-button color in the add-entry mode.
  Color get successClr => isDarkMode ? _dark.successClr : _light.successClr;

  /// Blue confirm-button color in the edit-entry mode.
  Color get infoClr => isDarkMode ? _dark.infoClr : _light.infoClr;

  /// Orange confirm-button color in the edit-title mode.
  Color get warningClr => isDarkMode ? _dark.warningClr : _light.warningClr;
}

/// The light palette; every value is fixed and stateless.
///
/// Instantiated once by [AppColors] and never mutated, so the values can be
/// treated as compile-time constants by readers.
class LightColors {
  /// App background color behind every page and dialog: pure white.
  final Color bgClr = Colors.white;

  /// Foreground color for raw surfaces such as the accent top bar: black.
  final Color fgClr = Colors.black;

  /// Card and dialog surface: the nearest grey step below white.
  final Color box = Colors.grey[100]!;

  /// Search-field surface: black on the light theme.
  final Color search = Colors.black;

  /// Lime accent, the brand color of the app (hex 0xFFDAFC08).
  final Color accnt = const Color(0xFFdafc08);

  /// Pale lime pill tint derived from [accnt] for chips on accent surfaces.
  final Color accntPill = const Color(0xFFf6fec2);

  /// Text on accent surfaces: black for contrast against the lime accent.
  final Color accntText = Colors.black;

  /// Primary text color: black.
  final Color textClr = Colors.black;

  /// Icon color: black.
  final Color iconClr = Colors.black;

  /// Subtle filled-pill color: mid grey.
  final Color pill = Colors.grey[300]!;

  /// Toast background: near-black so toasts stand out on the white theme.
  final Color toastBg = Colors.grey[900]!;

  /// Toast text: white on the near-black toast background.
  final Color toastText = Colors.white;

  /// Unselected switch thumb: translucent black.
  final Color thumbClr = Colors.black54;

  /// Unselected switch track outline: translucent black.
  final Color switchTrackOutlineClr = Colors.black54;

  /// Heart red for favorite markers and the like action.
  final Color likeClr = Colors.red;

  /// Red for destructive actions such as delete buttons and confirm dialogs.
  final Color dangerClr = Colors.redAccent;

  /// Hyperlink blue used by link text and previews (hex 0xFF4A90D9).
  final Color linkClr = const Color(0xFF4A90D9);

  /// Green confirm-button color in the add-entry mode (hex 0xFF4CAF50).
  final Color successClr = const Color(0xFF4CAF50);

  /// Blue confirm-button color in the edit-entry mode (hex 0xFF2196F3).
  final Color infoClr = const Color(0xFF2196F3);

  /// Orange confirm-button color in the edit-title mode (hex 0xFFFF9800).
  final Color warningClr = const Color(0xFFFF9800);
}

/// The dark palette; every value is fixed and stateless.
///
/// Instantiated once by [AppColors] and never mutated. Note that [search]
/// reuses the lime accent so the search surface glows on the black theme.
class DarkColors {
  /// App background color behind every page and dialog: pure black.
  final Color bgClr = Colors.black;

  /// Foreground color for raw surfaces such as the accent top bar: white.
  final Color fgClr = Colors.white;

  /// Card and dialog surface: near-black grey step above the background.
  final Color box = Colors.grey[900]!;

  /// Search-field surface: reuses the lime accent for a glowing look.
  final Color search = const Color(0xFFdafc08);

  /// Lime accent, the brand color of the app (hex 0xFFDAFC08).
  final Color accnt = const Color(0xFFdafc08);

  /// Tinted pill color for chips resting on accent surfaces: black.
  final Color accntPill = Colors.black;

  /// Text on accent surfaces: white.
  final Color accntText = Colors.white;

  /// Primary text color: white.
  final Color textClr = Colors.white;

  /// Icon color: white.
  final Color iconClr = Colors.white;

  /// Subtle filled-pill color: dark grey.
  final Color pill = Colors.grey[800]!;

  /// Toast background: near-white so toasts stand out on the black theme.
  final Color toastBg = Colors.grey[100]!;

  /// Toast text: black on the near-white toast background.
  final Color toastText = Colors.black;

  /// Unselected switch thumb: white.
  final Color thumbClr = Colors.white;

  /// Unselected switch track outline: transparent, so dark tracks blend in.
  final Color switchTrackOutlineClr = Colors.transparent;

  /// Heart red for favorite markers and the like action.
  final Color likeClr = Colors.red;

  /// Red for destructive actions such as delete buttons and confirm dialogs.
  final Color dangerClr = Colors.redAccent;

  /// Hyperlink blue used by link text and previews (hex 0xFF4A90D9).
  final Color linkClr = const Color(0xFF4A90D9);

  /// Green confirm-button color in the add-entry mode (hex 0xFF4CAF50).
  final Color successClr = const Color(0xFF4CAF50);

  /// Blue confirm-button color in the edit-entry mode (hex 0xFF2196F3).
  final Color infoClr = const Color(0xFF2196F3);

  /// Orange confirm-button color in the edit-title mode (hex 0xFFFF9800).
  final Color warningClr = const Color(0xFFFF9800);
}
