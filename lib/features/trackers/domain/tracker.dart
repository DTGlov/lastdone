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
  daily,
  weekly,
  everyTwoWeeks,
  everyThreeWeeks,
  monthly,
  everyThreeMonths,
  everyFourMonths,
  yearly,
}
