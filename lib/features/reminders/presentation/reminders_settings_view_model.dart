import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/notification_gateway.dart';
import '../domain/reminder.dart';
import '../domain/reminder_repository.dart';

class RemindersSettingsViewModel extends ChangeNotifier {
  RemindersSettingsViewModel({
    required this.repository,
    required this.gateway,
  }) {
    _subscription = repository.watchPreferences().listen(_receive);
    unawaited(refreshPermission());
  }
  final ReminderRepository repository;
  final NotificationGateway gateway;
  StreamSubscription<List<ReminderPreference>>? _subscription;
  NotificationPermissionStatus permission =
      NotificationPermissionStatus.notDetermined;
  int trackerCount = 0;
  int subscriptionCount = 0;
  bool sendingTest = false;
  String? errorMessage;
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

  Future<void> sendTest() async {
    if (sendingTest) return;
    sendingTest = true;
    errorMessage = null;
    notifyListeners();
    try {
      await gateway.showTestNotification();
    } catch (_) {
      errorMessage = 'We could not send a test reminder right now.';
    } finally {
      sendingTest = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> openSettings() async {
    try {
      await gateway.openSettings();
    } catch (_) {
      errorMessage = 'Notification settings are not available here.';
      notifyListeners();
    }
  }

  void _receive(List<ReminderPreference> values) {
    if (_disposed) return;
    trackerCount = values
        .where((v) => v.enabled && v.target.type == ReminderTargetType.tracker)
        .length;
    subscriptionCount = values
        .where(
          (v) => v.enabled && v.target.type == ReminderTargetType.subscription,
        )
        .length;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
