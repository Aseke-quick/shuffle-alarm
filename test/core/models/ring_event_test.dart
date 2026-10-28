import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/models/ring_event.dart';

void main() {
  group('RingEvent', () {
    test('keeps every value it was given', () {
      final event = RingEvent(
        soundId: 'pop-01',
        startedAt: DateTime(2026, 10, 29, 7),
        endedAt: DateTime(2026, 10, 29, 7, 0, 30),
        action: RingAction.timeout,
      );

      expect(event.soundId, 'pop-01');
      expect(event.startedAt, DateTime(2026, 10, 29, 7));
      expect(event.endedAt, DateTime(2026, 10, 29, 7, 0, 30));
      expect(event.action, RingAction.timeout);
    });

    test('accepts an end before its start, as the clock can jump back', () {
      final event = _event(endedAt: DateTime(2026, 10, 29, 6, 59, 58));

      expect(event.endedAt.isBefore(event.startedAt), isTrue);
    });

    test('equals an event with the same values', () {
      expect(_event(), _event());
      expect(_event().hashCode, _event().hashCode);
    });

    test('differs from an event with one other value', () {
      final event = _event();

      for (final other in [
        _event(soundId: 'pop-02'),
        _event(startedAt: DateTime(2026, 10, 29, 7, 0, 1)),
        _event(endedAt: DateTime(2026, 10, 29, 7, 0, 29)),
        _event(action: RingAction.stop),
      ]) {
        expect(other, isNot(event));
      }
    });
  });

  test('a sound ends by Stop, by Snooze, or when its time runs out', () {
    expect(RingAction.values.map((action) => action.name), [
      'stop',
      'snooze',
      'timeout',
    ]);
  });
}

/// The first sound of a 07:00 alarm, which played for its full 30 seconds.
RingEvent _event({
  String soundId = 'pop-01',
  DateTime? startedAt,
  DateTime? endedAt,
  RingAction action = RingAction.timeout,
}) => RingEvent(
  soundId: soundId,
  startedAt: startedAt ?? DateTime(2026, 10, 29, 7),
  endedAt: endedAt ?? DateTime(2026, 10, 29, 7, 0, 30),
  action: action,
);
