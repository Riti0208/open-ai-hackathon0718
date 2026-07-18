import 'package:flutter/material.dart';

/// 見た目を変えたいときは、まずこの値を編集します。
abstract final class AppColors {
  static const background = Color(0xFFFFFCF4);
  static const surface = Colors.white;
  static const ink = Color(0xFF414052);
  static const muted = Color(0xFF7C798C);
  static const primary = Color(0xFFFF91B8);
  static const yellow = Color(0xFFFFDE72);
  static const mint = Color(0xFFA8E5D5);
  static const lavender = Color(0xFFC5B9FF);
  static const sky = Color(0xFFB9E6FF);
  static const navigation = Color(0xFFFFFCFF);
  static const navigationIndicator = Color(0xFFFFD8E7);
  static const deepPink = Color(0xFFFF6EA4);
  static const blue = Color(0xFF8DD2FF);
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: '.SF Pro Rounded',
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: scheme,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.navigation,
        indicatorColor: AppColors.navigationIndicator,
        height: 76,
        elevation: 12,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
        ),
        iconTheme: WidgetStatePropertyAll(IconThemeData(color: AppColors.ink)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.ink,
          fontSize: 32,
          height: 1.15,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.2,
        ),
        titleLarge: TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        bodyMedium: TextStyle(
          color: AppColors.muted,
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );
  }
}
