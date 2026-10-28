import 'package:shuffle_alarm/core/adaptive_weights.dart';
import 'package:shuffle_alarm/data/database.dart';

/// Saves and reads the adaptive weights of the sounds.
class WeightRepository {
  WeightRepository(this._db);

  final AppDatabase _db;

  /// The weights of every sound. A sound without a saved weight has the
  /// start weight.
  Future<SoundWeights> load() async {
    final rows = await _db.select(_db.weights).get();
    return SoundWeights({for (final row in rows) row.soundId: row.weight});
  }

  /// Saves the weight that [weights] gives the sound with [soundId]: call it
  /// with the weights after `afterSnooze(soundId)` or `afterStop(soundId)`.
  ///
  /// Does nothing if no sound with [soundId] is saved, such as a song the
  /// user deleted while it rang: a weight goes with its sound.
  Future<void> save(SoundWeights weights, {required String soundId}) =>
      _db.transaction(() async {
        final sound = await (_db.select(
          _db.sounds,
        )..where((sound) => sound.id.equals(soundId))).getSingleOrNull();
        if (sound == null) return;

        await _db
            .into(_db.weights)
            .insertOnConflictUpdate(
              WeightsCompanion.insert(
                soundId: soundId,
                weight: weights.weightOf(soundId),
              ),
            );
      });

  /// Forgets every weight, so every sound is back at the start weight
  /// ("Reset learning", task 7.2).
  Future<void> clear() async {
    await _db.delete(_db.weights).go();
  }
}
