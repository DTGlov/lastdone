import 'package:flutter/material.dart';

class AppSpacing {
  const AppSpacing._();
  static const xs = 8.0, sm = 12.0, md = 16.0, lg = 24.0, xl = 32.0;
}

class AppRadii {
  const AppRadii._();
  static const card = 20.0, control = 14.0, pill = 999.0;
}

class AppMotion {
  const AppMotion._();
  static const short = Duration(milliseconds: 180),
      standard = Duration(milliseconds: 280),
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
    overdue: Color(0xFFFF8066),
    dueSoon: Color(0xFFFFD75A),
    completed: Color(0xFFA8E585),
    category: Color(0xFFB8A0EF),
    informational: Color(0xFF8ECFF2),
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
