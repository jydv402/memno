import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:memno/database/toggles_data.dart';

class AppColors extends ChangeNotifier {
  late Box<TogglesData> _togglesBox;
  bool _isDarkMode = false;

  AppColors() {
    init();
  }

  Future<void> init() async {
    Hive.registerAdapter(TogglesDataAdapter());
    _togglesBox = await Hive.openBox<TogglesData>('togglesData');

    TogglesData? togglesData = _togglesBox.get(0);
    _isDarkMode = togglesData?.darkMode ?? false;
    notifyListeners();
  }

  bool get isDarkMode => _isDarkMode;

  final _light = LightColors();
  final _dark = DarkColors();

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    TogglesData togglesData = TogglesData(darkMode: _isDarkMode);
    await _togglesBox.put(0, togglesData);
    notifyListeners();
  }

  Color get bgClr => _isDarkMode ? _dark.bgClr : _light.bgClr;
  Color get fgClr => _isDarkMode ? _dark.fgClr : _light.fgClr;
  Color get box => _isDarkMode ? _dark.box : _light.box;
  Color get accnt => _isDarkMode ? _dark.accnt : _light.accnt;
  Color get accntPill => _isDarkMode ? _dark.accntPill : _light.accntPill;
  Color get accntText => _isDarkMode ? _dark.accntText : _light.accntText;
  Color get textClr => _isDarkMode ? _dark.textClr : _light.textClr;
  Color get iconClr => _isDarkMode ? _dark.iconClr : _light.iconClr;
  Color get btnClr => _isDarkMode ? _dark.btnClr : _light.btnClr;
  Color get btnIcon => _isDarkMode ? _dark.btnIcon : _light.btnIcon;
  Color get pill => _isDarkMode ? _dark.pill : _light.pill;
}

class LightColors {
  final Color bgClr = Colors.white;
  final Color fgClr = Colors.black;
  final Color box = Colors.grey[100]!;
  final Color accnt = const Color(0xFFdafc08);
  final Color accntPill = const Color(0xFFf6fec2);
  final Color accntText = Colors.black;
  final Color textClr = Colors.black;
  final Color iconClr = Colors.black;
  final Color btnClr = Colors.black;
  final Color btnIcon = Colors.white;
  final Color pill = Colors.grey[300]!;
}

class DarkColors {
  final Color bgClr = Colors.black;
  final Color fgClr = Colors.white;
  final Color box = Colors.grey[900]!;
  final Color accnt = const Color(0xFFdafc08);
  final Color accntPill = Colors.black;
  final Color accntText = Colors.white;
  final Color textClr = Colors.white;
  final Color iconClr = Colors.white;
  final Color btnClr = Colors.grey[800]!.withOpacity(0.5);
  final Color btnIcon = Colors.white;
  final Color pill = Colors.grey[800]!;
}
