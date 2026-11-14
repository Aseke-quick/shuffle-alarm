import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/design/components/alarm_track_row.dart';
import 'package:shuffle_alarm/design/components/info_tile.dart';
import 'package:shuffle_alarm/design/components/mini_waveform.dart';
import 'package:shuffle_alarm/design/components/next_alarm_card.dart';
import 'package:shuffle_alarm/design/components/wordmark.dart';

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
    testWidgets('shows the wordmark and an empty record without alarms', (
      tester,
    ) async {
      await openAlarms(tester, db: db, now: wednesdayEvening);

      expect(find.byType(Wordmark), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);
      expect(_hero('No alarm set'), findsOneWidget);
      expect(_hero('Tap New alarm to set one.'), findsOneWidget);
      expect(find.text('All alarms'), findsNothing);
      expect(find.text('New alarm'), findsOneWidget);
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

      expect(find.text('All alarms'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      _expectRow('6:30 AM', 'Once', 'Rings in 6 h 50 min');
      _expectRow('7:00 AM', 'Work · Weekdays', 'Rings in 7 h 20 min');
      _expectRow('10:15 PM', 'Once', 'Off');
      final tops = [
        for (final time in ['6:30 AM', '7:00 AM', '10:15 PM'])
          tester.getTopLeft(_row(time)).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      // Only the alarms that are on have a waveform in the accent.
      expect(
        tester
            .widgetList<WaveformTile>(find.byType(WaveformTile))
            .map((waveform) => waveform.active),
        [true, true, false],
      );
    });

    testWidgets('shows the alarm that rings next as the record', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
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
      await alarms.save(
        Alarm(id: 'off', time: ClockTime(hour: 5, minute: 0), enabled: false),
      );

      await openAlarms(tester, db: db, now: wednesdayEvening);

      expect(_hero('6:30 AM'), findsOneWidget);
      expect(_hero('in 6 h 50 min'), findsOneWidget);
      expect(_hero('Once'), findsOneWidget);
      // The bedtime, 22:30, has passed: 6 h 50 min of night are left.
      expect(_hero('Sleep now: 6 h 50 min'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Next alarm 6:30 AM, in 6 h 50 min'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('says when to go to bed for the next alarm', (tester) async {
      await alarms.save(
        Alarm(
          id: 'work',
          time: ClockTime(hour: 7, minute: 0),
          repeatDays: const {1, 2, 3, 4, 5},
          label: 'Work',
        ),
      );

      // Wednesday 20:00.
      await openAlarms(tester, db: db, now: DateTime(2026, 11, 11, 20));

      expect(_hero('Work · Weekdays'), findsOneWidget);
      expect(_hero('Bed by 11:00 PM for 8 h of sleep'), findsOneWidget);
    });

    testWidgets('shows an empty record, and the list, when all are off', (
      tester,
    ) async {
      await alarms.save(
        Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0), enabled: false),
      );

      await openAlarms(tester, db: db, now: wednesdayEvening);

      expect(_hero('No alarm set'), findsOneWidget);
      expect(_hero('Tap New alarm to set one.'), findsNothing);
      _expectRow('7:00 AM', 'Once', 'Off');
    });

    testWidgets('counts down as the clock moves on', (tester) async {
      await alarms.save(Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0)));
      final clock = await openAlarms(tester, db: db, now: wednesdayEvening);
      _expectRow('7:00 AM', 'Once', 'Rings in 7 h 20 min');
      expect(_hero('in 7 h 20 min'), findsOneWidget);

      clock.moveTo(DateTime(2026, 11, 11, 23, 41));
      await tester.pumpAndSettle();
      _expectRow('7:00 AM', 'Once', 'Rings in 7 h 19 min');
      expect(_hero('in 7 h 19 min'), findsOneWidget);
      expect(_hero('Sleep now: 7 h 19 min'), findsOneWidget);

      clock.moveTo(DateTime(2026, 11, 12));
      await tester.pumpAndSettle();
      _expectRow('7:00 AM', 'Once', 'Rings in 7 h');
      expect(_hero('in 7 h'), findsOneWidget);
    });

    testWidgets('the switch turns an alarm off and on again', (tester) async {
      await alarms.save(Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0)));
      await openAlarms(tester, db: db, now: wednesdayEvening);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect((await alarms.byId('a'))!.enabled, isFalse);
      _expectRow('7:00 AM', 'Once', 'Off');
      expect(_hero('No alarm set'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect((await alarms.byId('a'))!.enabled, isTrue);
      _expectRow('7:00 AM', 'Once', 'Rings in 7 h 20 min');
      expect(_hero('7:00 AM'), findsOneWidget);
    });

    testWidgets('names each switch by its alarm for screen readers', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await alarms.save(Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0)));
      await openAlarms(tester, db: db, now: wednesdayEvening);

      expect(find.bySemanticsLabel('7:00 AM alarm'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('shows an error, not an empty list, if the database fails', (
      tester,
    ) async {
      final broken = brokenDatabase();

      await openAlarms(tester, db: broken, now: wednesdayEvening);

      expect(find.text('Alarms are not available'), findsOneWidget);
      expect(find.textContaining('Storage is blocked'), findsOneWidget);
      expect(find.text('No alarm set'), findsNothing);
      expect(find.text('New alarm'), findsNothing);

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
      expect(_row('7:00 AM'), findsOneWidget);
      expect(find.text('New alarm'), findsOneWidget);

      updates.addError(Exception('The disk failed'));
      await tester.pumpAndSettle();

      expect(find.text('Alarms are not available'), findsOneWidget);
      expect(find.text('7:00 AM'), findsNothing);
      expect(find.text('New alarm'), findsNothing);
    });

    testWidgets('Try again opens the database again', (tester) async {
      final broken = brokenDatabase();
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

      expect(_hero('No alarm set'), findsOneWidget);
      expect(find.text('New alarm'), findsOneWidget);
    });
  });
}

/// The row of the alarm at [time] in the list.
Finder _row(String time) => find.ancestor(
  of: find.descendant(
    of: find.byType(AlarmTrackRow),
    matching: find.text(time),
  ),
  matching: find.byType(AlarmTrackRow),
);

/// Checks that the row of the alarm at [time] shows [details] and [status].
void _expectRow(String time, String details, String status) {
  final row = _row(time);
  expect(row, findsOneWidget, reason: time);
  expect(
    find.descendant(of: row, matching: find.text(details)),
    findsOneWidget,
    reason: '$time: $details',
  );
  expect(
    find.descendant(of: row, matching: find.text(status)),
    findsOneWidget,
    reason: '$time: $status',
  );
}

/// [text] in the card of the next alarm, or in a tile under it.
Finder _hero(String text) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is NextAlarmCard || widget is InfoTile,
  ),
  matching: find.text(text),
);
