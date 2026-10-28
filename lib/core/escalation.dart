import 'package:meta/meta.dart';

import 'package:shuffle_alarm/core/models/sound.dart';

/// How strong and how loud each sound of a ringing alarm is: the gentle start.
///
/// A ring with a gentle start climbs one level per sound. Its first sound is
/// gentle and melodic, of intensity 1, at 40% volume; the second one is of
/// intensity 2 at 70%, and the third one of intensity 3 at full volume. From
/// the fourth sound on, any sound of the alarm can play, gentle ones too, all
/// at full volume. A ring without a gentle start plays any sound at full
/// volume from its first sound: a plain shuffle.
///
/// The shuffle bag picks each sound, of the intensity asked for or of the
/// nearest one it has (`ShuffleBag.next`), so the bag rules hold all through
/// a ring.
///
/// iOS has no public API for alarm loudness, so there only the order of the
/// sounds climbs, from gentle to strong.
@immutable
class Escalation {
  /// The escalation of the sound at [index] in a ring, where 0 is the first
  /// sound.
  ///
  /// [gentleStart] says whether the ring starts gently: it is the alarm's
  /// `Alarm.gentleStart`, but false for a ring after Snooze, which plays at
  /// full volume from its first sound.
  ///
  /// Throws a [RangeError] if [index] is negative.
  factory Escalation.at(int index, {required bool gentleStart}) {
    RangeError.checkNotNegative(index, 'index');
    if (!gentleStart || index >= volumes.length) {
      return const Escalation._(volume: fullVolume);
    }
    return Escalation._(
      volume: volumes[index],
      intensity: Sound.minIntensity + index,
    );
  }

  const Escalation._({required this.volume, this.intensity});

  /// The loudest the player plays.
  static const fullVolume = 1.0;

  /// The volume of the three levels of a gentle start, as a share of
  /// [fullVolume]: 40%, 70% and 100%. Start values; tune them with real data.
  static const volumes = <double>[0.4, 0.7, fullVolume];

  /// The intensity the sound should have, or null if any sound can play.
  final int? intensity;

  /// How loud the sound plays, from 0 (silent) to [fullVolume], on the
  /// platforms that let the app set it.
  final double volume;

  @override
  bool operator ==(Object other) =>
      other is Escalation &&
      other.intensity == intensity &&
      other.volume == volume;

  @override
  int get hashCode => Object.hash(intensity, volume);

  @override
  String toString() => 'Escalation(intensity: $intensity, volume: $volume)';
}
