// lib/presentation/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  static const orange     = Color(0xFFFF6B2C);
  static const orangeDim  = Color(0xFFFF8C57);
  static const dark       = Color(0xFF0F1117);
  static const surface    = Color(0xFF1A1D27);
  static const card       = Color(0xFF222637);
  static const border     = Color(0xFF2E3348);
  static const text       = Color(0xFFF2F4FF);
  static const subtext    = Color(0xFF8A8FA8);
  static const green      = Color(0xFF2ECC71);
  static const red        = Color(0xFFE74C3C);
  static const amber      = Color(0xFFF39C12);
  static const blue       = Color(0xFF3498DB);

  // Light
  static const lightBg      = Color(0xFFF5F7FF);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard    = Color(0xFFFFFFFF);
  static const lightBorder  = Color(0xFFE0E4F0);
  static const lightText    = Color(0xFF0F1117);
  static const lightSubtext = Color(0xFF6B7280);
}

ThemeData buildDarkTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.orange,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF3D1A00),
    secondary: AppColors.blue,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.subtext,
    outline: AppColors.border,
    error: AppColors.red,
    surfaceContainerHighest: AppColors.card,
  ),
  scaffoldBackgroundColor: AppColors.dark,
  cardTheme: CardTheme(
    color: AppColors.card,
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.text,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: AppColors.text,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.card,
    selectedColor: AppColors.orange.withOpacity(0.2),
    labelStyle: const TextStyle(color: AppColors.text, fontSize: 12),
    side: const BorderSide(color: AppColors.border),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.card,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.orange),
    ),
    hintStyle: const TextStyle(color: AppColors.subtext),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.orange,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      minimumSize: const Size(double.infinity, 52),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.card,
    contentTextStyle: const TextStyle(color: AppColors.text),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    behavior: SnackBarBehavior.floating,
  ),
  dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 0.5),
);

ThemeData buildLightTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: AppColors.orange,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFFFE5D6),
    secondary: AppColors.blue,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightText,
    onSurfaceVariant: AppColors.lightSubtext,
    outline: AppColors.lightBorder,
    error: AppColors.red,
    surfaceContainerHighest: AppColors.lightCard,
  ),
  scaffoldBackgroundColor: AppColors.lightBg,
  cardTheme: CardTheme(
    color: AppColors.lightCard,
    elevation: 1,
    shadowColor: Colors.black12,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.lightSurface,
    foregroundColor: AppColors.lightText,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: AppColors.lightText, fontSize: 20, fontWeight: FontWeight.bold,
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.lightCard,
    selectedColor: AppColors.orange.withOpacity(0.15),
    labelStyle: const TextStyle(color: AppColors.lightText, fontSize: 12),
    side: const BorderSide(color: AppColors.lightBorder),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightCard,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.lightBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.lightBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.orange),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.orange,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      minimumSize: const Size(double.infinity, 52),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.lightCard,
    contentTextStyle: const TextStyle(color: AppColors.lightText),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    behavior: SnackBarBehavior.floating,
  ),
  dividerTheme: const DividerThemeData(color: AppColors.lightBorder, thickness: 0.5),
);
