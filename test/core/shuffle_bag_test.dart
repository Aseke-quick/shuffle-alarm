import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

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
