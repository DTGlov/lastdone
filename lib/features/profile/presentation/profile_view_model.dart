import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/time/app_clock.dart';
import '../../reminders/data/notification_gateway.dart';
import '../../reminders/domain/reminder.dart';
import '../../reminders/domain/reminder_repository.dart';
import '../domain/profile_settings.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required this.clock,
    required this.statisticsRepository,
    required this.reminderRepository,
    required this.gateway,
  }) {
    if (statisticsRepository != null) {
      _statisticsSubscription = statisticsRepository!
          .watchStatistics(clock.now)
          .listen(_receiveStatistics);
    }
    _reminderSubscription = reminderRepository.watchPreferences().listen(
      _receiveReminders,
    );
    unawaited(refreshPermission());
  }
  final AppClock clock;
  final ProfileStatisticsRepository? statisticsRepository;
  final ReminderRepository reminderRepository;
  final NotificationGateway gateway;
  ProfileStatistics? statistics;
  NotificationPermissionStatus permission =
      NotificationPermissionStatus.notDetermined;
  int trackerReminders = 0;
  int subscriptionReminders = 0;
  String? errorMessage;
  StreamSubscription<ProfileStatistics>? _statisticsSubscription;
  StreamSubscription<List<ReminderPreference>>? _reminderSubscription;
  bool _disposed = false;

  Future<void> refreshPermission() async {
    try {
      permission = await gateway.permissionStatus();
      if (!_disposed) notifyListeners();
    } catch (_) {
      permission = NotificationPermissionStatus.unavailable;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> openNotificationSettings() async {
    try {
      await gateway.openSettings();
    } catch (_) {
      errorMessage = 'Notification settings are not available right now.';
      notifyListeners();
    }
  }

  Future<void> sendTestNotification() async {
    try {
      await gateway.showTestNotification();
    } catch (_) {
      errorMessage = 'We could not send a test reminder right now.';
      notifyListeners();
    }
  }

  void _receiveStatistics(ProfileStatistics value) {
    if (_disposed) return;
    statistics = value;
    notifyListeners();
  }

  void _receiveReminders(List<ReminderPreference> values) {
    if (_disposed) return;
    trackerReminders = values
        .where((v) => v.enabled && v.target.type == ReminderTargetType.tracker)
        .length;
    subscriptionReminders = values
        .where(
          (v) => v.enabled && v.target.type == ReminderTargetType.subscription,
        )
        .length;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_statisticsSubscription?.cancel());
    unawaited(_reminderSubscription?.cancel());
    super.dispose();
  }
}
