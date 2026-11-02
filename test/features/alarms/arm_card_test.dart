import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/due_rings.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/data/ring_session_repository.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/platform/providers.dart';

import '../../data/memory_database.dart';
import '../../design/design_app.dart';
import '../../platform/fake_platform.dart';
import 'alarms_app.dart';

void main() {
  late AppDatabase db;
  late FakeAlarmScheduler scheduler;
  late FakeSoundPlayer player;
  late FakeScreenWakeLock wakeLock;
  late DateTime now;

  setUp(() {
    db = memoryDatabase();
    scheduler = FakeAlarmScheduler();
    player = FakeSoundPlayer();
    wakeLock = FakeScreenWakeLock();
    now = DateTime(2026, 11, 12, 7);
  });
  // Not closed: see memoryDatabase().

  /// The web version: alarms ring, after a tap that unlocks their sound.
  List<Override> web() => [
    alarmSchedulerProvider.overrideWithValue(scheduler),
    soundPlayerProvider.overrideWithValue(player),
    screenWakeLockProvider.overrideWithValue(wakeLock),
    nowProvider.overrideWithValue(() => now),
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

  group('The screen stays on', () {
    Future<Alarm> armed(WidgetTester tester, {required bool oneTime}) async {
      askForLessMotion(tester);
      final alarm = Alarm(
        id: 'a',
        time: ClockTime(hour: 7, minute: 0),
        repeatDays: oneTime ? const {} : const {1, 2, 3, 4, 5, 6, 7},
      );
      await save(alarm);
      await openAlarms(tester, db: db, now: wednesdayEvening, overrides: web());
      await tester.tap(find.text('Arm alarms'));
      await tester.pumpAndSettle();
      expect(wakeLock.held, isTrue);
      return alarm;
    }

    testWidgets('while a one-time alarm rings, which is off by then', (
      tester,
    ) async {
      final alarm = await armed(tester, oneTime: true);

      scheduler.ring(DueRing(alarm, scheduledFor: now));
      await tester.pumpAndSettle();

      expect((await AlarmRepository(db).byId('a'))!.enabled, isFalse);
      expect(wakeLock.held, isTrue);

      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
      expect(wakeLock.held, isFalse);
    });

    testWidgets('during the snooze of a one-time alarm, until it ends', (
      tester,
    ) async {
      final alarm = await armed(tester, oneTime: true);
      scheduler.ring(DueRing(alarm, scheduledFor: now));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Snooze 5 min'));
      await tester.pumpAndSettle();
      expect(wakeLock.held, isTrue);
      expect(find.text('The screen stays on.'), findsOneWidget);

      await tester.tap(find.text('Stop alarm'));
      await tester.pumpAndSettle();
      expect(wakeLock.held, isFalse);
    });

    testWidgets('not after a one-time alarm went quiet at its cap', (
      tester,
    ) async {
      final alarm = await armed(tester, oneTime: true);
      scheduler.ring(DueRing(alarm, scheduledFor: now));
      await tester.pumpAndSettle();

      now = now.add(const Duration(minutes: 10));
      player.finishClip();
      await tester.pumpAndSettle();

      expect(find.text('Close'), findsOneWidget);
      expect(wakeLock.held, isFalse);
    });

    testWidgets('for the next alarm, after one rang', (tester) async {
      final alarm = await armed(tester, oneTime: false);
      scheduler.ring(DueRing(alarm, scheduledFor: now));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      expect(wakeLock.held, isTrue);
    });
  });

  testWidgets('asks to arm while a snooze waits, with no alarm on', (
    tester,
  ) async {
    // A reload during the snooze of a one-time alarm: the sound is locked
    // again, and it still has to ring.
    await save(_alarm('a', enabled: false));
    await RingSessionRepository(db).save(
      RingSession(
        id: 's',
        alarmId: 'a',
        scheduledFor: DateTime(2026, 11, 12, 7),
        events: [
          RingEvent(
            soundId: 'chime',
            startedAt: DateTime(2026, 11, 12, 7),
            endedAt: DateTime(2026, 11, 12, 7, 0, 30),
            action: RingAction.snooze,
          ),
        ],
      ),
    );

    await openAlarms(tester, db: db, now: wednesdayEvening, overrides: web());

    expect(find.text('Arm alarms'), findsOneWidget);
    await tester.tap(find.text('Arm alarms'));
    await tester.pumpAndSettle();
    expect(wakeLock.held, isTrue);
  });

  testWidgets('Arm alarms loads the library when the database has no sounds', (
    tester,
  ) async {
    await db.delete(db.sounds).go();
    await save(_alarm('a'));
    await openAlarms(
      tester,
      db: db,
      now: wednesdayEvening,
      overrides: [
        ...web(),
        libraryClipsProvider.overrideWithValue(
          () async => [
            StoredSound(
              Sound(
                id: 'file',
                title: 'File',
                source: SoundSource.builtin,
                genre: 'calm',
                intensity: 1,
                duration: const Duration(seconds: 20),
              ),
              audioPath: 'assets/library/calm/file.wav',
            ),
          ],
        ),
      ],
    );

    await tester.tap(find.text('Arm alarms'));
    await tester.pumpAndSettle();

    expect(player.preloaded, ['assets/library/calm/file.wav']);
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
