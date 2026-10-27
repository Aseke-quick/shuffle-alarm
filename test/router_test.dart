import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/app.dart';
import 'package:shuffle_alarm/router.dart';

void main() {
  testWidgets('the bottom tabs switch between Alarms, Library and Insights', (
    tester,
  ) async {
    await _openApp(tester);
    _expectTab(tester, 'Alarms', index: 0);

    await _tapTab(tester, 'Library');
    _expectTab(tester, 'Library', index: 1);
    expect(find.text('No sounds yet.'), findsOneWidget);

    await _tapTab(tester, 'Insights');
    _expectTab(tester, 'Insights', index: 2);
    expect(find.text('No mornings to show yet.'), findsOneWidget);

    await _tapTab(tester, 'Alarms');
    _expectTab(tester, 'Alarms', index: 0);
    expect(find.text('No alarms yet.'), findsOneWidget);
  });

  testWidgets('the gear opens Settings above the tabs, Back returns to them', (
    tester,
  ) async {
    await _openApp(tester);
    await _tapTab(tester, 'Library');

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
    expect(find.text('No settings yet.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();

    _expectTab(tester, 'Library', index: 1);
  });

  testWidgets('the home address opens the Alarms tab', (tester) async {
    await _openApp(tester);
    await _tapTab(tester, 'Insights');

    tester.container().read(routerProvider).go('/');
    await tester.pumpAndSettle();

    _expectTab(tester, 'Alarms', index: 0);
  });
}

Future<void> _openApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: ShuffleAlarmApp()));
  await tester.pumpAndSettle();
}

/// Taps the tab with this [label] in the bottom navigation bar.
Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// Checks that the tab with this [title] is open and selected in the bar.
void _expectTab(WidgetTester tester, String title, {required int index}) {
  expect(find.widgetWithText(AppBar, title), findsOneWidget);
  final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
  expect(bar.selectedIndex, index);
}
