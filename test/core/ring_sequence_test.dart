import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/adaptive_weights.dart';
import 'package:shuffle_alarm/core/clip_rule.dart';
import 'package:shuffle_alarm/core/escalation.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/core/ring_sequence.dart';

void main() {
  group('buildRingSequence', () {
    test('plays clips back to back until the time cap: no gap, no overlap', () {
      final breaks = <String>[];
      for (final cap in _caps) {
        for (final seed in _seeds) {
          final ring = _ring(_randomPool(seed), seed: seed, cap: cap);
          final where = 'Cap $cap, seed $seed';

          if (ring.first.startsAt != Duration.zero) {
            breaks.add(
              '$where: the first clip starts at ${ring.first.startsAt}',
            );
          }
          for (var i = 1; i < ring.length; i++) {
            if (ring[i].startsAt != ring[i - 1].endsAt) {
              breaks.add(
                '$where: clip ${i + 1} starts at ${ring[i].startsAt}, '
                'clip $i ends at ${ring[i - 1].endsAt}',
              );
            }
          }
          if (ring.last.endsAt != cap) {
            breaks.add('$where: the last clip ends at ${ring.last.endsAt}');
          }
        }
      }

      expect(breaks, isEmpty);
    });

    test('plays each clip whole, only the last one cut to end at the cap', () {
      final breaks = <String>[];
      for (final cap in _caps) {
        for (final seed in _seeds) {
          final ring = _ring(_randomPool(seed), seed: seed, cap: cap);
          final where = 'Cap $cap, seed $seed';

          for (final clip in ring.take(ring.length - 1)) {
            if (clip.window != ClipWindow.of(clip.sound)) {
              breaks.add('$where: $clip is not whole');
            }
          }
          final last = ring.last;
          final whole = ClipWindow.of(last.sound);
          if (last.window.start != whole.start ||
              last.window.end > whole.end ||
              last.window.length <= Duration.zero) {
            breaks.add(
              '$where: the last clip $last is not the start of $whole',
            );
          }
        }
      }

      expect(breaks, isEmpty);
    });

    test('fills 10 minutes with 20 clips of 29 s and one of 20 s', () {
      final ring = _ring([
        _sound('clip', duration: const Duration(seconds: 29)),
      ], seed: 1);

      expect(
        [for (final clip in ring) clip.window.length.inSeconds],
        [...List.filled(20, 29), 20],
      );
      expect(ring.last.endsAt, const Duration(minutes: 10));
    });

    test('starts the next sound as soon as a 12-s voice message ends', () {
      final pool = [
        _sound(
          'voice',
          source: SoundSource.voice,
          duration: const Duration(seconds: 12),
        ),
        _sound('clip', duration: const Duration(seconds: 29)),
      ];
      // The two sounds take turns, the voice message first or second.
      final starts = {
        for (final seed in _seeds)
          [
            for (final clip in _ring(pool, seed: seed).take(4))
              clip.startsAt.inSeconds,
          ].join(' '),
      };

      expect(starts, {'0 12 41 53', '0 29 41 70'});
    });

    test('rings for 10 minutes unless told otherwise', () {
      final ring = buildRingSequence(
        _alarm(),
        _randomPool(1),
        const SoundWeights.start(),
        1,
      );

      expect(defaultRingCap, const Duration(minutes: 10));
      expect(ring.last.endsAt, const Duration(minutes: 10));
    });

    test('rejects a time cap that is not positive', () {
      for (final cap in const [Duration.zero, Duration(seconds: -1)]) {
        expect(
          () => _ring(_randomPool(1), seed: 1, cap: cap),
          throwsA(isArgumentError.having((error) => error.name, 'name', 'cap')),
          reason: 'Cap $cap',
        );
      }
    });

    test('rejects a pool without sounds', () {
      expect(
        () => _ring(const [], seed: 1),
        throwsA(isArgumentError.having((error) => error.name, 'name', 'pool')),
      );
    });

    test('lets the weights choose: a heavier sound tends to come first', () {
      // Without a gentle start, the first sound is a weighted pick of all
      // four. Weights 3, 1, 1 and 1 add up to 6, so sound-1 should come first
      // in half of the rings; with 0.2, 1, 1 and 1 in one ring of 16.
      final pool = [for (var i = 1; i <= 4; i++) _sound('sound-$i')];
      List<String> firstSounds(SoundWeights weights) => [
        for (var seed = 0; seed < 2000; seed++)
          _ring(
            pool,
            seed: seed,
            gentleStart: false,
            weights: weights,
          ).first.sound.id,
      ];

      expect(
        _share('sound-1', firstSounds(SoundWeights(const {'sound-1': 3}))),
        closeTo(0.5, 0.04),
      );
      expect(
        _share('sound-1', firstSounds(SoundWeights(const {'sound-1': 0.2}))),
        closeTo(0.0625, 0.03),
      );
    });

    test(
      'gives the same clips for the same alarm, sounds, weights and seed',
      () {
        final weights = SoundWeights(const {
          'pop-1': 3,
          'rock-2': 0.2,
          'mom': 1.7,
        });

        for (final seed in _seeds) {
          for (final snoozedSoundId in const [null, 'mom']) {
            final ring = _ring(
              _library,
              seed: seed,
              genres: {'pop', 'rock'},
              weights: weights,
              snoozedSoundId: snoozedSoundId,
            );

            // Also whatever the order of the sounds.
            for (final pool in [
              _library,
              _library.reversed,
              [..._library.skip(4), ..._library.take(4)],
            ]) {
              expect(
                _ring(
                  pool,
                  seed: seed,
                  genres: {'rock', 'pop'},
                  weights: weights,
                  snoozedSoundId: snoozedSoundId,
                ),
                ring,
                reason:
                    'Pool ${_soundIds(pool)}, seed $seed, '
                    'snoozed $snoozedSoundId',
              );
            }
          }
        }
      },
    );

    test('shuffles: another seed gives another ring', () {
      final firstSounds = {
        for (final seed in _seeds)
          _ring(_library, seed: seed, gentleStart: false).first.sound.id,
      };

      expect(firstSounds, _soundIds(_library).toSet());
    });
  });

  test('no clip over 30 s, and no built-in clip over 29 s', () {
    final tooLong = <String>[];
    for (final seed in _seeds) {
      final ring = _ring(
        _randomPool(seed),
        seed: seed,
        cap: const Duration(hours: 1),
      );
      for (final clip in ring) {
        final limit = clip.sound.source == SoundSource.builtin
            ? const Duration(seconds: 29)
            : const Duration(seconds: 30);
        if (clip.window.length > limit) tooLong.add('Seed $seed: $clip');
      }
    }

    expect(tooLong, isEmpty);
  });

  test('no sound twice in a row, and every sound once per bag', () {
    for (var size = 2; size <= 12; size++) {
      // Clips of 5 s: 120 of them fill 10 minutes, 10 to 60 bags.
      final pool = [
        for (var i = 1; i <= size; i++)
          _sound(
            'sound-$i',
            intensity: i % 3 + 1,
            duration: const Duration(seconds: 5),
          ),
      ];
      for (final seed in _seeds) {
        final rings = {
          'Gentle start': _ring(pool, seed: seed),
          'No gentle start': _ring(pool, seed: seed, gentleStart: false),
          'After Snooze': _ring(pool, seed: seed, snoozedSoundId: 'sound-1'),
        };

        for (final MapEntry(key: kind, value: ring) in rings.entries) {
          expect(
            _bagRuleBreaks(_ids(ring), size),
            isEmpty,
            reason: '$kind, $size sounds, seed $seed',
          );
        }
      }
    }
  });

  group('The gentle start', () {
    test('climbs from intensity 1 to 3 at 40%, 70% and full volume', () {
      for (final seed in _seeds) {
        final ring = _ring(_library, seed: seed);

        expect(
          [
            for (final clip in ring.take(3))
              (clip.sound.intensity, clip.volume),
          ],
          [(1, 0.4), (2, 0.7), (3, 1.0)],
          reason: 'Seed $seed',
        );
        expect(_volumes(ring.skip(3)), everyElement(1.0), reason: 'Seed $seed');
      }
    });

    test('is off for an alarm without it: full volume from the start', () {
      final firstIntensities = <int>{};
      for (final seed in _seeds) {
        final ring = _ring(_library, seed: seed, gentleStart: false);
        firstIntensities.add(ring.first.sound.intensity);

        expect(_volumes(ring), everyElement(1.0), reason: 'Seed $seed');
      }

      // A plain shuffle: the first sound can be of any intensity.
      expect(firstIntensities, {1, 2, 3});
    });

    test('is off in a ring after Snooze: full volume from the start', () {
      final firstIntensities = <int>{};
      for (final seed in _seeds) {
        final ring = _ring(_library, seed: seed, snoozedSoundId: 'rock-3');
        firstIntensities.add(ring.first.sound.intensity);

        expect(_volumes(ring), everyElement(1.0), reason: 'Seed $seed');
      }

      expect(firstIntensities, {1, 2, 3});
    });
  });

  group('A ring after Snooze', () {
    test('never starts with the sound that was playing at Snooze', () {
      for (final snoozed in _library) {
        final firstSounds = {
          for (final seed in _seeds)
            _ring(
              _library,
              seed: seed,
              snoozedSoundId: snoozed.id,
            ).first.sound.id,
        };

        expect(
          firstSounds,
          _soundIds(_library).toSet()..remove(snoozed.id),
          reason: 'Snoozed ${snoozed.id}',
        );
      }
    });

    test('still rings with the only sound of a pool of one', () {
      final ring = _ring([_sound('only')], seed: 1, snoozedSoundId: 'only');

      expect(_ids(ring), everyElement('only'));
      expect(ring.last.endsAt, defaultRingCap);
    });
  });

  group('The sounds of a ring', () {
    test("are the built-in sounds of the alarm's genres, and no others", () {
      for (final seed in _seeds) {
        final ring = _ring(_library, seed: seed, genres: {'rock', 'jazz'});

        expect(_builtinIds(ring), {
          'rock-1',
          'rock-2',
          'rock-3',
          'jazz-1',
          'jazz-2',
          'jazz-3',
        }, reason: 'Seed $seed');
      }
    });

    test("always include the user's own songs and voice messages", () {
      const genreChoices = [
        <String>{},
        {'rock'},
        {'pop', 'jazz'},
        {'polka'},
      ];

      for (final genres in genreChoices) {
        for (final seed in _seeds) {
          expect(
            _ids(_ring(_library, seed: seed, genres: genres)),
            containsAll(['my-song', 'mom']),
            reason: 'Genres $genres, seed $seed',
          );
        }
      }
    });

    test('are every built-in sound when the alarm has no genres', () {
      for (final seed in _seeds) {
        expect(
          _builtinIds(_ring(_library, seed: seed)),
          _builtinLibraryIds,
          reason: 'Seed $seed',
        );
      }
    });

    test('are every built-in sound when none of its genres has one', () {
      for (final seed in _seeds) {
        expect(
          _builtinIds(_ring(_library, seed: seed, genres: {'polka'})),
          _builtinLibraryIds,
          reason: 'Seed $seed',
        );
      }
    });

    test("are the user's own sounds when there is no built-in sound", () {
      final own = [
        for (final sound in _library)
          if (sound.source != SoundSource.builtin) sound,
      ];

      for (final seed in _seeds) {
        expect(_ids(_ring(own, seed: seed, genres: {'rock'})).toSet(), {
          'my-song',
          'mom',
        }, reason: 'Seed $seed');
      }
    });
  });

  group('RingClip', () {
    test('equals a clip with the same sound, window, volume and start', () {
      final ring = _ring(_library, seed: 7);
      final again = _ring(_library, seed: 7);

      for (var i = 0; i < ring.length; i++) {
        expect(again[i], ring[i]);
        expect(again[i].hashCode, ring[i].hashCode);
      }
    });

    test('differs from a clip with another sound, window, volume or start', () {
      final only = [_sound('only')];
      final ring = _ring(only, seed: 1);
      final two = [_sound('a'), _sound('b')];

      // At 40% and at full volume.
      expect(ring.first, isNot(_ring(only, seed: 1, gentleStart: false).first));
      // 10 s and 20 s of the same clip.
      expect(
        _ring(only, seed: 1, cap: const Duration(seconds: 10)).first,
        isNot(_ring(only, seed: 1, cap: const Duration(seconds: 20)).first),
      );
      // The same clip at 1:20 and at 1:40.
      expect(ring[4], isNot(ring[5]));
      // Two sounds with the same clip window.
      expect(
        _ring(two, seed: 1, snoozedSoundId: 'a').first,
        isNot(_ring(two, seed: 1, snoozedSoundId: 'b').first),
      );
    });
  });

  group('buildRingSequence with a planned order', () {
    test(
      'plays the plan back clip for clip, whatever the seed and weights',
      () {
        final other = SoundWeights(const {'sound-1': 3, 'sound-2': 0.2});
        for (final seed in _seeds) {
          final pool = _randomPool(seed);
          final ring = _ring(pool, seed: seed);

          expect(
            buildRingSequence(
              _alarm(),
              pool,
              other,
              seed + 1,
              planned: _ids(ring),
            ),
            ring,
            reason: 'Seed $seed',
          );
        }
      },
    );

    test('with a plan of no use, plays what it would play without one', () {
      for (final planned in const [
        <String>[],
        ['gone', 'also-gone'],
      ]) {
        for (final seed in _seeds) {
          final pool = _randomPool(seed);
          expect(
            buildRingSequence(
              _alarm(),
              pool,
              const SoundWeights.start(),
              seed,
              planned: planned,
            ),
            _ring(pool, seed: seed),
            reason: 'Plan $planned, seed $seed',
          );
        }
      }
    });

    test('skips a sound that left the pool, and still fills the ring', () {
      final breaks = <String>[];
      for (final seed in _seeds) {
        final pool = _randomPool(seed);
        final planned = _ids(_ring(pool, seed: seed));
        final gone = pool[seed % pool.length];
        final left = [...pool]..remove(gone);
        final ring = buildRingSequence(
          _alarm(),
          left,
          const SoundWeights.start(),
          seed,
          planned: planned,
        );

        breaks.addAll(_ruleBreaks(ring, 'Seed $seed'));
        if (_ids(ring).contains(gone.id)) breaks.add('Seed $seed: $gone');
      }

      expect(breaks, isEmpty);
    });

    test('keeps the order of the other sounds when one leaves the pool', () {
      final pool = [for (var i = 1; i <= 5; i++) _sound('sound-$i')];
      final ring = _ring(pool, seed: 3, gentleStart: false);
      final firstBag = _ids(ring).take(5).toList();
      final gone = firstBag[2];

      final left = buildRingSequence(
        _alarm(gentleStart: false),
        [
          for (final sound in pool)
            if (sound.id != gone) sound,
        ],
        const SoundWeights.start(),
        3,
        planned: _ids(ring),
      );

      expect(_ids(left).take(4), [
        for (final id in firstBag)
          if (id != gone) id,
      ]);
    });

    test('still starts gently when the first planned sound left the pool', () {
      final pool = [
        _sound('gentle-a'),
        _sound('gentle-b'),
        _sound('medium', intensity: 2),
        _sound('strong', intensity: 3),
      ];
      final planned = ['gentle-a', 'medium', 'strong', 'gentle-b', 'medium'];

      final ring = buildRingSequence(
        _alarm(),
        pool.skip(1),
        const SoundWeights.start(),
        1,
        planned: planned,
      );

      expect(_ids(ring).take(3), ['gentle-b', 'medium', 'strong']);
      expect(_volumes(ring.take(3)), Escalation.volumes);
    });

    test('plays a sound the plan does not name after the planned ones', () {
      final pool = [_sound('a'), _sound('b'), _sound('new')];

      final ring = buildRingSequence(
        _alarm(gentleStart: false),
        pool,
        const SoundWeights.start(),
        1,
        planned: const ['b', 'a', 'b', 'a'],
      );

      expect(_ids(ring).take(3), ['b', 'a', 'new']);
    });

    test('plays only the sounds of the ring, whatever the plan names', () {
      final ring = buildRingSequence(
        _alarm(genres: const {'rock'}),
        _library,
        const SoundWeights.start(),
        1,
        planned: const ['pop-1', 'pop-2', 'rock-1', 'jazz-3'],
      );

      expect(_builtinIds(ring), {'rock-1', 'rock-2', 'rock-3'});
    });
  });

  group('buildRingSequence with sounds to skip', () {
    test('leaves them out of the whole ring, by every other rule', () {
      final breaks = <String>[];
      for (final seed in _seeds) {
        final pool = _randomPool(seed);
        final skipped = {pool[seed % pool.length].id, pool.last.id};
        final ring = buildRingSequence(
          _alarm(),
          pool,
          const SoundWeights.start(),
          seed,
          skipped: skipped,
        );

        breaks.addAll(_ruleBreaks(ring, 'Seed $seed'));
        for (final clip in ring) {
          if (skipped.contains(clip.sound.id)) {
            breaks.add('Seed $seed: ${clip.sound.id} plays');
          }
        }
      }

      expect(breaks, isEmpty);
    });

    test('plays them after all if nothing else is left: it must ring', () {
      final pool = [_sound('a'), _sound('b')];

      final ring = buildRingSequence(
        _alarm(),
        pool,
        const SoundWeights.start(),
        1,
        skipped: const {'a', 'b'},
      );

      expect(_ids(ring).toSet(), {'a', 'b'});
      expect(ring.last.endsAt, defaultRingCap);
    });

    test('holds for a ring after Snooze too', () {
      final pool = [_sound('a'), _sound('b'), _sound('c')];
      for (final seed in _seeds) {
        final ring = buildRingSequence(
          _alarm(),
          pool,
          const SoundWeights.start(),
          seed,
          snoozedSoundId: 'b',
          skipped: const {'a'},
        );

        expect(_ids(ring).first, 'c', reason: 'Seed $seed');
        expect(_ids(ring), isNot(contains('a')), reason: 'Seed $seed');
      }
    });

    test('a sound it does not know changes nothing', () {
      final pool = _randomPool(1);

      expect(
        buildRingSequence(
          _alarm(),
          pool,
          const SoundWeights.start(),
          1,
          skipped: const {'gone'},
        ),
        _ring(pool, seed: 1),
      );
    });
  });

  group('soundsOfRing', () {
    test('has the built-in sounds of the genres and the own sounds', () {
      expect(
        _soundIds(soundsOfRing(_alarm(genres: const {'rock'}), _library)),
        {'rock-1', 'rock-2', 'rock-3', 'my-song', 'mom'},
      );
    });

    test('has every built-in sound if the genres have none', () {
      expect(
        _soundIds(soundsOfRing(_alarm(genres: const {'folk'}), _library)),
        unorderedEquals(_soundIds(_library)),
      );
    });

    test('leaves out the sounds to skip, unless that leaves none', () {
      final alarm = _alarm(genres: const {'rock'});
      final pool = [
        for (final sound in _library)
          if (sound.genre == 'rock') sound,
      ];

      expect(_soundIds(soundsOfRing(alarm, pool, skipped: const {'rock-1'})), [
        'rock-2',
        'rock-3',
      ]);
      expect(
        _soundIds(
          soundsOfRing(
            alarm,
            pool,
            skipped: const {'rock-1', 'rock-2', 'rock-3'},
          ),
        ),
        ['rock-1', 'rock-2', 'rock-3'],
      );
    });
  });
}

/// Seeds for the random number generator, so each check runs many times.
final _seeds = <int>[for (var seed = 0; seed < 200; seed++) seed];

/// Time caps from 1 s to 25 min, the default among them.
const _caps = <Duration>[
  Duration(seconds: 1),
  Duration(seconds: 29),
  Duration(minutes: 1),
  Duration(minutes: 7, seconds: 13, milliseconds: 500),
  defaultRingCap,
  Duration(minutes: 25),
];

/// Built-in sounds of three genres, one of each intensity, and the user's
/// own sounds: a pop song and a voice message.
final _library = <Sound>[
  for (final genre in ['pop', 'rock', 'jazz'])
    for (var intensity = 1; intensity <= 3; intensity++)
      _sound('$genre-$intensity', genre: genre, intensity: intensity),
  _sound(
    'my-song',
    source: SoundSource.user,
    intensity: 2,
    duration: const Duration(minutes: 3),
    clipStart: const Duration(minutes: 1),
  ),
  _sound(
    'mom',
    source: SoundSource.voice,
    genre: 'voice',
    duration: const Duration(seconds: 12),
  ),
];

/// The ids of the built-in sounds in [_library].
final _builtinLibraryIds = <String>{
  for (final sound in _library)
    if (sound.source == SoundSource.builtin) sound.id,
};

/// 12 sounds of every source and intensity, with files from 1 s to 1 min long
/// and clips that start anywhere in them: the same ones for the same seed.
List<Sound> _randomPool(int seed) {
  // A generator of its own, so the ring's generator does not repeat it.
  final random = Random(seed + 1000);
  return [for (var i = 1; i <= 12; i++) _randomSound('sound-$i', random)];
}

Sound _randomSound(String id, Random random) {
  final source = SoundSource.values[random.nextInt(SoundSource.values.length)];
  final fileLength = Duration(milliseconds: 1000 + random.nextInt(59001));
  return _sound(
    id,
    source: source,
    intensity: Sound.minIntensity + random.nextInt(Sound.maxIntensity),
    duration: fileLength,
    // Built-in clips are cut already, so theirs start at zero.
    clipStart: source == SoundSource.builtin
        ? Duration.zero
        : Duration(milliseconds: random.nextInt(fileLength.inMilliseconds)),
  );
}

/// A sound: a built-in pop clip of 20 s and intensity 1, unless told
/// otherwise.
Sound _sound(
  String id, {
  SoundSource source = SoundSource.builtin,
  String genre = 'pop',
  int intensity = 1,
  Duration duration = const Duration(seconds: 20),
  Duration clipStart = Duration.zero,
}) => Sound(
  id: id,
  title: 'Clip',
  source: source,
  genre: genre,
  intensity: intensity,
  duration: duration,
  clipStart: clipStart,
);

/// An alarm at 07:00 with [genres], with a gentle start unless told
/// otherwise.
Alarm _alarm({Set<String> genres = const {}, bool gentleStart = true}) => Alarm(
  id: 'alarm-1',
  time: ClockTime(hour: 7, minute: 0),
  genres: genres,
  gentleStart: gentleStart,
);

/// The ring sequence of an alarm with [genres] and [gentleStart], out of
/// [pool].
List<RingClip> _ring(
  Iterable<Sound> pool, {
  required int seed,
  Set<String> genres = const {},
  bool gentleStart = true,
  SoundWeights weights = const SoundWeights.start(),
  String? snoozedSoundId,
  Duration cap = defaultRingCap,
}) => buildRingSequence(
  _alarm(genres: genres, gentleStart: gentleStart),
  pool,
  weights,
  seed,
  snoozedSoundId: snoozedSoundId,
  cap: cap,
);

/// The ids of the sounds of [ring], in their order.
List<String> _ids(Iterable<RingClip> ring) => [
  for (final clip in ring) clip.sound.id,
];

/// The ids of [sounds], in their order.
List<String> _soundIds(Iterable<Sound> sounds) => [
  for (final sound in sounds) sound.id,
];

/// The ids of the built-in sounds that [ring] plays.
Set<String> _builtinIds(Iterable<RingClip> ring) => {
  for (final clip in ring)
    if (clip.sound.source == SoundSource.builtin) clip.sound.id,
};

/// The volumes of [clips], in their order.
List<double> _volumes(Iterable<RingClip> clips) => [
  for (final clip in clips) clip.volume,
];

/// How often [id] is among [ids], from 0 (never) to 1 (every time).
double _share(String id, List<String> ids) =>
    ids.where((each) => each == id).length / ids.length;

/// Where [ids], the sounds of a ring of [poolSize] sounds, break the bag
/// rules: a bag without every sound once, or a sound twice in a row.
List<String> _bagRuleBreaks(List<String> ids, int poolSize) => [
  for (var start = 0; start + poolSize <= ids.length; start += poolSize)
    if (ids.sublist(start, start + poolSize).toSet().length < poolSize)
      'bag ${start ~/ poolSize + 1}: ${ids.sublist(start, start + poolSize)}',
  for (var i = 1; i < ids.length; i++)
    if (ids[i] == ids[i - 1]) 'clips $i and ${i + 1}: ${ids[i]}',
];

/// Where the clips of [ring] break a rule of a ring: a gap, a clip longer than
/// the clip rule allows, an end that is not the cap, or a sound twice in a
/// row in a ring of more than one sound.
List<String> _ruleBreaks(List<RingClip> ring, String where) {
  final ids = _ids(ring);
  return [
    if (ring.last.endsAt != defaultRingCap)
      '$where: the ring ends at ${ring.last.endsAt}',
    for (final clip in ring)
      if (clip.window.length > ClipWindow.maxLengthFor(clip.sound.source))
        '$where: $clip is too long',
    for (var i = 1; i < ring.length; i++) ...[
      if (ring[i].startsAt != ring[i - 1].endsAt)
        '$where: a gap before clip ${i + 1}',
      if (ids[i] == ids[i - 1] && ids.toSet().length > 1)
        '$where: ${ids[i]} twice in a row, at clip ${i + 1}',
    ],
  ];
}
