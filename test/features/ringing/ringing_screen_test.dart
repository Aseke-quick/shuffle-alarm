import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/due_rings.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/features/alarms/alarms_screen.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/ringing/ringing_screen.dart';
import 'package:shuffle_alarm/platform/providers.dart';

import '../../data/memory_database.dart';
import '../../platform/fake_platform.dart';
import '../alarms/alarms_app.dart';

void main() {
  late AppDatabase db;
  late FakeAlarmScheduler scheduler;
  late FakeSoundPlayer player;
  late DateTime now;

  setUp(() {
    db = memoryDatabase();
    scheduler = FakeAlarmScheduler();
    player = FakeSoundPlayer(needsUnlock: false);
    now = DateTime(2026, 11, 12, 7);
  });
  // Not closed: see memoryDatabase().

  List<Override> web() => [
    alarmSchedulerProvider.overrideWithValue(scheduler),
    soundPlayerProvider.overrideWithValue(player),
    screenWakeLockProvider.overrideWithValue(FakeScreenWakeLock()),
    nowProvider.overrideWithValue(() => now),
  ];

  /// The app on the Alarms tab, with one sound and [alarm].
  Future<void> open(WidgetTester tester, Alarm alarm) async {
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
    await AlarmRepository(db).save(alarm);
    await openAlarms(tester, db: db, now: wednesdayEvening, overrides: web());
  }

  /// [alarm] comes due at 07:00 on Thursday.
  Future<void> ring(WidgetTester tester, Alarm alarm) async {
    scheduler.ring(DueRing(alarm, scheduledFor: now));
    await tester.pumpAndSettle();
  }

  testWidgets('a ring opens the ringing page above the tabs; Stop ends it', (
    tester,
  ) async {
    final alarm = _alarm(label: 'Gym');
    await open(tester, alarm);

    await ring(tester, alarm);

    expect(find.byType(RingingScreen), findsOneWidget);
    expect(find.text('ALARM'), findsOneWidget);
    expect(find.text('7:00 AM'), findsOneWidget);
    expect(find.text('Gym'), findsOneWidget);
    expect(player.plays, hasLength(1));

    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();

    expect(find.byType(RingingScreen), findsNothing);
    expect(find.byType(AlarmsScreen), findsOneWidget);
    expect(player.stopCalls, 1);
  });

  testWidgets('Back does not end a ring', (tester) async {
    final alarm = _alarm();
    await open(tester, alarm);
    await ring(tester, alarm);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(RingingScreen), findsOneWidget);
  });

  testWidgets('a one-time alarm is off after its ring', (tester) async {
    final alarm = _alarm();
    await open(tester, alarm);

    await ring(tester, alarm);
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();

    expect(find.text('Off'), findsOneWidget);
  });

  testWidgets('a blocked sound offers to play it', (tester) async {
    player.blocked = true;
    final alarm = _alarm();
    await open(tester, alarm);

    await ring(tester, alarm);

    expect(find.text('The sound did not play.'), findsOneWidget);
    await tester.tap(find.text('Play sound'));
    await tester.pumpAndSettle();

    expect(player.unlockCalls, 1);
    expect(player.plays, hasLength(1));
    expect(find.text('Play sound'), findsNothing);
  });

  testWidgets('a ring that reached its cap says so, and Close ends it', (
    tester,
  ) async {
    final alarm = _alarm();
    await open(tester, alarm);
    await ring(tester, alarm);

    now = now.add(const Duration(minutes: 10));
    player.finishClip();
    await tester.pumpAndSettle();

    expect(
      find.text('It rang for 10 min, and nobody stopped it.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(RingingScreen), findsNothing);
  });
}

Alarm _alarm({String label = ''}) =>
    Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0), label: label);
