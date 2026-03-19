import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeController {
  static final ThemeModeController _singleton = ThemeModeController._internal();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  factory ThemeModeController() {
    return _singleton;
  }

  ThemeModeController._internal();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('themeMode');
    if (savedTheme == 'dark') {
      themeMode.value = ThemeMode.dark;
    } else if (savedTheme == 'light') {
      themeMode.value = ThemeMode.light;
    }
  }

  Future<void> toggle(bool isCurrentlyDark) async {
    final newTheme = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
    themeMode.value = newTheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', newTheme == ThemeMode.dark ? 'dark' : 'light');
  }
}
