import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/adaptive_weights.dart';
import 'package:shuffle_alarm/core/due_rings.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/core/ring_plan.dart';
import 'package:shuffle_alarm/core/ring_sequence.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/data/ring_plan_repository.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/data/weight_repository.dart';
import 'package:shuffle_alarm/design/components/mix_bars.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/alarms/tonight_mix.dart';
import 'package:shuffle_alarm/features/ringing/ringing_controller.dart';
import 'package:shuffle_alarm/platform/providers.dart';

import '../../data/memory_database.dart';
import '../../platform/fake_platform.dart';

void main() {
  late _Mix app;

  setUp(() async => app = await _Mix.open());
  tearDown(() => app.close());

  group('nextRingProvider', () {
    test('is the alarm that rings first, and when', () async {
      await app.saveAlarm(_alarm('late', hour: 9));
      await app.saveAlarm(_alarm('early'));

      final next = app.container.read(nextRingProvider);

      expect(next?.alarm.id, 'early');
      expect(next?.ring, _sevenTomorrow);
    });

    test('is null without an alarm that is on', () async {
      await app.saveAlarm(_alarm('off', enabled: false));

      expect(app.container.read(nextRingProvider), isNull);
    });
  });

  group("Tonight's mix", () {
    test('is null without an alarm that is on', () async {
      await app.saveAlarm(_alarm('off', enabled: false));

      expect(await app.mix, isNull);
      expect(await app.storedPlans, isEmpty);
    });

    test('is null without a sound, and stores nothing', () async {
      final empty = await _Mix.open(
        withSounds: false,
        overrides: (_) => [
          libraryClipsProvider.overrideWithValue(
            () async => throw StateError('No network'),
          ),
        ],
      );
      addTearDown(empty.close);
      await empty.saveAlarm(_alarm('a'));

      expect(await empty.mix, isNull);
      expect(await empty.storedPlans, isEmpty);
    });

    test('is the plan of the next ring, and it is stored', () async {
      await app.saveAlarm(_alarm('a'));

      final mix = (await app.mix)!;

      expect(mix.alarm.id, 'a');
      expect(mix.ringAt, _sevenTomorrow);
      expect(mix.plan, await app.plans.forRing('a', _sevenTomorrow));
      expect(_ids(mix.clips), mix.plan.soundIds);
      expect(mix.clips.last.endsAt, defaultRingCap);
    });

    test('knows where the audio of its sounds is', () async {
      await app.saveAlarm(_alarm('a'));

      final mix = (await app.mix)!;

      expect(mix.audioPathOf('sound-1'), 'assets/sound-1.wav');
    });

    test('has every sound once in its round, in play order', () async {
      await app.saveAlarm(_alarm('a'));

      final mix = (await app.mix)!;

      expect(mix.round, mix.clips.take(4));
      expect(_ids(mix.round).toSet(), hasLength(4));
    });

    test('stays the same when asked again', () async {
      await app.saveAlarm(_alarm('a'));

      final first = (await app.mix)!;
      app.container.invalidate(tonightMixProvider);
      final second = (await app.mix)!;

      expect(second.plan, first.plan);
      expect(await app.storedPlans, hasLength(1));
    });

    test('moves to the next ring when the clock passes this one', () async {
      await app.saveAlarm(_alarm('a'));
      final tonight = (await app.mix)!;

      app.clock.moveTo(_sevenTomorrow);
      await app.settle();
      final next = (await app.mix)!;

      expect(next.ringAt, _sevenTomorrow.add(const Duration(days: 1)));
      expect(await app.plans.forRing('a', _sevenTomorrow), tonight.plan);
    });

    test('keeps its plan when the alarm moves', () async {
      final alarm = await app.saveAlarm(_alarm('a'));
      final before = (await app.mix)!;
      await app.mixController.skip(_ids(before.round).first);
      final shaped = (await app.mix)!;

      await app.saveAlarm(alarm.copyWith(time: ClockTime(hour: 7, minute: 30)));
      await app.settle();

      final moved = (await app.mix)!;
      final later = _sevenTomorrow.add(const Duration(minutes: 30));
      expect(moved.ringAt, later);
      expect(moved.plan.soundIds, shaped.plan.soundIds);
      expect(moved.plan.notTonight, shaped.plan.notTonight);
      expect(await app.plans.forRing('a', _sevenTomorrow), isNull);
      expect(await app.plans.forRing('a', later), moved.plan);
    });

    test('keeps its plan while the alarm is off and on again', () async {
      final alarm = await app.saveAlarm(_alarm('a'));
      final before = (await app.mix)!;

      await app.saveAlarm(alarm.copyWith(enabled: false));
      await app.settle();
      expect(await app.mix, isNull);
      await app.saveAlarm(alarm.copyWith(enabled: true));
      await app.settle();

      expect((await app.mix)!.plan, before.plan);
    });

    test('shows another alarm when that one comes first', () async {
      await app.saveAlarm(_alarm('late', hour: 9));
      expect((await app.mix)!.alarm.id, 'late');

      await app.saveAlarm(_alarm('early'));
      await app.settle();

      expect((await app.mix)!.alarm.id, 'early');
      expect(await app.storedPlans, hasLength(2));
    });

    test('skips a sound deleted since, and keeps its order', () async {
      await app.saveAlarm(_alarm('a'));
      final before = (await app.mix)!;
      final gone = _ids(before.round)[1];

      await SoundRepository(app.db).delete(gone);
      await app.settle();

      final after = (await app.mix)!;
      expect(after.plan, before.plan);
      expect(_ids(after.round), [
        for (final id in _ids(before.round))
          if (id != gone) id,
      ]);
    });

    test(
      'makes its order again when a sound joins, and keeps the seed',
      () async {
        await app.saveAlarm(_alarm('a'));
        final before = (await app.mix)!;

        await SoundRepository(app.db).save(_stored('sound-5'));
        await app.settle();

        final after = (await app.mix)!;
        expect(_ids(after.round), contains('sound-5'));
        expect(after.plan.seed, before.plan.seed);
        expect(await app.plans.forRing('a', _sevenTomorrow), after.plan);
      },
    );

    test(
      'comes from the library files before the sync has saved them',
      () async {
        final fromFiles = await _Mix.open(
          withSounds: false,
          overrides: (_) => [
            libraryClipsProvider.overrideWithValue(
              () async => [_stored('file-1'), _stored('file-2')],
            ),
          ],
        );
        addTearDown(fromFiles.close);
        await fromFiles.saveAlarm(_alarm('a'));

        final mix = (await fromFiles.mix)!;

        expect(_ids(mix.round).toSet(), {'file-1', 'file-2'});
      },
    );

    test('is null when its plan cannot be stored', () async {
      final broken = await _Mix.open(
        overrides: (db) => [
          ringPlanRepositoryProvider.overrideWithValue(_BrokenPlans(db)),
        ],
      );
      addTearDown(broken.close);
      await broken.saveAlarm(_alarm('a'));

      expect(await broken.mix, isNull);
    });

    test('starts over from a row that cannot be read', () async {
      await app.saveAlarm(_alarm('a'));
      await app.mix;
      await app.db.customStatement("UPDATE ring_plans SET sound_ids = 'x'");

      app.container.invalidate(tonightMixProvider);
      final mix = (await app.mix)!;

      expect(mix.plan.soundIds, isNotEmpty);
      expect(await app.plans.forRing('a', _sevenTomorrow), mix.plan);
    });
  });

  group('Reshuffle', () {
    test('stores a new order with a new seed', () async {
      await app.saveAlarm(_alarm('a'));
      final before = (await app.mix)!;

      final changed = await app.mixController.reshuffle();

      final after = (await app.mix)!;
      expect(changed, isTrue);
      expect(after.plan.seed, isNot(before.plan.seed));
      expect(_ids(after.round), isNot(_ids(before.round)));
      expect(await app.plans.forRing('a', _sevenTomorrow), after.plan);
      expect(await app.storedPlans, hasLength(1));
    });

    test('says so when the sounds allow one order only', () async {
      final one = await _Mix.open(
        withSounds: false,
        overrides: (_) => [
          libraryClipsProvider.overrideWithValue(() async => [_stored('only')]),
        ],
      );
      addTearDown(one.close);
      await one.saveAlarm(_alarm('a'));
      final before = (await one.mix)!;

      final changed = await one.mixController.reshuffle();

      expect(changed, isFalse);
      expect((await one.mix)!.plan, before.plan);
    });

    test('uses what the weights have learned so far', () async {
      await app.saveAlarm(_alarm('a'));
      await app.mix;
      final weights = SoundWeights(const {
        'sound-1': SoundWeights.minWeight,
        'sound-2': SoundWeights.maxWeight,
        'sound-3': SoundWeights.minWeight,
        'sound-4': SoundWeights.minWeight,
      });
      for (var i = 1; i <= 4; i++) {
        await WeightRepository(app.db).save(weights, soundId: 'sound-$i');
      }

      // The heaviest sound comes first 5 times in 6.
      var first = 0;
      for (var i = 0; i < 60; i++) {
        await app.mixController.reshuffle();
        if (_ids((await app.mix)!.round).first == 'sound-2') first++;
      }

      expect(first, greaterThan(30));
    });

    test('fails without changing the mix when it cannot be stored', () async {
      final broken = await _Mix.open(
        overrides: (db) => [
          ringPlanRepositoryProvider.overrideWithValue(_NoSaves(db)),
        ],
      );
      addTearDown(broken.close);
      await broken.saveAlarm(_alarm('a'));
      final before = (await broken.mix)!;

      await expectLater(broken.mixController.reshuffle(), throwsStateError);

      expect((await broken.mix)!.plan, before.plan);
    });
  });

  group('Not tonight', () {
    test(
      'takes a sound out, keeps the others in order, and stores it',
      () async {
        await app.saveAlarm(_alarm('a'));
        final before = (await app.mix)!;
        final skipped = _ids(before.round)[1];

        await app.mixController.skip(skipped);

        final after = (await app.mix)!;
        expect(after.plan.notTonight, {skipped});
        expect(_ids(after.clips), isNot(contains(skipped)));
        expect(_ids(after.round), [
          for (final id in _ids(before.round))
            if (id != skipped) id,
        ]);
        expect(after.notTonight.single.id, skipped);
        expect(await app.plans.forRing('a', _sevenTomorrow), after.plan);
      },
    );

    test('brings a sound back to its place', () async {
      await app.saveAlarm(_alarm('a'));
      final before = (await app.mix)!;
      final skipped = _ids(before.round)[1];
      await app.mixController.skip(skipped);

      await app.mixController.bringBack(skipped);

      final after = (await app.mix)!;
      expect(after.plan, before.plan);
      expect(after.clips, before.clips);
      expect(after.notTonight, isEmpty);
      expect(await app.plans.forRing('a', _sevenTomorrow), before.plan);
    });

    test('holds after Reshuffle', () async {
      await app.saveAlarm(_alarm('a'));
      final skipped = _ids((await app.mix)!.round).first;
      await app.mixController.skip(skipped);

      await app.mixController.reshuffle();

      final after = (await app.mix)!;
      expect(after.plan.notTonight, {skipped});
      expect(_ids(after.clips), isNot(contains(skipped)));
    });

    test('holds after a reload', () async {
      await app.saveAlarm(_alarm('a'));
      final skipped = _ids((await app.mix)!.round).first;
      await app.mixController.skip(skipped);

      app.container.invalidate(tonightMixProvider);

      expect(_ids((await app.mix)!.clips), isNot(contains(skipped)));
    });

    test('leaves one sound: the alarm must have something to play', () async {
      await app.saveAlarm(_alarm('a'));
      final round = _ids((await app.mix)!.round);

      expect((await app.mix)!.canSkip, isTrue);
      for (final id in round.take(3)) {
        await app.mixController.skip(id);
      }
      expect((await app.mix)!.canSkip, isFalse);

      await app.mixController.skip(round.last);

      final mix = (await app.mix)!;
      expect(_ids(mix.round), [round.last]);
      expect(mix.plan.notTonight, unorderedEquals(round.take(3)));
    });

    test('fails without changing the mix when it cannot be stored', () async {
      final broken = await _Mix.open(
        overrides: (db) => [
          ringPlanRepositoryProvider.overrideWithValue(_NoSaves(db)),
        ],
      );
      addTearDown(broken.close);
      await broken.saveAlarm(_alarm('a'));
      final before = (await broken.mix)!;

      await expectLater(
        broken.mixController.skip(_ids(before.round).first),
        throwsStateError,
      );

      expect((await broken.mix)!.plan, before.plan);
    });

    test('lists the sounds it keeps out by title, not by id', () async {
      final sounds = SoundRepository(app.db);
      for (final (id, title) in [('a-id', 'Zebra'), ('z-id', 'Apple')]) {
        await sounds.save(
          StoredSound(
            Sound(
              id: id,
              title: title,
              source: SoundSource.builtin,
              genre: 'test',
              intensity: 1,
              duration: const Duration(seconds: 20),
            ),
            audioPath: 'assets/$id.wav',
          ),
        );
      }
      await app.saveAlarm(_alarm('a'));
      await app.mix;
      await app.mixController.skip('a-id');
      await app.mixController.skip('z-id');

      final titles = [
        for (final sound in (await app.mix)!.notTonight) sound.title,
      ];

      expect(titles, ['Apple', 'Zebra']);
    });
  });

  group('mixSegmentsOf', () {
    test('has the length and the strength of each clip, in play order', () {
      final clips = buildRingSequence(
        _alarm('a'),
        [
          _intense('gentle', 1, seconds: 10),
          _intense('medium', 2, seconds: 20),
          _intense('strong', 3, seconds: 30),
        ],
        const SoundWeights.start(),
        1,
      );

      expect(mixSegmentsOf(firstRound(clips)), [
        for (final clip in firstRound(clips))
          MixSegment(
            length: clip.window.length,
            strength: (clip.sound.intensity - 1) / 2,
          ),
      ]);
      expect(
        {
          for (final segment in mixSegmentsOf(firstRound(clips)))
            segment.length.inSeconds: segment.strength,
        },
        {10: 0.0, 20: 0.5, 29: 1.0},
      );
    });
  });

  group('The ring', () {
    test('plays what the mix shows, exactly', () async {
      await app.saveAlarm(_alarm('a'));
      final mix = (await app.mix)!;

      await app.ring(mix);

      for (final (index, clip) in mix.clips.take(6).indexed) {
        expect(
          app.player.plays[index].asset,
          mix.audioPathOf(clip.sound.id),
          reason: 'Clip ${index + 1}',
        );
        expect(app.player.plays[index].volume, clip.volume);
        await app.nextClip(clip);
      }
    });

    test('plays what the mix shows after Reshuffle and Not tonight', () async {
      await app.saveAlarm(_alarm('a'));
      await app.mixController.reshuffle();
      final round = _ids((await app.mix)!.round);
      await app.mixController.skip(round[1]);
      final mix = (await app.mix)!;

      await app.ring(mix);

      for (final (index, clip) in mix.clips.take(6).indexed) {
        expect(
          app.player.plays[index].asset,
          mix.audioPathOf(clip.sound.id),
          reason: 'Clip ${index + 1}',
        );
        await app.nextClip(clip);
      }
    });
  });
}

/// 20:00 on a Wednesday, and 07:00 the morning after.
final _evening = DateTime(2026, 11, 11, 20);
final _sevenTomorrow = DateTime(2026, 11, 12, 7);

Alarm _alarm(String id, {int hour = 7, bool enabled = true}) => Alarm(
  id: id,
  time: ClockTime(hour: hour, minute: 0),
  repeatDays: const {1, 2, 3, 4, 5, 6, 7},
  enabled: enabled,
  gentleStart: false,
);

StoredSound _stored(String id) => StoredSound(
  Sound(
    id: id,
    title: 'Title $id',
    source: SoundSource.builtin,
    genre: 'test',
    intensity: 1,
    duration: const Duration(seconds: 20),
  ),
  audioPath: 'assets/$id.wav',
);

/// A built-in sound of [intensity], of [seconds] seconds.
Sound _intense(String id, int intensity, {required int seconds}) => Sound(
  id: id,
  title: id,
  source: SoundSource.builtin,
  genre: 'test',
  intensity: intensity,
  duration: Duration(seconds: seconds),
);

/// The ids of the sounds of [clips], in their order.
List<String> _ids(Iterable<RingClip> clips) => [
  for (final clip in clips) clip.sound.id,
];

class _BrokenPlans extends RingPlanRepository {
  _BrokenPlans(super._db);

  @override
  Future<RingPlan> settle(
    String alarmId, {
    required DateTime now,
    required RingPlan Function(List<RingPlan> stored) choose,
  }) async => throw StateError('Broken');
}

/// A store of plans that makes them, but cannot save a change.
class _NoSaves extends RingPlanRepository {
  _NoSaves(super._db);

  @override
  Future<void> save(RingPlan plan) async {
    if (!_settling) throw StateError('Broken');
    await super.save(plan);
  }

  var _settling = false;

  @override
  Future<RingPlan> settle(
    String alarmId, {
    required DateTime now,
    required RingPlan Function(List<RingPlan> stored) choose,
  }) async {
    _settling = true;
    try {
      return await super.settle(alarmId, now: now, choose: choose);
    } finally {
      _settling = false;
    }
  }
}

/// A clock that shows the same time until a test moves it on.
class _Clock extends Clock {
  _Clock(this._time);

  DateTime _time;

  DateTime get time => _time;

  @override
  DateTime build() => _time;

  void moveTo(DateTime time) => state = _time = time;
}

/// The app on a database in memory, by default with four sounds of 20 s, at a
/// clock that the test moves.
class _Mix {
  _Mix._(this.db, this.container, this.clock);

  static Future<_Mix> open({
    bool withSounds = true,
    List<Override> Function(AppDatabase db)? overrides,
  }) async {
    final db = memoryDatabase();
    if (withSounds) {
      for (var i = 1; i <= 4; i++) {
        await SoundRepository(db).save(_stored('sound-$i'));
      }
    }
    final clock = _Clock(_evening);
    final container =
        ProviderContainer.test(
            overrides: [
              databaseProvider.overrideWithValue(db),
              clockProvider.overrideWith(() => clock),
              nowProvider.overrideWithValue(() => clock.time),
              alarmSchedulerProvider.overrideWithValue(FakeAlarmScheduler()),
              soundPlayerProvider.overrideWithValue(FakeSoundPlayer()),
              ...?overrides?.call(db),
            ],
          )
          ..listen(tonightMixProvider, (_, _) {})
          ..listen(ringingProvider, (_, _) {});
    final mix = _Mix._(db, container, clock);
    await mix.settle();
    return mix;
  }

  final AppDatabase db;
  final ProviderContainer container;
  final _Clock clock;

  late final plans = RingPlanRepository(db);

  FakeSoundPlayer get player =>
      container.read(soundPlayerProvider) as FakeSoundPlayer;

  TonightMixController get mixController =>
      container.read(tonightMixProvider.notifier);

  Future<TonightMix?> get mix async {
    await settle();
    return await container.read(tonightMixProvider.future);
  }

  Future<List<Object?>> get storedPlans async {
    final rows = await db.customSelect('SELECT alarm_id FROM ring_plans').get();
    return [for (final row in rows) row.data['alarm_id']];
  }

  /// Lets the writes to the database end.
  Future<void> settle() => pumpEventQueue(times: 100);

  Future<Alarm> saveAlarm(Alarm alarm) async {
    await AlarmRepository(db).save(alarm);
    await settle();
    return alarm;
  }

  /// The ring of [mix] comes due at its time.
  Future<void> ring(TonightMix mix) async {
    clock.moveTo(mix.ringAt);
    (container.read(alarmSchedulerProvider) as FakeAlarmScheduler).ring(
      DueRing(mix.alarm, scheduledFor: mix.ringAt),
    );
    await settle();
  }

  /// [clip] ends, at its time.
  Future<void> nextClip(RingClip clip) async {
    clock.moveTo(clock.time.add(clip.window.length));
    player.finishClip();
    await settle();
  }

  Future<void> close() async {
    container.dispose();
    await db.close();
  }
}
