import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/next_ring.dart';

void main() {
  group('nextRing', () {
    test('rings today when its time is still to come', () {
      final alarm = _alarm(7, 0);

      expect(
        nextRing(alarm, DateTime(2026, 11, 11, 6)),
        DateTime(2026, 11, 11, 7),
      );
      expect(
        nextRing(alarm, DateTime(2026, 11, 11, 6, 59, 59, 999, 999)),
        DateTime(2026, 11, 11, 7),
      );
    });

    test('rings tomorrow when its time has passed today', () {
      expect(
        nextRing(_alarm(7, 0), DateTime(2026, 11, 11, 7, 30)),
        DateTime(2026, 11, 12, 7),
      );
    });

    test('rings tomorrow, not now, when now is its time', () {
      // So it rings once a day at most: the ring after a ring is tomorrow's.
      final ring = DateTime(2026, 11, 11, 7);

      expect(nextRing(_alarm(7, 0), ring), DateTime(2026, 11, 12, 7));
    });

    test('rings at the start and at the end of a day', () {
      expect(
        nextRing(_alarm(0, 0), DateTime(2026, 11, 11, 23, 59)),
        DateTime(2026, 11, 12),
      );
      expect(
        nextRing(_alarm(23, 59), DateTime(2026, 11, 11)),
        DateTime(2026, 11, 11, 23, 59),
      );
    });

    test('rings across the end of a month and of a year', () {
      for (final (now, ring) in [
        (DateTime(2026, 11, 30, 8), DateTime(2026, 12, 1, 7)),
        (DateTime(2026, 12, 31, 8), DateTime(2027, 1, 1, 7)),
        (DateTime(2027, 2, 28, 8), DateTime(2027, 3, 1, 7)),
        // 2028 is a leap year.
        (DateTime(2028, 2, 28, 8), DateTime(2028, 2, 29, 7)),
      ]) {
        expect(nextRing(_alarm(7, 0), now), ring, reason: 'Now $now');
      }
    });

    test('a switched-off alarm does not ring', () {
      final now = DateTime(2026, 11, 11, 6);

      expect(nextRing(_alarm(7, 0, enabled: false), now), isNull);
      expect(
        nextRing(_alarm(7, 0, days: _everyDay, enabled: false), now),
        isNull,
      );
    });

    test('rings on its next repeat day', () {
      final alarm = _alarm(
        7,
        0,
        days: {DateTime.monday, DateTime.wednesday, DateTime.friday},
      );

      for (final (now, ring) in [
        // Wednesday before 07:00: today.
        (DateTime(2026, 11, 11, 6), DateTime(2026, 11, 11, 7)),
        // Wednesday after 07:00: Friday.
        (DateTime(2026, 11, 11, 8), DateTime(2026, 11, 13, 7)),
        // Friday after 07:00: Monday, after the weekend.
        (DateTime(2026, 11, 13, 8), DateTime(2026, 11, 16, 7)),
        // Saturday: Monday.
        (DateTime(2026, 11, 14, 6), DateTime(2026, 11, 16, 7)),
      ]) {
        expect(nextRing(alarm, now), ring, reason: 'Now $now');
      }
    });

    test('rings a week later on its only day once its time has passed', () {
      final alarm = _alarm(7, 0, days: {DateTime.wednesday});

      expect(
        nextRing(alarm, DateTime(2026, 11, 11, 7, 0, 0, 1)),
        DateTime(2026, 11, 18, 7),
      );
    });

    test('rings on the first repeat day whose time is still to come', () {
      // Every set of repeat days, from each day of a week, just before, at
      // and just after the alarm's time.
      for (var bits = 1; bits < 1 << DateTime.daysPerWeek; bits++) {
        final days = {
          for (var day = DateTime.monday; day <= DateTime.sunday; day++)
            if (bits & 1 << (day - 1) != 0) day,
        };
        final alarm = _alarm(7, 0, days: days);
        // 2026-11-09 is a Monday.
        for (var date = 9; date < 9 + DateTime.daysPerWeek; date++) {
          for (final now in [
            DateTime(2026, 11, date, 6, 59),
            DateTime(2026, 11, date, 7),
            DateTime(2026, 11, date, 7, 1),
          ]) {
            final ring = nextRing(alarm, now)!;
            final reason = 'Days $days, now $now, ring $ring';

            expect(ring.isAfter(now), isTrue, reason: reason);
            expect((ring.hour, ring.minute, ring.second), (7, 0, 0));
            expect(days, contains(ring.weekday), reason: reason);
            // No repeat day between now and the ring was left out.
            for (
              var day = DateTime(now.year, now.month, now.day);
              day.isBefore(DateTime(ring.year, ring.month, ring.day));
              day = DateTime(day.year, day.month, day.day + 1)
            ) {
              final missed =
                  days.contains(day.weekday) &&
                  DateTime(day.year, day.month, day.day, 7).isAfter(now);
              expect(missed, isFalse, reason: '$reason left out $day');
            }
          }
        }
      }
    });

    test('takes now in UTC as the same moment, and rings in local time', () {
      // 22:00 local time is already the next day in UTC west of Greenwich,
      // such as in New York.
      final now = DateTime(2026, 11, 11, 22);
      for (final alarm in [
        _alarm(23, 0),
        _alarm(23, 0, days: {DateTime.wednesday}),
      ]) {
        final ring = nextRing(alarm, now.toUtc());

        expect(ring, DateTime(2026, 11, 11, 23), reason: '$alarm');
        expect(ring!.isUtc, isFalse);
      }
    });
  });

  // These tests need a time zone with daylight saving time. CI runs in UTC
  // and runs this file again in each zone of [_dstZones], such as
  // `TZ=Europe/Berlin flutter test test/core/next_ring_test.dart`.
  final zone = _dstZones.where((zone) => zone.isLocal).firstOrNull;
  test('runs the tests of a clock change in the zone TZ names', () {
    // So that they are not skipped because a computer lacks the zone.
    final named = Platform.environment['TZ'];
    if (_dstZones.any((zone) => zone.name == named)) {
      expect(zone?.name, named);
    }
  });
  group(
    'nextRing across a change of the clock in ${zone?.name ?? 'a DST zone'}',
    skip: zone == null
        ? 'Needs the time zone Europe/Berlin or America/New_York (TZ)'
        : false,
    () {
      test('keeps its clock time when the clock jumps forward', () {
        final z = zone!;
        // It rang at 07:00 the day before.
        final now = z.day(z.springForward, -1, 7, 0);
        final ring = nextRing(_alarm(7, 0), now)!;

        expect(ring, z.day(z.springForward, 0, 7, 0));
        // The night is one hour shorter.
        expect(ring.difference(now), const Duration(hours: 23));
        expect(
          nextRing(_alarm(7, 0), ring)!.difference(ring),
          const Duration(hours: 24),
        );
      });

      test('keeps its clock time when the clock goes back', () {
        final z = zone!;
        final now = z.day(z.fallBack, -1, 7, 0);
        final ring = nextRing(_alarm(7, 0), now)!;

        expect(ring, z.day(z.fallBack, 0, 7, 0));
        // The night is one hour longer.
        expect(ring.difference(now), const Duration(hours: 25));
      });

      test('keeps its repeat days across a change of the clock', () {
        final z = zone!;
        for (final change in [z.springForward, z.fallBack]) {
          // The clock changes on a Sunday, in both zones.
          final now = z.day(change, -2, 8, 0);
          final alarm = _alarm(7, 0, days: {DateTime.monday});

          expect(nextRing(alarm, now), z.day(change, 1, 7, 0));
        }
      });

      test('rings a time the clock skips as much later as it jumps', () {
        final z = zone!;
        // The clock jumps from 02:00 to 03:00, so 02:30 rings at 03:30: the
        // same time after 01:00 as on any other night.
        final alarm = _alarm(2, 30);

        for (final now in [
          z.day(z.springForward, 0, 1, 0),
          z.day(z.springForward, 0, 1, 59),
        ]) {
          final ring = nextRing(alarm, now)!;

          expect(ring, z.day(z.springForward, 0, 3, 30), reason: 'Now $now');
          expect(
            ring.difference(z.day(z.springForward, 0, 1, 0)),
            const Duration(hours: 1, minutes: 30),
          );
        }
      });

      test('rings a time the clock shows twice the first time only', () {
        final z = zone!;
        final alarm = _alarm(z.repeatedHour, 30);
        final now = z.day(z.fallBack, 0, z.repeatedHour, 0);

        final ring = nextRing(alarm, now)!;
        final after = nextRing(alarm, ring)!;

        expect(ring.difference(now), const Duration(minutes: 30));
        expect(after, z.day(z.fallBack, 1, z.repeatedHour, 30));
        // Not again an hour later, when the clock shows the time again.
        expect(after.difference(ring), const Duration(hours: 25));
      });
    },
  );
}

const _everyDay = {1, 2, 3, 4, 5, 6, 7};

Alarm _alarm(
  int hour,
  int minute, {
  Set<int> days = const {},
  bool enabled = true,
}) => Alarm(
  id: 'a1',
  time: ClockTime(hour: hour, minute: minute),
  repeatDays: days,
  enabled: enabled,
);

/// A time zone with daylight saving time in 2026, in which the clock changes
/// on a Sunday.
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
