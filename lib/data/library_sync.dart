import 'package:meta/meta.dart';

import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';

/// What saving the built-in library into the database changes (task 2.3).
@immutable
class LibrarySyncPlan {
  LibrarySyncPlan({
    List<StoredSound> save = const [],
    List<String> delete = const [],
    List<String> clashes = const [],
  }) : save = List.unmodifiable(save),
       delete = List.unmodifiable(delete),
       clashes = List.unmodifiable(clashes);

  /// The built-in sounds to save: the new ones, and those whose values
  /// changed. Saving keeps a sound's weight.
  final List<StoredSound> save;

  /// The ids of the built-in sounds to delete, which left the library. Their
  /// weights go with them; their ring history stays.
  final List<String> delete;

  /// The ids of clips that a song or voice message of the user's already
  /// has. Those clips are left out, so the user's sound stays as it is.
  final List<String> clashes;

  /// Whether the database already holds the library as it is.
  bool get isEmpty => save.isEmpty && delete.isEmpty;

  @override
  String toString() =>
      'LibrarySyncPlan(save: ${[for (final sound in save) sound.sound.id]}, '
      'delete: $delete, clashes: $clashes)';
}

/// What saving [library], the clips of the manifest as built-in sounds, into
/// a database that holds [stored] changes: the new and changed clips to
/// save, and the built-in sounds that left the library to delete.
///
/// The user's songs and voice messages are never saved over or deleted: a
/// clip with the id of one of them is left out ([LibrarySyncPlan.clashes]).
LibrarySyncPlan planLibrarySync({
  required List<StoredSound> library,
  required List<StoredSound> stored,
}) {
  final storedById = {for (final sound in stored) sound.sound.id: sound};
  final save = <StoredSound>[];
  final clashes = <String>[];
  for (final clip in library) {
    final old = storedById[clip.sound.id];
    if (old == null) {
      save.add(clip);
    } else if (old.sound.source != SoundSource.builtin) {
      clashes.add(clip.sound.id);
    } else if (old != clip) {
      save.add(clip);
    }
  }
  final libraryIds = {for (final clip in library) clip.sound.id};
  return LibrarySyncPlan(
    save: save,
    delete: [
      for (final sound in stored)
        if (sound.sound.source == SoundSource.builtin &&
            !libraryIds.contains(sound.sound.id))
          sound.sound.id,
    ],
    clashes: clashes,
  );
}

/// Saves the built-in [library] into [db] as [planLibrarySync] plans it, and
/// gives the plan.
///
/// All in one transaction, so a listener sees the library before or after,
/// never half of it.
Future<LibrarySyncPlan> syncLibrary(
  AppDatabase db,
  List<StoredSound> library,
) => db.transaction(() async {
  final sounds = SoundRepository(db);
  final plan = planLibrarySync(library: library, stored: await sounds.all());
  for (final sound in plan.save) {
    await sounds.save(sound);
  }
  for (final id in plan.delete) {
    await sounds.delete(id);
  }
  return plan;
});
