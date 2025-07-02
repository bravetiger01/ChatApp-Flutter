// utils/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color darkBackground = Color(0xFF1C1C1E);
  static const Color cardBackground = Color(0xFF2C2C2E);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color accentOrange = Color(0xFFFF9500);

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBackground,
        primarySwatch: Colors.blue,
        primaryColor: primaryBlue,
        cardColor: cardBackground,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: textPrimary,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: textSecondary,
            fontSize: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: textSecondary),
        ),
      );
}