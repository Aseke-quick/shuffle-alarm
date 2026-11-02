import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/due_rings.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/platform/alarm_scheduler.dart';
import 'package:shuffle_alarm/platform/ticking_alarm_scheduler.dart';

/// The timers run on the fake time of a widget test, and the clock of the
/// scheduler is [_Clock], which the test moves on with them.
void main() {
  testWidgets('checks the clock every second, and tells about a ring once', (
    tester,
  ) async {
    final clock = _Clock(DateTime(2026, 11, 11, 6, 59, 58));
    final scheduler = TickingAlarmScheduler(now: clock.now);
    final due = _listen(scheduler);
    final alarm = _alarm('a', 7, 0);

    scheduler.watch([alarm]);
    await clock.tick(tester);
    expect(due, isEmpty);
    await clock.tick(tester);
    expect(due, [DueRing(alarm, scheduledFor: DateTime(2026, 11, 11, 7))]);
    for (var i = 0; i < 5; i++) {
      await clock.tick(tester);
    }
    expect(due, hasLength(1));

    unawaited(scheduler.dispose());
  });

  testWidgets('a late tick finds the ring, with the time it was set for', (
    tester,
  ) async {
    // As in a background tab whose timer runs once a minute.
    final clock = _Clock(DateTime(2026, 11, 11, 6, 59, 30));
    final scheduler = TickingAlarmScheduler(now: clock.now);
    final due = _listen(scheduler);
    final alarm = _alarm('a', 7, 0);

    scheduler.watch([alarm]);
    clock.time = DateTime(2026, 11, 11, 7, 0, 50);
    await tester.pump(scheduler.interval);

    expect(due, [DueRing(alarm, scheduledFor: DateTime(2026, 11, 11, 7))]);
    unawaited(scheduler.dispose());
  });

  testWidgets('a wake-up checks at once, between two ticks', (tester) async {
    final clock = _Clock(DateTime(2026, 11, 11, 6, 59, 59));
    final wakeUps = StreamController<void>(sync: true);
    final scheduler = TickingAlarmScheduler(
      now: clock.now,
      wakeUps: wakeUps.stream,
      interval: const Duration(minutes: 1),
    );
    final due = _listen(scheduler);
    final alarm = _alarm('a', 7, 0);

    scheduler.watch([alarm]);
    clock.time = DateTime(2026, 11, 11, 7, 0, 1);
    wakeUps.add(null);

    expect(due, [DueRing(alarm, scheduledFor: DateTime(2026, 11, 11, 7))]);
    unawaited(scheduler.dispose());
  });

  testWidgets('a ring before the first watch does not come due', (
    tester,
  ) async {
    // The app opened at 07:05; the 07:00 ring was while it was closed.
    final clock = _Clock(DateTime(2026, 11, 11, 7, 5));
    final scheduler = TickingAlarmScheduler(now: clock.now);
    final due = _listen(scheduler);

    scheduler.watch([_alarm('a', 7, 0)]);
    await clock.tick(tester);

    expect(due, isEmpty);
    unawaited(scheduler.dispose());
  });

  testWidgets('watches the alarms it was given last', (tester) async {
    final clock = _Clock(DateTime(2026, 11, 11, 6, 59, 59));
    final scheduler = TickingAlarmScheduler(now: clock.now);
    final due = _listen(scheduler);
    final kept = _alarm('kept', 7, 0);

    scheduler
      ..watch([_alarm('deleted', 7, 0)])
      ..watch([kept]);
    await clock.tick(tester);

    expect(due, [DueRing(kept, scheduledFor: DateTime(2026, 11, 11, 7))]);
    unawaited(scheduler.dispose());
  });

  group('A scheduled ring, such as one after Snooze,', () {
    final back = DueRing(
      _alarm('a', 7, 0),
      scheduledFor: DateTime(2026, 11, 11, 7),
      startsAt: DateTime(2026, 11, 11, 7, 5),
      snoozedSoundId: 'chime',
    );

    testWidgets('comes due at its start, once', (tester) async {
      final clock = _Clock(DateTime(2026, 11, 11, 7, 4, 58));
      final scheduler = TickingAlarmScheduler(now: clock.now);
      final due = _listen(scheduler);

      scheduler
        ..watch(const [])
        ..schedule(back);
      await clock.tick(tester);
      expect(due, isEmpty);
      await clock.tick(tester);
      expect(due, [back]);
      for (var i = 0; i < 5; i++) {
        await clock.tick(tester);
      }
      expect(due, hasLength(1));

      unawaited(scheduler.dispose());
    });

    testWidgets('comes due at a late tick, as in a background tab', (
      tester,
    ) async {
      final clock = _Clock(DateTime(2026, 11, 11, 7, 4, 30));
      final scheduler = TickingAlarmScheduler(now: clock.now);
      final due = _listen(scheduler);

      scheduler
        ..watch(const [])
        ..schedule(back);
      clock.time = DateTime(2026, 11, 11, 7, 5, 50);
      await tester.pump(scheduler.interval);

      expect(due, [back]);
      unawaited(scheduler.dispose());
    });

    testWidgets('comes due at a wake-up, between two ticks', (tester) async {
      final clock = _Clock(DateTime(2026, 11, 11, 7, 4, 59));
      final wakeUps = StreamController<void>(sync: true);
      final scheduler = TickingAlarmScheduler(
        now: clock.now,
        wakeUps: wakeUps.stream,
        interval: const Duration(minutes: 1),
      );
      final due = _listen(scheduler);

      scheduler
        ..watch(const [])
        ..schedule(back);
      clock.time = DateTime(2026, 11, 11, 7, 5, 1);
      wakeUps.add(null);

      expect(due, [back]);
      unawaited(scheduler.dispose());
    });

    testWidgets('comes due also when its start is behind the first watch', (
      tester,
    ) async {
      // The app opened again after the snooze ended.
      final clock = _Clock(DateTime(2026, 11, 11, 7, 7));
      final scheduler = TickingAlarmScheduler(now: clock.now);
      final due = _listen(scheduler);

      scheduler
        ..schedule(back)
        ..watch(const []);
      await clock.tick(tester);

      expect(due, [back]);
      unawaited(scheduler.dispose());
    });

    testWidgets('comes due also when the clock was set back past its start', (
      tester,
    ) async {
      final clock = _Clock(DateTime(2026, 11, 11, 7, 30));
      final scheduler = TickingAlarmScheduler(now: clock.now);
      final due = _listen(scheduler);

      scheduler
        ..watch(const [])
        ..schedule(back);
      clock.time = DateTime(2026, 11, 11, 7, 6);
      await tester.pump(scheduler.interval);

      expect(due, [back]);
      unawaited(scheduler.dispose());
    });

    testWidgets('does not come due once it was cancelled', (tester) async {
      final clock = _Clock(DateTime(2026, 11, 11, 7, 4, 59));
      final scheduler = TickingAlarmScheduler(now: clock.now);
      final due = _listen(scheduler);

      scheduler
        ..watch(const [])
        ..schedule(back)
        ..cancel(back);
      await clock.tick(tester);

      expect(due, isEmpty);
      unawaited(scheduler.dispose());
    });

    testWidgets('comes in order of time with the alarms of that check', (
      tester,
    ) async {
      final clock = _Clock(DateTime(2026, 11, 11, 6, 59, 30));
      final scheduler = TickingAlarmScheduler(now: clock.now);
      final due = _listen(scheduler);
      final later = _alarm('later', 7, 6);
      final earlier = DueRing(
        _alarm('b', 6, 0),
        scheduledFor: DateTime(2026, 11, 11, 6),
        startsAt: DateTime(2026, 11, 11, 7, 1),
        snoozedSoundId: 'bell',
      );

      scheduler
        ..watch([later])
        ..schedule(back)
        ..schedule(earlier);
      clock.time = DateTime(2026, 11, 11, 7, 6, 30);
      await tester.pump(scheduler.interval);

      expect(due, [
        earlier,
        back,
        DueRing(later, scheduledFor: DateTime(2026, 11, 11, 7, 6)),
      ]);
      unawaited(scheduler.dispose());
    });
  });

  testWidgets('stops checking when disposed', (tester) async {
    final clock = _Clock(DateTime(2026, 11, 11, 6, 59, 59));
    final scheduler = TickingAlarmScheduler(now: clock.now);
    final due = <DueRing>[];
    scheduler.dueRings.listen(due.add);

    scheduler.watch([_alarm('a', 7, 0)]);
    unawaited(scheduler.dispose());
    await clock.tick(tester);
    scheduler.check();

    expect(due, isEmpty);
  });

  test('rings alarms; the idle scheduler of other platforms does not', () {
    expect(TickingAlarmScheduler().ringsAlarms, isTrue);
    const idle = IdleAlarmScheduler();
    expect(idle.ringsAlarms, isFalse);
    expect(idle.dueRings, emitsDone);
  });

  test('the idle scheduler takes a scheduled ring, and it never comes due', () {
    const idle = IdleAlarmScheduler();
    final ring = DueRing(
      _alarm('a', 7, 0),
      scheduledFor: DateTime(2026, 11, 11, 7),
    );

    idle
      ..schedule(ring)
      ..cancel(ring);

    expect(idle.dueRings, emitsDone);
  });
}

/// A clock that the test moves on.
class _Clock {
  _Clock(this.time);

  DateTime time;

  DateTime now() => time;

  /// One second on, for the clock and for the timers.
  Future<void> tick(WidgetTester tester) async {
    time = time.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }
}

List<DueRing> _listen(AlarmScheduler scheduler) {
  final due = <DueRing>[];
  scheduler.dueRings.listen(due.add);
  return due;
}

Alarm _alarm(String id, int hour, int minute) => Alarm(
  id: id,
  time: ClockTime(hour: hour, minute: minute),
);
