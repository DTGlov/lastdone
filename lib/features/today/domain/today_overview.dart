import '../../trackers/domain/tracker.dart';
import '../../trackers/domain/tracker_repository.dart';

enum TodayStatus {
  notStarted,
  overdue,
  dueToday,
  dueSoon,
  upcoming,
  recentlyDone,
  unscheduled,
}

class TodayTracker {
  const TodayTracker({
    required this.overview,
    required this.status,
    this.nextDueDate,
  });
  final TrackerOverview overview;
  final TodayStatus status;
  final DateTime? nextDueDate;

  Tracker get tracker => overview.tracker;
  Completion? get latestCompletion => overview.latestCompletion;
}

class TodaySections {
  const TodaySections({
    required this.needsAttention,
    required this.comingUp,
    required this.recentlyDone,
  });
  final List<TodayTracker> needsAttention;
  final List<TodayTracker> comingUp;
  final List<TodayTracker> recentlyDone;
  bool get isEmpty =>
      needsAttention.isEmpty && comingUp.isEmpty && recentlyDone.isEmpty;
  int get count =>
      needsAttention.length + comingUp.length + recentlyDone.length;
}

class TodayClassifier {
  const TodayClassifier._();

  static TodaySections classify({
    required DateTime currentDate,
    required Iterable<TrackerOverview> overviews,
  }) {
    final today = _dateOnly(currentDate);
    final attention = <TodayTracker>[];
    final comingUp = <TodayTracker>[];
    final recentlyDone = <TodayTracker>[];

    for (final overview in overviews) {
      final tracker = overview.tracker;
      final completion = overview.latestCompletion;
      if (completion == null) {
        final item = TodayTracker(
          overview: overview,
          status: tracker.repeatRule == RepeatRule.unscheduled
              ? TodayStatus.unscheduled
              : TodayStatus.notStarted,
        );
        if (item.status == TodayStatus.notStarted) {
          attention.add(item);
        } else {
          comingUp.add(item);
        }
        continue;
      }

      final completedOn = _dateOnly(completion.completedAt);
      final nextDueDate = nextDueDateFor(completedOn, tracker);
      final status = _statusFor(
        today: today,
        completedOn: completedOn,
        nextDueDate: nextDueDate,
      );
      final item = TodayTracker(
        overview: overview,
        status: status,
        nextDueDate: nextDueDate,
      );
      switch (status) {
        case TodayStatus.overdue:
        case TodayStatus.dueToday:
          attention.add(item);
        case TodayStatus.dueSoon:
        case TodayStatus.upcoming:
        case TodayStatus.unscheduled:
          comingUp.add(item);
        case TodayStatus.recentlyDone:
        case TodayStatus.notStarted:
          recentlyDone.add(item);
      }
    }

    attention.sort(_attentionCompare);
    comingUp.sort(_comingUpCompare);
    recentlyDone.sort(
      (a, b) => b.latestCompletion!.completedAt.compareTo(
        a.latestCompletion!.completedAt,
      ),
    );
    return TodaySections(
      needsAttention: List.unmodifiable(attention),
      comingUp: List.unmodifiable(comingUp),
      recentlyDone: List.unmodifiable(recentlyDone),
    );
  }

  static TodayStatus _statusFor({
    required DateTime today,
    required DateTime completedOn,
    required DateTime? nextDueDate,
  }) {
    if (nextDueDate == null) {
      return _calendarDaysBetween(completedOn, today) <= 7
          ? TodayStatus.recentlyDone
          : TodayStatus.unscheduled;
    }
    if (nextDueDate.isBefore(today)) {
      return TodayStatus.overdue;
    }
    if (_sameDate(nextDueDate, today)) {
      return TodayStatus.dueToday;
    }
    if (!nextDueDate.isAfter(today.add(const Duration(days: 7)))) {
      return TodayStatus.dueSoon;
    }
    if (_calendarDaysBetween(completedOn, today) <= 7) {
      return TodayStatus.recentlyDone;
    }
    return TodayStatus.upcoming;
  }

  static int _attentionCompare(TodayTracker a, TodayTracker b) {
    final rank = {
      TodayStatus.overdue: 0,
      TodayStatus.dueToday: 1,
      TodayStatus.notStarted: 2,
    };
    final statusCompare = rank[a.status]!.compareTo(rank[b.status]!);
    if (statusCompare != 0) return statusCompare;
    if (a.status == TodayStatus.overdue &&
        a.nextDueDate != null &&
        b.nextDueDate != null) {
      final dueCompare = a.nextDueDate!.compareTo(b.nextDueDate!);
      if (dueCompare != 0) return dueCompare;
    }
    return _titleCompare(a, b);
  }

  static int _comingUpCompare(TodayTracker a, TodayTracker b) {
    final aUnscheduled = a.status == TodayStatus.unscheduled;
    final bUnscheduled = b.status == TodayStatus.unscheduled;
    if (aUnscheduled != bUnscheduled) return aUnscheduled ? 1 : -1;
    if (!aUnscheduled && a.nextDueDate != null && b.nextDueDate != null) {
      final dueCompare = a.nextDueDate!.compareTo(b.nextDueDate!);
      if (dueCompare != 0) return dueCompare;
    }
    return _titleCompare(a, b);
  }

  static int _titleCompare(TodayTracker a, TodayTracker b) =>
      a.tracker.title.toLowerCase().compareTo(b.tracker.title.toLowerCase());

  static DateTime? nextDueDateFor(
    DateTime completedOn,
    Tracker tracker,
  ) => switch (tracker.repeatRule) {
    RepeatRule.unscheduled => null,
    RepeatRule.daily => completedOn.add(Duration(days: tracker.repeatInterval)),
    RepeatRule.weekly => completedOn.add(
      Duration(days: tracker.repeatInterval * 7),
    ),
    RepeatRule.everyTwoWeeks => completedOn.add(const Duration(days: 14)),
    RepeatRule.everyThreeWeeks => completedOn.add(const Duration(days: 21)),
    RepeatRule.monthly => _addMonths(completedOn, tracker.repeatInterval),
    RepeatRule.everyThreeMonths => _addMonths(completedOn, 3),
    RepeatRule.everyFourMonths => _addMonths(completedOn, 4),
    RepeatRule.yearly => _addMonths(completedOn, tracker.repeatInterval * 12),
  };

  static DateTime _addMonths(DateTime date, int months) {
    final monthIndex = date.month - 1 + months;
    final year = date.year + monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final day = date.day.clamp(1, _daysInMonth(year, month));
    return DateTime(year, month, day);
  }

  static int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;
  static DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  static int _calendarDaysBetween(DateTime earlier, DateTime later) =>
      _dateOnly(later).difference(_dateOnly(earlier)).inDays;
}
