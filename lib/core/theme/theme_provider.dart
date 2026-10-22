import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// System (the default) follows the device; Light and Dark override it and are saved.
class ThemeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';
  static const _legacyKey = 'is_dark_theme'; // older builds stored only light/dark

  @override
  ThemeMode build() {
    return ThemeMode.system;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  /// The saved choice, or System when nothing was ever chosen.
  static ThemeMode fromPrefs(SharedPreferences prefs) {
    switch (prefs.getString(_key)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
    }
    final legacy = prefs.getBool(_legacyKey);
    if (legacy == null) return ThemeMode.system;
    return legacy ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> loadTheme() async {
    state = fromPrefs(await SharedPreferences.getInstance());
  }

  /// Dark → Light → System → Dark, the order the theme button steps through.
  static ThemeMode nextAfter(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return ThemeMode.dark;
      case ThemeMode.dark:
        return ThemeMode.light;
      case ThemeMode.light:
        return ThemeMode.system;
    }
  }

  Future<void> cycle() async {
    final next = nextAfter(state);
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, next.name);
    await prefs.remove(_legacyKey);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);
