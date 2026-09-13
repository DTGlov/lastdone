import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:everdun/core/time/app_clock.dart';
import 'package:everdun/features/onboarding/data/onboarding_status_store.dart';
import 'package:everdun/app/app_router.dart';
import 'package:everdun/features/trackers/domain/tracker.dart';
import 'package:everdun/features/trackers/domain/tracker_repository.dart';

class _FakeTrackerRepository implements TrackerRepository {
  @override
  Future<List<Tracker>> listTrackers() async => const [];
  @override
  Future<void> insertStarterTrackers(List<Tracker> trackers) async {}
}

void main() {
  testWidgets('router exposes persistent navigation destinations', (
    tester,
  ) async {
    final appRouter = AppRouter(
      onboardingComplete: true,
      trackerRepository: _FakeTrackerRepository(),
      statusStore: MemoryOnboardingStatusStore(),
      clock: FixedAppClock(DateTime.utc(2026)),
    );
    addTearDown(appRouter.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter.router));
    expect(find.text('Today'), findsNWidgets(2));
    await tester.tap(find.text('Timeline'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Timeline'), findsNWidgets(2));
    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();
    expect(find.textContaining('You'), findsNWidgets(2));
  });

  testWidgets('first launch opens onboarding and preserves area progress', (
    tester,
  ) async {
    final statusStore = MemoryOnboardingStatusStore();
    final appRouter = AppRouter(
      onboardingComplete: false,
      trackerRepository: _FakeTrackerRepository(),
      statusStore: statusStore,
      clock: FixedAppClock(DateTime.utc(2026)),
    );
    addTearDown(appRouter.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter.router));
    expect(
      find.text('Remember the things life doesn’t schedule.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Let’s begin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('A few good starts'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('What deserves remembering?'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('onboarding completes and routes to Today', (tester) async {
    final appRouter = AppRouter(
      onboardingComplete: false,
      trackerRepository: _FakeTrackerRepository(),
      statusStore: MemoryOnboardingStatusStore(),
      clock: FixedAppClock(DateTime.utc(2026)),
    );
    addTearDown(appRouter.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter.router));
    await tester.tap(find.text('Let’s begin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Change bedsheets'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('See my day'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsWidgets);
    expect(find.text('EverDun'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('What deserves remembering?'), findsNothing);
  });

  testWidgets('core onboarding renders at 200 percent text scale', (
    tester,
  ) async {
    final appRouter = AppRouter(
      onboardingComplete: false,
      trackerRepository: _FakeTrackerRepository(),
      statusStore: MemoryOnboardingStatusStore(),
      clock: FixedAppClock(DateTime.utc(2026)),
    );
    addTearDown(appRouter.dispose);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp.router(routerConfig: appRouter.router),
      ),
    );
    expect(find.text('EverDun'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Let’s begin'), 400);
    await tester.tap(find.text('Let’s begin'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
