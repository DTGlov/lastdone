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
  static const brandPrimary = Color(0xFFC8F55B);
  static const onPrimary = Color(0xFF1E241F);
  static const overdueCoral = Color(0xFFFF8066);
  static const dueSoonGold = Color(0xFFFFD75A);
  static const completedMint = Color(0xFFA8E585);
  static const categoryPlum = Color(0xFFB8A0EF);
  static const informationalSky = Color(0xFF8ECFF2);
  final Color canvas, surface, elevatedSurface, primaryInk, mutedInk, divider;
  static const light = AppColors._(
    canvas: Color(0xFFF8F4E8),
    surface: Color(0xFFFFFDF7),
    elevatedSurface: Colors.white,
    primaryInk: Color(0xFF1E241F),
    mutedInk: Color(0xFF687069),
    divider: Color(0xFFE7E1D4),
  );
  static const dark = AppColors._(
    canvas: Color(0xFF161A17),
    surface: Color(0xFF222722),
    elevatedSurface: Color(0xFF2C322C),
    primaryInk: Color(0xFFF7F4EB),
    mutedInk: Color(0xFFB6BDB7),
    divider: Color(0xFF343A34),
  );
}
