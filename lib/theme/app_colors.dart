import 'package:flutter/material.dart';

class AppColors extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  final _light = LightColors();
  final _dark = DarkColors();

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  Color get bgClr => _isDarkMode ? _dark.bgClr : _light.bgClr;
  Color get fgClr => _isDarkMode ? _dark.fgClr : _light.fgClr;
  Color get box => _isDarkMode ? _dark.box : _light.box;
  Color get accnt => _isDarkMode ? _dark.accnt : _light.accnt;
  Color get textClr => _isDarkMode ? _dark.textClr : _light.textClr;
  Color get iconClr => _isDarkMode ? _dark.iconClr : _light.iconClr;
  Color get btnClr => _isDarkMode ? _dark.btnClr : _light.btnClr;
  Color get btnIcon => _isDarkMode ? _dark.btnIcon : _light.btnIcon;
  Color get pill => _isDarkMode ? _dark.pill : _light.pill;
  Color get grdnt1 => _isDarkMode ? _dark.grdnt1 : _light.grdnt1;
  Color get grdnt2 => _isDarkMode ? _dark.grdnt2 : _light.grdnt2;
}

class LightColors {
  final Color bgClr = Colors.white;
  final Color fgClr = Colors.black;
  final Color box = Colors.white;
  final Color accnt = const Color(0xFFdafc08);
  final Color textClr = Colors.black;
  final Color iconClr = Colors.black;
  final Color btnClr = Colors.black;
  final Color btnIcon = Colors.white;
  final Color pill = const Color(0xFFEDEDED);
  final Color grdnt1 = const Color(0xFFEDEDED);
  final Color grdnt2 = Colors.white;
}

class DarkColors {
  final Color bgClr = Colors.black;
  final Color fgClr = Colors.white;
  final Color box = Colors.black;
  final Color accnt = const Color(0xFFdafc08);
  final Color textClr = Colors.white;
  final Color iconClr = Colors.white;
  final Color btnClr = Colors.white;
  final Color btnIcon = Colors.black;
  final Color pill = const Color(0xFFEDEDED);
  final Color grdnt1 = Colors.black;
  final Color grdnt2 = Colors.black;
}
