import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/time/app_clock.dart';
import '../core/design_system/app_icons.dart';
import '../features/onboarding/data/onboarding_status_store.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/presentation/onboarding_view_model.dart';
import '../features/profile/presentation/you_screen.dart';
import '../features/subscriptions/presentation/subscriptions_screen.dart';
import '../features/subscriptions/presentation/subscriptions_view_model.dart';
import '../features/subscriptions/presentation/subscription_editor_sheet.dart';
import '../features/subscriptions/domain/subscription_repository.dart';
import '../features/timeline/presentation/timeline_screen.dart';
import '../features/timeline/domain/timeline_repository.dart';
import '../features/timeline/presentation/timeline_view_model.dart';
import '../features/trackers/presentation/today_screen.dart';
import '../features/trackers/presentation/tracker_detail_screen.dart';
import '../features/trackers/presentation/tracker_detail_view_model.dart';
import '../features/trackers/domain/tracker_repository.dart';
import '../features/trackers/presentation/tracker_editor_sheet.dart';
import '../features/today/presentation/today_view_model.dart';

class AppRouter {
  AppRouter({
    required bool onboardingComplete,
    required TrackerRepository trackerRepository,
    required OnboardingStatusStore statusStore,
    required AppClock clock,
    SubscriptionRepository? subscriptionRepository,
  }) : router = GoRouter(
         initialLocation: onboardingComplete ? '/today' : '/onboarding',
         routes: [
           GoRoute(
             path: '/onboarding',
             builder: (_, _) => ChangeNotifierProvider(
               create: (_) => OnboardingViewModel(
                 trackerRepository: trackerRepository,
                 statusStore: statusStore,
                 clock: clock,
               ),
               child: const OnboardingScreen(),
             ),
           ),
           GoRoute(
             path: '/trackers/:id',
             builder: (_, state) => ChangeNotifierProvider(
               create: (context) => TrackerDetailViewModel(
                 repository: context.read<TrackerRepository>(),
                 clock: context.read<AppClock>(),
                 trackerId: state.pathParameters['id']!,
               ),
               child: TrackerDetailScreen(
                 trackerId: state.pathParameters['id']!,
               ),
             ),
           ),
           StatefulShellRoute.indexedStack(
             builder: (_, _, shell) => AppShell(navigationShell: shell),
             branches: [
               StatefulShellBranch(
                 routes: [
                   GoRoute(
                     path: '/today',
                     builder: (_, _) => ChangeNotifierProvider(
                       create: (_) => TodayViewModel(
                         repository: trackerRepository,
                         clock: clock,
                       ),
                       child: const TodayScreen(),
                     ),
                   ),
                 ],
               ),
               StatefulShellBranch(
                 routes: [
                   GoRoute(
                     path: '/subscriptions',
                     builder: (_, _) => ChangeNotifierProvider(
                       create: (_) => SubscriptionsViewModel(
                         repository:
                             subscriptionRepository ??
                             const UnavailableSubscriptionRepository(),
                         clock: clock,
                       ),
                       child: const SubscriptionsScreen(),
                     ),
                   ),
                 ],
               ),
               StatefulShellBranch(
                 routes: [
                   GoRoute(
                     path: '/timeline',
                     builder: (context, _) {
                       final trackerRepository = context
                           .read<TrackerRepository>();
                       final TimelineRepository timelineRepository;
                       if (trackerRepository
                           case final TimelineRepository value) {
                         timelineRepository = value;
                       } else {
                         timelineRepository =
                             const UnavailableTimelineRepository();
                       }
                       return ChangeNotifierProvider(
                         create: (_) => TimelineViewModel(
                           repository: timelineRepository,
                           clock: context.read<AppClock>(),
                         ),
                         child: const TimelineScreen(),
                       );
                     },
                   ),
                 ],
               ),
               StatefulShellBranch(
                 routes: [
                   GoRoute(path: '/you', builder: (_, _) => const YouScreen()),
                 ],
               ),
             ],
           ),
         ],
       );
  final GoRouter router;
  void dispose() => router.dispose();
}

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: navigationShell,
    floatingActionButton: SafeArea(
      child: FloatingActionButton(
        key: const Key('create-action'),
        tooltip: 'Create tracker',
        onPressed: () => _createAction(context, navigationShell.currentIndex),
        child: const Icon(AppIcons.add),
      ),
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    bottomNavigationBar: NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
      destinations: const [
        NavigationDestination(
          icon: Icon(AppIcons.today),
          selectedIcon: Icon(AppIcons.today),
          label: 'Today',
        ),
        NavigationDestination(
          icon: Icon(AppIcons.subscriptions),
          selectedIcon: Icon(AppIcons.subscriptions),
          label: 'Subs',
        ),
        NavigationDestination(
          icon: Icon(AppIcons.timeline),
          selectedIcon: Icon(AppIcons.timeline),
          label: 'Timeline',
        ),
        NavigationDestination(
          icon: Icon(AppIcons.profile),
          selectedIcon: Icon(AppIcons.profile),
          label: 'You',
        ),
      ],
    ),
  );
}

Future<void> _createAction(BuildContext context, int index) async {
  if (index == 0) {
    await _createTracker(context);
  } else if (index == 1) {
    await _createSubscription(context);
  } else {
    final choice = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(AppIcons.tracker),
              title: const Text('Tracker'),
              onTap: () => Navigator.pop(context, false),
            ),
            ListTile(
              leading: const Icon(AppIcons.subscriptions),
              title: const Text('Subscription'),
              onTap: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (choice == true) await _createSubscription(context);
    if (choice == false && context.mounted) await _createTracker(context);
  }
}

Future<void> _createTracker(BuildContext context) async {
  final result = await showTrackerEditor(
    context: context,
    repository: context.read<TrackerRepository>(),
    clock: context.read<AppClock>(),
  );
  if (result == true && context.mounted) {
    context.go('/today');
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Added to your rhythm.')));
  }
}

Future<void> _createSubscription(BuildContext context) async {
  final result = await showSubscriptionEditor(
    context: context,
    repository: context.read<SubscriptionRepository>(),
    clock: context.read<AppClock>(),
  );
  if (result == true && context.mounted) {
    context.go('/subscriptions');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to your monthly picture.')),
    );
  }
}
