import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/adaptive_weights.dart';
import 'package:shuffle_alarm/core/clip_rule.dart';
import 'package:shuffle_alarm/core/fallback_tone.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/core/ring_sequence.dart';

void main() {
  final alarm = Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0));

  test('is a clip of a built-in sound, so it follows the clip rule', () {
    expect(fallbackTone.source, SoundSource.builtin);
    expect(fallbackTone.title, 'Alarm tone');
    expect(ClipWindow.of(fallbackTone).length, ClipWindow.maxBuiltinLength);
  });

  test('a ring of it covers the time cap, and starts gently', () {
    final clips = buildRingSequence(
      alarm,
      [fallbackTone],
      const SoundWeights.start(),
      1,
    );

    expect(clips.map((clip) => clip.sound), everyElement(fallbackTone));
    expect(clips.last.endsAt, defaultRingCap);
    expect(clips.take(3).map((clip) => clip.volume), [0.4, 0.7, 1.0]);
  });

  test('a ring of it after Snooze plays too, at full volume', () {
    final clips = buildRingSequence(
      alarm,
      [fallbackTone],
      const SoundWeights.start(),
      1,
      snoozedSoundId: fallbackTone.id,
    );

    expect(clips.first.sound, fallbackTone);
    expect(clips.first.volume, 1.0);
  });
}
