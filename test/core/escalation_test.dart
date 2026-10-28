import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/escalation.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/core/shuffle_bag.dart';

void main() {
  group('Escalation.at', () {
    test('asks for intensity 1, 2, 3 at 40%, 70% and 100% volume', () {
      expect(_steps(gentleStart: true).take(3), [(1, 0.4), (2, 0.7), (3, 1.0)]);
    });

    test('then lets any sound play, at full volume', () {
      expect(_steps(gentleStart: true).skip(3), everyElement((null, 1.0)));
    });

    test('without a gentle start, lets any sound play at full volume', () {
      expect(_steps(gentleStart: false), everyElement((null, 1.0)));
    });

    test('rejects a negative index', () {
      expect(
        () => Escalation.at(-1, gentleStart: true),
        throwsA(isRangeError.having((error) => error.name, 'name', 'index')),
      );
    });
  });

  group('A ring with a gentle start', () {
    test('plays intensity 1, then 2, then 3', () {
      for (var size = 3; size <= 12; size++) {
        for (final seed in _seeds) {
          final ring = _ring(
            _mixedPool(size),
            seed: seed,
            gentleStart: true,
            count: 3,
          );

          expect(
            [for (final sound in ring) sound.intensity],
            [1, 2, 3],
            reason: '$size sounds, seed $seed',
          );
        }
      }
    });

    test('plays the nearest intensity when a level is missing', () {
      // The intensities in a pool, and those of the first three sounds.
      const cases = [
        ([3, 3, 3, 3], [3, 3, 3]),
        ([1, 1, 1, 1], [1, 1, 1]),
        ([2, 2, 2, 2], [2, 2, 2]),
        // 1 and 3 are just as near to 2: the gentler one plays.
        ([1, 1, 3, 3], [1, 1, 3]),
        ([2, 2, 3, 3], [2, 2, 3]),
        ([1, 1, 2, 2], [1, 2, 2]),
        // The bag rules come first: two sounds take turns.
        ([1, 3], [1, 3, 1]),
      ];

      for (final (intensities, played) in cases) {
        for (final seed in _seeds) {
          final ring = _ring(
            _poolOf(intensities),
            seed: seed,
            gentleStart: true,
            count: 3,
          );

          expect(
            [for (final sound in ring) sound.intensity],
            played,
            reason: 'Pool of intensities $intensities, seed $seed',
          );
        }
      }
    });

    test('still plays every sound once per bag, none twice in a row', () {
      for (var size = 2; size <= 10; size++) {
        for (final seed in _seeds) {
          // 1000 sounds are 100 to 500 bags.
          final ring = _ring(
            _mixedPool(size),
            seed: seed,
            gentleStart: true,
            count: 1000,
          );

          expect(
            _bagRuleBreaks(_ids(ring), size),
            isEmpty,
            reason: '$size sounds, seed $seed',
          );
        }
      }
    });

    test('is the same for the same seed', () {
      final pool = _mixedPool(9);

      for (final seed in _seeds) {
        expect(
          _ids(_ring(pool, seed: seed, gentleStart: true)),
          _ids(_ring(pool, seed: seed, gentleStart: true)),
          reason: 'Seed $seed',
        );
      }
    });
  });

  test('a ring without a gentle start is a plain shuffle', () {
    final pool = _mixedPool(9);

    for (final seed in _seeds) {
      final bag = ShuffleBag(pool, random: Random(seed));

      expect(_ids(_ring(pool, seed: seed, gentleStart: false)), [
        for (var i = 0; i < 60; i++) bag.next().id,
      ], reason: 'Seed $seed');
    }
  });
}

/// Seeds for the random number generator, so each check runs many times.
final _seeds = <int>[for (var seed = 0; seed < 200; seed++) seed];

/// The intensity and the volume that the first 50 sounds of a ring get.
List<(int?, double)> _steps({required bool gentleStart}) =>
    List.generate(50, (index) {
      final step = Escalation.at(index, gentleStart: gentleStart);
      return (step.intensity, step.volume);
    });

/// The first [count] sounds of a ring of [pool], picked the way task 1.6
/// will pick them: each one out of the shuffle bag, of the intensity that
/// its escalation asks for.
List<Sound> _ring(
  List<Sound> pool, {
  required int seed,
  required bool gentleStart,
  int count = 60,
}) {
  final bag = ShuffleBag(pool, random: Random(seed));
  return [
    for (var index = 0; index < count; index++)
      bag.next(
        intensity: Escalation.at(index, gentleStart: gentleStart).intensity,
      ),
  ];
}

/// [size] built-in sounds of intensity 1, 2, 3, 1, 2, 3 and so on.
List<Sound> _mixedPool(int size) =>
    _poolOf([for (var i = 0; i < size; i++) i % 3 + 1]);

/// Built-in sounds `sound-1`, `sound-2` and so on, one of each of
/// [intensities], in this order.
List<Sound> _poolOf(List<int> intensities) => [
  for (var i = 0; i < intensities.length; i++)
    Sound(
      id: 'sound-${i + 1}',
      title: 'Clip',
      source: SoundSource.builtin,
      genre: 'pop',
      intensity: intensities[i],
      duration: const Duration(seconds: 20),
    ),
];

/// The ids of [sounds], in their order.
List<String> _ids(Iterable<Sound> sounds) => [
  for (final sound in sounds) sound.id,
];

/// Where [ids], the sounds of a ring of [poolSize] sounds, break the bag
/// rules: a bag without every sound once, or a sound twice in a row.
List<String> _bagRuleBreaks(List<String> ids, int poolSize) => [
  for (var start = 0; start + poolSize <= ids.length; start += poolSize)
    if (ids.sublist(start, start + poolSize).toSet().length < poolSize)
      'bag ${start ~/ poolSize + 1}: ${ids.sublist(start, start + poolSize)}',
  for (var i = 1; i < ids.length; i++)
    if (ids[i] == ids[i - 1]) 'sounds $i and ${i + 1}: ${ids[i]}',
];
