import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/database/database_bootstrap.dart';
import '../core/time/app_clock.dart';
import '../features/trackers/data/local_tracker_repository.dart';
import '../features/trackers/domain/tracker_repository.dart';
import '../features/subscriptions/domain/subscription_repository.dart';
import '../features/onboarding/data/onboarding_status_store.dart';
import '../features/reminders/application/reminder_coordinator.dart';
import '../features/reminders/data/notification_gateway.dart';
import '../features/reminders/domain/reminder_repository.dart';
import '../features/reminders/domain/reminder.dart';
import 'app_router.dart';
import 'app_theme.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) => FlutterError.presentError(details);
  final database = await DatabaseBootstrap.open();
  final preferences = await SharedPreferences.getInstance();
  final statusStore = SharedPreferencesOnboardingStatusStore(preferences);
  final onboardingComplete = await statusStore.isComplete();
  final trackerRepository = LocalTrackerRepository(database: database);
  final notificationGateway = LocalNotificationGateway();
  final reminderCoordinator = ReminderCoordinator(
    reminders: trackerRepository,
    trackerRepository: trackerRepository,
    subscriptionRepository: trackerRepository,
    gateway: notificationGateway,
    clock: SystemAppClock(),
  );
  unawaited(reminderCoordinator.start());
  runApp(
    LastDoneApp(
      clock: SystemAppClock(),
      trackerRepository: trackerRepository,
      subscriptionRepository: trackerRepository,
      reminderRepository: trackerRepository,
      notificationGateway: notificationGateway,
      statusStore: statusStore,
      onboardingComplete: onboardingComplete,
      onDispose: () async {
        await reminderCoordinator.dispose();
        await trackerRepository.dispose();
        await database.close();
      },
    ),
  );
}

class LastDoneApp extends StatefulWidget {
  const LastDoneApp({
    required this.clock,
    required this.trackerRepository,
    required this.subscriptionRepository,
    required this.statusStore,
    required this.reminderRepository,
    required this.notificationGateway,
    required this.onboardingComplete,
    required this.onDispose,
    super.key,
  });
  final AppClock clock;
  final TrackerRepository trackerRepository;
  final SubscriptionRepository subscriptionRepository;
  final OnboardingStatusStore statusStore;
  final ReminderRepository reminderRepository;
  final NotificationGateway notificationGateway;
  final bool onboardingComplete;
  final Future<void> Function() onDispose;
  @override
  State<LastDoneApp> createState() => _LastDoneAppState();
}

class _LastDoneAppState extends State<LastDoneApp> {
  StreamSubscription<NotificationDestination>? _notificationSubscription;
  late final AppRouter _appRouter = AppRouter(
    onboardingComplete: widget.onboardingComplete,
    trackerRepository: widget.trackerRepository,
    subscriptionRepository: widget.subscriptionRepository,
    statusStore: widget.statusStore,
    clock: widget.clock,
  );
  @override
  void initState() {
    super.initState();
    _notificationSubscription = widget.notificationGateway.destinations.listen((
      destination,
    ) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final path = destination.target.type == ReminderTargetType.tracker
            ? '/trackers/${destination.target.id}'
            : '/subscriptions/${destination.target.id}';
        _appRouter.router.go(path);
      });
    });
  }

  @override
  void dispose() {
    unawaited(widget.onDispose());
    unawaited(_notificationSubscription?.cancel());
    _appRouter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider<AppClock>.value(value: widget.clock),
      Provider<TrackerRepository>.value(value: widget.trackerRepository),
      Provider<SubscriptionRepository>.value(
        value: widget.subscriptionRepository,
      ),
      Provider<OnboardingStatusStore>.value(value: widget.statusStore),
      Provider<ReminderRepository>.value(value: widget.reminderRepository),
      Provider<NotificationGateway>.value(value: widget.notificationGateway),
    ],
    child: MaterialApp.router(
      title: 'LastDone',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      routerConfig: _appRouter.router,
    ),
  );
}
