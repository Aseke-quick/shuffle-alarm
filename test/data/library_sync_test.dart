import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/adaptive_weights.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/library_manifest.dart';
import 'package:shuffle_alarm/data/library_sync.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/data/weight_repository.dart';

import 'memory_database.dart';

void main() {
  // The real library comes from the app's assets.
  TestWidgetsFlutterBinding.ensureInitialized();

  final calm = _builtin('calm');
  final bright = _builtin('bright', genre: 'electronic', intensity: 3);
  final song = _own('my-song', SoundSource.user);
  final mom = _own('mom', SoundSource.voice);

  group('planLibrarySync', () {
    test('saves every clip into an empty database', () {
      final plan = planLibrarySync(library: [calm, bright], stored: []);

      expect(plan.save, [calm, bright]);
      expect(plan.delete, isEmpty);
      expect(plan.clashes, isEmpty);
      expect(plan.isEmpty, isFalse);
    });

    test('changes nothing when the database holds the library as it is', () {
      final plan = planLibrarySync(
        library: [calm, bright],
        stored: [bright, song, calm],
      );

      expect(plan.save, isEmpty);
      expect(plan.delete, isEmpty);
      expect(plan.isEmpty, isTrue);
    });

    test('saves a clip again when any of its values changed', () {
      for (final changed in [
        _builtin('calm', title: 'Calm (new mix)'),
        _builtin('calm', genre: 'lo-fi'),
        _builtin('calm', intensity: 2),
        _builtin('calm', seconds: 21.5),
        _builtin('calm', file: 'acoustic/calm.mp3'),
      ]) {
        final plan = planLibrarySync(
          library: [changed, bright],
          stored: [calm, bright],
        );

        expect(plan.save, [changed], reason: '$changed');
        expect(plan.delete, isEmpty, reason: '$changed');
      }
    });

    test('deletes the built-in sounds that left the library', () {
      final plan = planLibrarySync(
        library: [bright],
        stored: [calm, bright, _builtin('old')],
      );

      expect(plan.save, isEmpty);
      expect(plan.delete, ['calm', 'old']);
    });

    test('never deletes a song or a voice message of the user', () {
      final plan = planLibrarySync(library: [], stored: [song, calm, mom]);

      expect(plan.delete, ['calm']);
    });

    test('leaves out a clip whose id a song or voice message has', () {
      final clash = _builtin('my-song');

      final plan = planLibrarySync(library: [clash, calm], stored: [song]);

      expect(plan.save, [calm]);
      expect(plan.delete, isEmpty);
      expect(plan.clashes, ['my-song']);
    });
  });

  group('syncLibrary', () {
    late AppDatabase db;
    late SoundRepository sounds;
    late WeightRepository weights;

    setUp(() {
      db = memoryDatabase();
      sounds = SoundRepository(db);
      weights = WeightRepository(db);
    });

    tearDown(() => db.close());

    test('saves the library, and a second time changes nothing', () async {
      final first = await syncLibrary(db, [calm, bright]);

      expect(first.save, [calm, bright]);
      expect(await sounds.all(), [bright, calm]);

      final second = await syncLibrary(db, [calm, bright]);

      expect(second.isEmpty, isTrue);
      expect(await sounds.all(), [bright, calm]);
    });

    test(
      'keeps the weights of the clips that stay, also of a changed one',
      () async {
        final old = _builtin('old');
        await syncLibrary(db, [calm, bright, old]);
        final learned = const SoundWeights.start()
            .afterStop('calm')
            .afterSnooze('bright')
            .afterStop('old');
        for (final id in ['calm', 'bright', 'old']) {
          await weights.save(learned, soundId: id);
        }
        final remixed = _builtin('bright', title: 'Bright (new mix)');

        final plan = await syncLibrary(db, [calm, remixed]);

        expect(plan.save, [remixed]);
        expect(plan.delete, ['old']);
        expect(await sounds.all(), [remixed, calm]);
        expect(
          await weights.load(),
          SoundWeights(const {'calm': 1.1, 'bright': 0.8}),
        );
      },
    );

    test(
      'leaves the songs and voice messages and their weights alone',
      () async {
        await sounds.save(song);
        await sounds.save(mom);
        final learned = const SoundWeights.start()
            .afterSnooze('my-song')
            .afterStop('mom');
        await weights.save(learned, soundId: 'my-song');
        await weights.save(learned, soundId: 'mom');

        final plan = await syncLibrary(db, [_builtin('mom'), calm]);

        expect(plan.clashes, ['mom']);
        expect(await sounds.all(), [calm, mom, song]);
        expect(await weights.load(), learned);
      },
    );

    test('a listener sees the whole library at once', () async {
      final updates = <List<StoredSound>>[];
      final subscription = sounds.watchAll().listen(updates.add);
      await pumpEventQueue();

      await syncLibrary(db, [calm, bright, _builtin('third')]);
      await pumpEventQueue();
      await subscription.cancel();

      expect(updates, [
        isEmpty,
        [bright, calm, _builtin('third')],
      ]);
    });
  });

  group('librarySyncProvider', () {
    test('saves the bundled library, so its genres can be chosen', () async {
      final logs = _captureLog();
      final db = memoryDatabase();
      addTearDown(db.close);
      final container = ProviderContainer.test(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      final library = await loadLibraryManifest(rootBundle);

      startLibrarySync(container);
      final plan = await container.read(librarySyncProvider.future);

      final saved = [for (final entry in library) entry.toStoredSound()];
      expect(plan.save, saved);
      expect(await SoundRepository(db).all(), unorderedEquals(saved));
      final genres = container.listen(genresProvider.future, (_, _) {});
      expect(await genres.read(), ['acoustic', 'electronic', 'lo-fi']);
      expect(logs, [startsWith('Saved the built-in library: ')]);

      // The next start finds the library saved, and says nothing.
      container.invalidate(librarySyncProvider);
      final again = await container.read(librarySyncProvider.future);
      expect(again.isEmpty, isTrue);
      expect(logs, hasLength(1));
    });

    test('logs a database that cannot open, and saves the library into the '
        'next one', () async {
      final logs = _captureLog();
      final db = memoryDatabase();
      addTearDown(db.close);
      var opened = 0;
      final container = ProviderContainer.test(
        // Riverpod would try again by itself a moment later.
        retry: (_, _) => null,
        overrides: [
          databaseProvider.overrideWith(
            (ref) => opened++ == 0 ? _brokenDatabase() : db,
          ),
        ],
      );

      startLibrarySync(container);
      await expectLater(
        container.read(librarySyncProvider.future),
        throwsA(isA<Exception>()),
      );

      expect(logs, [
        startsWith(
          'Could not save the built-in library: '
          'Exception: Storage is blocked',
        ),
      ]);

      // Try again on the Alarms tab opens a new database.
      container.invalidate(databaseProvider);
      await container.read(librarySyncProvider.future);

      expect(await SoundRepository(db).all(), hasLength(9));
      expect(logs, hasLength(2));
      expect(logs.last, startsWith('Saved the built-in library: '));
    });
  });
}

/// The lines that [debugPrint] prints until the end of the test, which go
/// there instead of the console.
List<String?> _captureLog() {
  final lines = <String?>[];
  final print = debugPrint;
  debugPrint = (message, {wrapWidth}) => lines.add(message);
  addTearDown(() => debugPrint = print);
  return lines;
}

/// A built-in clip with every value set, as [LibraryEntry.toStoredSound]
/// makes it.
StoredSound _builtin(
  String id, {
  String? title,
  String genre = 'acoustic',
  int intensity = 1,
  double seconds = 20,
  String? file,
}) => LibraryEntry(
  id: id,
  title: title ?? id,
  artist: 'Wakemix',
  genre: genre,
  intensity: intensity,
  file: file ?? '$genre/$id.wav',
  duration: Duration(microseconds: (seconds * 1e6).round()),
  license: 'original',
  sourceUrl: 'tool/generate_placeholder_library.dart',
  attribution: 'Wakemix',
).toStoredSound();

/// A song or voice message of the user's.
StoredSound _own(String id, SoundSource source) => StoredSound(
  Sound(
    id: id,
    title: id,
    source: source,
    genre: source.name,
    intensity: 2,
    duration: const Duration(seconds: 30),
  ),
  audioPath: 'sounds/$id.m4a',
);

/// A database that cannot open, as in a browser that blocks the storage of
/// the site. Do not close it: it never opened.
AppDatabase _brokenDatabase() => AppDatabase(
  DatabaseConnection(
    LazyDatabase(() => throw Exception('Storage is blocked')),
    closeStreamsSynchronously: true,
  ),
);
