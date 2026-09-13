import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppSpacing {
  const AppSpacing._();
  static const xs = 8.0, sm = 12.0, md = 16.0, lg = 24.0, xl = 32.0;
}

class AppRadii {
  const AppRadii._();
  static const card = 18.0, control = 12.0, pill = 999.0;
}

class AppMotion {
  const AppMotion._();
  static const short = Duration(milliseconds: 180),
      standard = Duration(milliseconds: 240),
      curve = Curves.easeOutCubic;
}

@immutable
class TrackerStatusThemeExtension
    extends ThemeExtension<TrackerStatusThemeExtension> {
  const TrackerStatusThemeExtension({
    required this.overdue,
    required this.dueSoon,
    required this.completed,
    required this.category,
    required this.informational,
  });
  static const defaults = TrackerStatusThemeExtension(
    overdue: AppColors.overdueCoral,
    dueSoon: AppColors.dueSoonGold,
    completed: AppColors.completedMint,
    category: AppColors.categoryPlum,
    informational: AppColors.informationalSky,
  );
  final Color overdue, dueSoon, completed, category, informational;
  @override
  TrackerStatusThemeExtension copyWith({
    Color? overdue,
    Color? dueSoon,
    Color? completed,
    Color? category,
    Color? informational,
  }) => TrackerStatusThemeExtension(
    overdue: overdue ?? this.overdue,
    dueSoon: dueSoon ?? this.dueSoon,
    completed: completed ?? this.completed,
    category: category ?? this.category,
    informational: informational ?? this.informational,
  );
  @override
  TrackerStatusThemeExtension lerp(
    covariant TrackerStatusThemeExtension? other,
    double t,
  ) => other == null
      ? this
      : TrackerStatusThemeExtension(
          overdue: Color.lerp(overdue, other.overdue, t)!,
          dueSoon: Color.lerp(dueSoon, other.dueSoon, t)!,
          completed: Color.lerp(completed, other.completed, t)!,
          category: Color.lerp(category, other.category, t)!,
          informational: Color.lerp(informational, other.informational, t)!,
        );
}
