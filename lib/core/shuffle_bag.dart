import 'dart:math';

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
/// All chance comes from the [Random] the bag gets, so the same sounds and a
/// `Random` with the same seed give the same sounds in the same order.
class ShuffleBag {
  /// A bag of the sounds in [pool]. Sounds are told apart by [Sound.id]:
  /// sounds with the same id count as one sound, the first of them. The order
  /// of [pool] does not change what plays.
  ///
  /// Throws an [ArgumentError] if [pool] is empty, as there is nothing to
  /// play. An alarm without sounds gets all the built-in sounds instead (task
  /// 1.6), so it still rings.
  ShuffleBag(Iterable<Sound> pool, {required this._random})
    : _pool = _oneSoundPerId(pool) {
    if (_pool.isEmpty) throw ArgumentError('Must not be empty', 'pool');
  }

  /// Every sound of the pool once, sorted by id.
  final List<Sound> _pool;

  final Random _random;

  /// The sounds left in the current bag.
  final _left = <Sound>[];

  /// The id of the sound that played last, or null before the first one.
  String? _lastId;

  /// Takes the next sound out of the bag. An empty bag is refilled first.
  Sound next() {
    if (_left.isEmpty) _left.addAll(_pool);
    // Only the first sound out of a new bag can be the one that just played.
    // A pool of one sound has no other, so its sound plays again.
    final others = [
      for (final sound in _left)
        if (sound.id != _lastId) sound,
    ];
    final sound = _pick(others.isEmpty ? _left : others);
    _left.remove(sound);
    _lastId = sound.id;
    return sound;
  }

  /// Chooses one of [candidates] at random. The bag makes every choice here,
  /// so task 1.5 can turn it into a weighted choice in this one place.
  Sound _pick(List<Sound> candidates) =>
      candidates[_random.nextInt(candidates.length)];
}

/// The first sound of each id in [sounds], sorted by id.
List<Sound> _oneSoundPerId(Iterable<Sound> sounds) {
  final byId = <String, Sound>{};
  for (final sound in sounds) {
    byId.putIfAbsent(sound.id, () => sound);
  }
  return byId.values.toList()..sort((a, b) => a.id.compareTo(b.id));
}
