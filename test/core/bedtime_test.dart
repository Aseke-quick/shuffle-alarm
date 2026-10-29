import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/bedtime.dart';

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
    },
  );
}

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
