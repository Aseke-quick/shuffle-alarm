import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/due_rings.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/ringing/ringing_controller.dart';
import 'package:shuffle_alarm/platform/providers.dart';

import '../../data/memory_database.dart';
import '../../platform/fake_platform.dart';

void main() {
  late _Ring ring;

  setUp(() async => ring = await _Ring.open());
  tearDown(() => ring.close());

  test('the scheduler watches the alarms of the database', () async {
    final alarm = await ring.save(_alarm('a', days: _everyDay));

    expect(ring.scheduler.watched.last, [alarm]);
  });

  test(
    'a due ring plays the ring sequence, one clip after the other',
    () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));

      await ring.due(alarm);

      expect(ring.ringing, Ringing(ring.dueOf(alarm)));
      // The gentle start: intensity 1, 2 and 3, at 40%, 70% and 100%.
      expect(ring.player.plays, [_play('gentle', volume: 0.4)]);
      await ring.nextClip();
      await ring.nextClip();
      expect(ring.player.plays, [
        _play('gentle', volume: 0.4),
        _play('medium', volume: 0.7),
        _play('strong', volume: 1),
      ]);
    },
  );

  test('a clip that ends a moment early is not played again', () async {
    final alarm = await ring.save(_alarm('a', days: _everyDay));
    await ring.due(alarm);

    // The clock is a moment behind the sound: 19.9 s into a 20-s clip.
    ring.now = ring.now.add(const Duration(seconds: 19, milliseconds: 900));
    ring.player.finishClip();
    await pumpEventQueue();

    expect(ring.player.plays, [
      _play('gentle', volume: 0.4),
      _play('medium', volume: 0.7),
    ]);
  });

  test('a clip that cannot be read is skipped: the next one plays', () async {
    final alarm = await ring.save(_alarm('a', days: _everyDay));
    ring.player.broken.add('assets/library/test/gentle.wav');

    await ring.due(alarm);

    expect(ring.ringing, Ringing(ring.dueOf(alarm)));
    expect(ring.player.plays, [_play('medium', volume: 0.7)]);
  });

  test(
    'when no clip can be read, the ring says its sound did not play',
    () async {
      // As without a network, before the clips were loaded ahead.
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      ring.player.broken.addAll([
        for (final id in ['gentle', 'medium', 'strong'])
          'assets/library/test/$id.wav',
      ]);

      await ring.due(alarm);

      expect(ring.ringing, Ringing(ring.dueOf(alarm), audible: false));
    },
  );

  test('a ring found late starts where the clock says', () async {
    // As in a background tab: 25 s late, 5 s into the second clip.
    final alarm = await ring.save(_alarm('a', days: _everyDay));

    await ring.due(alarm, late: const Duration(seconds: 25));

    expect(ring.player.plays, [
      _play('medium', volume: 0.7, from: const Duration(seconds: 5)),
    ]);
  });

  test('a ring found after its time cap is missed: no sound', () async {
    final alarm = await ring.save(_alarm('a', days: _everyDay));

    await ring.due(alarm, late: const Duration(minutes: 10));

    expect(ring.ringing, isNull);
    expect(ring.player.plays, isEmpty);
  });

  test('a one-time alarm switches off when it comes due', () async {
    final once = await ring.save(_alarm('once'));
    final daily = await ring.save(_alarm('daily', days: _everyDay));

    await ring.due(once);
    await ring.stop();
    await ring.due(daily);

    expect(await ring.alarms.byId('once'), once.copyWith(enabled: false));
    expect(await ring.alarms.byId('daily'), daily);
  });

  test('a one-time alarm changed since it came due stays as it is', () async {
    final once = await ring.save(_alarm('once'));
    final moved = await ring.save(
      once.copyWith(time: ClockTime(hour: 8, minute: 0)),
    );

    await ring.due(once);

    expect(await ring.alarms.byId('once'), moved);
  });

  test('one ring at a time: another due alarm does not ring', () async {
    final first = await ring.save(_alarm('first', days: _everyDay));
    final second = await ring.save(_alarm('second', days: _everyDay));

    await ring.due(first);
    await ring.due(second);

    expect(ring.ringing?.due.alarm, first);
    expect(ring.player.plays, hasLength(1));
  });

  test('Stop ends the sound and the ring', () async {
    final alarm = await ring.save(_alarm('a', days: _everyDay));
    await ring.due(alarm);

    await ring.stop();
    await pumpEventQueue();

    expect(ring.ringing, isNull);
    expect(ring.player.stopCalls, 1);
    // The clip that Stop ended is not followed by the next one.
    expect(ring.player.plays, hasLength(1));
  });

  test('at its time cap the ring goes quiet and counts as over', () async {
    final alarm = await ring.save(_alarm('a', days: _everyDay));
    await ring.due(alarm);

    ring.now = ring.now.add(const Duration(minutes: 10));
    ring.player.finishClip();
    await pumpEventQueue();

    expect(ring.ringing, Ringing(ring.dueOf(alarm), over: true));
    expect(ring.player.plays, hasLength(1));
  });

  test('a blocked sound rings without it, until a tap plays it', () async {
    final alarm = await ring.save(_alarm('a', days: _everyDay));
    ring.player.blocked = true;

    await ring.due(alarm, late: const Duration(seconds: 3));

    expect(ring.ringing, Ringing(ring.dueOf(alarm), audible: false));
    expect(ring.player.plays, isEmpty);

    ring.now = ring.now.add(const Duration(seconds: 30));
    await ring.container.read(ringingProvider.notifier).playSound();
    await pumpEventQueue();

    expect(ring.player.unlockCalls, 1);
    expect(ring.ringing, Ringing(ring.dueOf(alarm)));
    // 33 s after the ring: 13 s into the second clip.
    expect(ring.player.plays, [
      _play('medium', volume: 0.7, from: const Duration(seconds: 13)),
    ]);
  });

  test('without sounds it still rings, without sound', () async {
    await ring.db.delete(ring.db.sounds).go();
    final alarm = await ring.save(_alarm('a', days: _everyDay));

    await ring.due(alarm);

    expect(ring.ringing, Ringing(ring.dueOf(alarm), audible: false));
    expect(ring.player.plays, isEmpty);
  });
}

const _everyDay = {1, 2, 3, 4, 5, 6, 7};

Alarm _alarm(String id, {Set<int> days = const {}}) =>
    Alarm(id: id, time: ClockTime(hour: 7, minute: 0), repeatDays: days);

FakePlay _play(
  String id, {
  required double volume,
  Duration from = Duration.zero,
}) => (
  asset: 'assets/library/test/$id.wav',
  from: from,
  to: const Duration(seconds: 20),
  volume: volume,
);

/// A ring controller on a database in memory with three sounds of 20 s, a
/// gentle, a medium and a strong one, and a clock that the test moves.
class _Ring {
  _Ring._(this.db, this.container);

  static Future<_Ring> open() async {
    final db = memoryDatabase();
    final sounds = SoundRepository(db);
    for (final (id, intensity) in [
      ('gentle', 1),
      ('medium', 2),
      ('strong', 3),
    ]) {
      await sounds.save(
        StoredSound(
          Sound(
            id: id,
            title: id,
            source: SoundSource.builtin,
            genre: 'test',
            intensity: intensity,
            duration: const Duration(seconds: 20),
          ),
          audioPath: 'assets/library/test/$id.wav',
        ),
      );
    }
    late final _Ring ring;
    final container = ProviderContainer.test(
      overrides: [
        databaseProvider.overrideWithValue(db),
        alarmSchedulerProvider.overrideWithValue(FakeAlarmScheduler()),
        soundPlayerProvider.overrideWithValue(FakeSoundPlayer()),
        nowProvider.overrideWithValue(() => ring.now),
      ],
    );
    ring = _Ring._(db, container);
    container.listen(ringingProvider, (_, _) {});
    return ring;
  }

  final AppDatabase db;
  final ProviderContainer container;
  DateTime now = DateTime(2026, 11, 11, 7);

  late final alarms = AlarmRepository(db);

  FakeAlarmScheduler get scheduler =>
      container.read(alarmSchedulerProvider) as FakeAlarmScheduler;

  FakeSoundPlayer get player =>
      container.read(soundPlayerProvider) as FakeSoundPlayer;

  Ringing? get ringing => container.read(ringingProvider);

  /// The ring of [alarm] at 07:00 today.
  DueRing dueOf(Alarm alarm) =>
      DueRing(alarm, scheduledFor: DateTime(2026, 11, 11, 7));

  Future<Alarm> save(Alarm alarm) async {
    await alarms.save(alarm);
    await pumpEventQueue();
    return alarm;
  }

  /// [alarm] comes due at 07:00, found [late].
  Future<void> due(Alarm alarm, {Duration late = Duration.zero}) async {
    now = DateTime(2026, 11, 11, 7).add(late);
    scheduler.ring(dueOf(alarm));
    await pumpEventQueue();
  }

  /// The clip that plays ends, 20 s on.
  Future<void> nextClip() async {
    now = now.add(const Duration(seconds: 20));
    player.finishClip();
    await pumpEventQueue();
  }

  Future<void> stop() => container.read(ringingProvider.notifier).stop();

  Future<void> close() async {
    container.dispose();
    await db.close();
  }
}
