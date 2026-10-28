import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/adaptive_weights.dart';
import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/ring_session_repository.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/data/weight_repository.dart';

import 'memory_database.dart';

void main() {
  late AppDatabase db;
  late SoundRepository sounds;

  setUp(() {
    db = memoryDatabase();
    sounds = SoundRepository(db);
  });

  tearDown(() => db.close());

  group('SoundRepository', () {
    test(
      'saves a sound of each source and reads back the same sound',
      () async {
        final stored = _library();

        for (final sound in stored) {
          await sounds.save(sound);
        }

        for (final sound in stored) {
          expect(await sounds.byId(sound.sound.id), sound);
        }
        expect(await sounds.all(), unorderedEquals(stored));
      },
    );

    test('keeps the length and the clip start to the microsecond', () async {
      // A clip start 1 µs before the end of the file is still inside it. A
      // database that rounded to milliseconds would move it to the end, and
      // the sound could not be read back.
      final sound = StoredSound(
        Sound(
          id: 'my-song',
          title: 'My song',
          source: SoundSource.user,
          genre: 'my-songs',
          intensity: 2,
          duration: const Duration(minutes: 3, microseconds: 500),
          clipStart: const Duration(minutes: 3, microseconds: 499),
        ),
        audioPath: 'sounds/my-song.mp3',
      );

      await sounds.save(sound);

      expect(await sounds.byId('my-song'), sound);
    });

    test('lists the sounds by id', () async {
      for (final sound in _library().reversed) {
        await sounds.save(sound);
      }

      expect((await sounds.all()).map((stored) => stored.sound.id), [
        'mom',
        'my-song',
        'sunrise',
      ]);
    });

    test(
      'saving a sound again replaces its values and keeps its weight',
      () async {
        final weights = WeightRepository(db);
        await sounds.save(_library().first);
        await weights.save(
          const SoundWeights.start().afterStop('sunrise'),
          soundId: 'sunrise',
        );
        final changed = StoredSound(
          Sound(
            id: 'sunrise',
            title: 'Sunrise (new mix)',
            source: SoundSource.builtin,
            genre: 'acoustic',
            intensity: 2,
            duration: const Duration(seconds: 20),
          ),
          audioPath: 'assets/library/acoustic/sunrise.mp3',
        );

        await sounds.save(changed);

        expect(await sounds.all(), [changed]);
        expect((await weights.load()).weightOf('sunrise'), 1.1);
      },
    );

    test('reads null for a sound it does not have', () async {
      expect(await sounds.byId('missing'), isNull);
    });

    test(
      'deletes a sound with its weight, and keeps its ring history',
      () async {
        final weights = WeightRepository(db);
        final sessions = RingSessionRepository(db);
        final session = RingSession(
          id: 's1',
          alarmId: 'a',
          scheduledFor: DateTime(2026, 10, 29, 7),
          events: [
            RingEvent(
              soundId: 'mom',
              startedAt: DateTime(2026, 10, 29, 7),
              endedAt: DateTime(2026, 10, 29, 7, 0, 12),
              action: RingAction.stop,
            ),
          ],
        );
        for (final sound in _library()) {
          await sounds.save(sound);
        }
        final learned = const SoundWeights.start()
            .afterStop('mom')
            .afterSnooze('sunrise');
        await weights.save(learned, soundId: 'mom');
        await weights.save(learned, soundId: 'sunrise');
        await sessions.save(session);

        await sounds.delete('mom');

        expect(await sounds.byId('mom'), isNull);
        expect((await sounds.all()).map((stored) => stored.sound.id), [
          'my-song',
          'sunrise',
        ]);
        expect(await weights.load(), SoundWeights(const {'sunrise': 0.8}));
        expect(await sessions.byId('s1'), session);
      },
    );
  });

  group('StoredSound', () {
    test('is equal to a stored sound with the same sound and path', () {
      final [sunrise, mySong, _] = _library();

      expect(_library().first, sunrise);
      expect(_library().first.hashCode, sunrise.hashCode);
      expect(
        StoredSound(sunrise.sound, audioPath: 'assets/elsewhere.mp3'),
        isNot(sunrise),
      );
      expect(
        StoredSound(mySong.sound, audioPath: sunrise.audioPath),
        isNot(sunrise),
      );
    });
  });
}

/// A built-in clip, a user song and a voice message, each with every value
/// set and lengths with microseconds.
List<StoredSound> _library() => [
  StoredSound(
    Sound(
      id: 'sunrise',
      title: 'Sunrise',
      source: SoundSource.builtin,
      genre: 'pop',
      intensity: 1,
      duration: const Duration(seconds: 28, microseconds: 512345),
    ),
    audioPath: 'assets/library/pop/sunrise.mp3',
  ),
  StoredSound(
    Sound(
      id: 'my-song',
      title: 'Song I love',
      source: SoundSource.user,
      genre: 'my-songs',
      intensity: 3,
      duration: const Duration(minutes: 3, seconds: 12, microseconds: 345678),
      clipStart: const Duration(seconds: 61, microseconds: 1),
    ),
    audioPath: 'sounds/my-song.m4a',
  ),
  StoredSound(
    Sound(
      id: 'mom',
      title: 'Mom',
      source: SoundSource.voice,
      genre: 'voice',
      intensity: 2,
      duration: const Duration(seconds: 12, microseconds: 7),
    ),
    audioPath: 'sounds/mom.webm',
  ),
];
