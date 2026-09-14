import '../../subscriptions/domain/subscription.dart';
import '../../trackers/domain/tracker.dart';
import '../../trackers/domain/tracker_repository.dart';
import 'timeline.dart';

class PlannerDate {
  const PlannerDate(this.year, this.month, this.day);
  final int year, month, day;
  DateTime get date => DateTime(year, month, day);
  String get key =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  factory PlannerDate.from(DateTime value) {
    final local = value.toLocal();
    return PlannerDate(local.year, local.month, local.day);
  }
  @override
  bool operator ==(Object other) =>
      other is PlannerDate &&
      year == other.year &&
      month == other.month &&
      day == other.day;
  @override
  int get hashCode => Object.hash(year, month, day);
}

enum PlannerItemType { trackerDue, subscriptionCharge, completion }

enum PlannerItemStatus { due, overdue, upcoming, handled }

class PlannerItem {
  const PlannerItem({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    required this.status,
    required this.navigationTarget,
    this.trackerId,
    this.category,
    this.iconKey,
    this.color,
    this.amountMinor,
    this.currency,
    this.cadence,
    this.completedAt,
  });
  final String id, title, navigationTarget;
  final PlannerItemType type;
  final PlannerDate date;
  final PlannerItemStatus status;
  final String? trackerId, iconKey, currency, cadence;
  final TrackerCategory? category;
  final TrackerColor? color;
  final int? amountMinor;
  final DateTime? completedAt;
}

class PlannerMonthSummary {
  const PlannerMonthSummary({
    required this.dueCount,
    required this.handledCount,
    required this.subscriptionTotals,
  });
  final int dueCount, handledCount;
  final Map<String, int> subscriptionTotals;
}

class PlannerSnapshot {
  const PlannerSnapshot({required this.itemsByDate, required this.summary});
  final Map<PlannerDate, List<PlannerItem>> itemsByDate;
  final PlannerMonthSummary summary;
}

class PlannerSources {
  const PlannerSources({
    required this.overviews,
    required this.subscriptions,
    required this.completions,
  });
  final List<TrackerOverview> overviews;
  final List<Subscription> subscriptions;
  final List<TimelineEntry> completions;
}
