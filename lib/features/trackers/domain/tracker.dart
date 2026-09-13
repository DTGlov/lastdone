class Tracker {
  const Tracker({
    required this.id,
    required this.title,
    required this.repeatRule,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(id != '', 'id is required'),
       assert(title != '', 'title is required');
  final String id, title;
  final RepeatRule repeatRule;
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
}
