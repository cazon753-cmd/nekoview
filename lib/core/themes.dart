import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, amoled }

class ThemeProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  AppThemeMode _themeMode = AppThemeMode.dark;

  ThemeProvider(this._prefs) {
    final savedTheme = _prefs.getString('app_theme') ?? 'dark';
    switch (savedTheme) {
      case 'light':
        _themeMode = AppThemeMode.light;
        break;
      case 'amoled':
        _themeMode = AppThemeMode.amoled;
        break;
      case 'dark':
      default:
        _themeMode = AppThemeMode.dark;
        break;
    }
  }

  AppThemeMode get currentTheme => _themeMode;

  ThemeData getThemeData() {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeData(brightness: Brightness.light, colorSchemeSeed: Colors.indigo, useMaterial3: true);
      case AppThemeMode.dark:
        return ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF121212), colorSchemeSeed: Colors.indigo, useMaterial3: true);
      case AppThemeMode.amoled:
        return ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: Colors.black, appBarTheme: const AppBarTheme(backgroundColor: Colors.black), drawerTheme: const DrawerThemeData(backgroundColor: Colors.black), colorSchemeSeed: Colors.indigo, useMaterial3: true);
    }
  }

  void cycleTheme() {
    if (_themeMode == AppThemeMode.light) {
      _themeMode = AppThemeMode.dark;
      _prefs.setString('app_theme', 'dark');
    } else if (_themeMode == AppThemeMode.dark) {
      _themeMode = AppThemeMode.amoled;
      _prefs.setString('app_theme', 'amoled');
    } else {
      _themeMode = AppThemeMode.light;
      _prefs.setString('app_theme', 'light');
    }
    notifyListeners();
  }

  String get themeName => _themeMode == AppThemeMode.light ? "Light Theme" : _themeMode == AppThemeMode.dark ? "Dark Theme" : "AMOLED Theme";
}