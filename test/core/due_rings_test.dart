import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/due_rings.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';

void main() {
  group('dueRings', () {
    test('an alarm comes due at its time', () {
      final alarm = _alarm('a', 7, 0);

      expect(
        dueRings(
          [alarm],
          since: DateTime(2026, 11, 11, 6, 59, 59),
          now: DateTime(2026, 11, 11, 7),
        ),
        [DueRing(alarm, scheduledFor: DateTime(2026, 11, 11, 7))],
      );
    });

    test('nothing comes due before its time', () {
      expect(
        dueRings(
          [_alarm('a', 7, 0)],
          since: DateTime(2026, 11, 11, 6, 59),
          now: DateTime(2026, 11, 11, 6, 59, 59, 999, 999),
        ),
        isEmpty,
      );
    });

    test('a ring comes due once: the check after it finds nothing', () {
      // The check before found it at 07:00, so this one starts there.
      expect(
        dueRings(
          [_alarm('a', 7, 0)],
          since: DateTime(2026, 11, 11, 7),
          now: DateTime(2026, 11, 11, 7, 0, 1),
        ),
        isEmpty,
      );
    });

    test('a late check finds the ring, with the time it was set for', () {
      // A background tab may check once a minute.
      final alarm = _alarm('a', 7, 0);

      expect(
        dueRings(
          [alarm],
          since: DateTime(2026, 11, 11, 6, 59, 30),
          now: DateTime(2026, 11, 11, 7, 0, 50),
        ),
        [DueRing(alarm, scheduledFor: DateTime(2026, 11, 11, 7))],
      );
    });

    test('after a long gap, only the last ring of an alarm comes due', () {
      // The device slept for two days.
      final daily = _alarm('daily', 7, 0, days: _everyDay);

      expect(
        dueRings(
          [daily],
          since: DateTime(2026, 11, 9, 6),
          now: DateTime(2026, 11, 11, 8),
        ),
        [DueRing(daily, scheduledFor: DateTime(2026, 11, 11, 7))],
      );
    });

    test('rings on its repeat days only, also across a gap', () {
      final weekdays = _alarm('weekdays', 7, 0, days: {1, 2, 3, 4, 5});
      // Friday 2026-11-13 after the ring, to Monday 2026-11-16.
      final friday = DateTime(2026, 11, 13, 8);

      expect(
        dueRings([weekdays], since: friday, now: DateTime(2026, 11, 16, 6)),
        isEmpty,
      );
      expect(
        dueRings([weekdays], since: friday, now: DateTime(2026, 11, 16, 7, 30)),
        [DueRing(weekdays, scheduledFor: DateTime(2026, 11, 16, 7))],
      );
    });

    test('an alarm that is off never comes due', () {
      expect(
        dueRings(
          [_alarm('off', 7, 0, enabled: false)],
          since: DateTime(2026, 11, 11, 6),
          now: DateTime(2026, 11, 11, 8),
        ),
        isEmpty,
      );
    });

    test('lists several alarms earliest first, then by id', () {
      final b = _alarm('b', 7, 0);
      final a = _alarm('a', 7, 0);
      final early = _alarm('z-early', 6, 59);

      expect(
        dueRings(
          [b, a, early],
          since: DateTime(2026, 11, 11, 6, 58),
          now: DateTime(2026, 11, 11, 7, 1),
        ),
        [
          DueRing(early, scheduledFor: DateTime(2026, 11, 11, 6, 59)),
          DueRing(a, scheduledFor: DateTime(2026, 11, 11, 7)),
          DueRing(b, scheduledFor: DateTime(2026, 11, 11, 7)),
        ],
      );
    });

    test('finds nothing when the clock did not move on', () {
      final alarm = _alarm('a', 7, 0);
      final at = DateTime(2026, 11, 11, 7);

      expect(dueRings([alarm], since: at, now: at), isEmpty);
      // The clock was set back from 07:05 to 06:55.
      expect(
        dueRings(
          [alarm],
          since: DateTime(2026, 11, 11, 7, 5),
          now: DateTime(2026, 11, 11, 6, 55),
        ),
        isEmpty,
      );
    });

    test('works with the times of the check in UTC', () {
      final alarm = _alarm('a', 7, 0);
      final ring = DateTime(2026, 11, 11, 7);

      final due = dueRings(
        [alarm],
        since: ring.subtract(const Duration(seconds: 1)).toUtc(),
        now: ring.toUtc(),
      );

      expect(due, hasLength(1));
      expect(due.single.scheduledFor.isAtSameMomentAs(ring), isTrue);
    });
  });

  group('DueRing', () {
    test('is equal to a ring of the same alarm at the same time', () {
      final alarm = _alarm('a', 7, 0);
      final at = DateTime(2026, 11, 11, 7);

      expect(
        DueRing(alarm, scheduledFor: at),
        DueRing(alarm, scheduledFor: at),
      );
      expect(
        DueRing(alarm, scheduledFor: at).hashCode,
        DueRing(alarm, scheduledFor: at).hashCode,
      );
      expect(
        DueRing(alarm, scheduledFor: at),
        isNot(DueRing(alarm, scheduledFor: at.add(const Duration(days: 1)))),
      );
      expect(
        DueRing(alarm, scheduledFor: at),
        isNot(DueRing(_alarm('b', 7, 0), scheduledFor: at)),
      );
    });
  });

  group('DueRing', () {
    final at = DateTime(2026, 11, 11, 7);
    final back = DateTime(2026, 11, 11, 7, 5);

    test('a first ring starts at the time it was set for', () {
      final ring = DueRing(_alarm('a', 7, 0), scheduledFor: at);

      expect(ring.startsAt, at);
      expect(ring.snoozedSoundId, isNull);
    });

    test('a ring after Snooze keeps that time, and starts at its own', () {
      final ring = DueRing(
        _alarm('a', 7, 0),
        scheduledFor: at,
        startsAt: back,
        snoozedSoundId: 'chime',
      );

      expect(ring.scheduledFor, at);
      expect(ring.startsAt, back);
      expect(ring.snoozedSoundId, 'chime');
    });

    test('rings with another start or snoozed sound are not equal', () {
      final alarm = _alarm('a', 7, 0);
      final ring = DueRing(
        alarm,
        scheduledFor: at,
        startsAt: back,
        snoozedSoundId: 'chime',
      );

      expect(
        ring,
        DueRing(
          alarm,
          scheduledFor: at,
          startsAt: back,
          snoozedSoundId: 'chime',
        ),
      );
      expect(
        ring.hashCode,
        DueRing(
          alarm,
          scheduledFor: at,
          startsAt: back,
          snoozedSoundId: 'chime',
        ).hashCode,
      );
      expect(
        ring,
        isNot(
          DueRing(
            alarm,
            scheduledFor: at,
            startsAt: at,
            snoozedSoundId: 'chime',
          ),
        ),
      );
      expect(
        ring,
        isNot(
          DueRing(
            alarm,
            scheduledFor: at,
            startsAt: back,
            snoozedSoundId: 'bell',
          ),
        ),
      );
    });
  });
}

const _everyDay = {1, 2, 3, 4, 5, 6, 7};

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
