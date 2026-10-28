import 'dart:math';

import 'package:meta/meta.dart';

import 'package:shuffle_alarm/core/adaptive_weights.dart';
import 'package:shuffle_alarm/core/clip_rule.dart';
import 'package:shuffle_alarm/core/escalation.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/core/shuffle_bag.dart';

/// How long an alarm rings at most, unless the user sets another time cap.
/// A ring that reaches its cap without a tap stops and counts as missed.
const defaultRingCap = Duration(minutes: 10);

/// The clips that one ring of [alarm] plays, in order, from its first sound
/// until the time [cap]: its ring sequence.
///
/// The clips play back to back: each one starts when the one before it
/// ends, so a 12-s voice message is followed at once by the next sound. Each
/// clip plays its whole [ClipWindow], 30 s at most, but the last one is cut
/// so the ring ends at [cap] exactly.
///
/// [pool] is every sound on the device. A ring plays the built-in sounds of
/// the alarm's genres, and every song and voice message of the user's own,
/// whatever its genre. If the alarm has no genres, or none of them has a
/// built-in sound, it plays every built-in sound instead, so it still rings.
///
/// One [ShuffleBag] with the [weights] picks the sounds of the whole ring, so
/// every sound plays once per bag and none twice in a row. [Escalation] gives
/// each clip its intensity and volume: with the alarm's gentle start, the
/// first three climb from gentle to strong.
///
/// [snoozedSoundId] makes it a ring after Snooze: it is the id of the sound
/// that was playing when the user tapped Snooze, and the [weights] have
/// learned from that tap already (`SoundWeights.afterSnooze`). Such a ring
/// plays at full volume from its first sound and does not start with that
/// sound. Leave it null for the first ring of an alarm.
///
/// The same alarm, sounds, weights, seed and snoozed sound give the same
/// clips, whatever the order of [pool]; give each ring a [seed] of its own.
/// A `Random` with a seed may give other numbers after a Dart update, so a
/// platform that schedules a ring ahead, such as the chain of alarms on iOS,
/// keeps the clips it scheduled, not only the seed.
///
/// Throws an [ArgumentError] if [cap] is not positive or [pool] is empty.
List<RingClip> buildRingSequence(
  Alarm alarm,
  Iterable<Sound> pool,
  SoundWeights weights,
  int seed, {
  String? snoozedSoundId,
  Duration cap = defaultRingCap,
}) {
  if (cap <= Duration.zero) {
    throw ArgumentError('Must be positive, was $cap', 'cap');
  }
  final bag = ShuffleBag(
    _soundsOfRing(alarm, pool),
    random: Random(seed),
    weights: weights,
    lastId: snoozedSoundId,
  );
  final gentleStart = alarm.gentleStart && snoozedSoundId == null;
  final clips = <RingClip>[];
  var startsAt = Duration.zero;
  for (var index = 0; startsAt < cap; index++) {
    final step = Escalation.at(index, gentleStart: gentleStart);
    final sound = bag.next(intensity: step.intensity);
    final window = ClipWindow.of(sound).cutTo(cap - startsAt);
    clips.add(
      RingClip._(
        sound: sound,
        window: window,
        volume: step.volume,
        startsAt: startsAt,
      ),
    );
    startsAt += window.length;
  }
  return List.unmodifiable(clips);
}

/// One clip of a ring: which sound plays, which part of its file, how loud,
/// and when.
@immutable
class RingClip {
  const RingClip._({
    required this.sound,
    required this.window,
    required this.volume,
    required this.startsAt,
  });

  final Sound sound;

  /// The part of the sound's file that plays: its [ClipWindow], cut short if
  /// the ring reaches its time cap first.
  final ClipWindow window;

  /// How loud it plays, from 0 (silent) to [Escalation.fullVolume], on the
  /// platforms that let the app set it.
  final double volume;

  /// When it starts, counted from the start of the ring.
  final Duration startsAt;

  /// When it ends, counted from the start of the ring. The next clip starts
  /// then.
  Duration get endsAt => startsAt + window.length;

  @override
  bool operator ==(Object other) =>
      other is RingClip &&
      other.sound == sound &&
      other.window == window &&
      other.volume == volume &&
      other.startsAt == startsAt;

  @override
  int get hashCode => Object.hash(sound, window, volume, startsAt);

  @override
  String toString() =>
      'RingClip(sound: ${sound.id}, window: $window, volume: $volume, '
      'startsAt: $startsAt)';
}

/// The sounds of [pool] that a ring of [alarm] plays: the built-in sounds of
/// its genres, or every built-in sound if that leaves none, and every sound
/// of the user's own.
List<Sound> _soundsOfRing(Alarm alarm, Iterable<Sound> pool) {
  final builtin = [
    for (final sound in pool)
      if (sound.source == SoundSource.builtin) sound,
  ];
  final ofGenres = [
    for (final sound in builtin)
      if (alarm.genres.contains(sound.genre)) sound,
  ];
  return [
    if (ofGenres.isEmpty) ...builtin else ...ofGenres,
    for (final sound in pool)
      if (sound.source != SoundSource.builtin) sound,
  ];
}
