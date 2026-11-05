import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/core/morning.dart';

void main() {
  group('Morning.of', () {
    test('reads a session that a Stop ended', () {
      expect(
        Morning.of(_session([_played('a', 0, 12, RingAction.stop)])),
        isNotNull,
      );
    });

    test('has nothing for a ring that is snoozed', () {
      expect(
        Morning.of(_session([_played('a', 0, 12, RingAction.snooze)])),
        isNull,
      );
    });

    test('has nothing for a ring that reached its cap', () {
      expect(
        Morning.of(_session([_played('a', 0, 20, RingAction.timeout)])),
        isNull,
      );
    });

    test('has nothing for a ring without a sound', () {
      expect(Morning.of(_session(const [])), isNull);
    });
  });

  group('When the user woke', () {
    test('is the moment of the Stop', () {
      final morning = Morning.of(
        _session([
          _played('a', 0, 20, RingAction.timeout),
          _played('b', 20, 33, RingAction.stop),
        ]),
      )!;

      expect(morning.wokeAt, _seven.add(const Duration(seconds: 33)));
    });

    test('is the tap on a Stop without sound, such as during a snooze', () {
      final morning = Morning.of(
        _session([
          _played('a', 0, 20, RingAction.snooze),
          _silent('a', 200, RingAction.stop),
        ]),
      )!;

      expect(morning.wokeAt, _seven.add(const Duration(seconds: 200)));
    });

    test('says how long after the alarm', () {
      final morning = Morning.of(
        _session([_played('a', 240, 245, RingAction.stop)]),
      )!;

      expect(morning.afterAlarm, const Duration(seconds: 245));
    });

    test('is never before the alarm, also when the clock jumped back', () {
      final morning = Morning.of(
        _session([_played('a', -30, -20, RingAction.stop)]),
      )!;

      expect(morning.afterAlarm, Duration.zero);
    });
  });

  group('The snoozes', () {
    test('are none for a ring stopped at once', () {
      final morning = Morning.of(
        _session([_played('a', 0, 5, RingAction.stop)]),
      )!;

      expect(morning.snoozes, 0);
    });

    test('count each Snooze of the session', () {
      final morning = Morning.of(
        _session([
          _played('a', 0, 20, RingAction.timeout),
          _played('b', 20, 25, RingAction.snooze),
          _played('c', 325, 340, RingAction.snooze),
          _played('a', 640, 650, RingAction.stop),
        ]),
      )!;

      expect(morning.snoozes, 2);
    });

    test('count a Snooze without sound too', () {
      final morning = Morning.of(
        _session([
          _silent('a', 25, RingAction.snooze),
          _silent('a', 325, RingAction.stop),
        ]),
      )!;

      expect(morning.snoozes, 1);
    });
  });

  group('The sounds', () {
    test('come in the order they played', () {
      final morning = Morning.of(
        _session([
          _played('b', 0, 20, RingAction.timeout),
          _played('a', 20, 40, RingAction.timeout),
          _played('c', 40, 45, RingAction.stop),
        ]),
      )!;

      expect(morning.sounds.map((sound) => sound.soundId), ['b', 'a', 'c']);
    });

    test('each come once, at the first time they played', () {
      final morning = Morning.of(
        _session([
          _played('a', 0, 20, RingAction.timeout),
          _played('b', 20, 40, RingAction.snooze),
          _played('a', 340, 345, RingAction.stop),
        ]),
      )!;

      expect(morning.sounds, const [
        MorningSound(
          soundId: 'a',
          firstAt: Duration.zero,
          played: Duration(seconds: 25),
        ),
        MorningSound(
          soundId: 'b',
          firstAt: Duration(seconds: 20),
          played: Duration(seconds: 20),
        ),
      ]);
    });

    test('are only those that played: an event without length is none', () {
      final morning = Morning.of(
        _session([
          _played('a', 0, 20, RingAction.snooze),
          _silent('b', 320, RingAction.stop),
        ]),
      )!;

      expect(morning.sounds.map((sound) => sound.soundId), ['a']);
    });

    test('are none when no sound played, such as with the sound blocked', () {
      final morning = Morning.of(
        _session([
          _silent('a', 5, RingAction.snooze),
          _silent('a', 305, RingAction.stop),
        ]),
      )!;

      expect(morning.sounds, isEmpty);
    });

    test('start late when the ring was found late', () {
      final morning = Morning.of(
        _session([_played('b', 25, 30, RingAction.stop)]),
      )!;

      expect(morning.sounds.single.firstAt, const Duration(seconds: 25));
    });

    test('are never before the alarm or shorter than nothing', () {
      // The clock jumped back during the ring.
      final morning = Morning.of(
        _session([
          _played('a', -40, -60, RingAction.timeout),
          _played('b', -60, -50, RingAction.stop),
        ]),
      )!;

      expect(morning.sounds, const [
        MorningSound(
          soundId: 'a',
          firstAt: Duration.zero,
          played: Duration.zero,
        ),
        MorningSound(
          soundId: 'b',
          firstAt: Duration.zero,
          played: Duration(seconds: 10),
        ),
      ]);
    });

    test('cannot be changed from outside', () {
      final morning = Morning.of(
        _session([_played('a', 0, 5, RingAction.stop)]),
      )!;

      expect(
        () => morning.sounds.add(
          const MorningSound(
            soundId: 'b',
            firstAt: Duration.zero,
            played: Duration.zero,
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('MorningSound', () {
    const sound = MorningSound(
      soundId: 'a',
      firstAt: Duration(seconds: 1),
      played: Duration(seconds: 2),
    );

    test('equals a sound with the same values', () {
      const same = MorningSound(
        soundId: 'a',
        firstAt: Duration(seconds: 1),
        played: Duration(seconds: 2),
      );

      expect(same, sound);
      expect(same.hashCode, sound.hashCode);
    });

    test('differs from a sound with one other value', () {
      for (final other in const [
        MorningSound(
          soundId: 'b',
          firstAt: Duration(seconds: 1),
          played: Duration(seconds: 2),
        ),
        MorningSound(
          soundId: 'a',
          firstAt: Duration(seconds: 3),
          played: Duration(seconds: 2),
        ),
        MorningSound(
          soundId: 'a',
          firstAt: Duration(seconds: 1),
          played: Duration(seconds: 3),
        ),
      ]) {
        expect(other, isNot(sound));
      }
    });

    test('says what it holds', () {
      expect(sound.toString(), contains('a'));
    });
  });

  // This test needs a time zone with daylight saving time. CI runs in UTC and
  // runs this file again in each zone of [_dstZones], such as
  // `TZ=Europe/Berlin flutter test test/core/morning_test.dart`.
  final zone = _dstZones.where((zone) => zone.isLocal).firstOrNull;
  test('runs the tests of a clock change in the zone TZ names', () {
    // So that they are not skipped because a computer lacks the zone.
    final named = Platform.environment['TZ'];
    if (_dstZones.any((zone) => zone.name == named)) {
      expect(zone?.name, named);
    }
  });
  group(
    'A morning across a change of the clock in ${zone?.name ?? 'a DST zone'}',
    skip: zone == null
        ? 'Needs the time zone Europe/Berlin or America/New_York (TZ)'
        : false,
    () {
      test('counts the time that passed when the clock jumps forward', () {
        final z = zone!;
        // An alarm at 01:59, stopped at 03:01: the clock jumped over 02:00.
        final set = DateTime(z.year, z.month, z.day, 1, 59);
        final stop = DateTime(z.year, z.month, z.day, 3, 1);

        final morning = Morning.of(
          RingSession(
            id: 's1',
            alarmId: 'a1',
            scheduledFor: set,
            events: [
              RingEvent(
                soundId: 'a',
                startedAt: set,
                endedAt: stop,
                action: RingAction.stop,
              ),
            ],
          ),
        )!;

        expect(morning.afterAlarm, const Duration(minutes: 2));
        expect((morning.wokeAt.hour, morning.wokeAt.minute), (3, 1));
      });
    },
  );
}

final _seven = DateTime(2026, 11, 3, 7);

RingSession _session(List<RingEvent> events) =>
    RingSession(id: 's1', alarmId: 'a1', scheduledFor: _seven, events: events);

/// A sound that played, with its times in seconds after 07:00.
RingEvent _played(String id, int from, int to, RingAction action) => RingEvent(
  soundId: id,
  startedAt: _seven.add(Duration(seconds: from)),
  endedAt: _seven.add(Duration(seconds: to)),
  action: action,
);

/// A ring that ended while no sound played, in seconds after 07:00.
RingEvent _silent(String id, int at, RingAction action) => RingEvent.silent(
  soundId: id,
  at: _seven.add(Duration(seconds: at)),
  action: action,
);

class _DstZone {
  const _DstZone(
    this.name, {
    required this.year,
    required this.month,
    required this.day,
  });

  final String name;

  /// The day the clock jumps from 02:00 to 03:00.
  final int year;
  final int month;
  final int day;

  /// Whether the tests run in this zone: on this day, 02:30 does not exist,
  /// and `DateTime` moves it to 03:30.
  bool get isLocal {
    final skipped = DateTime(year, month, day, 2, 30);
    return (skipped.hour, skipped.minute) == (3, 30);
  }
}

const _dstZones = [
  _DstZone('Europe/Berlin', year: 2026, month: 3, day: 29),
  _DstZone('America/New_York', year: 2026, month: 3, day: 8),
];
