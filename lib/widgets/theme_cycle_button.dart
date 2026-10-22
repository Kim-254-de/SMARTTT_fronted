import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/locale_provider.dart';
import '../core/theme/theme_provider.dart';

/// App-bar button for the theme, the same as on the attendance portals. The icon shows what a
/// tap switches to, not the current mode: moon (Dark), then sun (Light), then laptop (System).
class ThemeCycleButton extends ConsumerWidget {
  const ThemeCycleButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ThemeNotifier.nextAfter(ref.watch(themeProvider));
    final (icon, label) = switch (next) {
      ThemeMode.dark => (Icons.dark_mode_outlined, 'Switch to dark theme'),
      ThemeMode.light => (Icons.light_mode_outlined, 'Switch to light theme'),
      ThemeMode.system => (Icons.laptop_outlined, 'Use the device theme'),
    };
    return IconButton(
      onPressed: () => ref.read(themeProvider.notifier).cycle(),
      tooltip: context.tr(label),
      icon: Icon(icon, color: color),
    );
  }
}
