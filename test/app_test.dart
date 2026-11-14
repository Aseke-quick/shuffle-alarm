import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/app.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/design/components/wordmark.dart';
import 'package:shuffle_alarm/design/theme.dart';
import 'package:shuffle_alarm/design/tokens.dart';

import 'data/memory_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());
  // Not closed: see memoryDatabase().

  testWidgets('App is Wakemix, in its themes, on the Alarms tab', (
    tester,
  ) async {
    await _openApp(tester, db);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'Wakemix');
    expect(app.theme, same(WakemixTheme.light));
    expect(app.darkTheme, same(WakemixTheme.dark));
    expect(app.themeMode, ThemeMode.system);
    expect(app.theme!.useMaterial3, isTrue);

    expect(find.byType(Wordmark), findsOneWidget);
    expect(find.text('No alarm set'), findsOneWidget);
  });

  testWidgets('follows the device to the dark or the light theme', (
    tester,
  ) async {
    for (final (brightness, background) in [
      (Brightness.dark, WakemixColors.dark.background),
      (Brightness.light, WakemixColors.light.background),
    ]) {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await _openApp(tester, db);

      final context = tester.element(find.byType(Wordmark));
      expect(WakemixColors.of(context).background, background);
    }
  });

  testWidgets('registers the licenses of its fonts', (tester) async {
    await _openApp(tester, db);

    final packages = {
      for (final entry in await LicenseRegistry.licenses.toList())
        ...entry.packages,
    };
    expect(packages, contains('Geist'));
    // The fonts that left the bundle with ADR-005.
    expect(packages, isNot(contains('Unbounded')));
    expect(packages, isNot(contains('Geist Mono')));
  });
}

/// Opens the app with [db], empty, as its database.
Future<void> _openApp(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const ShuffleAlarmApp(),
    ),
  );
  await tester.pumpAndSettle();
}
