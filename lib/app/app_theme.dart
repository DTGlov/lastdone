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
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.brandPrimary,
          brightness: brightness,
          surface: colors.surface,
          onSurface: colors.primaryInk,
        ).copyWith(
          primary: AppColors.brandPrimary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primarySoft,
          onPrimaryContainer: colors.primaryInk,
          outline: colors.divider,
        ),
    scaffoldBackgroundColor: colors.canvas,
    textTheme: AppTypography.textTheme(colors.primaryInk, colors.mutedInk),
    extensions: [TrackerStatusThemeExtension.defaults],
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.elevatedSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: brightness == Brightness.dark
          ? const Color(0xFF2C4B3A)
          : AppColors.primarySoft,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      height: 72,
      labelTextStyle: WidgetStatePropertyAll(
        AppTypography.textTheme(colors.primaryInk, colors.mutedInk).labelMedium,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: brightness == Brightness.dark
          ? AppColors.primarySoft
          : AppColors.brandPrimary,
      foregroundColor: brightness == Brightness.dark
          ? AppColors.light.primaryInk
          : AppColors.onPrimary,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(color: colors.divider),
      ),
      elevation: 0,
    ),
  );
}
