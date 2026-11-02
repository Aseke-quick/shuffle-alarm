import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/library_manifest.dart';
import 'package:shuffle_alarm/data/library_sync.dart';
import 'package:shuffle_alarm/data/ring_session_repository.dart';
import 'package:shuffle_alarm/data/settings_repository.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/data/weight_repository.dart';

/// The app's database: opened once, when the app first needs it, and closed
/// with the app. Tests override it with a database in memory.
///
/// Opening it can fail, such as in a browser that blocks the site's storage.
/// The first query then fails, such as the stream of [alarmsProvider].
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.onDevice();
  ref.onDispose(() => unawaited(db.close()));
  return db;
});

final alarmRepositoryProvider = Provider<AlarmRepository>(
  (ref) => AlarmRepository(ref.watch(databaseProvider)),
);

/// Every alarm, by time of day: now, and again after each change.
final alarmsProvider = StreamProvider<List<Alarm>>(
  (ref) => ref.watch(alarmRepositoryProvider).watchAll(),
);

final soundRepositoryProvider = Provider<SoundRepository>(
  (ref) => SoundRepository(ref.watch(databaseProvider)),
);

final weightRepositoryProvider = Provider<WeightRepository>(
  (ref) => WeightRepository(ref.watch(databaseProvider)),
);

final ringSessionRepositoryProvider = Provider<RingSessionRepository>(
  (ref) => RingSessionRepository(ref.watch(databaseProvider)),
);

/// The simple settings. Reading it throws where the platform has no store,
/// such as in the Dart VM of the tests, unless a test sets one up.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(SharedPreferencesAsync()),
);

/// The genres of the built-in sounds, A to Z: the genres an alarm can choose
/// (`buildRingSequence`). Now, and again after each change.
final genresProvider = StreamProvider<List<String>>(
  (ref) => ref
      .watch(soundRepositoryProvider)
      .watchAll()
      .map(
        (sounds) => {
          for (final stored in sounds)
            if (stored.sound.source == SoundSource.builtin) stored.sound.genre,
        }.toList()..sort(),
      ),
);

/// Reads the clips of the built-in library straight from the app's assets
/// (`assets/library/manifest.json`), as built-in sounds. Tests override it.
final libraryClipsProvider = Provider<Future<List<StoredSound>> Function()>(
  (ref) =>
      () async => [
        for (final entry in await loadLibraryManifest(rootBundle))
          entry.toStoredSound(),
      ],
);

/// Reads the sounds that alarms can play: every sound in the database, or the
/// library straight from its files when the database has none or cannot be
/// read, such as after a failed library sync. So an alarm does not depend on
/// that sync (`.10x/decisions/sre/placeholder-library.md`, risk 1).
///
/// Throws when the library cannot be read either.
final ringSoundsProvider = Provider<Future<List<StoredSound>> Function()>((
  ref,
) {
  final repository = ref.watch(soundRepositoryProvider);
  final library = ref.watch(libraryClipsProvider);
  return () async {
    var sounds = const <StoredSound>[];
    try {
      sounds = await repository.all();
    } on Object catch (error) {
      debugPrint('Could not read the sounds: $error');
    }
    return sounds.isNotEmpty ? sounds : await library();
  };
});

/// Saves the clips of the built-in library (`assets/library/manifest.json`)
/// into the database as built-in sounds, and deletes the built-in sounds
/// that left it (task 2.3). It runs again for each new database, such as
/// after Try again, while [startLibrarySync] listens.
final librarySyncProvider = FutureProvider<LibrarySyncPlan>((ref) async {
  final db = ref.watch(databaseProvider);
  final library = await ref.watch(libraryClipsProvider)();
  return await syncLibrary(db, library);
});

/// Starts [librarySyncProvider] in [container] when the app starts, and
/// keeps listening, so each new database gets the library too.
///
/// A failure only goes to the log and never stops the app: when the database
/// cannot open, the Alarms tab says so.
ProviderSubscription<AsyncValue<LibrarySyncPlan>> startLibrarySync(
  ProviderContainer container,
) => container.listen(librarySyncProvider, (_, next) {
  // While it runs again, it still shows the value or error from before.
  if (next.isLoading) return;
  if (next case AsyncError(:final error, :final stackTrace)) {
    debugPrint('Could not save the built-in library: $error\n$stackTrace');
  } else if (next case AsyncData(:final value) when !value.isEmpty) {
    debugPrint('Saved the built-in library: $value');
  }
});
