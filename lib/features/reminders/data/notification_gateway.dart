import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder.dart';

class NotificationDestination {
  const NotificationDestination(this.target);
  final ReminderTarget target;
}

abstract interface class NotificationGateway {
  Stream<NotificationDestination> get destinations;
  Future<void> initialize();
  Future<NotificationPermissionStatus> permissionStatus();
  Future<NotificationPermissionStatus> requestPermission();
  Future<void> schedule(ReminderCandidate candidate);
  Future<void> cancel(int notificationId);
  Future<List<int>> pendingIds();
  Future<void> showTestNotification();
  Future<bool> openSettings();
}

class LocalNotificationGateway implements NotificationGateway {
  LocalNotificationGateway({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<NotificationDestination> _destinations =
      StreamController<NotificationDestination>.broadcast();
  bool _initialized = false;
  Future<void>? _initialization;

  @override
  Stream<NotificationDestination> get destinations => _destinations.stream;

  @override
  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      // tz.UTC is the package's initialized fallback location. Calling
      // getLocation('UTC') is unsafe with data variants that omit that alias.
      tz.setLocalLocation(tz.UTC);
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_lastdone'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        defaultPresentAlert: true,
        defaultPresentBadge: false,
        defaultPresentSound: true,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _receiveResponse,
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      _receivePayload(launch!.notificationResponse?.payload);
    }
    _initialized = true;
  }

  @override
  Future<NotificationPermissionStatus> permissionStatus() async {
    await initialize();
    if (!_initialized) return NotificationPermissionStatus.unavailable;
    if (Platform.isIOS || Platform.isMacOS) {
      final value = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      if (value == null) return NotificationPermissionStatus.unavailable;
      return value.isEnabled
          ? NotificationPermissionStatus.authorized
          : NotificationPermissionStatus.denied;
    }
    if (Platform.isAndroid) {
      final enabled = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
      return enabled == null
          ? NotificationPermissionStatus.unavailable
          : enabled
          ? NotificationPermissionStatus.authorized
          : NotificationPermissionStatus.denied;
    }
    return NotificationPermissionStatus.unavailable;
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    await initialize();
    if (!_initialized) return NotificationPermissionStatus.unavailable;
    if (Platform.isIOS || Platform.isMacOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, sound: true, badge: false);
    } else if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
    return permissionStatus();
  }

  @override
  Future<void> schedule(ReminderCandidate candidate) async {
    await initialize();
    final when = tz.TZDateTime.from(candidate.fireAt, tz.local);
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;
    await _plugin.cancel(id: candidate.preference.notificationId);
    await _plugin.zonedSchedule(
      id: candidate.preference.notificationId,
      title: candidate.title,
      body: candidate.body,
      scheduledDate: when,
      payload: _encodePayload(candidate.preference.target),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'lastdone_reminders',
          'LastDone reminders',
          channelDescription: 'Friendly reminders from LastDone.',
          icon: 'ic_stat_lastdone',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: true,
          largeIcon: DrawableResourceAndroidBitmap('dun_notification'),
        ),
        iOS: DarwinNotificationDetails(presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(int notificationId) async {
    if (_initialized) await _plugin.cancel(id: notificationId);
  }

  @override
  Future<List<int>> pendingIds() async {
    if (!_initialized) return const [];
    final pending = await _plugin.pendingNotificationRequests();
    return pending.map((item) => item.id).toList(growable: false);
  }

  @override
  Future<void> showTestNotification() async {
    await _plugin.show(
      id: 999999,
      title: 'Dun is ready',
      body: 'LastDone reminders are working.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'lastdone_reminders',
          'LastDone reminders',
          channelDescription: 'Friendly reminders from LastDone.',
          icon: 'ic_stat_lastdone',
        ),
        iOS: DarwinNotificationDetails(presentSound: true),
      ),
    );
  }

  @override
  Future<bool> openSettings() async =>
      (await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.openAppNotificationSettings()) ??
      (await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.openAppNotificationSettings()) ??
      false;

  void _receiveResponse(NotificationResponse response) {
    _receivePayload(response.payload);
  }

  void _receivePayload(String? payload) {
    if (payload == null) return;
    final parts = payload.split('|');
    if (parts.length != 2) return;
    final type = ReminderTargetType.values
        .where((value) => value.name == parts[0])
        .firstOrNull;
    if (type == null || parts[1].isEmpty) return;
    _destinations.add(
      NotificationDestination(
        ReminderTarget(type, Uri.decodeComponent(parts[1])),
      ),
    );
  }

  static String _encodePayload(ReminderTarget target) =>
      '${target.type.name}|${Uri.encodeComponent(target.id)}';

  Future<void> dispose() async => _destinations.close();
}
