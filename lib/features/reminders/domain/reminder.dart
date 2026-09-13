enum ReminderTargetType { tracker, subscription }

enum ReminderLeadTime {
  onDay(0),
  oneDayBefore(1),
  threeDaysBefore(3),
  sevenDaysBefore(7);

  const ReminderLeadTime(this.days);
  final int days;
  String get label => switch (this) {
    ReminderLeadTime.onDay => 'On the day',
    ReminderLeadTime.oneDayBefore => 'One day before',
    ReminderLeadTime.threeDaysBefore => 'Three days before',
    ReminderLeadTime.sevenDaysBefore => 'Seven days before',
  };

  static ReminderLeadTime fromDays(int days) => ReminderLeadTime.values
      .firstWhere((value) => value.days == days, orElse: () => onDay);
}

class ReminderTarget {
  const ReminderTarget(this.type, this.id);
  final ReminderTargetType type;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is ReminderTarget && other.type == type && other.id == id;

  @override
  int get hashCode => Object.hash(type, id);
}

class ReminderPreference {
  const ReminderPreference({
    required this.notificationId,
    required this.target,
    required this.enabled,
    required this.leadTime,
    required this.localHour,
    required this.localMinute,
    required this.createdAt,
    required this.updatedAt,
    this.lastScheduledOccurrenceKey,
  });

  final int notificationId;
  final ReminderTarget target;
  final bool enabled;
  final ReminderLeadTime leadTime;
  final int localHour;
  final int localMinute;
  final String? lastScheduledOccurrenceKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReminderPreference copyWith({
    int? notificationId,
    ReminderTarget? target,
    bool? enabled,
    ReminderLeadTime? leadTime,
    int? localHour,
    int? localMinute,
    String? lastScheduledOccurrenceKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ReminderPreference(
    notificationId: notificationId ?? this.notificationId,
    target: target ?? this.target,
    enabled: enabled ?? this.enabled,
    leadTime: leadTime ?? this.leadTime,
    localHour: localHour ?? this.localHour,
    localMinute: localMinute ?? this.localMinute,
    lastScheduledOccurrenceKey:
        lastScheduledOccurrenceKey ?? this.lastScheduledOccurrenceKey,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

enum NotificationPermissionStatus {
  notDetermined,
  authorized,
  denied,
  unavailable,
}

class ReminderCandidate {
  const ReminderCandidate({
    required this.preference,
    required this.fireAt,
    required this.occurrenceKey,
    required this.title,
    required this.body,
  });
  final ReminderPreference preference;
  final DateTime fireAt;
  final String occurrenceKey;
  final String title;
  final String body;
}

class ReminderDraft {
  const ReminderDraft({
    required this.target,
    required this.enabled,
    required this.leadTime,
    required this.localHour,
    required this.localMinute,
  });
  final ReminderTarget target;
  final bool enabled;
  final ReminderLeadTime leadTime;
  final int localHour;
  final int localMinute;
}
