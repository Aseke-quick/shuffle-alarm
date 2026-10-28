import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/providers.dart';

import '../../data/memory_database.dart';
import 'alarms_app.dart';

void main() {
  late AppDatabase db;
  late AlarmRepository alarms;

  setUp(() {
    db = memoryDatabase();
    alarms = AlarmRepository(db);
  });

  // Not closed: see memoryDatabase().

  group('The Alarms tab', () {
    testWidgets('without alarms, says so and offers the + button', (
      tester,
    ) async {
      await openAlarms(tester, db: db, now: wednesdayEvening);

      expect(find.text('No alarms yet.'), findsOneWidget);
      expect(find.text('Tap + to add one.'), findsOneWidget);
      expect(find.byTooltip('Add alarm'), findsOneWidget);
    });

    testWidgets('lists the alarms by time of day, with when each rings', (
      tester,
    ) async {
      await alarms.save(
        Alarm(
          id: 'late',
          time: ClockTime(hour: 22, minute: 15),
          enabled: false,
        ),
      );
      await alarms.save(
        Alarm(
          id: 'work',
          time: ClockTime(hour: 7, minute: 0),
          repeatDays: const {1, 2, 3, 4, 5},
          label: 'Work',
        ),
      );
      await alarms.save(
        Alarm(id: 'early', time: ClockTime(hour: 6, minute: 30)),
      );

      // Wednesday 23:40.
      await openAlarms(tester, db: db, now: wednesdayEvening);

      expect(find.text('No alarms yet.'), findsNothing);
      expect(_tile('6:30 AM', 'Once\nRings in 6 h 50 min'), findsOneWidget);
      expect(
        _tile('7:00 AM', 'Work · Weekdays\nRings in 7 h 20 min'),
        findsOneWidget,
      );
      expect(_tile('10:15 PM', 'Once\nOff'), findsOneWidget);
      final tops = [
        for (final time in ['6:30 AM', '7:00 AM', '10:15 PM'])
          tester.getTopLeft(find.text(time)).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
    });

    testWidgets('counts down as the clock moves on', (tester) async {
      await alarms.save(Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0)));
      final clock = await openAlarms(tester, db: db, now: wednesdayEvening);
      expect(find.text('Once\nRings in 7 h 20 min'), findsOneWidget);

      clock.moveTo(DateTime(2026, 11, 11, 23, 41));
      await tester.pumpAndSettle();
      expect(find.text('Once\nRings in 7 h 19 min'), findsOneWidget);

      clock.moveTo(DateTime(2026, 11, 12));
      await tester.pumpAndSettle();
      expect(find.text('Once\nRings in 7 h'), findsOneWidget);
    });

    testWidgets('the switch turns an alarm off and on again', (tester) async {
      await alarms.save(Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0)));
      await openAlarms(tester, db: db, now: wednesdayEvening);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect((await alarms.byId('a'))!.enabled, isFalse);
      expect(find.text('Once\nOff'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect((await alarms.byId('a'))!.enabled, isTrue);
      expect(find.text('Once\nRings in 7 h 20 min'), findsOneWidget);
    });

    testWidgets('shows an error, not an empty list, if the database fails', (
      tester,
    ) async {
      final broken = _brokenDatabase();

      await openAlarms(tester, db: broken, now: wednesdayEvening);

      expect(find.text('Alarms are not available'), findsOneWidget);
      expect(find.textContaining('Storage is blocked'), findsOneWidget);
      expect(find.text('No alarms yet.'), findsNothing);
      expect(find.byTooltip('Add alarm'), findsNothing);

      // Riverpod tries again on its own a moment later; the error stays.
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Alarms are not available'), findsOneWidget);
    });

    testWidgets('shows the error also when it comes after the alarms', (
      tester,
    ) async {
      // Not closed: closing would wait on the fake time of the test.
      final updates = StreamController<List<Alarm>>()
        ..add([Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0))]);
      await openAlarms(
        tester,
        db: db,
        now: wednesdayEvening,
        overrides: [alarmsProvider.overrideWith((ref) => updates.stream)],
      );
      expect(find.text('7:00 AM'), findsOneWidget);
      expect(find.byTooltip('Add alarm'), findsOneWidget);

      updates.addError(Exception('The disk failed'));
      await tester.pumpAndSettle();

      expect(find.text('Alarms are not available'), findsOneWidget);
      expect(find.text('7:00 AM'), findsNothing);
      expect(find.byTooltip('Add alarm'), findsNothing);
    });

    testWidgets('Try again opens the database again', (tester) async {
      final broken = _brokenDatabase();
      var opened = 0;

      await openAlarms(
        tester,
        now: wednesdayEvening,
        overrides: [
          databaseProvider.overrideWith((ref) => opened++ == 0 ? broken : db),
        ],
      );
      expect(find.text('Alarms are not available'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('No alarms yet.'), findsOneWidget);
      expect(find.byTooltip('Add alarm'), findsOneWidget);
    });
  });
}

/// The list item with [time] as its title and [subtitle] below it.
Finder _tile(String time, String subtitle) => find.ancestor(
  of: find.text(subtitle),
  matching: find.widgetWithText(ListTile, time),
);

/// A database that cannot open, as in a browser that blocks the storage of
/// the site. Do not close it: it never opened, and its close would wait for
/// the failed opening on the fake time of the test, which is over by then.
AppDatabase _brokenDatabase() => AppDatabase(
  DatabaseConnection(
    LazyDatabase(() => throw Exception('Storage is blocked')),
    closeStreamsSynchronously: true,
  ),
);
