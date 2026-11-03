import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/core/ring_plan.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/ring_plan_repository.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';

import 'memory_database.dart';

void main() {
  late AppDatabase db;
  late RingPlanRepository plans;

  setUp(() async {
    db = memoryDatabase();
    plans = RingPlanRepository(db);
    await AlarmRepository(db).save(_alarm('a'));
    await AlarmRepository(db).save(_alarm('b'));
  });

  tearDown(() => db.close());

  group('RingPlanRepository', () {
    test('reads back what it saved, to the microsecond', () async {
      final ringAt = DateTime(2026, 11, 12, 7, 0, 0, 123, 456);
      final plan = _plan('a', ringAt);

      await plans.save(plan);

      final read = await plans.forRing('a', ringAt);
      expect(read, plan);
      expect(read!.soundIds, ['two', 'one', 'three', 'one']);
      expect(read.notTonight, {'three'});
      expect(read.seed, 7);
    });

    test('finds only the plan of that alarm and that ring', () async {
      await plans.save(_plan('a', _seven));

      expect(await plans.forRing('b', _seven), isNull);
      expect(
        await plans.forRing('a', _seven.add(const Duration(microseconds: 1))),
        isNull,
      );
    });

    test('saves new values for a plan it has', () async {
      await plans.save(_plan('a', _seven));
      final next = RingPlan(
        alarmId: 'a',
        ringAt: _seven,
        seed: 9,
        soundIds: const ['three'],
      );

      await plans.save(next);

      expect(await plans.forRing('a', _seven), next);
      expect(await _count(db), 1);
    });

    test('a plan goes with its alarm', () async {
      await plans.save(_plan('a', _seven));
      await plans.save(_plan('b', _seven));

      await AlarmRepository(db).delete('a');

      expect(await plans.forRing('a', _seven), isNull);
      expect(await plans.forRing('b', _seven), isNotNull);
    });

    test('a plan stays when its alarm is saved again', () async {
      final plan = _plan('a', _seven);
      await plans.save(plan);

      await AlarmRepository(db).save(_alarm('a').copyWith(label: 'Gym'));

      expect(await plans.forRing('a', _seven), plan);
    });

    test('a plan stays when a sound it names is deleted', () async {
      final sounds = SoundRepository(db);
      await sounds.save(
        StoredSound(
          Sound(
            id: 'one',
            title: 'One',
            source: SoundSource.builtin,
            genre: 'pop',
            intensity: 1,
            duration: const Duration(seconds: 20),
          ),
          audioPath: 'assets/one.wav',
        ),
      );
      final plan = _plan('a', _seven);
      await plans.save(plan);

      await sounds.delete('one');

      expect(await plans.forRing('a', _seven), plan);
    });

    for (final (what, soundIds, notTonight) in const [
      ('is not JSON', 'not json', '[]'),
      ('is not a list', '{"a":1}', '[]'),
      ('holds other than text', '[1,2]', '[]'),
      ('has a broken Not tonight', '["a"]', 'not json'),
      ('has another kind of Not tonight', '["a"]', '[1]'),
    ]) {
      test('counts a row that $what as no plan', () async {
        await plans.save(_plan('a', _seven));
        await db.customStatement(
          'UPDATE ring_plans SET sound_ids = ?, not_tonight = ?',
          [soundIds, notTonight],
        );

        expect(await plans.forRing('a', _seven), isNull);
      });
    }
  });

  group('RingPlanRepository.settle', () {
    RingPlan fresh(String alarmId, DateTime ringAt) => RingPlan(
      alarmId: alarmId,
      ringAt: ringAt,
      seed: 1,
      soundIds: const ['new'],
    );

    test('saves the plan it is given, and returns it', () async {
      final plan = fresh('a', _seven);

      final settled = await plans.settle(
        'a',
        now: _evening,
        choose: (stored) {
          expect(stored, isEmpty);
          return plan;
        },
      );

      expect(settled, plan);
      expect(await plans.forRing('a', _seven), plan);
    });

    test('shows the plans of that alarm only, oldest first', () async {
      final tomorrow = _seven.add(const Duration(days: 1));
      await plans.save(_plan('a', tomorrow));
      await plans.save(_plan('a', _seven));
      await plans.save(_plan('b', _seven));

      final seen = <RingPlan>[];
      await plans.settle(
        'a',
        now: _evening,
        choose: (stored) {
          seen.addAll(stored);
          return stored.first;
        },
      );

      expect(seen, [_plan('a', _seven), _plan('a', tomorrow)]);
    });

    test('leaves one plan for a ring still to come, as a plan moves', () async {
      final moved = _seven.add(const Duration(minutes: 30));
      await plans.save(_plan('a', _seven));

      await plans.settle(
        'a',
        now: _evening,
        choose: (stored) => stored.single.movedTo(moved),
      );

      expect(await plans.forRing('a', _seven), isNull);
      expect(await plans.forRing('a', moved), _plan('a', moved));
      expect(await _count(db), 1);
    });

    test('keeps the plan of a ring that has come, for its Snooze', () async {
      final tomorrow = _seven.add(const Duration(days: 1));
      final rang = _plan('a', _seven);
      await plans.save(rang);

      await plans.settle(
        'a',
        now: _seven.add(const Duration(seconds: 1)),
        choose: (_) => fresh('a', tomorrow),
      );

      expect(await plans.forRing('a', _seven), rang);
      expect(await plans.forRing('a', tomorrow), fresh('a', tomorrow));
    });

    test(
      'keeps a plan a day after its ring, and forgets it after three',
      () async {
        final yesterday = _seven.subtract(const Duration(days: 1));
        final longAgo = _seven.subtract(const Duration(days: 3));
        await plans.save(_plan('a', yesterday));
        await plans.save(_plan('a', longAgo));

        await plans.settle('a', now: _seven, choose: (_) => fresh('a', _seven));

        expect(await plans.forRing('a', yesterday), isNotNull);
        expect(await plans.forRing('a', longAgo), isNull);
      },
    );

    test('leaves the plan of another alarm for a ring still to come', () async {
      final other = _plan('b', _seven.add(const Duration(hours: 1)));
      await plans.save(other);

      await plans.settle('a', now: _evening, choose: (_) => fresh('a', _seven));

      expect(await plans.forRing('b', other.ringAt), other);
    });

    test('forgets the plans of rings long past, of every alarm', () async {
      final old = _seven.subtract(RingPlanRepository.keptFor);
      final recent = old.add(const Duration(minutes: 1));
      await plans.save(_plan('a', old));
      await plans.save(_plan('a', recent));
      await plans.save(_plan('b', old));

      await plans.settle('a', now: _seven, choose: (_) => fresh('a', _seven));

      expect(await plans.forRing('a', old), isNull);
      expect(await plans.forRing('b', old), isNull);
      expect(await plans.forRing('a', recent), isNotNull);
    });

    test(
      'does not show a row that cannot be read, and saves over it',
      () async {
        await plans.save(_plan('a', _seven));
        await db.customStatement("UPDATE ring_plans SET sound_ids = 'broken'");

        final seen = <RingPlan>[];
        final settled = await plans.settle(
          'a',
          now: _evening,
          choose: (stored) {
            seen.addAll(stored);
            return fresh('a', _seven);
          },
        );

        expect(seen, isEmpty);
        expect(await plans.forRing('a', _seven), settled);
      },
    );

    test('of two at once, the second finds the plan of the first', () async {
      RingPlan? first;
      final results = await Future.wait([
        plans.settle(
          'a',
          now: _evening,
          choose: (stored) => first = fresh('a', _seven),
        ),
        plans.settle(
          'a',
          now: _evening,
          choose: (stored) => stored.isEmpty
              ? RingPlan(
                  alarmId: 'a',
                  ringAt: _seven,
                  seed: 2,
                  soundIds: const ['other'],
                )
              : stored.single,
        ),
      ]);

      expect(results.last, first);
      expect(await plans.forRing('a', _seven), first);
    });
  });
}

/// 07:00 on a Thursday, and the evening before.
final _seven = DateTime(2026, 11, 12, 7);
final _evening = DateTime(2026, 11, 11, 23);

Alarm _alarm(String id) => Alarm(id: id, time: ClockTime(hour: 7, minute: 0));

RingPlan _plan(String alarmId, DateTime ringAt) => RingPlan(
  alarmId: alarmId,
  ringAt: ringAt,
  seed: 7,
  soundIds: const ['two', 'one', 'three', 'one'],
  notTonight: const {'three'},
);

/// How many plans [db] holds.
Future<Object?> _count(AppDatabase db) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM ring_plans').getSingle())
        .data['n'];
