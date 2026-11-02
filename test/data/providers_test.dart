import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';

import 'memory_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = memoryDatabase();
    container = ProviderContainer.test(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() => db.close());

  test('the alarm list follows every change', () async {
    final alarms = AlarmRepository(db);
    final lists = <List<Alarm>>[];
    container.listen(alarmsProvider, (_, next) => lists.add(next.requireValue));

    expect(await container.read(alarmsProvider.future), isEmpty);
    final alarm = Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0));
    await alarms.save(alarm);
    await pumpEventQueue();
    await alarms.delete('a');
    await pumpEventQueue();

    expect(lists, [
      isEmpty,
      [alarm],
      isEmpty,
    ]);
  });

  test(
    'the genres are those of the built-in sounds, A to Z, once each',
    () async {
      final sounds = SoundRepository(db);
      for (final (id, source, genre) in [
        ('sunrise', SoundSource.builtin, 'pop'),
        ('ocean', SoundSource.builtin, 'pop'),
        ('blue', SoundSource.builtin, 'jazz'),
        ('my-song', SoundSource.user, 'my-songs'),
        ('mom', SoundSource.voice, 'voice'),
      ]) {
        await sounds.save(
          StoredSound(
            Sound(
              id: id,
              title: id,
              source: source,
              genre: genre,
              intensity: 1,
              duration: const Duration(seconds: 20),
            ),
            audioPath: '$genre/$id.mp3',
          ),
        );
      }

      // Riverpod pauses a provider that nobody listens to.
      final genres = container.listen(genresProvider.future, (_, _) {});
      expect(await genres.read(), ['jazz', 'pop']);
    },
  );

  group('The sounds that alarms can play', () {
    final fromFiles = StoredSound(
      Sound(
        id: 'file',
        title: 'File',
        source: SoundSource.builtin,
        genre: 'calm',
        intensity: 1,
        duration: const Duration(seconds: 20),
      ),
      audioPath: 'assets/library/calm/file.wav',
    );
    final saved = StoredSound(
      Sound(
        id: 'saved',
        title: 'Saved',
        source: SoundSource.builtin,
        genre: 'calm',
        intensity: 1,
        duration: const Duration(seconds: 20),
      ),
      audioPath: 'assets/library/calm/saved.wav',
    );

    ProviderContainer withLibrary(
      Future<List<StoredSound>> Function() library, {
      SoundRepository? sounds,
    }) => ProviderContainer.test(
      overrides: [
        databaseProvider.overrideWithValue(db),
        libraryClipsProvider.overrideWithValue(library),
        if (sounds != null) soundRepositoryProvider.overrideWithValue(sounds),
      ],
    );

    test('are the sounds of the database, when it has any', () async {
      await SoundRepository(db).save(saved);
      final sounds = withLibrary(() async => [fromFiles]);

      expect(await sounds.read(ringSoundsProvider)(), [saved]);
    });

    test(
      'are the library from its files, when the database has none',
      () async {
        final sounds = withLibrary(() async => [fromFiles]);

        expect(await sounds.read(ringSoundsProvider)(), [fromFiles]);
      },
    );

    test('are the library, when the database cannot be read', () async {
      final sounds = withLibrary(
        () async => [fromFiles],
        sounds: _BrokenSounds(db),
      );

      expect(await sounds.read(ringSoundsProvider)(), [fromFiles]);
    });

    test('throw when the library cannot be read either', () async {
      final sounds = withLibrary(() async => throw StateError('No network'));

      await expectLater(sounds.read(ringSoundsProvider)(), throwsStateError);
    });
  });
}

class _BrokenSounds extends SoundRepository {
  _BrokenSounds(super._db);

  @override
  Future<List<StoredSound>> all() async => throw StateError('Broken');
}
