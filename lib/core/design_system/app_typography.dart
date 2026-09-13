import 'package:flutter/material.dart';

class AppTypography {
  const AppTypography._();
  static const headingFamily = 'Bricolage Grotesque';
  static const bodyFamily = 'Manrope';
  static const label = TextStyle(
    fontFamily: bodyFamily,
    fontWeight: FontWeight.w700,
    fontSize: 12,
  );
  static TextTheme textTheme(Color ink, Color muted) => TextTheme(
    displaySmall: TextStyle(
      fontFamily: headingFamily,
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    headlineSmall: TextStyle(
      fontFamily: headingFamily,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    titleLarge: TextStyle(
      fontFamily: headingFamily,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: ink,
    ),
    titleMedium: TextStyle(
      fontFamily: headingFamily,
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: ink,
    ),
    bodyLarge: TextStyle(fontFamily: bodyFamily, fontSize: 16, color: ink),
    bodyMedium: TextStyle(fontFamily: bodyFamily, fontSize: 14, color: muted),
    bodySmall: TextStyle(fontFamily: bodyFamily, fontSize: 13, color: muted),
    labelLarge: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    labelMedium: label.copyWith(color: muted),
  );
}
