import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/bedtime.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';

void main() {
  group('bedtimeFor', () {
    test('is the sleep goal before the ring, 8 h by default', () {
      expect(defaultSleepGoal, const Duration(hours: 8));
      expect(bedtimeFor(DateTime(2026, 11, 12, 7)), DateTime(2026, 11, 11, 23));
      expect(
        bedtimeFor(DateTime(2026, 11, 12, 6, 30)),
        DateTime(2026, 11, 11, 22, 30),
      );
    });

    test('takes another sleep goal', () {
      expect(
        bedtimeFor(
          DateTime(2026, 11, 12, 7),
          goal: const Duration(hours: 7, minutes: 30),
        ),
        DateTime(2026, 11, 11, 23, 30),
      );
      expect(
        bedtimeFor(DateTime(2026, 11, 12, 7), goal: const Duration(hours: 10)),
        DateTime(2026, 11, 11, 21),
      );
    });

    test('is the same moment for a ring in UTC', () {
      final ring = DateTime(2026, 11, 12, 7);

      expect(
        bedtimeFor(ring.toUtc()).isAtSameMomentAs(bedtimeFor(ring)),
        isTrue,
      );
    });

    test('rejects a sleep goal that is not positive', () {
      final ring = DateTime(2026, 11, 12, 7);

      expect(() => bedtimeFor(ring, goal: Duration.zero), throwsArgumentError);
      expect(
        () => bedtimeFor(ring, goal: const Duration(hours: -8)),
        throwsArgumentError,
      );
    });
  });

  group('sleepAdvice', () {
    // The ring of a 07:00 alarm on Thursday morning.
    final ring = DateTime(2026, 11, 12, 7);

    test('before the bedtime, says when to go to bed', () {
      for (final now in [
        DateTime(2026, 11, 11, 8),
        DateTime(2026, 11, 11, 22, 59, 59, 999, 999),
      ]) {
        expect(
          sleepAdvice(ring: ring, now: now),
          BedBy(DateTime(2026, 11, 11, 23), goal: defaultSleepGoal),
          reason: 'Now $now',
        );
      }
    });

    test('from the bedtime on, says how long the night still is', () {
      expect(
        sleepAdvice(ring: ring, now: DateTime(2026, 11, 11, 23)),
        const SleepNow(Duration(hours: 8)),
      );
      expect(
        sleepAdvice(ring: ring, now: DateTime(2026, 11, 11, 23, 55)),
        const SleepNow(Duration(hours: 7, minutes: 5)),
      );
      expect(
        sleepAdvice(ring: ring, now: DateTime(2026, 11, 12, 6, 59)),
        const SleepNow(Duration(minutes: 1)),
      );
    });

    test('rounds the night down to whole minutes', () {
      // Nobody sleeps longer than the time that is left.
      expect(
        sleepAdvice(ring: ring, now: DateTime(2026, 11, 11, 23, 40, 30)),
        const SleepNow(Duration(hours: 7, minutes: 19)),
      );
      expect(
        sleepAdvice(ring: ring, now: DateTime(2026, 11, 12, 6, 59, 0, 1)),
        const SleepNow(Duration.zero),
      );
    });

    test('takes another sleep goal', () {
      const goal = Duration(hours: 6);

      expect(
        sleepAdvice(ring: ring, now: DateTime(2026, 11, 11, 23), goal: goal),
        BedBy(DateTime(2026, 11, 12, 1), goal: goal),
      );
      expect(
        sleepAdvice(ring: ring, now: DateTime(2026, 11, 12, 1), goal: goal),
        const SleepNow(goal),
      );
    });

    test('takes now in UTC as the same moment', () {
      expect(
        sleepAdvice(ring: ring, now: DateTime(2026, 11, 11, 22).toUtc()),
        BedBy(DateTime(2026, 11, 11, 23), goal: defaultSleepGoal),
      );
      expect(
        sleepAdvice(ring: ring, now: DateTime(2026, 11, 12, 1).toUtc()),
        const SleepNow(Duration(hours: 6)),
      );
    });

    test('rejects a ring that is not after now', () {
      expect(() => sleepAdvice(ring: ring, now: ring), throwsArgumentError);
      expect(
        () => sleepAdvice(ring: ring, now: DateTime(2026, 11, 12, 8)),
        throwsArgumentError,
      );
    });

    test('says the same as the bedtime it names', () {
      // Every minute of the 24 hours before the ring.
      for (var minutes = 1; minutes <= Duration.minutesPerDay; minutes++) {
        final now = ring.subtract(Duration(minutes: minutes));
        final advice = sleepAdvice(ring: ring, now: now);
        final reason = 'Now $now: $advice';

        switch (advice) {
          case BedBy(:final bedtime, :final goal):
            expect(now.isBefore(bedtime), isTrue, reason: reason);
            expect(ring.difference(bedtime), goal, reason: reason);
          case SleepNow(:final sleep):
            expect(sleep, Duration(minutes: minutes), reason: reason);
            expect(sleep <= defaultSleepGoal, isTrue, reason: reason);
        }
      }
    });
  });

  test('the advice has value equality and a readable form', () {
    final bedtime = DateTime(2026, 11, 11, 23);

    expect(
      BedBy(bedtime, goal: defaultSleepGoal),
      BedBy(DateTime(2026, 11, 11, 23), goal: const Duration(hours: 8)),
    );
    expect(
      BedBy(bedtime, goal: defaultSleepGoal).hashCode,
      BedBy(DateTime(2026, 11, 11, 23), goal: defaultSleepGoal).hashCode,
    );
    expect(
      BedBy(bedtime, goal: defaultSleepGoal),
      isNot(BedBy(bedtime, goal: const Duration(hours: 7))),
    );
    expect(
      const SleepNow(Duration(hours: 7)),
      const SleepNow(Duration(hours: 7)),
    );
    expect(
      const SleepNow(Duration(hours: 7)).hashCode,
      const SleepNow(Duration(hours: 7)).hashCode,
    );
    expect(
      const SleepNow(Duration(hours: 7)),
      isNot(const SleepNow(Duration(hours: 6))),
    );
    expect(
      BedBy(bedtime, goal: defaultSleepGoal).toString(),
      'BedBy(2026-11-11 23:00:00.000, goal: 8:00:00.000000)',
    );
    expect(
      const SleepNow(Duration(hours: 7)).toString(),
      'SleepNow(7:00:00.000000)',
    );
  });

  group('dueBedtimeRing', () {
    // A 07:00 alarm: its bedtime on Wednesday evening is 23:00, for the ring
    // on Thursday morning.
    final seven = _alarm('seven', 7, 0);
    final ring = DateTime(2026, 11, 12, 7);
    DateTime evening(int hour, int minute, [int second = 0]) =>
        DateTime(2026, 11, 11, hour, minute, second);

    test('comes due at the bedtime of the next alarm', () {
      expect(
        dueBedtimeRing([seven], since: evening(22, 59), now: evening(23, 0)),
        ring,
      );
    });

    test('does not come due before the bedtime', () {
      expect(
        dueBedtimeRing(
          [seven],
          since: evening(22, 59),
          now: DateTime(2026, 11, 11, 22, 59, 59, 999, 999),
        ),
        isNull,
      );
    });

    test('comes due once: the check after it finds nothing', () {
      expect(
        dueBedtimeRing([seven], since: evening(23, 0), now: evening(23, 1)),
        isNull,
      );
    });

    test('comes due once a night through a whole day of checks', () {
      final found = _checksThrough(
        [seven],
        from: evening(7, 30),
        to: DateTime(2026, 11, 12, 7, 30),
      );

      expect(found, [ring]);
    });

    test('a late check still finds it, up to the grace', () {
      // A background tab may check once a minute, a laptop wakes much later.
      for (final now in [
        evening(23, 1),
        evening(23, 20),
        DateTime(2026, 11, 11, 23, 29, 59, 999, 999),
      ]) {
        expect(
          dueBedtimeRing([seven], since: evening(22, 40), now: now),
          ring,
          reason: 'Now $now',
        );
      }
    });

    test('a check 30 min after the bedtime or later finds nothing', () {
      expect(bedtimeReminderGrace, const Duration(minutes: 30));
      for (final now in [
        evening(23, 30),
        evening(23, 59),
        // On the morning of the ring, and after it.
        DateTime(2026, 11, 12, 6, 50),
        DateTime(2026, 11, 12, 7, 30),
      ]) {
        expect(
          dueBedtimeRing([seven], since: evening(22, 40), now: now),
          isNull,
          reason: 'Now $now',
        );
      }
    });

    test('after a long gap, only the bedtime that just came counts', () {
      // The laptop slept from Monday evening to Wednesday, 23:05.
      expect(
        dueBedtimeRing(
          [seven],
          since: DateTime(2026, 11, 9, 22),
          now: evening(23, 5),
        ),
        ring,
      );
    });

    test('an alarm set after its bedtime does not come due', () {
      // At 23:30 someone sets an alarm for 07:00.
      expect(
        dueBedtimeRing([seven], since: evening(23, 30), now: evening(23, 31)),
        isNull,
      );
    });

    test('only the next alarm counts, so one reminder a night', () {
      final six = _alarm('six', 6, 0);

      expect(
        dueBedtimeRing(
          [six, seven],
          since: evening(21, 59),
          now: evening(22, 0),
        ),
        DateTime(2026, 11, 12, 6),
      );
      // 23:00 is the bedtime of the 07:00 alarm, which is not the next one.
      expect(
        dueBedtimeRing(
          [six, seven],
          since: evening(22, 59),
          now: evening(23, 0),
        ),
        isNull,
      );
      expect(
        _checksThrough(
          [six, seven],
          from: evening(7, 30),
          to: DateTime(2026, 11, 12, 5, 30),
        ),
        [DateTime(2026, 11, 12, 6)],
      );
    });

    test('an alarm that rings at the bedtime gives way at that moment', () {
      // At 23:00 this alarm rings, and the next one is the 07:00 alarm.
      final eleven = _alarm('eleven', 23, 0);

      expect(
        dueBedtimeRing(
          [eleven, seven],
          since: evening(22, 59),
          now: evening(23, 0),
        ),
        ring,
      );
    });

    test('an alarm that rings before the morning one is the next alarm', () {
      // At 23:00 the next alarm is the one at 23:30, whose bedtime has
      // passed.
      final late = _alarm('late', 23, 30);

      expect(
        dueBedtimeRing(
          [late, seven],
          since: evening(22, 59),
          now: evening(23, 0),
        ),
        isNull,
      );
    });

    test('an alarm in the day has its bedtime in the day', () {
      // As the sleep calculator says it: "Bed by 10:00 AM".
      expect(
        dueBedtimeRing(
          [_alarm('evening', 18, 0)],
          since: evening(9, 59),
          now: evening(10, 0),
        ),
        evening(18, 0),
      );
    });

    test('goes by the days an alarm repeats on', () {
      final weekdays = _alarm('weekdays', 7, 0, days: {1, 2, 3, 4, 5});

      // Friday evening: the next ring is on Monday.
      expect(
        dueBedtimeRing(
          [weekdays],
          since: DateTime(2026, 11, 13, 22, 59),
          now: DateTime(2026, 11, 13, 23),
        ),
        isNull,
      );
      // Sunday evening.
      expect(
        dueBedtimeRing(
          [weekdays],
          since: DateTime(2026, 11, 15, 22, 59),
          now: DateTime(2026, 11, 15, 23),
        ),
        DateTime(2026, 11, 16, 7),
      );
    });

    test('an alarm that is off does not come due', () {
      expect(
        dueBedtimeRing(
          [_alarm('off', 7, 0, enabled: false)],
          since: evening(22, 59),
          now: evening(23, 0),
        ),
        isNull,
      );
      expect(
        dueBedtimeRing(const [], since: evening(22, 59), now: evening(23, 0)),
        isNull,
      );
    });

    test('nothing comes due when the clock was set back', () {
      expect(
        dueBedtimeRing([seven], since: evening(23, 10), now: evening(22, 50)),
        isNull,
      );
    });

    test('takes another sleep goal', () {
      const goal = Duration(hours: 7, minutes: 30);

      expect(
        dueBedtimeRing(
          [seven],
          since: evening(22, 59),
          now: evening(23, 0),
          goal: goal,
        ),
        isNull,
      );
      expect(
        dueBedtimeRing(
          [seven],
          since: evening(23, 29),
          now: evening(23, 30),
          goal: goal,
        ),
        ring,
      );
    });

    test('takes times in UTC', () {
      expect(
        dueBedtimeRing(
          [seven],
          since: evening(22, 59).toUtc(),
          now: evening(23, 0).toUtc(),
        ),
        ring,
      );
    });
  });

  // These tests need a time zone with daylight saving time. CI runs in UTC
  // and runs this file again in each zone of [_dstZones], such as
  // `TZ=Europe/Berlin flutter test test/core/bedtime_test.dart`.
  final zone = _dstZones.where((zone) => zone.isLocal).firstOrNull;
  test('runs the tests of a clock change in the zone TZ names', () {
    // So that they are not skipped because a computer lacks the zone.
    final named = Platform.environment['TZ'];
    if (_dstZones.any((zone) => zone.name == named)) {
      expect(zone?.name, named);
    }
  });
  group(
    'The sleep calculator across a change of the clock in '
    '${zone?.name ?? 'a DST zone'}',
    skip: zone == null
        ? 'Needs the time zone Europe/Berlin or America/New_York (TZ)'
        : false,
    () {
      test('gives a full night when the clock jumps forward', () {
        final z = zone!;
        // The clock jumps from 02:00 to 03:00 in the night before the ring.
        final ring = z.day(z.springForward, 0, 7, 0);
        final bedtime = bedtimeFor(ring);

        // One hour earlier on the clock than on other nights.
        expect(bedtime, z.day(z.springForward, -1, 22, 0));
        expect(ring.difference(bedtime), defaultSleepGoal);
        expect(
          sleepAdvice(ring: ring, now: z.day(z.springForward, -1, 21, 0)),
          BedBy(bedtime, goal: defaultSleepGoal),
        );
      });

      test('gives a full night when the clock goes back', () {
        final z = zone!;
        final ring = z.day(z.fallBack, 0, 7, 0);
        final bedtime = bedtimeFor(ring);

        // One hour later on the clock than on other nights: midnight.
        expect(bedtime, z.day(z.fallBack, 0, 0, 0));
        expect(ring.difference(bedtime), defaultSleepGoal);
      });

      test('counts the night that is left in real time', () {
        final z = zone!;
        // From 01:00 to 07:00 on the clock, but the hour from 02:00 to 03:00
        // never comes.
        expect(
          sleepAdvice(
            ring: z.day(z.springForward, 0, 7, 0),
            now: z.day(z.springForward, 0, 1, 0),
          ),
          const SleepNow(Duration(hours: 5)),
        );
        // From 00:30 to 07:00 on the clock, and the clock shows one hour
        // twice.
        expect(
          sleepAdvice(
            ring: z.day(z.fallBack, 0, 7, 0),
            now: z.day(z.fallBack, 0, 0, 30),
          ),
          const SleepNow(Duration(hours: 7, minutes: 30)),
        );
      });

      test('the reminder comes a full night before the ring', () {
        final z = zone!;
        final seven = _alarm('seven', 7, 0);

        // The clock jumps forward in the night: the bedtime is 22:00.
        expect(
          dueBedtimeRing(
            [seven],
            since: z.day(z.springForward, -1, 21, 59),
            now: z.day(z.springForward, -1, 22, 0),
          ),
          z.day(z.springForward, 0, 7, 0),
        );
        // The clock goes back in the night: the bedtime is midnight.
        expect(
          dueBedtimeRing(
            [seven],
            since: z.day(z.fallBack, -1, 23, 59),
            now: z.day(z.fallBack, 0, 0, 0),
          ),
          z.day(z.fallBack, 0, 7, 0),
        );
      });

      test('the reminder comes once across each change of the clock', () {
        final z = zone!;
        final seven = _alarm('seven', 7, 0);

        expect(
          _checksThrough(
            [seven],
            from: z.day(z.springForward, -1, 12, 0),
            to: z.day(z.springForward, 0, 6, 0),
          ),
          [z.day(z.springForward, 0, 7, 0)],
        );
        expect(
          _checksThrough(
            [seven],
            from: z.day(z.fallBack, -1, 12, 0),
            to: z.day(z.fallBack, 0, 6, 0),
          ),
          [z.day(z.fallBack, 0, 7, 0)],
        );
      });
    },
  );
}

Alarm _alarm(
  String id,
  int hour,
  int minute, {
  Set<int> days = const {},
  bool enabled = true,
}) => Alarm(
  id: id,
  time: ClockTime(hour: hour, minute: minute),
  repeatDays: days,
  enabled: enabled,
);

/// What [dueBedtimeRing] finds when a check runs each minute, [from] until
/// [to].
List<DateTime> _checksThrough(
  List<Alarm> alarms, {
  required DateTime from,
  required DateTime to,
}) => [
  for (
    var since = from;
    since.isBefore(to);
    since = since.add(const Duration(minutes: 1))
  )
    ?dueBedtimeRing(
      alarms,
      since: since,
      now: since.add(const Duration(minutes: 1)),
    ),
];

/// A time zone with daylight saving time in 2026, in which the clock changes
/// on a Sunday. The same zones as in `next_ring_test.dart`.
class _DstZone {
  const _DstZone(
    this.name, {
    required this.springForward,
    required this.fallBack,
    required this.repeatedHour,
  });

  final String name;

  /// The day the clock jumps from 02:00 to 03:00.
  final (int, int, int) springForward;

  /// The day the clock goes back one hour and shows the hour from
  /// [repeatedHour] twice.
  final (int, int, int) fallBack;
  final int repeatedHour;

  /// Whether the tests run in this zone.
  bool get isLocal {
    // On this day, 02:30 does not exist: DateTime moves it to 03:30.
    final skipped = day(springForward, 0, 2, 30);
    // On this day, the moment an hour after the first time the clock shows
    // [repeatedHour]:30 shows it again.
    final repeated = day(
      fallBack,
      0,
      repeatedHour,
      30,
    ).add(const Duration(hours: 1));
    return (skipped.hour, skipped.minute) == (3, 30) &&
        (repeated.hour, repeated.minute) == (repeatedHour, 30);
  }

  /// [hour]:[minute] local time, [offset] days after [date].
  DateTime day((int, int, int) date, int offset, int hour, int minute) {
    final (year, month, dayOfMonth) = date;
    return DateTime(year, month, dayOfMonth + offset, hour, minute);
  }
}

const _dstZones = [
  _DstZone(
    'Europe/Berlin',
    springForward: (2026, 3, 29),
    fallBack: (2026, 10, 25),
    repeatedHour: 2,
  ),
  _DstZone(
    'America/New_York',
    springForward: (2026, 3, 8),
    fallBack: (2026, 11, 1),
    repeatedHour: 1,
  ),
];
