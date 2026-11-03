import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/adaptive_weights.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/core/shuffle_bag.dart';

void main() {
  group('ShuffleBag', () {
    test('plays every sound once in each bag', () {
      for (var size = 1; size <= 10; size++) {
        final pool = _pool(size);
        final poolIds = _ids(pool);
        for (final seed in _seeds) {
          final ids = _next(ShuffleBag(pool, random: Random(seed)), size * 20);

          for (var start = 0; start < ids.length; start += size) {
            expect(
              ids.sublist(start, start + size),
              unorderedEquals(poolIds),
              reason: 'Bag ${start ~/ size + 1} of $size sounds, seed $seed',
            );
          }
        }
      }
    });

    test('starts a new bag with any sound but the one that just played', () {
      final pool = _pool(3);
      // Picks 3 and 4 are the last sound of the first bag and the first
      // sound of the second one.
      final refills = {
        for (final seed in _seeds)
          _next(
            ShuffleBag(pool, random: Random(seed)),
            4,
          ).sublist(2).join(' then '),
      };

      expect(refills, {
        'sound-1 then sound-2',
        'sound-1 then sound-3',
        'sound-2 then sound-1',
        'sound-2 then sound-3',
        'sound-3 then sound-1',
        'sound-3 then sound-2',
      });
    });

    test('makes the two sounds of a pool of two take turns', () {
      final firstSounds = <String>{};
      for (final seed in _seeds) {
        final ids = _next(ShuffleBag(_pool(2), random: Random(seed)), 100);
        firstSounds.add(ids.first);

        expect(ids.take(2), unorderedEquals(['sound-1', 'sound-2']));
        expect(ids, [
          for (var i = 0; i < ids.length; i++) ids[i % 2],
        ], reason: 'Seed $seed');
      }

      expect(firstSounds, {'sound-1', 'sound-2'});
    });

    test('plays the only sound of a pool of one every time', () {
      final sound = _sound('sound-1');
      final bag = ShuffleBag([sound], random: Random(1));

      for (var i = 0; i < 50; i++) {
        expect(bag.next(), sound);
      }
    });

    test('rejects an empty pool', () {
      expect(
        () => ShuffleBag(const [], random: Random(1)),
        throwsA(isArgumentError.having((error) => error.name, 'name', 'pool')),
      );
    });

    test('gives the same sounds in the same order for the same seed', () {
      final pool = _pool(5);

      for (final seed in _seeds) {
        expect(
          _next(ShuffleBag(pool, random: Random(seed)), 100),
          _next(ShuffleBag(pool, random: Random(seed)), 100),
          reason: 'Seed $seed',
        );
      }
    });

    test('shuffles: every order of three sounds turns up', () {
      final pool = _pool(3);
      final orders = {
        for (final seed in _seeds)
          _next(ShuffleBag(pool, random: Random(seed)), 3).join(' '),
      };

      expect(orders, {
        'sound-1 sound-2 sound-3',
        'sound-1 sound-3 sound-2',
        'sound-2 sound-1 sound-3',
        'sound-2 sound-3 sound-1',
        'sound-3 sound-1 sound-2',
        'sound-3 sound-2 sound-1',
      });
    });

    test('gives the same order whatever the order of the pool', () {
      final pool = _pool(6);

      for (final seed in _seeds) {
        final sequence = _next(ShuffleBag(pool, random: Random(seed)), 60);

        for (final reordered in [
          pool.reversed,
          [...pool.skip(2), ...pool.take(2)],
        ]) {
          expect(
            _next(ShuffleBag(reordered, random: Random(seed)), 60),
            sequence,
            reason: 'Pool ${_ids(reordered)}, seed $seed',
          );
        }
      }
    });

    test('counts sounds with the same id as one sound: the first one', () {
      final first = _sound('sound-1');
      final other = _sound('sound-2');
      final sameId = _sound('sound-1', title: 'Same id, other title');

      for (final seed in _seeds) {
        final bag = ShuffleBag([first, other, sameId], random: Random(seed));
        final sounds = [for (var i = 0; i < 40; i++) bag.next()];

        expect(sounds.toSet(), {first, other}, reason: 'Seed $seed');
        expect(sounds, [
          for (var i = 0; i < sounds.length; i++) sounds[i % 2],
        ], reason: 'Two sounds take turns, seed $seed');
      }
    });
  });

  test('no sound twice in a row, also when the bag is refilled', () {
    for (var size = 2; size <= 10; size++) {
      for (final seed in _seeds) {
        // 1000 picks are 100 to 500 bags.
        final ids = _next(ShuffleBag(_pool(size), random: Random(seed)), 1000);
        final repeats = [
          for (var i = 1; i < ids.length; i++)
            if (ids[i] == ids[i - 1]) 'picks $i and ${i + 1}: ${ids[i]}',
        ];

        expect(repeats, isEmpty, reason: '$size sounds, seed $seed');
      }
    }
  });

  group('ShuffleBag.next with an intensity', () {
    test('takes a sound of that intensity while the bag has one', () {
      // Two sounds of each intensity: sound-3 and sound-4 are intensity 2.
      final pool = _poolOf([1, 1, 2, 2, 3, 3]);

      for (final seed in _seeds) {
        final bag = ShuffleBag(pool, random: Random(seed));

        expect(
          [bag.next(intensity: 2).id, bag.next(intensity: 2).id],
          unorderedEquals(['sound-3', 'sound-4']),
          reason: 'Seed $seed',
        );
        // This bag has no sound of intensity 2 left, and 1 and 3 are just as
        // near: the gentler one plays.
        expect(bag.next(intensity: 2).intensity, 1, reason: 'Seed $seed');
      }
    });

    test('picks at random among the sounds of that intensity', () {
      final pool = _poolOf([1, 1, 1, 3]);
      final firstSounds = {
        for (final seed in _seeds)
          ShuffleBag(pool, random: Random(seed)).next(intensity: 1).id,
      };

      expect(firstSounds, {'sound-1', 'sound-2', 'sound-3'});
    });

    test('takes the nearest intensity, the gentler one on a tie', () {
      // The intensities in a pool, the one asked for and the one played.
      const cases = [
        ([3, 3], 1, 3),
        ([1, 1], 3, 1),
        ([2, 3], 1, 2),
        ([1, 2], 3, 2),
        ([1, 3], 2, 1),
      ];

      for (final (intensities, asked, played) in cases) {
        for (final seed in _seeds) {
          final bag = ShuffleBag(_poolOf(intensities), random: Random(seed));

          expect(
            bag.next(intensity: asked).intensity,
            played,
            reason: 'Intensities $intensities, asked for $asked, seed $seed',
          );
        }
      }
    });

    test('keeps both bag rules, whatever intensity it is asked for', () {
      const asks = [null, 1, 2, 3];

      for (var size = 2; size <= 10; size++) {
        final pool = _poolOf([for (var i = 0; i < size; i++) i % 3 + 1]);
        for (final seed in _seeds) {
          final bag = ShuffleBag(pool, random: Random(seed));
          // A generator of its own picks what to ask for, so the bag's
          // generator still only picks sounds.
          final askRandom = Random(seed + 1000);
          final ids = [
            for (var i = 0; i < 1000; i++)
              bag.next(intensity: asks[askRandom.nextInt(asks.length)]).id,
          ];
          final breaks = [
            for (var start = 0; start + size <= ids.length; start += size)
              if (ids.sublist(start, start + size).toSet().length < size)
                'bag ${start ~/ size + 1}: ${ids.sublist(start, start + size)}',
            for (var i = 1; i < ids.length; i++)
              if (ids[i] == ids[i - 1]) 'picks $i and ${i + 1}: ${ids[i]}',
          ];

          expect(breaks, isEmpty, reason: '$size sounds, seed $seed');
        }
      }
    });
  });

  group('ShuffleBag with weights', () {
    test('takes each sound as likely as its weight says', () {
      // Weights 3, 1, 0.5 and 0.5 add up to 5: the first sound out of a bag
      // should be sound-1 in 60% of the bags, sound-2 in 20%, and sound-3
      // and sound-4 in 10% each.
      final weights = SoundWeights(const {
        'sound-1': 3,
        'sound-3': 0.5,
        'sound-4': 0.5,
      });
      final firstSounds = [
        for (var seed = 0; seed < 2000; seed++)
          ShuffleBag(
            _pool(4),
            random: Random(seed),
            weights: weights,
          ).next().id,
      ];

      expect(_share('sound-1', firstSounds), closeTo(0.6, 0.04));
      expect(_share('sound-2', firstSounds), closeTo(0.2, 0.04));
      expect(_share('sound-3', firstSounds), closeTo(0.1, 0.04));
      expect(_share('sound-4', firstSounds), closeTo(0.1, 0.04));
    });

    test('makes a heavier sound come out of its bag earlier', () {
      // sound-1 is 3 times as heavy as the other sounds, sound-6 5 times as
      // light.
      final weights = SoundWeights(const {'sound-1': 3, 'sound-6': 0.2});
      // The places each sound came in, added up over 10 bags per seed: 1 is
      // the first sound out of a bag, 6 the last one.
      final placeSums = <String, int>{};
      for (final seed in _seeds) {
        final bag = ShuffleBag(
          _pool(6),
          random: Random(seed),
          weights: weights,
        );
        for (var i = 0; i < 60; i++) {
          final id = bag.next().id;
          placeSums[id] = (placeSums[id] ?? 0) + i % 6 + 1;
        }
      }
      // Every sound comes once in each bag.
      double averagePlace(String id) => placeSums[id]! / (10 * _seeds.length);

      // Without weights, every sound would come in place 3.5 on average.
      expect(averagePlace('sound-1'), lessThan(2.5));
      expect(averagePlace('sound-3'), closeTo(3.5, 0.25));
      expect(averagePlace('sound-6'), greaterThan(4.5));
    });

    test('still plays every sound once per bag, none twice in a row', () {
      const asks = [null, 1, 2, 3];

      for (var size = 2; size <= 10; size++) {
        final pool = _poolOf([for (var i = 0; i < size; i++) i % 3 + 1]);
        for (final seed in _seeds) {
          // A generator of its own picks the weights and what to ask for, so
          // the bag's generator still only picks sounds.
          final setup = Random(seed + 1000);
          final weights = SoundWeights({
            for (final sound in pool)
              sound.id:
                  SoundWeights.minWeight +
                  setup.nextDouble() *
                      (SoundWeights.maxWeight - SoundWeights.minWeight),
          });
          final bag = ShuffleBag(pool, random: Random(seed), weights: weights);
          final ids = [
            for (var i = 0; i < 1000; i++)
              bag.next(intensity: asks[setup.nextInt(asks.length)]).id,
          ];

          expect(
            _bagRuleBreaks(ids, size),
            isEmpty,
            reason: '$size sounds, seed $seed, $weights',
          );
        }
      }
    });

    test('still takes the only sound it may take, whatever its weight', () {
      final only = _sound('sound-1');
      final lightBag = ShuffleBag(
        [only],
        random: Random(1),
        weights: SoundWeights(const {'sound-1': 0.2}),
      );
      for (var i = 0; i < 50; i++) {
        expect(lightBag.next(), only);
      }

      // The only gentle sound is as light as can be, the strong ones as
      // heavy as can be.
      final pool = _poolOf([1, 3, 3]);
      final weights = SoundWeights(const {
        'sound-1': 0.2,
        'sound-2': 3,
        'sound-3': 3,
      });
      for (final seed in _seeds) {
        final bag = ShuffleBag(pool, random: Random(seed), weights: weights);

        expect(bag.next(intensity: 1).id, 'sound-1', reason: 'Seed $seed');
      }
    });

    test('picks like a bag without weights when all weights are equal', () {
      final pool = _pool(6);
      // Only how the weights compare counts.
      final equal = SoundWeights({for (final sound in pool) sound.id: 2});

      for (final seed in _seeds) {
        expect(
          _next(ShuffleBag(pool, random: Random(seed), weights: equal), 100),
          _next(ShuffleBag(pool, random: Random(seed)), 100),
          reason: 'Seed $seed',
        );
      }
    });

    test('ignores the weights of sounds outside its pool', () {
      final pool = _pool(4);
      final others = SoundWeights(const {'other-1': 3, 'other-2': 0.2});

      for (final seed in _seeds) {
        expect(
          _next(ShuffleBag(pool, random: Random(seed), weights: others), 100),
          _next(ShuffleBag(pool, random: Random(seed)), 100),
          reason: 'Seed $seed',
        );
      }
    });

    test('gives the same sounds in the same order for the same seed', () {
      final pool = _pool(6);
      final weights = SoundWeights(const {
        'sound-2': 3,
        'sound-4': 0.2,
        'sound-5': 1.7,
      });

      for (final seed in _seeds) {
        final sequence = _next(
          ShuffleBag(pool, random: Random(seed), weights: weights),
          60,
        );

        // Also whatever the order of the pool.
        for (final sounds in [pool, pool.reversed]) {
          expect(
            _next(
              ShuffleBag(sounds, random: Random(seed), weights: weights),
              60,
            ),
            sequence,
            reason: 'Pool ${_ids(sounds)}, seed $seed',
          );
        }
      }
    });

    test('draws one random number per sound, whatever the weights', () {
      const asks = [null, 1, 2, 3];
      final random = _CountingRandom(Random(1));
      // Asked for intensity 2, this bag has one sound to choose from at most.
      final bag = ShuffleBag(
        _poolOf([1, 1, 2, 3, 3]),
        random: random,
        weights: SoundWeights(const {'sound-1': 3, 'sound-4': 0.2}),
      );

      for (var i = 0; i < 100; i++) {
        bag.next(intensity: asks[i % asks.length]);
      }

      expect(random.draws, 100);
    });
  });

  group('ShuffleBag after another sound', () {
    test('starts with any sound but the one that played before it', () {
      for (var size = 2; size <= 10; size++) {
        final pool = _pool(size);
        for (final last in pool) {
          final firstSounds = <String>{};
          for (final seed in _seeds) {
            final ids = _next(
              ShuffleBag(pool, random: Random(seed), lastId: last.id),
              size * 10,
            );
            firstSounds.add(ids.first);

            expect(
              _bagRuleBreaks(ids, size),
              isEmpty,
              reason: '$size sounds after ${last.id}, seed $seed',
            );
          }

          expect(
            firstSounds,
            _ids(pool).toSet()..remove(last.id),
            reason: '$size sounds after ${last.id}',
          );
        }
      }
    });

    test('plays the only sound of a pool of one, also after itself', () {
      final sound = _sound('sound-1');
      final bag = ShuffleBag([sound], random: Random(1), lastId: 'sound-1');

      for (var i = 0; i < 10; i++) {
        expect(bag.next(), sound);
      }
    });

    test('is not changed by a sound outside its pool', () {
      final pool = _pool(4);

      for (final seed in _seeds) {
        expect(
          _next(ShuffleBag(pool, random: Random(seed), lastId: 'other'), 40),
          _next(ShuffleBag(pool, random: Random(seed)), 40),
          reason: 'Seed $seed',
        );
      }
    });
  });

  group('A bag with a plan', () {
    test('takes the planned sounds in their order, whatever the Random', () {
      const planned = ['sound-3', 'sound-1', 'sound-5', 'sound-2', 'sound-4'];

      for (final seed in _seeds) {
        final bag = ShuffleBag(
          _pool(5),
          random: Random(seed),
          planned: planned,
        );

        expect(_next(bag, 5), planned, reason: 'Seed $seed');
      }
    });

    test('follows the plan into the next bag too', () {
      final bag = ShuffleBag(
        _pool(3),
        random: Random(1),
        planned: const [
          'sound-1',
          'sound-2',
          'sound-3',
          'sound-2',
          'sound-3',
          'sound-1',
        ],
      );

      expect(_next(bag, 6), [
        'sound-1',
        'sound-2',
        'sound-3',
        'sound-2',
        'sound-3',
        'sound-1',
      ]);
    });

    test('skips a planned sound that is not in the pool', () {
      final bag = ShuffleBag(
        _pool(2),
        random: Random(1),
        planned: const ['gone', 'sound-2', 'gone', 'sound-1'],
      );

      expect(_next(bag, 2), ['sound-2', 'sound-1']);
    });

    test('takes a sound the plan does not name after the planned ones', () {
      for (final seed in _seeds) {
        final bag = ShuffleBag(
          _pool(3),
          random: Random(seed),
          planned: const ['sound-3', 'sound-1'],
        );

        expect(_next(bag, 3), [
          'sound-3',
          'sound-1',
          'sound-2',
        ], reason: 'Seed $seed');
      }
    });

    test('never plays a sound twice in a row, whatever the plan says', () {
      final bag = ShuffleBag(
        _pool(2),
        random: Random(1),
        planned: const ['sound-1', 'sound-1', 'sound-2', 'sound-2'],
      );

      expect(_next(bag, 4), ['sound-1', 'sound-2', 'sound-1', 'sound-2']);
    });

    test('does not start with the sound before it, whatever the plan says', () {
      final bag = ShuffleBag(
        _pool(2),
        random: Random(1),
        lastId: 'sound-1',
        planned: const ['sound-1', 'sound-2'],
      );

      expect(bag.next().id, 'sound-2');
    });

    test('asked for an intensity, takes the first planned sound of it', () {
      final gentle = _sound('gentle');
      final soft = _sound('soft');
      final medium = _sound('medium', intensity: 2);
      final bag = ShuffleBag(
        [gentle, soft, medium],
        random: Random(1),
        planned: const ['medium', 'soft', 'gentle'],
      );

      expect(bag.next(intensity: 1).id, 'soft');
      expect(bag.next(intensity: 2).id, 'medium');
      expect(bag.next().id, 'gentle');
    });

    test('with a plan of no use, picks as a bag without a plan', () {
      for (final planned in const [
        <String>[],
        ['gone', 'also-gone'],
      ]) {
        for (final seed in _seeds) {
          final pool = _pool(4);
          expect(
            _next(ShuffleBag(pool, random: Random(seed), planned: planned), 20),
            _next(ShuffleBag(pool, random: Random(seed)), 20),
            reason: 'Plan $planned, seed $seed',
          );
        }
      }
    });

    test('goes on with the Random after the plan ends, by the bag rules', () {
      for (final seed in _seeds) {
        final bag = ShuffleBag(
          _pool(4),
          random: Random(seed),
          planned: const ['sound-4', 'sound-2'],
        );
        final ids = _next(bag, 40);

        expect(ids.take(2), ['sound-4', 'sound-2']);
        expect(_bagRuleBreaks(ids, 4), isEmpty, reason: 'Seed $seed');
      }
    });
  });
}

/// Seeds for the random number generator, so each check runs many times.
final _seeds = <int>[for (var seed = 0; seed < 200; seed++) seed];

/// [count] built-in sounds: `sound-1`, `sound-2` and so on.
List<Sound> _pool(int count) => [
  for (var i = 1; i <= count; i++) _sound('sound-$i'),
];

/// Built-in sounds `sound-1`, `sound-2` and so on, one of each of
/// [intensities], in this order.
List<Sound> _poolOf(List<int> intensities) => [
  for (var i = 0; i < intensities.length; i++)
    _sound('sound-${i + 1}', intensity: intensities[i]),
];

/// A built-in clip. The shuffle bag tells sounds apart by their id, and looks
/// at their intensity only when [ShuffleBag.next] is asked for one.
Sound _sound(String id, {String title = 'Clip', int intensity = 1}) => Sound(
  id: id,
  title: title,
  source: SoundSource.builtin,
  genre: 'pop',
  intensity: intensity,
  duration: const Duration(seconds: 20),
);

/// The ids of the next [count] sounds out of [bag].
List<String> _next(ShuffleBag bag, int count) => [
  for (var i = 0; i < count; i++) bag.next().id,
];

/// The ids of [sounds], in their order.
List<String> _ids(Iterable<Sound> sounds) => [
  for (final sound in sounds) sound.id,
];

/// How often [id] is among [ids], from 0 (never) to 1 (every time).
double _share(String id, List<String> ids) =>
    ids.where((each) => each == id).length / ids.length;

/// Where [ids], the sounds out of a bag of [poolSize] sounds, break the bag
/// rules: a bag without every sound once, or a sound twice in a row.
List<String> _bagRuleBreaks(List<String> ids, int poolSize) => [
  for (var start = 0; start + poolSize <= ids.length; start += poolSize)
    if (ids.sublist(start, start + poolSize).toSet().length < poolSize)
      'bag ${start ~/ poolSize + 1}: ${ids.sublist(start, start + poolSize)}',
  for (var i = 1; i < ids.length; i++)
    if (ids[i] == ids[i - 1]) 'picks $i and ${i + 1}: ${ids[i]}',
];

/// A [Random] that counts the numbers it gives out.
class _CountingRandom implements Random {
  _CountingRandom(this._random);

  final Random _random;

  /// How many numbers it gave out.
  int draws = 0;

  @override
  bool nextBool() {
    draws++;
    return _random.nextBool();
  }

  @override
  double nextDouble() {
    draws++;
    return _random.nextDouble();
  }

  @override
  int nextInt(int max) {
    draws++;
    return _random.nextInt(max);
  }
}
