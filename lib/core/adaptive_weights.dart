import 'package:meta/meta.dart';

/// How likely each sound is to come early in its shuffle bag: its weight,
/// learned from the buttons the user taps.
///
/// Every sound starts at [startWeight]. When the user taps Snooze, the sound
/// that was playing gets lighter ([afterSnooze]); when they tap Stop, it gets
/// heavier ([afterStop]). That sound is the one of the last `RingEvent` of
/// the ring, whose action is `snooze` or `stop`. A missed alarm, which
/// reached its time cap without a tap, changes no weight: nobody may have
/// been there to hear it. The sound the user names on the Morning card gets
/// heavier too ([afterWoke]), on top of what those taps taught.
///
/// Weights are kept by `Sound.id`, one set for all alarms, and built-in
/// sounds, user songs and voice messages learn alike. The shuffle bag still
/// plays every sound once per bag: a weight only changes how early in its
/// bag a sound tends to come (`ShuffleBag`).
///
/// The factors and the limits are start values; tune them with real data.
@immutable
class SoundWeights {
  /// The weights in [weights], by `Sound.id`. A sound without one has the
  /// [startWeight].
  ///
  /// A weight outside [minWeight]–[maxWeight], such as one saved before the
  /// limits were tuned, moves to the nearest limit, and one that is not a
  /// number gets the [startWeight], so a stored value can never break an
  /// alarm.
  SoundWeights([Map<String, double> weights = const {}])
    : _byId = {
        for (final MapEntry(key: id, value: weight) in weights.entries)
          id: _limited(weight),
      }..removeWhere((_, weight) => weight == startWeight);

  /// Every sound at the [startWeight].
  const SoundWeights.start() : _byId = const {};

  /// The weight of a sound that has learned nothing yet.
  static const startWeight = 1.0;

  /// What the weight of the sound at Snooze is multiplied by.
  static const snoozeFactor = 0.8;

  /// What the weight of the sound at Stop is multiplied by.
  static const stopFactor = 1.1;

  /// What the weight of the sound that woke the user is multiplied by: a clear
  /// answer says more than a tap, which falls on whichever clip plays then.
  static const wokeFactor = 1.2;

  /// The lightest a weight gets, so every sound can still come early.
  static const minWeight = 0.2;

  /// The heaviest a weight gets, so no sound always comes first.
  static const maxWeight = 3.0;

  /// The weights that are not the [startWeight], by sound id.
  final Map<String, double> _byId;

  /// The weight of the sound with [soundId].
  double weightOf(String soundId) => _byId[soundId] ?? startWeight;

  /// These weights after the user tapped Snooze while the sound with
  /// [soundId] played: its weight times [snoozeFactor], at least [minWeight].
  SoundWeights afterSnooze(String soundId) => _scaled(soundId, snoozeFactor);

  /// These weights after the user tapped Stop while the sound with [soundId]
  /// played: its weight times [stopFactor], at most [maxWeight].
  SoundWeights afterStop(String soundId) => _scaled(soundId, stopFactor);

  /// These weights after the user named the sound with [soundId] on the
  /// Morning card: its weight times [wokeFactor], at most [maxWeight]. "Not
  /// sure" changes no weight, and what Stop taught stays.
  SoundWeights afterWoke(String soundId) => _scaled(soundId, wokeFactor);

  SoundWeights _scaled(String soundId, double factor) =>
      SoundWeights({..._byId, soundId: weightOf(soundId) * factor});

  @override
  bool operator ==(Object other) =>
      other is SoundWeights &&
      other._byId.length == _byId.length &&
      _byId.entries.every((entry) => other._byId[entry.key] == entry.value);

  @override
  int get hashCode => Object.hashAllUnordered(
    _byId.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );

  @override
  String toString() => 'SoundWeights($_byId)';
}

/// [weight] moved inside the limits. `clamp` would make a weight that is not
/// a number the heaviest one, so it gets the start weight instead.
double _limited(double weight) => weight.isNaN
    ? SoundWeights.startWeight
    : weight.clamp(SoundWeights.minWeight, SoundWeights.maxWeight);
