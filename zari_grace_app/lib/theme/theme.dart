import 'package:flutter/material.dart';

class BoutiqueTheme {
  // Brand colors matching the luxury website theme
  static const Color primaryBg = Color(0xFF08040C);      // Deep midnight violet
  static const Color cardBg = Color(0xFF150A24);         // Deep royal amethyst card container
  static const Color accentGold = Color(0xFFE6C687);     // Radiant champagne gold for accents
  static const Color textWhite = Color(0xFFFAF8F5);      // Ivory cream for readability
  static const Color textMuted = Color(0xFF9FA5C0);      // Lavender silver for descriptions

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryBg,
      primaryColor: accentGold,
      colorScheme: const ColorScheme.dark(
        primary: accentGold,
        secondary: accentGold,
        background: primaryBg,
        surface: cardBg,
        onBackground: textWhite,
        onSurface: textWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accentGold),
        titleTextStyle: TextStyle(
          color: textWhite,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.5,
          fontFamily: 'serif',
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textWhite,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          fontFamily: 'serif',
        ),
        titleLarge: TextStyle(
          color: textWhite,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          fontFamily: 'serif',
        ),
        bodyLarge: TextStyle(
          color: textWhite,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: textMuted,
          fontSize: 14,
          height: 1.4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          foregroundColor: primaryBg,
          elevation: 4,
          shadowColor: accentGold.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
