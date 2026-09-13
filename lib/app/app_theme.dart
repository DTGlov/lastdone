import 'package:flutter/material.dart';

import '../core/design_system/app_colors.dart';
import '../core/design_system/app_typography.dart';
import '../core/design_system/design_tokens.dart';

ThemeData buildLightTheme() => _buildTheme(Brightness.light);
ThemeData buildDarkTheme() => _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness brightness) {
  final colors = brightness == Brightness.dark
      ? AppColors.dark
      : AppColors.light;
  return ThemeData(
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: brightness,
      surface: colors.surface,
      onSurface: colors.primaryInk,
    ).copyWith(primary: AppColors.brandPrimary, onPrimary: AppColors.onPrimary),
    scaffoldBackgroundColor: colors.canvas,
    textTheme: AppTypography.textTheme(colors.primaryInk, colors.mutedInk),
    extensions: [TrackerStatusThemeExtension.defaults],
    navigationBarTheme: const NavigationBarThemeData(
      indicatorColor: AppColors.brandPrimary,
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
    ),
  );
}
