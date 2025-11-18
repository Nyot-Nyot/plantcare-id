import 'package:flutter/material.dart';

/// App color tokens.
/// Keep simple named colors here so the design system is consistent.
class AppColors {
  AppColors._();

  // From docs/ux-spec.md — Design Tokens
  static const primary = Color(0xFF27AE60);
  static const primaryStrong = Color(0xFF1E8449);
  static const secondary = Color(0xFF58D68D);
  static const accent = Color(0xFFF2C94C);
  static const danger = Color(0xFFE74C3C);
  // Light accent used for subtle icon backgrounds in the profile screen
  static const accentLight = Color(0xFFFEF5E7);

  static const bg = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF6F8F9);
  static const muted = Color(0xFF9AA4A6);

  // Text colors
  static const textPrimary = Color(0xFF17202A);
  static const textSecondary = Color(0xFF5D6D7E);

  // On-* colors
  static const onPrimary = Color(0xFFFFFFFF);
  static const onSecondary = Color(0xFF17202A);
  static const onBackground = Color(0xFF17202A);
  static const onSurface = Color(0xFF17202A);

  // Additional tokens used by small components
  static const surfaceBorder = Color(0xFFECF0F1);
  static const imageBg = Color(0xFFF2F4F6);
}
