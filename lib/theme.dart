import 'package:flutter/material.dart';

// Neon Cyberpunk Color Palette
const Color deepDarkBlue = Color(0xFF0A0E17);
const Color cardSlate = Color(0xFF121824);
const Color electricCyan = Color(0xFF00F5FF);
const Color neonPink = Color(0xFFFF2E93);
const Color cyberPurple = Color(0xFF9D00FF);
const Color icyWhite = Color(0xFFF0F5FF);
const Color softGrey = Color(0xFF8F9CAE);

ThemeData getCyberTheme() {
  return ThemeData(
    scaffoldBackgroundColor: deepDarkBlue,
    primaryColor: electricCyan,
    colorScheme: const ColorScheme.dark(
      background: deepDarkBlue,
      surface: cardSlate,
      primary: electricCyan,
      secondary: neonPink,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: icyWhite,
        fontSize: 32,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
      titleMedium: TextStyle(
        color: icyWhite,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        color: icyWhite,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: softGrey,
        fontSize: 14,
      ),
      labelMedium: TextStyle(
        color: electricCyan,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.0,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: deepDarkBlue,
      elevation: 0,
      iconTheme: IconThemeData(color: icyWhite),
      titleTextStyle: TextStyle(
        color: icyWhite,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    useMaterial3: true,
  );
}
