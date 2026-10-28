import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/models/clock_time.dart';

void main() {
  group('ClockTime', () {
    test('keeps its hour and minute', () {
      final time = ClockTime(hour: 7, minute: 30);

      expect(time.hour, 7);
      expect(time.minute, 30);
    });

    test('accepts the first and the last minute of the day', () {
      expect(ClockTime(hour: 0, minute: 0).toString(), '00:00');
      expect(ClockTime(hour: 23, minute: 59).toString(), '23:59');
    });

    test('rejects an hour outside 0 to 23', () {
      expect(() => ClockTime(hour: -1, minute: 0), throwsRangeError);
      expect(() => ClockTime(hour: 24, minute: 0), throwsRangeError);
    });

    test('rejects a minute outside 0 to 59', () {
      expect(() => ClockTime(hour: 7, minute: -1), throwsRangeError);
      expect(() => ClockTime(hour: 7, minute: 60), throwsRangeError);
    });

    test('equals a time with the same hour and minute', () {
      final time = ClockTime(hour: 7, minute: 30);

      expect(time, ClockTime(hour: 7, minute: 30));
      expect(time.hashCode, ClockTime(hour: 7, minute: 30).hashCode);
      expect(time, isNot(ClockTime(hour: 8, minute: 30)));
      expect(time, isNot(ClockTime(hour: 7, minute: 31)));
    });

    test('prints as 24-hour time with two digits each', () {
      expect(ClockTime(hour: 7, minute: 5).toString(), '07:05');
      expect(ClockTime(hour: 19, minute: 45).toString(), '19:45');
    });
  });
}
