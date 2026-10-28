import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/database.dart';

/// A sound, and where its audio is.
@immutable
class StoredSound {
  const StoredSound(this.sound, {required this.audioPath});

  final Sound sound;

  /// Where the audio file of [sound] is.
  ///
  /// For a built-in sound, its asset path in the app, such as
  /// `assets/library/pop/sunrise.mp3` (task 2.3). For a song or voice message
  /// of the user's, its path in the app's own storage for sounds: a folder on
  /// the device, or the browser's storage on the web (tasks 2.6 and 2.7).
  /// Never a full path: the app's folders can move, as iOS moves them with
  /// each app update.
  final String audioPath;

  @override
  bool operator ==(Object other) =>
      other is StoredSound &&
      other.sound == sound &&
      other.audioPath == audioPath;

  @override
  int get hashCode => Object.hash(sound, audioPath);

  @override
  String toString() => 'StoredSound($sound, audioPath: $audioPath)';
}

/// Saves and reads the sounds: the built-in ones, the user's songs and their
/// voice messages.
class SoundRepository {
  SoundRepository(this._db);

  final AppDatabase _db;

  /// Every sound, by id.
  Future<List<StoredSound>> all() =>
      (_db.select(_db.sounds)
            ..orderBy([(sound) => OrderingTerm(expression: sound.id)]))
          .map(_fromRow)
          .get();

  /// The sound with [id], or null if there is none.
  Future<StoredSound?> byId(String id) async {
    final row = await (_db.select(
      _db.sounds,
    )..where((sound) => sound.id.equals(id))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Saves [sound]: a new sound, or new values for the sound with its id. A
  /// sound saved again keeps its weight.
  Future<void> save(StoredSound sound) async {
    // An upsert updates the row in place. A delete and insert would delete
    // the sound's weight with it (foreign key).
    await _db.into(_db.sounds).insertOnConflictUpdate(_toRow(sound));
  }

  /// Deletes the sound with [id], if there is one, and its weight. Its ring
  /// history stays.
  Future<void> delete(String id) async {
    await (_db.delete(_db.sounds)..where((sound) => sound.id.equals(id))).go();
  }
}

StoredSound _fromRow(SoundRow row) => StoredSound(
  Sound(
    id: row.id,
    title: row.title,
    source: row.source,
    genre: row.genre,
    intensity: row.intensity,
    duration: row.duration,
    clipStart: row.clipStart,
  ),
  audioPath: row.audioPath,
);

SoundsCompanion _toRow(StoredSound stored) => SoundsCompanion.insert(
  id: stored.sound.id,
  title: stored.sound.title,
  source: stored.sound.source,
  genre: stored.sound.genre,
  intensity: stored.sound.intensity,
  duration: stored.sound.duration,
  clipStart: stored.sound.clipStart,
  audioPath: stored.audioPath,
);
