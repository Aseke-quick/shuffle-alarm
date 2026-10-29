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
