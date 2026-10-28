import 'dart:math';

import 'package:shuffle_alarm/core/adaptive_weights.dart';
import 'package:shuffle_alarm/core/models/sound.dart';

/// Picks the sounds of a ringing alarm one at a time, like cards from a bag.
///
/// The bag starts with every sound of the pool in it, and each [next] takes
/// one of the sounds left out of it at random, so no sound plays again before
/// every sound has played. When the bag is empty, every sound goes back in,
/// but the sound that just played cannot be the first one out of the new
/// bag. So no sound plays twice in a row, also when the bag is refilled. Only
/// a pool of one sound plays its sound every time: there is no other sound,
/// and the alarm must still ring.
///
/// [next] can also be asked for a sound of some intensity, as the gentle
/// start of a ring does (`Escalation`). The bag rules still hold.
///
/// The [SoundWeights] the bag gets make a heavier sound more likely to be
/// the next one out, so it tends to come earlier in its bag. They only choose
/// among the sounds the bag rules allow, so every sound still plays once per
/// bag.
///
/// All chance comes from the [Random] the bag gets, so the same sounds, the
/// same weights and a `Random` with the same seed give the same sounds in the
/// same order.
class ShuffleBag {
  /// A bag of the sounds in [pool]. Sounds are told apart by [Sound.id]:
  /// sounds with the same id count as one sound, the first of them. The order
  /// of [pool] does not change what plays.
  ///
  /// Without `weights`, every sound has the start weight, so each sound the
  /// bag rules allow is just as likely to come next.
  ///
  /// Throws an [ArgumentError] if [pool] is empty, as there is nothing to
  /// play. An alarm without sounds gets all the built-in sounds instead (task
  /// 1.6), so it still rings.
  ShuffleBag(
    Iterable<Sound> pool, {
    required this._random,
    this._weights = const SoundWeights.start(),
  }) : _pool = _oneSoundPerId(pool) {
    if (_pool.isEmpty) throw ArgumentError('Must not be empty', 'pool');
  }

  /// Every sound of the pool once, sorted by id.
  final List<Sound> _pool;

  final Random _random;

  final SoundWeights _weights;

  /// The sounds left in the current bag.
  final _left = <Sound>[];

  /// The id of the sound that played last, or null before the first one.
  String? _lastId;

  /// Takes the next sound out of the bag. An empty bag is refilled first.
  ///
  /// With an [intensity], it takes a sound of that intensity if the bag rules
  /// allow one. If not, it takes one of the nearest intensity they allow: the
  /// gentler one when a gentler and a stronger one are just as near. So a
  /// pool without that intensity still rings.
  Sound next({int? intensity}) {
    if (_left.isEmpty) _left.addAll(_pool);
    // Only the first sound out of a new bag can be the one that just played.
    // A pool of one sound has no other, so its sound plays again.
    final others = [
      for (final sound in _left)
        if (sound.id != _lastId) sound,
    ];
    final allowed = others.isEmpty ? _left : others;
    final sound = _pick(
      intensity == null ? allowed : _nearestIntensity(allowed, intensity),
    );
    _left.remove(sound);
    _lastId = sound.id;
    return sound;
  }

  /// Chooses one of [candidates] at random, each as likely as its weight
  /// says: a sound of weight 2 is twice as likely as one of weight 1. The bag
  /// makes every choice here, with one number from the [Random] per [next],
  /// so the same seed gives the same sounds.
  Sound _pick(List<Sound> candidates) {
    final weights = [
      for (final sound in candidates) _weights.weightOf(sound.id),
    ];
    // Each candidate gets a stretch of the line from 0 to the sum of the
    // weights, as long as its weight; a random point on it picks one.
    var point = _random.nextDouble() * weights.reduce((a, b) => a + b);
    for (final (index, sound) in candidates.indexed) {
      point -= weights[index];
      if (point < 0) return sound;
    }
    // Rounding can leave the point just past the last stretch.
    return candidates.last;
  }
}

/// The first sound of each id in [sounds], sorted by id.
List<Sound> _oneSoundPerId(Iterable<Sound> sounds) {
  final byId = <String, Sound>{};
  for (final sound in sounds) {
    byId.putIfAbsent(sound.id, () => sound);
  }
  return byId.values.toList()..sort((a, b) => a.id.compareTo(b.id));
}

/// The sounds of [sounds] whose intensity is nearest to [intensity]. If a
/// gentler and a stronger intensity are just as near, the gentler ones, so a
/// ring never climbs faster than it should.
List<Sound> _nearestIntensity(List<Sound> sounds, int intensity) {
  final distance = sounds
      .map((sound) => (sound.intensity - intensity).abs())
      .reduce(min);
  final gentler = intensity - distance;
  final nearest = sounds.any((sound) => sound.intensity == gentler)
      ? gentler
      : intensity + distance;
  return [
    for (final sound in sounds)
      if (sound.intensity == nearest) sound,
  ];
}
