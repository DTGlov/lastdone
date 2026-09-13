import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/database/database_bootstrap.dart';
import '../core/time/app_clock.dart';
import '../features/trackers/data/local_tracker_repository.dart';
import '../features/trackers/domain/tracker_repository.dart';
import 'app_router.dart';
import 'app_theme.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) => FlutterError.presentError(details);
  final database = await DatabaseBootstrap.open();
  runApp(
    LastDoneApp(
      clock: SystemAppClock(),
      trackerRepository: LocalTrackerRepository(database: database),
      onDispose: database.close,
    ),
  );
}

class LastDoneApp extends StatefulWidget {
  const LastDoneApp({
    required this.clock,
    required this.trackerRepository,
    required this.onDispose,
    super.key,
  });
  final AppClock clock;
  final TrackerRepository trackerRepository;
  final Future<void> Function() onDispose;
  @override
  State<LastDoneApp> createState() => _LastDoneAppState();
}

class _LastDoneAppState extends State<LastDoneApp> {
  late final AppRouter _appRouter = AppRouter();
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
