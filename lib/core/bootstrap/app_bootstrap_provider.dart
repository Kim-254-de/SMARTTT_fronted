import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/locale_provider.dart';
import '../theme/theme_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final appBootstrapProvider = FutureProvider<void>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    final isDark = prefs.getBool('is_dark_theme') ?? false;
    ref.read(themeProvider.notifier).setThemeMode(
          isDark ? ThemeMode.dark : ThemeMode.light,
        );

    final localeCode = prefs.getString('locale') ?? 'en';
    ref.read(localeProvider.notifier).setLocaleDirect(Locale(localeCode));

    await ref.read(authProvider.notifier).checkAuth();
  } catch (_) {
    ref.read(themeProvider.notifier).setThemeMode(ThemeMode.light);
    ref.read(localeProvider.notifier).setLocaleDirect(const Locale('en'));
    await ref.read(authProvider.notifier).checkAuth();
  }
});