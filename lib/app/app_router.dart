import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/profile/presentation/you_screen.dart';
import '../features/timeline/presentation/timeline_screen.dart';
import '../features/trackers/presentation/today_screen.dart';

class AppRouter {
  AppRouter()
    : router = GoRouter(
        initialLocation: '/today',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => AppShell(navigationShell: shell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/today',
                    builder: (_, _) => const TodayScreen(),
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
    floatingActionButton: FloatingActionButton(
      key: const Key('create-action'),
      tooltip: 'Create',
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Create is coming soon',
              key: Key('create-placeholder'),
            ),
          ),
        ),
      ),
      child: const Icon(Icons.add),
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
