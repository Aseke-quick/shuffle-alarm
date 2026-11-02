import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/due_rings.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/core/snooze.dart';

void main() {
  final alarm = Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0));
  final set = DateTime(2026, 11, 11, 7);

  test('Snooze lasts 5 min by default', () {
    expect(defaultSnooze, const Duration(minutes: 5));
  });

  group('ringAfterSnooze', () {
    final tap = DateTime(2026, 11, 11, 7, 0, 42);

    test(
      'starts the snooze after the tap, and keeps the alarm and its time',
      () {
        final back = ringAfterSnooze(
          DueRing(alarm, scheduledFor: set),
          soundId: 'chime',
          at: tap,
        );

        expect(back.alarm, alarm);
        expect(back.scheduledFor, set);
        expect(back.startsAt, DateTime(2026, 11, 11, 7, 5, 42));
        expect(back.snoozedSoundId, 'chime');
      },
    );

    test('a second Snooze still keeps the time the alarm was set for', () {
      final first = ringAfterSnooze(
        DueRing(alarm, scheduledFor: set),
        soundId: 'chime',
        at: tap,
      );

      final second = ringAfterSnooze(
        first,
        soundId: 'bell',
        at: DateTime(2026, 11, 11, 7, 6),
      );

      expect(second.scheduledFor, set);
      expect(second.startsAt, DateTime(2026, 11, 11, 7, 11));
      expect(second.snoozedSoundId, 'bell');
    });

    test('takes another length', () {
      final back = ringAfterSnooze(
        DueRing(alarm, scheduledFor: set),
        soundId: 'chime',
        at: tap,
        snooze: const Duration(minutes: 9),
      );

      expect(back.startsAt, DateTime(2026, 11, 11, 7, 9, 42));
    });
  });

  group('snoozedRingOf', () {
    RingEvent event(String id, int second, RingAction action) => RingEvent(
      soundId: id,
      startedAt: DateTime(2026, 11, 11, 7, 0, second),
      endedAt: DateTime(2026, 11, 11, 7, 0, second + 10),
      action: action,
    );

    RingSession session(List<RingEvent> events) =>
        RingSession(id: 's', alarmId: 'a', scheduledFor: set, events: events);

    test('a snoozed session comes back the snooze after its last event', () {
      expect(
        snoozedRingOf(
          session([
            event('bell', 0, RingAction.timeout),
            event('chime', 10, RingAction.snooze),
          ]),
          alarm,
        ),
        DueRing(
          alarm,
          scheduledFor: set,
          startsAt: DateTime(2026, 11, 11, 7, 5, 20),
          snoozedSoundId: 'chime',
        ),
      );
    });

    test('a session that is not snoozed has none', () {
      for (final events in [
        const <RingEvent>[],
        [event('chime', 0, RingAction.timeout)],
        [event('chime', 0, RingAction.stop)],
        [
          event('chime', 0, RingAction.snooze),
          event('bell', 10, RingAction.stop),
        ],
      ]) {
        expect(
          snoozedRingOf(session(events), alarm),
          isNull,
          reason: '$events',
        );
      }
    });
  });
}
