import 'package:flutter/material.dart';
import 'light.dart';
import 'dark.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _theme = lightTheme;

  ThemeData get themeData => _theme;

  bool get isDarkMode => _theme == darkTheme;

  set themeData(ThemeData themeData) {
    _theme = themeData;
    notifyListeners();
  }

  void toggleTheme() {
    if (_theme == lightTheme) {
      _theme = darkTheme;
    } else {
      _theme = lightTheme;
    }
    notifyListeners();
  }
}
