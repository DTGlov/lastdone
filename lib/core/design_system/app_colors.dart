import 'package:flutter/material.dart';

class AppColors {
  const AppColors._({
    required this.canvas,
    required this.surface,
    required this.elevatedSurface,
    required this.primaryInk,
    required this.mutedInk,
    required this.divider,
  });
  static const brandPrimary = Color(0xFF2F6B4F);
  static const onPrimary = Color(0xFFF4F7F2);
  static const primarySoft = Color(0xFFA9D9BE);
  static const celebrationApricot = Color(0xFFE9A66A);
  static const overdueCoral = Color(0xFFB85C4B);
  static const dueSoonGold = Color(0xFFB78335);
  static const completedMint = Color(0xFFA9D9BE);
  static const categoryPlum = Color(0xFF8D7AB8);
  static const informationalSky = Color(0xFF6C9CB5);
  final Color canvas, surface, elevatedSurface, primaryInk, mutedInk, divider;
  static const light = AppColors._(
    canvas: Color(0xFFF7F4EC),
    surface: Color(0xFFFFFEFA),
    elevatedSurface: Color(0xFFFFFFFF),
    primaryInk: Color(0xFF17231D),
    mutedInk: Color(0xFF5F7166),
    divider: Color(0xFFD7E2DA),
  );
  static const dark = AppColors._(
    canvas: Color(0xFF0F1512),
    surface: Color(0xFF171E1A),
    elevatedSurface: Color(0xFF1D2721),
    primaryInk: Color(0xFFF4F7F2),
    mutedInk: Color(0xFFA9B5AD),
    divider: Color(0xFF314137),
  );
}
