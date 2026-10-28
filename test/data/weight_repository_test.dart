import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/adaptive_weights.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/data/weight_repository.dart';

import 'memory_database.dart';

void main() {
  late AppDatabase db;
  late WeightRepository weights;

  setUp(() async {
    db = memoryDatabase();
    weights = WeightRepository(db);
    final sounds = SoundRepository(db);
    for (final id in ['a', 'b', 'c']) {
      await sounds.save(_sound(id));
    }
  });

  tearDown(() => db.close());

  group('WeightRepository', () {
    test(
      'gives every sound the start weight before anything is saved',
      () async {
        expect(await weights.load(), const SoundWeights.start());
      },
    );

    test(
      'saves the weights after each tap and reads back the same weights',
      () async {
        var learned = const SoundWeights.start();
        for (final (tap, soundId) in [
          (_stop, 'a'),
          (_snooze, 'b'),
          (_snooze, 'b'),
          (_stop, 'c'),
          (_snooze, 'c'),
        ]) {
          learned = tap(learned, soundId);
          await weights.save(learned, soundId: soundId);
        }

        final read = await weights.load();
        expect(read, learned);
        expect(read.weightOf('a'), 1.1);
        expect(read.weightOf('b'), closeTo(0.64, 1e-9));
        expect(read.weightOf('c'), closeTo(0.88, 1e-9));
      },
    );

    test('keeps a weight at each limit', () async {
      var learned = const SoundWeights.start();
      for (var i = 0; i < 20; i++) {
        learned = learned.afterSnooze('a').afterStop('b');
      }
      await weights.save(learned, soundId: 'a');
      await weights.save(learned, soundId: 'b');

      final read = await weights.load();
      expect(read.weightOf('a'), SoundWeights.minWeight);
      expect(read.weightOf('b'), SoundWeights.maxWeight);
    });

    test('saves only the weight of the sound it is given', () async {
      final learned = const SoundWeights.start()
          .afterStop('a')
          .afterSnooze('b');

      await weights.save(learned, soundId: 'b');

      expect(await weights.load(), SoundWeights(const {'b': 0.8}));
    });

    test('does nothing for a sound that is not saved', () async {
      // Such as a song the user deleted while it rang: a weight goes with
      // its sound.
      final learned = const SoundWeights.start().afterStop('deleted');

      await weights.save(learned, soundId: 'deleted');

      expect(await weights.load(), const SoundWeights.start());
    });

    test('forgets every weight when cleared', () async {
      final learned = const SoundWeights.start()
          .afterStop('a')
          .afterSnooze('b');
      await weights.save(learned, soundId: 'a');
      await weights.save(learned, soundId: 'b');

      await weights.clear();

      expect(await weights.load(), const SoundWeights.start());
    });
  });
}

SoundWeights _stop(SoundWeights weights, String soundId) =>
    weights.afterStop(soundId);

SoundWeights _snooze(SoundWeights weights, String soundId) =>
    weights.afterSnooze(soundId);

StoredSound _sound(String id) => StoredSound(
  Sound(
    id: id,
    title: 'Sound $id',
    source: SoundSource.builtin,
    genre: 'pop',
    intensity: 1,
    duration: const Duration(seconds: 20),
  ),
  audioPath: 'assets/library/pop/$id.mp3',
);
