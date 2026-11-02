import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/nav_bar.dart';
import 'package:shuffle_alarm/design/tokens.dart';
import 'package:shuffle_alarm/features/alarms/alarm_editor_screen.dart';
import 'package:shuffle_alarm/features/alarms/alarms_screen.dart';
import 'package:shuffle_alarm/features/insights/insights_screen.dart';
import 'package:shuffle_alarm/features/library/library_screen.dart';
import 'package:shuffle_alarm/features/ringing/ringing_screen.dart';
import 'package:shuffle_alarm/features/settings/bedtime_reminder_screen.dart';
import 'package:shuffle_alarm/features/settings/settings_screen.dart';

/// All pages of the app: three bottom tabs, and Settings above them.
///
/// Every `ProviderScope` builds its own router, so each widget test starts
/// fresh on the Alarms tab.
final routerProvider = Provider<GoRouter>((ref) {
  // The navigator of the whole app, above the tabs.
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
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
                // AlarmEditorScreen.newPath and .pathFor(id). Above the tabs,
                // so they cover the bottom navigation bar.
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: rootNavigatorKey,
                    pageBuilder: (context, state) =>
                        _page(context, state, const AlarmEditorScreen()),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootNavigatorKey,
                    pageBuilder: (context, state) => _page(
                      context,
                      state,
                      AlarmEditorScreen(alarmId: state.pathParameters['id']),
                    ),
                  ),
                ],
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
        pageBuilder: (context, state) =>
            _page(context, state, const SettingsScreen()),
      ),
      // Above Settings, whose switch opens it.
      GoRoute(
        path: BedtimeReminderScreen.path,
        pageBuilder: (context, state) =>
            _page(context, state, const BedtimeReminderScreen()),
      ),
      // Above everything, while an alarm rings. The app opens it.
      GoRoute(
        path: RingingScreen.path,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            _page(context, state, const RingingScreen()),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// A page above the tabs: it comes in with the platform's transition, or at
/// once when the platform asks for less motion.
Page<void> _page(BuildContext context, GoRouterState state, Widget child) =>
    Motion.reduceMotion(context)
    ? NoTransitionPage<void>(key: state.pageKey, child: child)
    : MaterialPage<void>(key: state.pageKey, child: child);

/// The frame around the tabs: the open tab and the bottom navigation bar.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: WakemixNavBar(
        selectedIndex: navigationShell.currentIndex,
        onSelected: (index) => navigationShell.goBranch(
          index,
          // Tapping the open tab again goes back to its first page.
          initialLocation: index == navigationShell.currentIndex,
        ),
        // Same order as the branches in [routerProvider].
        destinations: const [
          NavDestination(
            icon: Icons.alarm_outlined,
            selectedIcon: Icons.alarm,
            label: 'Alarms',
          ),
          NavDestination(
            icon: Icons.library_music_outlined,
            selectedIcon: Icons.library_music,
            label: 'Library',
          ),
          NavDestination(
            icon: Icons.insights_outlined,
            selectedIcon: Icons.insights,
            label: 'Insights',
          ),
        ],
      ),
    );
  }
}
