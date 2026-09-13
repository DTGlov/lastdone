import '../../trackers/domain/tracker.dart';

enum TimelineCategoryFilter {
  all,
  home,
  vehicle,
  personalCare,
  technology,
  relationships,
  custom;

  TrackerCategory? get category => switch (this) {
    TimelineCategoryFilter.all => null,
    TimelineCategoryFilter.home => TrackerCategory.home,
    TimelineCategoryFilter.vehicle => TrackerCategory.vehicle,
    TimelineCategoryFilter.personalCare => TrackerCategory.personalCare,
    TimelineCategoryFilter.technology => TrackerCategory.technology,
    TimelineCategoryFilter.relationships => TrackerCategory.relationships,
    TimelineCategoryFilter.custom => TrackerCategory.custom,
  };

  static TimelineCategoryFilter fromCategory(TrackerCategory? category) =>
      switch (category) {
        null => TimelineCategoryFilter.all,
        TrackerCategory.home => TimelineCategoryFilter.home,
        TrackerCategory.vehicle => TimelineCategoryFilter.vehicle,
        TrackerCategory.personalCare => TimelineCategoryFilter.personalCare,
        TrackerCategory.technology => TimelineCategoryFilter.technology,
        TrackerCategory.relationships => TimelineCategoryFilter.relationships,
        TrackerCategory.custom => TimelineCategoryFilter.custom,
      };
}

class TimelineQuery {
  const TimelineQuery({
    required this.monthStart,
    required this.monthEnd,
    this.search = '',
    this.category,
    this.cursor,
  });
  final DateTime monthStart;
  final DateTime monthEnd;
  final String search;
  final TrackerCategory? category;
  final TimelineCursor? cursor;
}

class TimelineCursor {
  const TimelineCursor({required this.completedAt, required this.completionId});
  final DateTime completedAt;
  final String completionId;
}

class TimelineEntry {
  const TimelineEntry({
    required this.completionId,
    required this.trackerId,
    required this.completedAt,
    required this.title,
    required this.category,
    required this.iconKey,
    required this.color,
    this.cadence,
    this.missingTracker = false,
  });
  final String completionId;
  final String trackerId;
  final DateTime completedAt;
  final String title;
  final TrackerCategory category;
  final String iconKey;
  final TrackerColor color;
  final String? cadence;
  final bool missingTracker;
}

class TimelinePage {
  const TimelinePage({
    required this.entries,
    required this.hasMore,
    required this.monthlyCount,
  });
  final List<TimelineEntry> entries;
  final bool hasMore;
  final int monthlyCount;

  TimelineCursor? get nextCursor => entries.isEmpty
      ? null
      : TimelineCursor(
          completedAt: entries.last.completedAt,
          completionId: entries.last.completionId,
        );
}

class TimelineGroup {
  const TimelineGroup({required this.date, required this.entries});
  final DateTime date;
  final List<TimelineEntry> entries;
}
