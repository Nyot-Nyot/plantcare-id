import 'package:flutter/material.dart';

import 'colors.dart';
import 'text_styles.dart';

/// AppTheme exposes themed ThemeData instances (start with light theme).
class AppTheme {
  AppTheme._();

  static final lightTheme = ThemeData(
    // Use fromSeed then copyWith to avoid deprecated fields in ColorScheme.
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      error: AppColors.danger,
      onError: AppColors.onPrimary,
      onPrimary: AppColors.onPrimary,
      onSecondary: AppColors.onSecondary,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      centerTitle: false,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      headlineLarge: AppTextStyles.h1,
      headlineMedium: AppTextStyles.h2,
      headlineSmall: AppTextStyles.h3,
      titleLarge: TextStyle(
        color: AppColors.textTitle,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: AppColors.textTitle,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.body,
      // caption is deprecated on newer SDKs; use labelSmall for small captions.
      labelSmall: AppTextStyles.caption,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
    ),
  );
}
