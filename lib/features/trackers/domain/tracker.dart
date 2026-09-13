class Tracker {
  const Tracker({
    required this.id,
    required this.title,
    required this.repeatRule,
    required this.createdAt,
    required this.updatedAt,
    this.repeatInterval = 1,
    this.category = TrackerCategory.custom,
    this.iconKey = TrackerIconKeys.checklist,
    this.color = TrackerColor.plum,
    this.firstDueDate,
  }) : assert(id != '', 'id is required'),
       assert(title != '', 'title is required');
  final String id, title;
  final RepeatRule repeatRule;
  final int repeatInterval;
  final TrackerCategory category;
  final String iconKey;
  final TrackerColor color;

  /// The first scheduled due date, used only until the first real completion.
  final DateTime? firstDueDate;
  final DateTime createdAt, updatedAt;
}

class Completion {
  const Completion({
    required this.id,
    required this.trackerId,
    required this.completedAt,
  }) : assert(id != '', 'id is required'),
       assert(trackerId != '', 'trackerId is required');
  final String id, trackerId;
  final DateTime completedAt;
}

enum RepeatRule {
  unscheduled,
  daily,
  weekly,
  everyTwoWeeks,
  everyThreeWeeks,
  monthly,
  everyThreeMonths,
  everyFourMonths,
  yearly,
}

enum TrackerCategory {
  home,
  vehicle,
  personalCare,
  technology,
  relationships,
  custom,
}

enum TrackerColor { lime, plum, sky, coral, gold, mint }

class TrackerIconKeys {
  const TrackerIconKeys._();
  static const checklist = 'checklist';
  static const home = 'home';
  static const vehicle = 'vehicle';
  static const personalCare = 'personal-care';
  static const technology = 'technology';
  static const relationships = 'relationships';
  static const water = 'water';
  static const tools = 'tools';
  static const leaf = 'leaf';
}

extension RepeatRuleLabel on RepeatRule {
  String get label => switch (this) {
    RepeatRule.unscheduled => 'Whenever you’re ready',
    RepeatRule.daily => 'Every day',
    RepeatRule.weekly => 'Every week',
    RepeatRule.everyTwoWeeks => 'Every 2 weeks',
    RepeatRule.everyThreeWeeks => 'Every 3 weeks',
    RepeatRule.monthly => 'Every month',
    RepeatRule.everyThreeMonths => 'Every 3 months',
    RepeatRule.everyFourMonths => 'Every 4 months',
    RepeatRule.yearly => 'Every year',
  };

  String labelFor(int interval) {
    if (interval <= 1) return label;
    return switch (this) {
      RepeatRule.unscheduled => 'Whenever you’re ready',
      RepeatRule.daily => 'Every $interval days',
      RepeatRule.weekly => 'Every $interval weeks',
      RepeatRule.everyTwoWeeks => 'Every 2 weeks',
      RepeatRule.everyThreeWeeks => 'Every 3 weeks',
      RepeatRule.monthly => 'Every $interval months',
      RepeatRule.everyThreeMonths => 'Every 3 months',
      RepeatRule.everyFourMonths => 'Every 4 months',
      RepeatRule.yearly => 'Every $interval years',
    };
  }
}
