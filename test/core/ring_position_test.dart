import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/adaptive_weights.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/core/ring_position.dart';
import 'package:shuffle_alarm/core/ring_sequence.dart';

void main() {
  // Two sounds of 20 s and a cap of 50 s: clips from 0 to 20 s, 20 to 40 s
  // and 40 to 50 s, the last one cut at the cap.
  final clips = buildRingSequence(
    Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0)),
    [_sound('one'), _sound('two')],
    const SoundWeights.start(),
    1,
    cap: const Duration(seconds: 50),
  );

  test('the ring of the test has three clips, back to back', () {
    expect([for (final clip in clips) clip.startsAt.inSeconds], [0, 20, 40]);
    expect(clips.last.endsAt, const Duration(seconds: 50));
  });

  group('ringPosition', () {
    test('starts with the first clip, from its start', () {
      expect(ringPosition(clips, Duration.zero), const RingPosition(0));
    });

    test('is in the clip whose time holds the time since the start', () {
      expect(
        ringPosition(clips, const Duration(seconds: 5)),
        const RingPosition(0, offset: Duration(seconds: 5)),
      );
      expect(
        ringPosition(clips, const Duration(seconds: 45, milliseconds: 500)),
        const RingPosition(2, offset: Duration(seconds: 5, milliseconds: 500)),
      );
    });

    test('at the end of a clip is the start of the next one', () {
      expect(
        ringPosition(clips, const Duration(seconds: 20)),
        const RingPosition(1),
      );
    });

    test('is null once the ring reached its cap: it was missed', () {
      expect(ringPosition(clips, const Duration(seconds: 50)), isNull);
      expect(ringPosition(clips, const Duration(hours: 2)), isNull);
    });

    test('counts a time before the start as the start', () {
      // Such as from a clock that was set back a moment.
      expect(
        ringPosition(clips, const Duration(seconds: -3)),
        const RingPosition(0),
      );
    });

    test('is null for a ring without clips', () {
      expect(ringPosition(const [], Duration.zero), isNull);
    });
  });

  group('RingPosition', () {
    test('is equal to a position with the same clip and offset', () {
      const position = RingPosition(1, offset: Duration(seconds: 2));

      expect(position, const RingPosition(1, offset: Duration(seconds: 2)));
      expect(
        position.hashCode,
        const RingPosition(1, offset: Duration(seconds: 2)).hashCode,
      );
      expect(position, isNot(const RingPosition(1)));
      expect(
        position,
        isNot(const RingPosition(2, offset: Duration(seconds: 2))),
      );
    });
  });
}

Sound _sound(String id) => Sound(
  id: id,
  title: id,
  source: SoundSource.builtin,
  genre: 'calm',
  intensity: 1,
  duration: const Duration(seconds: 20),
);
