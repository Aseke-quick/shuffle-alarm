import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/features/alarms/alarms_screen.dart';
import 'package:shuffle_alarm/features/insights/insights_screen.dart';
import 'package:shuffle_alarm/features/library/library_screen.dart';
import 'package:shuffle_alarm/features/settings/settings_screen.dart';

/// All pages of the app: three bottom tabs, and Settings above them.
///
/// Every `ProviderScope` builds its own router, so each widget test starts
/// fresh on the Alarms tab.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      // The home address, such as the web site root, opens the Alarms tab.
      GoRoute(path: '/', redirect: (context, state) => AlarmsScreen.path),
      // Each tab keeps its own pages and scroll position while another tab
      // is open.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AlarmsScreen.path,
                builder: (context, state) => const AlarmsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: LibraryScreen.path,
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: InsightsScreen.path,
                builder: (context, state) => const InsightsScreen(),
              ),
            ],
          ),
        ],
      ),
      // Outside the tabs, so it covers the bottom navigation bar.
      GoRoute(
        path: SettingsScreen.path,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// The frame around the tabs: the open tab and the bottom navigation bar.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Tapping the open tab again goes back to its first page.
          initialLocation: index == navigationShell.currentIndex,
        ),
        // Same order as the branches in [routerProvider].
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.alarm_outlined),
            selectedIcon: Icon(Icons.alarm),
            label: 'Alarms',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
        ],
      ),
    );
  }
}
