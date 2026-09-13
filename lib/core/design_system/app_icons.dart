import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// App-owned icon vocabulary. Keeping the package mapping here makes the
/// visual language replaceable without coupling feature widgets to a library.
class AppIcons {
  const AppIcons._();

  static const today = LucideIcons.calendarCheck;
  static const subscriptions = LucideIcons.receipt;
  static const timeline = LucideIcons.chartLine;
  static const profile = LucideIcons.userRound;
  static const add = LucideIcons.plus;
  static const edit = LucideIcons.pencil;
  static const next = LucideIcons.chevronRight;
  static const complete = LucideIcons.circleCheck;
  static const check = LucideIcons.check;
  static const search = LucideIcons.search;
  static const insight = LucideIcons.sparkles;
  static const tracker = LucideIcons.listChecks;

  static Icon icon(
    IconData data, {
    double size = 24,
    Color? color,
    String? semanticLabel,
  }) => Icon(data, size: size, color: color, semanticLabel: semanticLabel);
}
