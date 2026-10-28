import 'package:flutter_test/flutter_test.dart';

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

  test('genreName starts a genre with a capital letter', () {
    expect(genreName('pop'), 'Pop');
    expect(genreName('hip-hop'), 'Hip-hop');
    expect(genreName('Jazz'), 'Jazz');
    expect(genreName(''), '');
  });
}
