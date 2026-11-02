import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';

void main() {
  group('RingSession', () {
    test('starts without events', () {
      final session = RingSession(
        id: 's1',
        alarmId: 'a1',
        scheduledFor: DateTime(2026, 10, 29, 7),
      );

      expect(session.id, 's1');
      expect(session.alarmId, 'a1');
      expect(session.scheduledFor, DateTime(2026, 10, 29, 7));
      expect(session.events, isEmpty);
    });

    test('keeps its events in the order they played, snoozes included', () {
      final session = _session();

      expect(session.events, _snoozedThenStopped());
      expect(session.events.map((event) => event.action), [
        RingAction.timeout,
        RingAction.snooze,
        RingAction.stop,
      ]);
    });

    test('cannot be changed through its events', () {
      final events = _snoozedThenStopped();
      final session = _session(events: events);

      events.removeLast();

      expect(session.events, hasLength(3));
      expect(() => session.events.add(events.first), throwsUnsupportedError);
    });

    test('equals a session with the same values', () {
      expect(_session(), _session());
      expect(_session().hashCode, _session().hashCode);
    });

    test('differs from a session with one other value', () {
      final session = _session();

      for (final other in [
        _session(id: 's2'),
        _session(alarmId: 'a2'),
        _session(scheduledFor: DateTime(2026, 10, 30, 7)),
        _session(events: _snoozedThenStopped().reversed.toList()),
        _session(events: _snoozedThenStopped().sublist(0, 2)),
      ]) {
        expect(other, isNot(session));
      }
    });
  });

  group('RingSession.outcome', () {
    test('a session that made no sound is missed', () {
      expect(_session(events: const []).outcome, RingOutcome.missed);
    });

    test('a session whose last sound ran out is missed', () {
      expect(_session(events: [_timeout]).outcome, RingOutcome.missed);
    });

    test('a session whose last event is a Stop is stopped', () {
      expect(_session(events: [_timeout, _stop]).outcome, RingOutcome.stopped);
    });

    test('a session whose last event is a Snooze is snoozed', () {
      expect(
        _session(events: [_timeout, _snooze]).outcome,
        RingOutcome.snoozed,
      );
    });

    test('only the last event counts', () {
      expect(_session().outcome, RingOutcome.stopped);
      expect(_session(events: [_snooze, _timeout]).outcome, RingOutcome.missed);
    });
  });

  group('RingSession.withEvent', () {
    test('gives the session with the event at its end', () {
      expect(
        _session(events: [_timeout]).withEvent(_stop),
        _session(events: [_timeout, _stop]),
      );
    });

    test('leaves the session it came from as it is', () {
      final session = _session(events: [_timeout]);

      expect(session.withEvent(_stop), isNot(session));

      expect(session.events, [_timeout]);
    });
  });

  group('RingSession.missedAt', () {
    final at = DateTime(2026, 10, 29, 7, 20);

    test('a snoozed session ends with a silent event of its last sound', () {
      final missed = _session(events: [_timeout, _snooze]).missedAt(at);

      expect(
        missed.events.last,
        RingEvent.silent(
          soundId: _snooze.soundId,
          at: at,
          action: RingAction.timeout,
        ),
      );
      expect(missed.events, hasLength(3));
      expect(missed.outcome, RingOutcome.missed);
    });

    test('a session that is missed already stays as it is', () {
      for (final session in [
        _session(events: const []),
        _session(events: [_timeout]),
      ]) {
        expect(session.missedAt(at), session);
      }
    });
  });
}

/// A session of a 07:00 alarm, by default with [_snoozedThenStopped] events.
RingSession _session({
  String id = 's1',
  String alarmId = 'a1',
  DateTime? scheduledFor,
  List<RingEvent>? events,
}) => RingSession(
  id: id,
  alarmId: alarmId,
  scheduledFor: scheduledFor ?? DateTime(2026, 10, 29, 7),
  events: events ?? _snoozedThenStopped(),
);

/// A 07:00 alarm: the first sound played for its full 30 seconds, the second
/// was snoozed, and the first sound after the 5-minute snooze was stopped.
List<RingEvent> _snoozedThenStopped() => [
  RingEvent(
    soundId: 'pop-01',
    startedAt: DateTime(2026, 10, 29, 7),
    endedAt: DateTime(2026, 10, 29, 7, 0, 30),
    action: RingAction.timeout,
  ),
  RingEvent(
    soundId: 'jazz-02',
    startedAt: DateTime(2026, 10, 29, 7, 0, 30),
    endedAt: DateTime(2026, 10, 29, 7, 0, 41),
    action: RingAction.snooze,
  ),
  RingEvent(
    soundId: 'rock-03',
    startedAt: DateTime(2026, 10, 29, 7, 5, 41),
    endedAt: DateTime(2026, 10, 29, 7, 5, 52),
    action: RingAction.stop,
  ),
];

final RingEvent _timeout = _snoozedThenStopped()[0];
final RingEvent _snooze = _snoozedThenStopped()[1];
final RingEvent _stop = _snoozedThenStopped()[2];
