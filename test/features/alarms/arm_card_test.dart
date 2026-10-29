import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/platform/providers.dart';

import '../../data/memory_database.dart';
import '../../platform/fake_platform.dart';
import 'alarms_app.dart';

void main() {
  late AppDatabase db;
  late FakeSoundPlayer player;
  late FakeScreenWakeLock wakeLock;

  setUp(() {
    db = memoryDatabase();
    player = FakeSoundPlayer();
    wakeLock = FakeScreenWakeLock();
  });
  // Not closed: see memoryDatabase().

  /// The web version: alarms ring, after a tap that unlocks their sound.
  List<Override> web() => [
    alarmSchedulerProvider.overrideWithValue(FakeAlarmScheduler()),
    soundPlayerProvider.overrideWithValue(player),
    screenWakeLockProvider.overrideWithValue(wakeLock),
  ];

  Future<void> save(Alarm alarm) => AlarmRepository(db).save(alarm);

  setUp(() async {
    await SoundRepository(db).save(
      StoredSound(
        Sound(
          id: 'chime',
          title: 'Chime',
          source: SoundSource.builtin,
          genre: 'calm',
          intensity: 1,
          duration: const Duration(seconds: 20),
        ),
        audioPath: 'assets/library/calm/chime.wav',
      ),
    );
  });

  testWidgets('asks to arm the alarms while one is on', (tester) async {
    await save(_alarm('a'));
    await openAlarms(tester, db: db, now: wednesdayEvening, overrides: web());

    expect(find.text('Arm alarms to hear them'), findsOneWidget);
    expect(
      find.text(
        'Your browser plays sound only after a tap. Arm alarms, then keep '
        'this tab open.',
      ),
      findsOneWidget,
    );
    expect(find.text('Arm alarms'), findsOneWidget);
  });

  testWidgets('says nothing while no alarm is on', (tester) async {
    await save(_alarm('off', enabled: false));
    await openAlarms(tester, db: db, now: wednesdayEvening, overrides: web());

    expect(find.text('Arm alarms'), findsNothing);
    expect(find.text('Keep this tab open'), findsNothing);
  });

  testWidgets('Arm alarms unlocks the sound and keeps the screen on', (
    tester,
  ) async {
    await save(_alarm('a'));
    await openAlarms(tester, db: db, now: wednesdayEvening, overrides: web());

    await tester.tap(find.text('Arm alarms'));
    await tester.pumpAndSettle();

    expect(player.unlockCalls, 1);
    expect(wakeLock.held, isTrue);
    // Every sound in memory, so a ring needs no network.
    expect(player.preloaded, [
      for (final stored in await SoundRepository(db).all()) stored.audioPath,
    ]);
    expect(find.text('Arm alarms'), findsNothing);
    expect(find.text('Keep this tab open'), findsOneWidget);
    expect(
      find.text(
        'Alarms ring only while this tab is open. Keep the sound on and the '
        'device plugged in.',
      ),
      findsOneWidget,
    );
    expect(find.text('The screen stays on.'), findsOneWidget);
  });

  testWidgets('says when the screen may turn off', (tester) async {
    await save(_alarm('a'));
    await openAlarms(tester, db: db, now: wednesdayEvening, overrides: web());
    await tester.tap(find.text('Arm alarms'));
    await tester.pumpAndSettle();

    // The browser lets go, such as while the tab is hidden.
    wakeLock.letGo();
    await tester.pump();

    expect(
      find.text('The screen may turn off. Keep this tab in front.'),
      findsOneWidget,
    );
  });

  testWidgets('a browser that cannot keep the screen on is armed too', (
    tester,
  ) async {
    wakeLock = FakeScreenWakeLock(supported: false);
    await save(_alarm('a'));
    await openAlarms(tester, db: db, now: wednesdayEvening, overrides: web());

    await tester.tap(find.text('Arm alarms'));
    await tester.pumpAndSettle();

    expect(find.text('Keep this tab open'), findsOneWidget);
    expect(
      find.text('The screen may turn off. Keep this tab in front.'),
      findsOneWidget,
    );
  });

  testWidgets('says when the browser did not let the sound play', (
    tester,
  ) async {
    player.unlocks = false;
    await save(_alarm('a'));
    await openAlarms(tester, db: db, now: wednesdayEvening, overrides: web());

    await tester.tap(find.text('Arm alarms'));
    await tester.pumpAndSettle();

    expect(
      find.text('The browser did not let the sound play. Try again.'),
      findsOneWidget,
    );
    expect(find.text('Arm alarms'), findsOneWidget);
    expect(wakeLock.held, isFalse);
  });

  testWidgets('lets the screen turn off when no alarm is on', (tester) async {
    await save(_alarm('a'));
    await openAlarms(tester, db: db, now: wednesdayEvening, overrides: web());
    await tester.tap(find.text('Arm alarms'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(wakeLock.held, isFalse);
    expect(find.text('Keep this tab open'), findsOneWidget);
    expect(find.text('The screen stays on.'), findsNothing);
    expect(
      find.text('The screen may turn off. Keep this tab in front.'),
      findsNothing,
    );
  });

  testWidgets('says nothing where alarms need no tap to ring', (tester) async {
    // The other platforms, until Phases 4 to 6, and the tests' Dart VM.
    await save(_alarm('a'));
    await openAlarms(tester, db: db, now: wednesdayEvening);

    expect(find.text('Arm alarms'), findsNothing);
    expect(find.text('Keep this tab open'), findsNothing);
  });
}

Alarm _alarm(String id, {bool enabled = true}) =>
    Alarm(id: id, time: ClockTime(hour: 7, minute: 0), enabled: enabled);
