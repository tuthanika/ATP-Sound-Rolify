import 'package:flutter/material.dart';

class ThemeModeController {
  static final ThemeModeController _singleton = ThemeModeController._internal();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  factory ThemeModeController() {
    return _singleton;
  }

  ThemeModeController._internal();

  void toggle(bool isCurrentlyDark) {
    themeMode.value = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
  }
}
