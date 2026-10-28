import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';

void main() {
  group('Alarm', () {
    test('a new alarm is on, starts gently and rings once', () {
      final alarm = Alarm(id: 'a1', time: ClockTime(hour: 7, minute: 30));

      expect(alarm.id, 'a1');
      expect(alarm.time, ClockTime(hour: 7, minute: 30));
      expect(alarm.enabled, isTrue);
      expect(alarm.gentleStart, isTrue);
      expect(alarm.repeatDays, isEmpty);
      expect(alarm.label, isEmpty);
      expect(alarm.genres, isEmpty);
      expect(alarm.experimentGroup, isNull);
    });

    test('keeps every value it was given', () {
      final alarm = Alarm(
        id: 'a1',
        time: ClockTime(hour: 6, minute: 45),
        repeatDays: const {DateTime.monday, DateTime.friday},
        label: 'Gym',
        enabled: false,
        genres: const {'jazz', 'lofi'},
        gentleStart: false,
        experimentGroup: ExperimentGroup.sameSound,
      );

      expect(alarm.time, ClockTime(hour: 6, minute: 45));
      expect(alarm.repeatDays, {DateTime.monday, DateTime.friday});
      expect(alarm.label, 'Gym');
      expect(alarm.enabled, isFalse);
      expect(alarm.genres, {'jazz', 'lofi'});
      expect(alarm.gentleStart, isFalse);
      expect(alarm.experimentGroup, ExperimentGroup.sameSound);
    });

    test('repeats on any day from Monday (1) to Sunday (7)', () {
      final alarm = _alarm(repeatDays: {1, 2, 3, 4, 5, 6, 7});

      expect(alarm.repeatDays, hasLength(7));
    });

    test('rejects a repeat day outside 1 to 7', () {
      expect(() => _alarm(repeatDays: {0}), throwsRangeError);
      expect(() => _alarm(repeatDays: {DateTime.monday, 8}), throwsRangeError);
    });

    test('cannot be changed through its repeat days or genres', () {
      final days = {DateTime.monday};
      final genres = {'jazz'};
      final alarm = _alarm(repeatDays: days, genres: genres);

      days.add(DateTime.tuesday);
      genres.add('rock');

      expect(alarm.repeatDays, {DateTime.monday});
      expect(alarm.genres, {'jazz'});
      expect(
        () => alarm.repeatDays.add(DateTime.sunday),
        throwsUnsupportedError,
      );
      expect(() => alarm.genres.add('pop'), throwsUnsupportedError);
    });

    test('equals an alarm with the same values in any order', () {
      final alarm = _alarm(
        repeatDays: {DateTime.monday, DateTime.friday},
        genres: {'jazz', 'lofi'},
      );
      final same = _alarm(
        repeatDays: {DateTime.friday, DateTime.monday},
        genres: {'lofi', 'jazz'},
      );

      expect(same, alarm);
      expect(same.hashCode, alarm.hashCode);
    });

    test('differs from an alarm with one other value', () {
      final alarm = _alarm();

      for (final other in [
        _alarm(id: 'a2'),
        _alarm(hour: 8),
        _alarm(repeatDays: {DateTime.sunday}),
        _alarm(label: 'Work'),
        _alarm(enabled: false),
        _alarm(genres: {'rock'}),
        _alarm(gentleStart: false),
        _alarm(experimentGroup: ExperimentGroup.sameSound),
        _alarm(experimentGroup: null),
      ]) {
        expect(other, isNot(alarm));
      }
    });
  });

  test('the experiment groups are same sound and rotation', () {
    expect(ExperimentGroup.values.map((group) => group.name), [
      'sameSound',
      'rotation',
    ]);
  });
}

/// An alarm with a value in every field, so a test can change any one of
/// them.
Alarm _alarm({
  String id = 'a1',
  int hour = 7,
  Set<int> repeatDays = const {DateTime.monday},
  String label = 'Gym',
  bool enabled = true,
  Set<String> genres = const {'jazz'},
  bool gentleStart = true,
  ExperimentGroup? experimentGroup = ExperimentGroup.rotation,
}) => Alarm(
  id: id,
  time: ClockTime(hour: hour, minute: 30),
  repeatDays: repeatDays,
  label: label,
  enabled: enabled,
  genres: genres,
  gentleStart: gentleStart,
  experimentGroup: experimentGroup,
);
