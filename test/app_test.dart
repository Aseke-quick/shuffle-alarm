import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/app.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/providers.dart';

import 'data/memory_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());
  // Not closed: see memoryDatabase().

  testWidgets('App opens on the Alarms tab, with its title and Material 3', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const ShuffleAlarmApp(),
      ),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'Shuffle Alarm');
    expect(app.theme!.useMaterial3, isTrue);
    expect(app.darkTheme!.useMaterial3, isTrue);

    expect(find.widgetWithText(AppBar, 'Alarms'), findsOneWidget);
    expect(find.text('No alarms yet.'), findsOneWidget);
  });
}
