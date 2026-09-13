import '../../trackers/domain/tracker.dart';

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
