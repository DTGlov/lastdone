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
  runApp(
    LastDoneApp(
      clock: SystemAppClock(),
      trackerRepository: trackerRepository,
      subscriptionRepository: trackerRepository,
      statusStore: statusStore,
      onboardingComplete: onboardingComplete,
      onDispose: () async {
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
    required this.onboardingComplete,
    required this.onDispose,
    super.key,
  });
  final AppClock clock;
  final TrackerRepository trackerRepository;
  final SubscriptionRepository subscriptionRepository;
  final OnboardingStatusStore statusStore;
  final bool onboardingComplete;
  final Future<void> Function() onDispose;
  @override
  State<LastDoneApp> createState() => _LastDoneAppState();
}

class _LastDoneAppState extends State<LastDoneApp> {
  late final AppRouter _appRouter = AppRouter(
    onboardingComplete: widget.onboardingComplete,
    trackerRepository: widget.trackerRepository,
    subscriptionRepository: widget.subscriptionRepository,
    statusStore: widget.statusStore,
    clock: widget.clock,
  );
  @override
  void dispose() {
    unawaited(widget.onDispose());
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
