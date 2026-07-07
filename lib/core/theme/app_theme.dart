import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Tharaka University Brand Colors ──────────────────────────────────────
  // Extracted directly from the TUN Students Portal dashboard:
  // Royal blue sidebar + golden yellow header = the two brand colors.

  static const Color primary = Color(0xFF1A3A8F);    // Royal blue — sidebar, nav, buttons
  static const Color secondary = Color(0xFF2952C4);  // Lighter blue — secondary actions
  static const Color accent = Color(0xFFF5A623);     // Golden yellow — header, highlights, FAB
  static const Color error = Color(0xFFEF4444);      // Red — errors, conflicts
  static const Color success = Color(0xFF28A745);    // Green — completed, synced states

  // ── Light Theme Colors ────────────────────────────────────────────────────
  static const Color bgLight = Color(0xFFF7F8FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1F2E);
  static const Color textSecondaryLight = Color(0xFF5C6478);
  static const Color borderLight = Color(0xFFE2E8F0);

  // ── Dark Theme Colors ─────────────────────────────────────────────────────
  static const Color bgDark = Color(0xFF0D1321);
  static const Color surfaceDark = Color(0xFF162040);
  static const Color textPrimaryDark = Color(0xFFF7F8FA);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF243564);

  static ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    bg: bgLight,
    surface: surfaceLight,
    textPrimary: textPrimaryLight,
    textSecondary: textSecondaryLight,
    border: borderLight,
  );

  static ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    bg: bgDark,
    surface: surfaceDark,
    textPrimary: textPrimaryDark,
    textSecondary: textSecondaryDark,
    border: borderDark,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: accent,
        onSecondary: Colors.white,
        error: error,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5),
          displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
          bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
          bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
    );
  }

  // ── Context-aware getters ─────────────────────────────────────────────────
  static Color getBackground(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color getSurface(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color getTextPrimary(BuildContext context) => Theme.of(context).textTheme.bodyLarge!.color!;
  static Color getTextSecondary(BuildContext context) => Theme.of(context).textTheme.bodyMedium!.color!;
  static Color getBorder(BuildContext context) => Theme.of(context).brightness == Brightness.light ? borderLight : borderDark;

  // ── Static convenience constants (light theme defaults) ───────────────────
  static const Color background = bgLight;
  static const Color surface = surfaceLight;
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color border = borderLight;
}
