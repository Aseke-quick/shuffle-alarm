import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/design/components/alarm_track_row.dart';
import 'package:shuffle_alarm/design/components/nav_bar.dart';
import 'package:shuffle_alarm/design/components/time_wheels.dart';
import 'package:shuffle_alarm/features/alarms/alarm_editor_screen.dart';
import 'package:shuffle_alarm/router.dart';

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

  group('A new alarm', () {
    testWidgets('opens above the tabs, at the time now', (tester) async {
      // Wednesday 23:40.
      await openAlarms(tester, db: db, now: wednesdayEvening);

      await tester.tap(find.text('New alarm'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'New alarm'), findsOneWidget);
      expect(find.byType(WakemixNavBar), findsNothing);
      expect(
        tester.widget<TimeWheels>(find.byType(TimeWheels)).time,
        const TimeOfDay(hour: 23, minute: 40),
      );
      expect(find.text('Rings in 1 d'), findsOneWidget);
      // Thursday 23:40, so bed by Thursday 15:40.
      expect(find.text('Bed by Thu 3:40 PM for 8 h of sleep'), findsOneWidget);
      expect(find.text('No days chosen, so it rings once.'), findsOneWidget);
      expect(find.byTooltip('Delete alarm'), findsNothing);
      expect(find.text('Save alarm'), findsOneWidget);
    });

    testWidgets('gets its time, days and label, and Save keeps it', (
      tester,
    ) async {
      await openAlarms(tester, db: db, now: wednesdayEvening);
      await tester.tap(find.text('New alarm'));
      await tester.pumpAndSettle();

      await _pickTime(tester, hour: '6', minute: '45', period: 'AM');
      expect(
        tester.widget<TimeWheels>(find.byType(TimeWheels)).time,
        const TimeOfDay(hour: 6, minute: 45),
      );
      expect(find.text('Rings in 7 h 5 min'), findsOneWidget);
      // Thursday 06:45: the bedtime, 22:45, has passed.
      expect(find.text('Sleep now: 7 h 5 min'), findsOneWidget);

      await tester.tap(find.text('Mon'));
      await tester.tap(find.text('Fri'));
      await tester.pump();
      // Friday 06:45.
      expect(find.text('Rings in 1 d 7 h 5 min'), findsOneWidget);
      expect(find.text('Bed by Thu 10:45 PM for 8 h of sleep'), findsOneWidget);
      expect(find.text('No days chosen, so it rings once.'), findsNothing);

      await tester.enterText(find.byType(TextField), ' Gym ');
      await tester.tap(find.text('Save alarm'));
      await tester.pumpAndSettle();

      expect(find.byType(WakemixNavBar), findsOneWidget);
      _expectRow('6:45 AM', 'Gym · Mon, Fri', 'Rings in 1 d 7 h 5 min');
      final [saved] = await alarms.all();
      expect(saved.id, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(
        saved,
        Alarm(
          id: saved.id,
          time: ClockTime(hour: 6, minute: 45),
          repeatDays: const {DateTime.monday, DateTime.friday},
          label: 'Gym',
        ),
      );
    });

    testWidgets('a failed save says so, and the page stays', (tester) async {
      await openAlarms(
        tester,
        db: db,
        now: wednesdayEvening,
        overrides: [
          alarmRepositoryProvider.overrideWith((ref) => _FullDisk(db)),
        ],
      );
      await tester.tap(find.text('New alarm'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save alarm'));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not save the alarm: Exception: The disk is full'),
        findsOneWidget,
      );
      expect(find.widgetWithText(AppBar, 'New alarm'), findsOneWidget);
      expect(await alarms.all(), isEmpty);
    });
  });

  group('An alarm', () {
    testWidgets('changes, and Save switches it on', (tester) async {
      await alarms.save(
        Alarm(
          id: 'work',
          time: ClockTime(hour: 7, minute: 0),
          label: 'Work',
          enabled: false,
          gentleStart: false,
        ),
      );
      await openAlarms(tester, db: db, now: wednesdayEvening);

      await tester.tap(_row('7:00 AM'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Edit alarm'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Work'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Office');
      await tester.tap(find.text('Sat'));
      await tester.tap(find.text('Save alarm'));
      await tester.pumpAndSettle();

      expect(await alarms.all(), [
        Alarm(
          id: 'work',
          time: ClockTime(hour: 7, minute: 0),
          repeatDays: const {DateTime.saturday},
          label: 'Office',
          gentleStart: false,
        ),
      ]);
      // Saturday 07:00.
      _expectRow('7:00 AM', 'Office · Sat', 'Rings in 2 d 7 h 20 min');
    });

    testWidgets('stays as it was when the page closes with Back', (
      tester,
    ) async {
      final alarm = Alarm(
        id: 'a',
        time: ClockTime(hour: 7, minute: 0),
        label: 'Work',
      );
      await alarms.save(alarm);
      await openAlarms(tester, db: db, now: wednesdayEvening);
      await tester.tap(_row('7:00 AM'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Office');
      await tester.tap(find.text('Sun'));
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(await alarms.all(), [alarm]);
      _expectRow('7:00 AM', 'Work · Once', 'Rings in 7 h 20 min');
    });

    testWidgets('is deleted after a question', (tester) async {
      await alarms.save(Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0)));
      await openAlarms(tester, db: db, now: wednesdayEvening);
      await tester.tap(_row('7:00 AM'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete alarm'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this alarm?'), findsOneWidget);
      expect(find.text('It will not ring again.'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Edit alarm'), findsOneWidget);
      expect(await alarms.all(), hasLength(1));

      await tester.tap(find.byTooltip('Delete alarm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('No alarm set'), findsOneWidget);
      expect(find.byType(AlarmTrackRow), findsNothing);
      expect(await alarms.all(), isEmpty);
    });

    testWidgets('that no longer exists says so', (tester) async {
      await openAlarms(tester, db: db, now: wednesdayEvening);

      unawaited(
        tester
            .container()
            .read(routerProvider)
            .push<void>(AlarmEditorScreen.pathFor('gone')),
      );
      await tester.pumpAndSettle();

      expect(find.text('This alarm no longer exists.'), findsOneWidget);
    });
  });

  group('The genres', () {
    testWidgets('are those of the built-in sounds of the library', (
      tester,
    ) async {
      final sounds = SoundRepository(db);
      for (final (id, source, genre) in [
        ('sunrise', SoundSource.builtin, 'pop'),
        ('ocean', SoundSource.builtin, 'pop'),
        ('blue', SoundSource.builtin, 'jazz'),
        ('my-song', SoundSource.user, 'my-songs'),
        ('mom', SoundSource.voice, 'voice'),
      ]) {
        await sounds.save(
          StoredSound(_sound(id, source, genre), audioPath: '$genre/$id.mp3'),
        );
      }
      await openAlarms(tester, db: db, now: wednesdayEvening);
      await tester.tap(find.text('New alarm'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilterChip, 'Jazz'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Pop'), findsOneWidget);
      expect(find.text('My-songs'), findsNothing);
      expect(find.text('Voice'), findsNothing);
      expect(
        find.text('None chosen, so it plays every genre.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Pop'));
      await tester.pump();
      expect(find.text('None chosen, so it plays every genre.'), findsNothing);
      await tester.tap(find.text('Save alarm'));
      await tester.pumpAndSettle();

      expect((await alarms.all()).single.genres, {'pop'});
    });

    testWidgets('are none while the library has none', (tester) async {
      await openAlarms(tester, db: db, now: wednesdayEvening);
      await tester.tap(find.text('New alarm'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'The library has no genres yet, so this alarm plays every sound.',
        ),
        findsOneWidget,
      );
      expect(find.byType(FilterChip), findsNothing);
    });

    testWidgets('include a chosen genre the library no longer has', (
      tester,
    ) async {
      await alarms.save(
        Alarm(
          id: 'a',
          time: ClockTime(hour: 7, minute: 0),
          genres: const {'jazz'},
        ),
      );
      await openAlarms(tester, db: db, now: wednesdayEvening);
      await tester.tap(_row('7:00 AM'));
      await tester.pumpAndSettle();

      final jazz = find.widgetWithText(FilterChip, 'Jazz');
      expect(tester.widget<FilterChip>(jazz).selected, isTrue);

      await tester.tap(jazz);
      await tester.tap(find.text('Save alarm'));
      await tester.pumpAndSettle();

      expect((await alarms.all()).single.genres, isEmpty);
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
  );
  expect(find.descendant(of: row, matching: find.text(status)), findsOneWidget);
}

/// Taps the time on the dial, types the time in, and confirms it.
Future<void> _pickTime(
  WidgetTester tester, {
  required String hour,
  required String minute,
  required String period,
}) async {
  await tester.tap(find.text('Type the time'));
  await tester.pumpAndSettle();
  final fields = find.descendant(
    of: find.byType(Dialog),
    matching: find.byType(TextField),
  );
  await tester.enterText(fields.at(0), hour);
  await tester.enterText(fields.at(1), minute);
  await tester.tap(
    find.descendant(of: find.byType(Dialog), matching: find.text(period)),
  );
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Sound _sound(String id, SoundSource source, String genre) => Sound(
  id: id,
  title: id,
  source: source,
  genre: genre,
  intensity: 1,
  duration: const Duration(seconds: 20),
);

/// Alarms that cannot be saved, as on a full disk.
class _FullDisk extends AlarmRepository {
  _FullDisk(super._db);

  @override
  Future<void> save(Alarm alarm) => Future.error(Exception('The disk is full'));
}
