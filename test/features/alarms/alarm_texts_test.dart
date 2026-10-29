import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/bedtime.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/features/alarms/alarm_texts.dart';

void main() {
  group('ringsIn', () {
    test('says hours and minutes', () {
      expect(
        ringsIn(const Duration(hours: 7, minutes: 20)),
        'Rings in 7 h 20 min',
      );
      expect(ringsIn(const Duration(minutes: 20)), 'Rings in 20 min');
      expect(ringsIn(const Duration(hours: 7)), 'Rings in 7 h');
    });

    test('rounds up to whole minutes, as the clock counts them', () {
      // At 23:40:30, an alarm at 07:00 rings in 7 h 19 min 30 s, but the
      // clock shows 23:40, which is 7 h 20 min before 07:00.
      expect(
        ringsIn(const Duration(hours: 7, minutes: 19, seconds: 30)),
        'Rings in 7 h 20 min',
      );
      expect(
        ringsIn(const Duration(hours: 7, minutes: 19, microseconds: 1)),
        'Rings in 7 h 20 min',
      );
      expect(ringsIn(const Duration(minutes: 59, seconds: 1)), 'Rings in 1 h');
      expect(ringsIn(const Duration(microseconds: 1)), 'Rings in 1 min');
    });

    test('says days from 24 hours on, and leaves out the parts that are 0', () {
      expect(ringsIn(const Duration(hours: 24)), 'Rings in 1 d');
      expect(
        ringsIn(const Duration(days: 1, hours: 2, minutes: 5)),
        'Rings in 1 d 2 h 5 min',
      );
      expect(
        ringsIn(const Duration(days: 2, minutes: 5)),
        'Rings in 2 d 5 min',
      );
      // The longest wait: an alarm for one day of the week that just rang.
      expect(
        ringsIn(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59)),
        'Rings in 7 d',
      );
    });
  });

  group('repeatText', () {
    test('says how often an alarm rings', () {
      expect(repeatText(const {}), 'Once');
      expect(repeatText(const {1, 2, 3, 4, 5, 6, 7}), 'Every day');
      expect(repeatText(const {1, 2, 3, 4, 5}), 'Weekdays');
      expect(repeatText(const {6, 7}), 'Weekends');
    });

    test('names the other days from Monday on', () {
      expect(repeatText(const {DateTime.friday}), 'Fri');
      expect(
        repeatText(const {
          DateTime.friday,
          DateTime.monday,
          DateTime.wednesday,
        }),
        'Mon, Wed, Fri',
      );
      expect(repeatText(const {DateTime.sunday, DateTime.monday}), 'Mon, Sun');
      expect(
        repeatText(const {1, 2, 3, 4, 5, 6}),
        'Mon, Tue, Wed, Thu, Fri, Sat',
      );
    });
  });

  test('dayName names every weekday from Monday to Sunday', () {
    expect(
      [
        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
          dayName(day),
      ],
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    );
  });

  test('fullDayName names every weekday in full, for screen readers', () {
    expect(
      [
        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
          fullDayName(day),
      ],
      [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ],
    );
  });

  test('countdownText counts down like ringsIn, for the record', () {
    expect(
      countdownText(const Duration(hours: 7, minutes: 19, seconds: 30)),
      'in 7 h 20 min',
    );
    expect(countdownText(const Duration(days: 1, hours: 2)), 'in 1 d 2 h');
    expect(countdownText(const Duration(microseconds: 1)), 'in 1 min');
  });

  test('alarmDetails gives the label, if any, and the repeat days', () {
    final alarm = Alarm(
      id: 'a',
      time: ClockTime(hour: 7, minute: 0),
      repeatDays: const {1, 2, 3, 4, 5},
      label: 'Work',
    );

    expect(alarmDetails(alarm), 'Work · Weekdays');
    expect(alarmDetails(alarm.copyWith(label: '')), 'Weekdays');
    expect(alarmDetails(alarm.copyWith(label: '', repeatDays: {})), 'Once');
  });

  group('sleepText', () {
    // Wednesday evening.
    final now = DateTime(2026, 11, 11, 20);
    String clock(DateTime time) =>
        '${time.hour}:${time.minute.toString().padLeft(2, '0')}';

    test('before the bedtime, says when to go to bed', () {
      expect(
        sleepText(
          BedBy(DateTime(2026, 11, 11, 22, 30), goal: defaultSleepGoal),
          now: now,
          clock: clock,
        ),
        'Bed by 22:30 for 8 h of sleep',
      );
      expect(
        sleepText(
          BedBy(
            DateTime(2026, 11, 11, 23),
            goal: const Duration(hours: 7, minutes: 30),
          ),
          now: now,
          clock: clock,
        ),
        'Bed by 23:00 for 7 h 30 min of sleep',
      );
    });

    test('names the day of a bedtime that is not today', () {
      // After midnight it is Thursday, and so are bedtimes of the weekend.
      for (final (bedtime, text) in [
        (DateTime(2026, 11, 12, 0, 30), 'Bed by Thu 0:30 for 8 h of sleep'),
        (DateTime(2026, 11, 15, 23), 'Bed by Sun 23:00 for 8 h of sleep'),
      ]) {
        expect(
          sleepText(
            BedBy(bedtime, goal: defaultSleepGoal),
            now: now,
            clock: clock,
          ),
          text,
        );
      }
    });

    test('takes a bedtime in UTC as local time', () {
      expect(
        sleepText(
          BedBy(DateTime(2026, 11, 11, 22, 30).toUtc(), goal: defaultSleepGoal),
          now: now,
          clock: clock,
        ),
        'Bed by 22:30 for 8 h of sleep',
      );
    });

    test('from the bedtime on, says how long the night is', () {
      expect(
        sleepText(
          const SleepNow(Duration(hours: 7, minutes: 5)),
          now: now,
          clock: clock,
        ),
        'Sleep now: 7 h 5 min',
      );
      expect(
        sleepText(const SleepNow(Duration(hours: 8)), now: now, clock: clock),
        'Sleep now: 8 h',
      );
      expect(
        sleepText(const SleepNow(Duration.zero), now: now, clock: clock),
        'Sleep now: under 1 min',
      );
    });
  });

  test('genreName starts a genre with a capital letter', () {
    expect(genreName('pop'), 'Pop');
    expect(genreName('hip-hop'), 'Hip-hop');
    expect(genreName('Jazz'), 'Jazz');
    expect(genreName(''), '');
  });
}
