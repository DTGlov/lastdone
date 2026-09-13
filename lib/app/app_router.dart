import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/time/app_clock.dart';
import '../features/onboarding/data/onboarding_status_store.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/presentation/onboarding_view_model.dart';
import '../features/profile/presentation/you_screen.dart';
import '../features/timeline/presentation/timeline_screen.dart';
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
                     path: '/timeline',
                     builder: (_, _) => const TimelineScreen(),
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
        onPressed: () => _createTracker(context),
        child: const Icon(Icons.add),
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
        NavigationDestination(icon: Icon(Icons.today), label: 'Today'),
        NavigationDestination(icon: Icon(Icons.timeline), label: 'Timeline'),
        NavigationDestination(icon: Icon(Icons.person), label: 'You'),
      ],
    ),
  );
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
