import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/adaptive_weights.dart';
import 'package:shuffle_alarm/core/clip_rule.dart';
import 'package:shuffle_alarm/core/escalation.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/core/ring_plan.dart';
import 'package:shuffle_alarm/core/ring_sequence.dart';

void main() {
  group('RingPlan', () {
    test('is equal by its values', () {
      expect(_plan(), _plan());
      expect(_plan().hashCode, _plan().hashCode);
      for (final other in [
        RingPlan(
          alarmId: 'other',
          ringAt: _ringAt,
          seed: 1,
          soundIds: const ['a', 'b'],
          notTonight: const {'c'},
        ),
        RingPlan(
          alarmId: 'alarm-1',
          ringAt: _ringAt.add(const Duration(minutes: 1)),
          seed: 1,
          soundIds: const ['a', 'b'],
          notTonight: const {'c'},
        ),
        RingPlan(
          alarmId: 'alarm-1',
          ringAt: _ringAt,
          seed: 2,
          soundIds: const ['a', 'b'],
          notTonight: const {'c'},
        ),
        RingPlan(
          alarmId: 'alarm-1',
          ringAt: _ringAt,
          seed: 1,
          soundIds: const ['b', 'a'],
          notTonight: const {'c'},
        ),
        RingPlan(
          alarmId: 'alarm-1',
          ringAt: _ringAt,
          seed: 1,
          soundIds: const ['a', 'b'],
        ),
        RingPlan(
          alarmId: 'alarm-1',
          ringAt: _ringAt,
          seed: 1,
          soundIds: const ['a', 'b'],
          notTonight: const {'d'},
        ),
      ]) {
        expect(other, isNot(_plan()), reason: '$other');
      }
    });

    test('cannot be changed through the lists it was given', () {
      final ids = ['a'];
      final skipped = {'b'};
      final plan = RingPlan(
        alarmId: 'alarm-1',
        ringAt: _ringAt,
        seed: 1,
        soundIds: ids,
        notTonight: skipped,
      );

      ids.add('c');
      skipped.add('c');

      expect(plan.soundIds, ['a']);
      expect(plan.notTonight, {'b'});
      expect(() => plan.soundIds.add('d'), throwsUnsupportedError);
      expect(() => plan.notTonight.add('d'), throwsUnsupportedError);
    });

    test('moves to another ring with everything else as it was', () {
      final later = _ringAt.add(const Duration(minutes: 30));

      final moved = _plan().movedTo(later);

      expect(moved.ringAt, later);
      expect(moved.alarmId, 'alarm-1');
      expect(moved.seed, 1);
      expect(moved.soundIds, ['a', 'b']);
      expect(moved.notTonight, {'c'});
    });

    test('skips a sound, and brings it back', () {
      final skipped = _plan().skipping('a');

      expect(skipped.notTonight, {'a', 'c'});
      expect(skipped.soundIds, ['a', 'b']);
      expect(skipped.bringingBack('a'), _plan());
      expect(_plan().bringingBack('not-skipped'), _plan());
    });
  });

  group('buildRingPlan', () {
    test('holds the order of the ring sequence of its seed', () {
      for (final seed in _seeds) {
        final pool = _randomPool(seed);
        final plan = buildRingPlan(_alarm(), _ringAt, pool, _weights, seed);

        expect(plan.alarmId, 'alarm-1');
        expect(plan.ringAt, _ringAt);
        expect(plan.seed, seed);
        expect(plan.notTonight, isEmpty);
        expect(
          plan.soundIds,
          _ids(buildRingSequence(_alarm(), pool, _weights, seed)),
          reason: 'Seed $seed',
        );
      }
    });

    test('keeps a skipped sound in its order, so it can come back', () {
      final pool = [for (var i = 1; i <= 5; i++) _sound('sound-$i')];

      final plain = buildRingPlan(_alarm(), _ringAt, pool, _weights, 1);
      final skipped = buildRingPlan(
        _alarm(),
        _ringAt,
        pool,
        _weights,
        1,
        notTonight: const {'sound-2'},
      );

      expect(skipped.soundIds, plain.soundIds);
      expect(skipped.notTonight, {'sound-2'});
    });
  });

  group('clipsOfPlan', () {
    test('are the clips the plan was built from, exactly', () {
      for (final seed in _seeds) {
        final pool = _randomPool(seed);
        final plan = buildRingPlan(_alarm(), _ringAt, pool, _weights, seed);

        expect(
          clipsOfPlan(plan, _alarm(), pool, _weights),
          buildRingSequence(_alarm(), pool, _weights, seed),
          reason: 'Seed $seed',
        );
      }
    });

    test('stay the same when the weights change after the plan', () {
      final learned = SoundWeights(const {'sound-1': 3, 'sound-2': 0.2});
      for (final seed in _seeds) {
        final pool = _randomPool(seed);
        final plan = buildRingPlan(_alarm(), _ringAt, pool, _weights, seed);

        expect(
          clipsOfPlan(plan, _alarm(), pool, learned),
          clipsOfPlan(plan, _alarm(), pool, _weights),
          reason: 'Seed $seed',
        );
      }
    });

    test('skip a sound deleted since, by every rule of a ring', () {
      final breaks = <String>[];
      for (final seed in _seeds) {
        final pool = _randomPool(seed);
        final plan = buildRingPlan(_alarm(), _ringAt, pool, _weights, seed);
        final gone = pool[seed % pool.length];

        final clips = clipsOfPlan(
          plan,
          _alarm(),
          [...pool]..remove(gone),
          _weights,
        );

        breaks.addAll(_ruleBreaks(clips, 'Seed $seed'));
        if (_ids(clips).contains(gone.id)) breaks.add('Seed $seed: $gone');
      }

      expect(breaks, isEmpty);
    });

    test('leave out a sound for tonight, by every rule of a ring', () {
      final breaks = <String>[];
      for (final seed in _seeds) {
        final pool = _randomPool(seed);
        final plan = buildRingPlan(_alarm(), _ringAt, pool, _weights, seed);
        final skipped = _ids(
          firstRound(clipsOfPlan(plan, _alarm(), pool, _weights)),
        )[seed % 3];

        final clips = clipsOfPlan(
          plan.skipping(skipped),
          _alarm(),
          pool,
          _weights,
        );

        breaks.addAll(_ruleBreaks(clips, 'Seed $seed'));
        if (_ids(clips).contains(skipped)) breaks.add('Seed $seed: $skipped');
      }

      expect(breaks, isEmpty);
    });

    test('keep the order of the other sounds after Not tonight', () {
      final pool = [for (var i = 1; i <= 6; i++) _sound('sound-$i')];
      final alarm = _alarm(gentleStart: false);
      final plan = buildRingPlan(alarm, _ringAt, pool, _weights, 2);
      final round = _ids(firstRound(clipsOfPlan(plan, alarm, pool, _weights)));

      final after = clipsOfPlan(plan.skipping(round[1]), alarm, pool, _weights);

      expect(_ids(after).take(5), [
        for (final id in round)
          if (id != round[1]) id,
      ]);
    });

    test('keep the gentle start after Not tonight on its first sound', () {
      final pool = [
        _sound('gentle-a'),
        _sound('gentle-b'),
        _sound('medium', intensity: 2),
        _sound('strong', intensity: 3),
      ];
      for (final seed in _seeds) {
        final plan = buildRingPlan(_alarm(), _ringAt, pool, _weights, seed);
        final first = plan.soundIds.first;

        final clips = clipsOfPlan(
          plan.skipping(first),
          _alarm(),
          pool,
          _weights,
        );

        expect(
          [for (final clip in clips.take(3)) clip.sound.intensity],
          [1, 2, 3],
          reason: 'Seed $seed',
        );
        expect(_volumes(clips.take(3)), Escalation.volumes);
      }
    });

    test('are the same again after a sound comes back', () {
      for (final seed in _seeds) {
        final pool = _randomPool(seed);
        final plan = buildRingPlan(_alarm(), _ringAt, pool, _weights, seed);

        final back = plan.skipping('sound-3').bringingBack('sound-3');

        expect(
          clipsOfPlan(back, _alarm(), pool, _weights),
          clipsOfPlan(plan, _alarm(), pool, _weights),
          reason: 'Seed $seed',
        );
      }
    });

    test('play the sounds after all if every one is skipped: it must ring', () {
      final pool = [_sound('a'), _sound('b')];
      final plan = buildRingPlan(
        _alarm(),
        _ringAt,
        pool,
        _weights,
        1,
      ).skipping('a').skipping('b');

      final clips = clipsOfPlan(plan, _alarm(), pool, _weights);

      expect(_ids(clips).toSet(), {'a', 'b'});
      expect(clips.last.endsAt, defaultRingCap);
    });

    test('of a plan of sounds that are all gone still fill the ring', () {
      final pool = _randomPool(1);
      final plan = RingPlan(
        alarmId: 'alarm-1',
        ringAt: _ringAt,
        seed: 1,
        soundIds: const ['gone', 'also-gone', 'gone'],
      );

      final clips = clipsOfPlan(plan, _alarm(), pool, _weights);

      expect(_ruleBreaks(clips, 'All gone'), isEmpty);
      expect(clips, buildRingSequence(_alarm(), pool, _weights, 1));
    });

    test('of an empty plan still fill the ring', () {
      final pool = _randomPool(2);
      final plan = RingPlan(
        alarmId: 'alarm-1',
        ringAt: _ringAt,
        seed: 2,
        soundIds: const [],
      );

      final clips = clipsOfPlan(plan, _alarm(), pool, _weights);

      expect(_ruleBreaks(clips, 'Empty'), isEmpty);
      expect(clips, buildRingSequence(_alarm(), pool, _weights, 2));
    });

    test('follow a sound that changed its clip', () {
      final song = _sound(
        'song',
        source: SoundSource.user,
        duration: const Duration(minutes: 3),
      );
      final plan = buildRingPlan(
        _alarm(),
        _ringAt,
        [song, _sound('clip')],
        _weights,
        1,
      );
      final moved = _sound(
        'song',
        source: SoundSource.user,
        duration: const Duration(minutes: 3),
        clipStart: const Duration(minutes: 1),
      );

      final clips = clipsOfPlan(plan, _alarm(), [
        moved,
        _sound('clip'),
      ], _weights);

      final clip = clips.firstWhere((clip) => clip.sound.id == 'song');
      expect(clip.window, ClipWindow.of(moved));
      expect(clip.window.length, ClipWindow.maxLength);
      expect(clips.last.endsAt, defaultRingCap);
    });
  });

  group('reshuffled', () {
    test('makes a new order with a new seed', () {
      final pool = [for (var i = 1; i <= 9; i++) _sound('sound-$i')];
      final plan = buildRingPlan(_alarm(), _ringAt, pool, _weights, 1);

      final next = reshuffled(plan, _alarm(), pool, _weights, Random(5));

      expect(next.seed, isNot(plan.seed));
      expect(next.alarmId, plan.alarmId);
      expect(next.ringAt, plan.ringAt);
      expect(_round(next, pool), isNot(_round(plan, pool)));
      expect(
        next.soundIds,
        _ids(buildRingSequence(_alarm(), pool, _weights, next.seed)),
      );
    });

    test('always shows another first round when one can be made', () {
      // Two sounds that can change places, the lighter one rarely first.
      final pool = [_sound('a'), _sound('b')];
      final weights = SoundWeights(const {'a': 3, 'b': 0.2});
      for (final seed in _seeds) {
        final plan = buildRingPlan(_alarm(), _ringAt, pool, weights, seed);

        final next = reshuffled(plan, _alarm(), pool, weights, Random(seed));

        expect(
          _round(next, pool, weights: weights),
          isNot(_round(plan, pool, weights: weights)),
          reason: 'Seed $seed',
        );
      }
    });

    test('keeps the sounds of Not tonight out', () {
      final pool = [for (var i = 1; i <= 5; i++) _sound('sound-$i')];
      final plan = buildRingPlan(
        _alarm(),
        _ringAt,
        pool,
        _weights,
        1,
      ).skipping('sound-2');

      final next = reshuffled(plan, _alarm(), pool, _weights, Random(5));

      expect(next.notTonight, {'sound-2'});
      expect(_round(next, pool), isNot(contains('sound-2')));
    });

    test('compares what plays: not a sound of Not tonight moving', () {
      // With "a" left out, only "b" and "c" can change places.
      final pool = [_sound('a'), _sound('b'), _sound('c')];
      final plan = buildRingPlan(
        _alarm(),
        _ringAt,
        pool,
        _weights,
        1,
      ).skipping('a');

      final next = reshuffled(plan, _alarm(), pool, _weights, Random(1));

      expect(_round(next, pool), isNot(_round(plan, pool)));
    });

    test('gives the same plan back when the rules allow one order only', () {
      final gentleToStrong = [
        _sound('gentle'),
        _sound('medium', intensity: 2),
        _sound('strong', intensity: 3),
      ];
      final one = [_sound('only')];
      for (final pool in [gentleToStrong, one]) {
        final plan = buildRingPlan(_alarm(), _ringAt, pool, _weights, 1);

        expect(
          reshuffled(plan, _alarm(), pool, _weights, Random(1)),
          plan,
          reason: '${_soundIds(pool)}',
        );
      }
    });
  });

  group('planFits', () {
    final pool = [_sound('a'), _sound('b'), _sound('c')];

    RingPlan planOf(List<Sound> sounds) =>
        buildRingPlan(_alarm(), _ringAt, sounds, _weights, 1);

    test('holds for the sounds it was made of', () {
      expect(planFits(planOf(pool), _alarm(), pool), isTrue);
    });

    test('holds when a sound was deleted: the ring skips it', () {
      expect(planFits(planOf(pool), _alarm(), pool.skip(1)), isTrue);
    });

    test('holds for a sound of Not tonight', () {
      expect(planFits(planOf(pool).skipping('a'), _alarm(), pool), isTrue);
    });

    test('does not hold when a new sound joined the ring', () {
      expect(
        planFits(planOf(pool), _alarm(), [...pool, _sound('new')]),
        isFalse,
      );
    });

    test('does not hold for a new genre of the alarm', () {
      final library = [_sound('pop'), _sound('rock', genre: 'rock')];
      final plan = buildRingPlan(
        _alarm(genres: const {'pop'}),
        _ringAt,
        library,
        _weights,
        1,
      );

      expect(planFits(plan, _alarm(genres: const {'pop'}), library), isTrue);
      expect(
        planFits(plan, _alarm(genres: const {'pop', 'rock'}), library),
        isFalse,
      );
    });

    test('holds when the time cap came before the second round', () {
      // It cannot tell a new sound from one that did not fit: the ring takes
      // it after the planned ones.
      final long = [
        for (var i = 0; i < 40; i++)
          _sound(
            'song-$i',
            source: SoundSource.user,
            duration: const Duration(seconds: 30),
          ),
      ];

      expect(planFits(planOf(long), _alarm(), long), isTrue);
    });

    test('does not hold when it has no sound of the ring', () {
      final empty = RingPlan(
        alarmId: 'alarm-1',
        ringAt: _ringAt,
        seed: 1,
        soundIds: const [],
      );
      final gone = RingPlan(
        alarmId: 'alarm-1',
        ringAt: _ringAt,
        seed: 1,
        soundIds: const ['gone-1', 'gone-2'],
      );

      expect(planFits(empty, _alarm(), pool), isFalse);
      expect(planFits(gone, _alarm(), pool), isFalse);
    });
  });

  group('planForRing', () {
    final pool = [_sound('a'), _sound('b'), _sound('c')];
    final evening = _ringAt.subtract(const Duration(hours: 8));

    RingPlan choose({
      List<RingPlan> stored = const [],
      DateTime? ringAt,
      List<Sound>? sounds,
    }) => planForRing(
      _alarm(),
      ringAt ?? _ringAt,
      stored: stored,
      now: evening,
      pool: sounds ?? pool,
      weights: _weights,
      random: Random(7),
    );

    RingPlan planAt(DateTime ringAt, {List<Sound>? sounds}) =>
        buildRingPlan(_alarm(), ringAt, sounds ?? pool, _weights, 42);

    test('makes a new plan when none is stored', () {
      final plan = choose();

      expect(plan.alarmId, 'alarm-1');
      expect(plan.ringAt, _ringAt);
      expect(plan.notTonight, isEmpty);
      expect(
        plan.soundIds,
        _ids(buildRingSequence(_alarm(), pool, _weights, plan.seed)),
      );
    });

    test('keeps the plan of its ring as it is', () {
      final stored = planAt(_ringAt).skipping('a');

      expect(choose(stored: [stored]), stored);
    });

    test('moves a plan for a ring still to come, as the alarm moved', () {
      final moved = _ringAt.add(const Duration(minutes: 30));
      final stored = planAt(_ringAt).skipping('a');

      expect(choose(stored: [stored], ringAt: moved), stored.movedTo(moved));
    });

    test('leaves the plan of a ring that has come', () {
      // Its Not tonight was for that morning.
      final passed = planAt(evening.subtract(const Duration(minutes: 1)))
          .skipping('a');

      final plan = choose(stored: [passed]);

      expect(plan.ringAt, _ringAt);
      expect(plan.notTonight, isEmpty);
    });

    test('takes the plan of its ring before one for another ring', () {
      final own = planAt(_ringAt).skipping('a');
      final other = planAt(_ringAt.add(const Duration(days: 1))).skipping('b');

      expect(choose(stored: [other, own]), own);
    });

    test('keeps the plan when a sound was deleted: the ring skips it', () {
      final stored = planAt(_ringAt);

      expect(choose(stored: [stored], sounds: pool.sublist(1)), stored);
    });

    test('makes the order again when a sound joined the ring', () {
      final stored = planAt(_ringAt).skipping('a');
      final more = [...pool, _sound('new')];

      final plan = choose(stored: [stored], sounds: more);

      expect(plan.seed, stored.seed);
      expect(plan.notTonight, {'a'});
      expect(
        plan.soundIds,
        _ids(buildRingSequence(_alarm(), more, _weights, stored.seed)),
      );
    });

    test('makes the order again when the plan names no sound of the ring', () {
      final empty = RingPlan(
        alarmId: 'alarm-1',
        ringAt: _ringAt,
        seed: 42,
        soundIds: const [],
      );

      expect(choose(stored: [empty]).soundIds, isNotEmpty);
    });
  });

  group('firstRound', () {
    test('has every sound once, in play order', () {
      final pool = [for (var i = 1; i <= 5; i++) _sound('sound-$i')];
      final clips = buildRingSequence(_alarm(), pool, _weights, 1);

      final round = firstRound(clips);

      expect(round, clips.take(5));
      expect(_ids(round).toSet(), hasLength(5));
    });

    test('of one sound is one clip', () {
      final clips = buildRingSequence(_alarm(), [_sound('only')], _weights, 1);

      expect(_ids(firstRound(clips)), ['only']);
    });

    test('has all the clips when the time cap comes first', () {
      final clips = buildRingSequence(
        _alarm(),
        [
          for (var i = 0; i < 40; i++)
            _sound(
              'song-$i',
              source: SoundSource.user,
              duration: const Duration(seconds: 30),
            ),
        ],
        _weights,
        1,
      );

      expect(firstRound(clips), clips);
      expect(clips, hasLength(20));
    });

    test('of nothing is nothing', () {
      expect(firstRound(const []), isEmpty);
    });
  });

  group('newRingSeed', () {
    test('is a whole number that every platform can store', () {
      final random = Random(1);
      for (var i = 0; i < 1000; i++) {
        final seed = newRingSeed(random);

        expect(seed, greaterThanOrEqualTo(0));
        expect(seed, lessThan(1 << 30));
      }
    });
  });
}

/// Seeds for the random number generator, so each check runs many times.
final _seeds = <int>[for (var seed = 0; seed < 200; seed++) seed];

/// The ring a plan is for: 07:00 on a Thursday.
final _ringAt = DateTime(2026, 11, 12, 7);

const _weights = SoundWeights.start();

/// A plan with a skipped sound, the same each time.
RingPlan _plan() => RingPlan(
  alarmId: 'alarm-1',
  ringAt: _ringAt,
  seed: 1,
  soundIds: const ['a', 'b'],
  notTonight: const {'c'},
);

/// An alarm at 07:00 with [genres], with a gentle start unless told
/// otherwise.
Alarm _alarm({Set<String> genres = const {}, bool gentleStart = true}) => Alarm(
  id: 'alarm-1',
  time: ClockTime(hour: 7, minute: 0),
  genres: genres,
  gentleStart: gentleStart,
);

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

/// 12 sounds of every source and intensity, with files from 1 s to 1 min long
/// and clips that start anywhere in them: the same ones for the same seed.
List<Sound> _randomPool(int seed) {
  final random = Random(seed + 1000);
  return [
    for (var i = 1; i <= 12; i++)
      () {
        final source =
            SoundSource.values[random.nextInt(SoundSource.values.length)];
        final length = Duration(milliseconds: 1000 + random.nextInt(59001));
        return _sound(
          'sound-$i',
          source: source,
          intensity: Sound.minIntensity + random.nextInt(Sound.maxIntensity),
          duration: length,
          clipStart: source == SoundSource.builtin
              ? Duration.zero
              : Duration(milliseconds: random.nextInt(length.inMilliseconds)),
        );
      }(),
  ];
}

/// The ids of the sounds of [clips], in their order.
List<String> _ids(Iterable<RingClip> clips) => [
  for (final clip in clips) clip.sound.id,
];

/// The ids of [sounds], in their order.
List<String> _soundIds(Iterable<Sound> sounds) => [
  for (final sound in sounds) sound.id,
];

/// The volumes of [clips], in their order.
List<double> _volumes(Iterable<RingClip> clips) => [
  for (final clip in clips) clip.volume,
];

/// The ids of the first round that [plan] plays out of [pool].
List<String> _round(
  RingPlan plan,
  List<Sound> pool, {
  SoundWeights weights = _weights,
}) => _ids(firstRound(clipsOfPlan(plan, _alarm(), pool, weights)));

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
