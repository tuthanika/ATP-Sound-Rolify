import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeController {
  static final ThemeModeController _singleton = ThemeModeController._internal();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);
  final ValueNotifier<int> sortMode = ValueNotifier(0); // 0: A-Z, 1: Newest
  final ValueNotifier<bool> isCollapsed = ValueNotifier(false);

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
    
    sortMode.value = prefs.getInt('sortMode') ?? 0;
    isCollapsed.value = prefs.getBool('isCollapsed') ?? false;
  }

  Future<void> setSortMode(int mode) async {
    sortMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sortMode', mode);
  }

  Future<void> setCollapsed(bool collapsed) async {
    isCollapsed.value = collapsed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCollapsed', collapsed);
  }

  Future<void> toggle(bool isCurrentlyDark) async {
    final newTheme = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
    themeMode.value = newTheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', newTheme == ThemeMode.dark ? 'dark' : 'light');
  }
}
