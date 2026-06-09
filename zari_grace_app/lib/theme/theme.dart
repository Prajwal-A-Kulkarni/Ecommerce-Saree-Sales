import 'package:flutter/material.dart';

class BoutiqueTheme {
  // Brand colors matching the luxury website theme
  static const Color primaryBg = Color(0xFF130105);      // Full dark body background
  static const Color cardBg = Color(0xFF230810);         // Deep maroon/burgundy card container
  static const Color accentGold = Color(0xFFD4AF37);     // Metallic rich gold for buttons, links
  static const Color textWhite = Color(0xFFF9F6F0);      // Soft cream white for primary text
  static const Color textMuted = Color(0xFFB59A9A);      // Greyish pink for descriptions, ratings

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
        backgroundColor: primaryBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textWhite,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
