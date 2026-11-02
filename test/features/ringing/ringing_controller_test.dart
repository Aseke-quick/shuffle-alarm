import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/adaptive_weights.dart';
import 'package:shuffle_alarm/core/due_rings.dart';
import 'package:shuffle_alarm/core/fallback_tone.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/data/ring_session_repository.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/data/weight_repository.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/ringing/ringing_controller.dart';
import 'package:shuffle_alarm/platform/providers.dart';

import '../../data/memory_database.dart';
import '../../platform/fake_platform.dart';

void main() {
  late _Ring ring;

  setUp(() async => ring = await _Ring.open());
  tearDown(() => ring.close());

  group('A ring', () {
    test('the scheduler watches the alarms of the database', () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));

      expect(ring.scheduler.watched.last, [alarm]);
    });

    test('plays the ring sequence, one clip after the other', () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));

      await ring.due(alarm);

      expect(ring.ringing, Ringing(ring.dueOf(alarm), sound: _sound('gentle')));
      // The gentle start: intensity 1, 2 and 3, at 40%, 70% and 100%.
      expect(ring.player.plays, [_play('gentle', volume: 0.4)]);
      await ring.nextClip();
      expect(ring.ringing?.sound, _sound('medium'));
      await ring.nextClip();
      expect(ring.ringing?.sound, _sound('strong'));
      expect(ring.player.plays, [
        _play('gentle', volume: 0.4),
        _play('medium', volume: 0.7),
        _play('strong', volume: 1),
      ]);
    });

    test('a clip that ends a moment early is not played again', () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      await ring.due(alarm);

      // The clock is a moment behind the sound: 19.9 s into a 20-s clip.
      ring.now = ring.now.add(const Duration(seconds: 19, milliseconds: 900));
      ring.player.finishClip();
      await ring.settle();

      expect(ring.player.plays, [
        _play('gentle', volume: 0.4),
        _play('medium', volume: 0.7),
      ]);
    });

    test('found late, it starts where the clock says', () async {
      // As in a background tab: 25 s late, 5 s into the second clip.
      final alarm = await ring.save(_alarm('a', days: _everyDay));

      await ring.due(alarm, late: const Duration(seconds: 25));

      expect(ring.player.plays, [
        _play('medium', volume: 0.7, from: const Duration(seconds: 5)),
      ]);
    });

    test('of a one-time alarm switches it off', () async {
      final once = await ring.save(_alarm('once'));
      final daily = await ring.save(_alarm('daily', days: _everyDay));

      await ring.due(once);
      await ring.stop();
      await ring.due(daily);

      expect(await ring.alarms.byId('once'), once.copyWith(enabled: false));
      expect(await ring.alarms.byId('daily'), daily);
    });

    test('of a one-time alarm changed since then leaves it as it is', () async {
      final once = await ring.save(_alarm('once'));
      final moved = await ring.save(
        once.copyWith(time: ClockTime(hour: 8, minute: 0)),
      );

      await ring.due(once);

      expect(await ring.alarms.byId('once'), moved);
    });

    test('at a time: another due alarm does not ring, and is missed', () async {
      final first = await ring.save(_alarm('first', days: _everyDay));
      final second = await ring.save(_alarm('second', days: _everyDay));

      await ring.due(first);
      await ring.due(second);

      expect(ring.ringing?.due.alarm, first);
      expect(ring.player.plays, hasLength(1));
      final other = (await ring.sessions).singleWhere(
        (session) => session.alarmId == 'second',
      );
      expect(other.events, isEmpty);
      expect(other.outcome, RingOutcome.missed);
    });

    test(
      'found after its time cap is missed: no sound, and in the log',
      () async {
        final alarm = await ring.save(_alarm('a', days: _everyDay));

        await ring.due(alarm, late: const Duration(minutes: 10));

        expect(ring.ringing, isNull);
        expect(ring.player.plays, isEmpty);
        final session = (await ring.sessions).single;
        expect(session.alarmId, 'a');
        expect(session.scheduledFor, _seven);
        expect(session.outcome, RingOutcome.missed);
      },
    );
  });

  group('Stop', () {
    test('ends the sound and the ring', () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      await ring.due(alarm);

      await ring.stop();
      await ring.settle();

      expect(ring.ringing, isNull);
      expect(ring.player.stopCalls, 1);
      // The clip that Stop ended is not followed by the next one.
      expect(ring.player.plays, hasLength(1));
    });

    test('is logged with the sound at the tap', () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      await ring.due(alarm);
      await ring.nextClip();

      ring.now = ring.now.add(const Duration(seconds: 3));
      await ring.stop();
      await ring.settle();

      final session = (await ring.sessions).single;
      expect(session.scheduledFor, _seven);
      expect(session.events.last, _event('medium', 20, 23, RingAction.stop));
      expect(session.outcome, RingOutcome.stopped);
    });

    test('makes the sound at the tap heavier, and only that one', () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      await ring.due(alarm);
      await ring.nextClip();

      await ring.stop();
      await ring.settle();

      final weights = await ring.weights;
      expect(weights.weightOf('medium'), SoundWeights.stopFactor);
      expect(weights.weightOf('gentle'), SoundWeights.startWeight);
    });

    test('tapped twice is logged once, and learns once', () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      await ring.due(alarm);

      await ring.stop();
      await ring.stop();
      await ring.settle();

      final session = (await ring.sessions).single;
      expect(session.events, hasLength(1));
      expect((await ring.weights).weightOf('gentle'), SoundWeights.stopFactor);
    });
  });

  group('The log', () {
    test(
      'has the ring from its start, so a closed tab leaves it missed',
      () async {
        final alarm = await ring.save(_alarm('a', days: _everyDay));

        await ring.due(alarm);
        await ring.settle();

        final session = (await ring.sessions).single;
        expect(session.alarmId, 'a');
        expect(session.events, isEmpty);
        expect(session.outcome, RingOutcome.missed);
      },
    );

    test('gets each clip that ended, with its times', () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      await ring.due(alarm);

      await ring.nextClip();
      await ring.nextClip();
      await ring.settle();

      expect((await ring.sessions).single.events, [
        _event('gentle', 0, 20, RingAction.timeout),
        _event('medium', 20, 40, RingAction.timeout),
      ]);
    });

    test('that fails never stops a ring', () async {
      final broken = await _Ring.open(
        overrides: (db) => [
          ringSessionRepositoryProvider.overrideWithValue(_BrokenLog(db)),
          weightRepositoryProvider.overrideWithValue(_BrokenWeights(db)),
        ],
      );
      addTearDown(broken.close);
      final alarm = await broken.save(_alarm('a', days: _everyDay));

      await broken.due(alarm);
      expect(broken.player.plays, hasLength(1));
      await broken.nextClip();
      expect(broken.player.plays, hasLength(2));
      await broken.snooze();
      expect(broken.scheduler.scheduled, hasLength(1));

      broken.now = broken.scheduler.scheduled.single.startsAt;
      broken.scheduler.ringScheduled();
      await broken.settle();
      expect(broken.player.plays, hasLength(3));
      await broken.stop();
      expect(broken.ringing, isNull);
    });
  });

  group('The time cap', () {
    test(
      'quiets the ring, which counts as missed and teaches nothing',
      () async {
        final alarm = await ring.save(_alarm('a', days: _everyDay));
        await ring.due(alarm);

        ring.now = ring.now.add(const Duration(minutes: 10));
        ring.player.finishClip();
        await ring.settle();

        expect(ring.ringing, Ringing(ring.dueOf(alarm), over: true));
        expect(ring.player.plays, hasLength(1));
        final session = (await ring.sessions).single;
        expect(session.events.single.action, RingAction.timeout);
        expect(session.outcome, RingOutcome.missed);
        expect(await ring.weights, const SoundWeights.start());
      },
    );

    test('holds also when no clip reports its end', () async {
      // Its time runs out 50 ms from now, with the clip still playing.
      final alarm = await ring.save(_alarm('a', days: _everyDay));

      await ring.due(alarm, late: _cap - const Duration(milliseconds: 50));
      expect(ring.ringing?.over, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await ring.settle();

      expect(ring.ringing?.over, isTrue);
      expect(ring.player.stopCalls, 1);
      expect((await ring.sessions).single.outcome, RingOutcome.missed);
    });

    test('Close after it adds nothing to the log', () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      await ring.due(alarm);
      ring.now = ring.now.add(const Duration(minutes: 10));
      ring.player.finishClip();
      await ring.settle();
      final before = (await ring.sessions).single;

      await ring.stop();
      await ring.settle();

      expect(ring.ringing, isNull);
      expect((await ring.sessions).single, before);
      expect(await ring.weights, const SoundWeights.start());
    });

    test('Snooze does nothing after it', () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      await ring.due(alarm);
      ring.now = ring.now.add(const Duration(minutes: 10));
      ring.player.finishClip();
      await ring.settle();

      await ring.snooze();

      expect(ring.ringing?.over, isTrue);
      expect(ring.scheduler.scheduled, isEmpty);
    });

    test('a ring that went quiet does not hold back the next alarm', () async {
      // Nobody tapped Close, and the tab stayed open until the next alarm.
      final missed = await ring.save(_alarm('missed', days: _everyDay));
      final next = await ring.save(_alarm('next', days: _everyDay));
      await ring.due(missed);
      ring.now = ring.now.add(const Duration(minutes: 10));
      ring.player.finishClip();
      await ring.settle();

      await ring.due(next, at: DateTime(2026, 11, 12, 7));

      expect(ring.ringing?.due.alarm, next);
      expect(ring.ringing?.over, isFalse);
      expect(ring.player.plays, hasLength(2));
    });
  });

  group('A blocked sound', () {
    test('rings without it, until a tap plays it', () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      ring.player.blocked = true;

      await ring.due(alarm, late: const Duration(seconds: 3));

      expect(ring.ringing, Ringing(ring.dueOf(alarm), audible: false));
      expect(ring.player.plays, isEmpty);

      ring.now = ring.now.add(const Duration(seconds: 30));
      await ring.container.read(ringingProvider.notifier).playSound();
      await ring.settle();

      expect(ring.player.unlockCalls, 1);
      expect(ring.ringing, Ringing(ring.dueOf(alarm), sound: _sound('medium')));
      // 33 s after the ring: 13 s into the second clip.
      expect(ring.player.plays, [
        _play('medium', volume: 0.7, from: const Duration(seconds: 13)),
      ]);
    });

    test(
      'still reaches the time cap, and does not hold back the next',
      () async {
        final blocked = await ring.save(_alarm('blocked', days: _everyDay));
        final next = await ring.save(_alarm('next', days: _everyDay));
        ring.player.blocked = true;

        await ring.due(blocked, late: _cap - const Duration(milliseconds: 50));
        expect(ring.ringing?.audible, isFalse);
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await ring.settle();

        expect(ring.ringing?.over, isTrue);
        expect((await ring.sessions).single.outcome, RingOutcome.missed);

        ring.player.blocked = false;
        await ring.due(next, at: DateTime(2026, 11, 12, 7));
        expect(ring.ringing?.due.alarm, next);
        expect(ring.player.plays, hasLength(1));
      },
    );

    test('Stop is logged without length, and teaches nothing', () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      ring.player.blocked = true;
      await ring.due(alarm, late: const Duration(seconds: 25));

      await ring.stop();
      await ring.settle();

      final session = (await ring.sessions).single;
      // The sound the clock says, which nobody heard.
      expect(session.events, [_event('medium', 25, 25, RingAction.stop)]);
      expect(await ring.weights, const SoundWeights.start());
    });

    test(
      'Snooze is logged without length, teaches nothing, and comes back',
      () async {
        final alarm = await ring.save(_alarm('a', days: _everyDay));
        ring.player.blocked = true;
        await ring.due(alarm, late: const Duration(seconds: 25));

        await ring.snooze();
        await ring.settle();

        final session = (await ring.sessions).single;
        expect(session.events, [_event('medium', 25, 25, RingAction.snooze)]);
        expect(await ring.weights, const SoundWeights.start());
        expect(ring.scheduler.scheduled, hasLength(1));
      },
    );
  });

  group('A sound that cannot be read', () {
    test(
      'gives way to the tone for its time, then the next one plays',
      () async {
        final alarm = await ring.save(_alarm('a', days: _everyDay));
        ring.player.broken.add(_asset('gentle'));

        await ring.due(alarm);

        expect(ring.ringing, Ringing(ring.dueOf(alarm), sound: fallbackTone));
        expect(ring.player.plays, [_tone(volume: 0.4, seconds: 20)]);

        await ring.nextClip();
        expect(ring.ringing?.sound, _sound('medium'));
        expect(ring.player.plays.last, _play('medium', volume: 0.7));

        await ring.settle();
        expect((await ring.sessions).single.events, [
          _event(fallbackTone.id, 0, 20, RingAction.timeout),
        ]);
      },
    );

    test('found late, the tone plays only the rest of its time', () async {
      // 25 s late, 5 s into the second clip of 20 s.
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      ring.player.broken.add(_asset('medium'));

      await ring.due(alarm, late: const Duration(seconds: 25));

      expect(ring.player.plays, [_tone(volume: 0.7, seconds: 15)]);
    });

    test('when none can be read, the ring still makes a sound', () async {
      // As without a network, before the clips were loaded ahead.
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      ring.player.broken.addAll([
        for (final id in ['gentle', 'medium', 'strong']) _asset(id),
      ]);

      await ring.due(alarm);
      await ring.nextClip();

      expect(ring.ringing?.audible, isTrue);
      expect(ring.player.plays, [
        _tone(volume: 0.4, seconds: 20),
        _tone(volume: 0.7, seconds: 20),
      ]);
    });

    test('when the tone cannot play either, the ring says so', () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      ring.player
        ..broken.add(_asset('gentle'))
        ..toneBroken = true;

      await ring.due(alarm);

      expect(ring.ringing, Ringing(ring.dueOf(alarm), audible: false));
    });
  });

  group('Without sounds on the device', () {
    test('a ring plays the library straight from its files', () async {
      final fromFiles = await _Ring.open(
        withSounds: false,
        overrides: (_) => [
          libraryClipsProvider.overrideWithValue(
            () async => [
              StoredSound(_sound('gentle'), audioPath: _asset('gentle')),
            ],
          ),
        ],
      );
      addTearDown(fromFiles.close);
      final alarm = await fromFiles.save(_alarm('a', days: _everyDay));

      await fromFiles.due(alarm);

      expect(fromFiles.ringing?.sound, _sound('gentle'));
      expect(fromFiles.player.plays, [_play('gentle', volume: 0.4)]);
    });

    test('a ring plays the tone when the library cannot be read', () async {
      final without = await _Ring.open(
        withSounds: false,
        overrides: (_) => [
          libraryClipsProvider.overrideWithValue(
            () async => throw StateError('No network'),
          ),
        ],
      );
      addTearDown(without.close);
      final alarm = await without.save(_alarm('a', days: _everyDay));

      await without.due(alarm);

      expect(
        without.ringing,
        Ringing(without.dueOf(alarm), sound: fallbackTone),
      );
      expect(without.player.plays, [_tone(volume: 0.4, seconds: 29)]);

      without.now = without.now.add(const Duration(seconds: 29));
      without.player.finishClip();
      await without.settle();
      expect(without.player.plays.last, _tone(volume: 0.7, seconds: 29));
    });

    test('a ring plays the library when the sounds cannot be read', () async {
      final broken = await _Ring.open(
        overrides: (db) => [
          soundRepositoryProvider.overrideWithValue(_BrokenSounds(db)),
          libraryClipsProvider.overrideWithValue(
            () async => [
              StoredSound(_sound('medium'), audioPath: _asset('medium')),
            ],
          ),
        ],
      );
      addTearDown(broken.close);
      final alarm = await broken.save(_alarm('a', days: _everyDay));

      await broken.due(alarm);

      expect(broken.ringing?.sound, _sound('medium'));
    });

    test(
      'a ring plays with start weights when the weights cannot be read',
      () async {
        final broken = await _Ring.open(
          overrides: (db) => [
            weightRepositoryProvider.overrideWithValue(_BrokenWeights(db)),
          ],
        );
        addTearDown(broken.close);
        final alarm = await broken.save(_alarm('a', days: _everyDay));

        await broken.due(alarm);

        expect(broken.ringing?.sound, _sound('gentle'));
      },
    );

    test('Snooze on the tone comes back with the tone', () async {
      final without = await _Ring.open(
        withSounds: false,
        overrides: (_) => [
          libraryClipsProvider.overrideWithValue(
            () async => throw StateError('No network'),
          ),
        ],
      );
      addTearDown(without.close);
      final alarm = await without.save(_alarm('a', days: _everyDay));
      await without.due(alarm);

      await without.snooze();
      without.now = without.scheduler.scheduled.single.startsAt;
      without.scheduler.ringScheduled();
      await without.settle();

      expect(without.ringing?.sound, fallbackTone);
      expect(without.player.plays.last, _tone(volume: 1, seconds: 29));
    });
  });

  group('Snooze', () {
    test('silences the ring, and says when it comes back', () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      await ring.due(alarm);
      ring.now = ring.now.add(const Duration(seconds: 7));

      await ring.snooze();
      await ring.settle();

      expect(ring.ringing, isNull);
      expect(ring.player.stopCalls, 1);
      expect(ring.player.plays, hasLength(1));
      final back = DueRing(
        alarm,
        scheduledFor: _seven,
        startsAt: DateTime(2026, 11, 11, 7, 5, 7),
        snoozedSoundId: 'gentle',
      );
      expect(ring.scheduler.scheduled, [back]);
      expect(ring.snoozed.single.due, back);
    });

    test('is logged with the sound at the tap', () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      await ring.due(alarm);
      await ring.nextClip();
      ring.now = ring.now.add(const Duration(seconds: 3));

      await ring.snooze();
      await ring.settle();

      final session = (await ring.sessions).single;
      expect(session.events, [
        _event('gentle', 0, 20, RingAction.timeout),
        _event('medium', 20, 23, RingAction.snooze),
      ]);
      expect(session.outcome, RingOutcome.snoozed);
    });

    test('makes the sound at the tap lighter, and only that one', () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      await ring.due(alarm);
      await ring.nextClip();

      await ring.snooze();
      await ring.settle();

      final weights = await ring.weights;
      expect(weights.weightOf('medium'), SoundWeights.snoozeFactor);
      expect(weights.weightOf('gentle'), SoundWeights.startWeight);
    });

    test('tapped after Stop does nothing', () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      await ring.due(alarm);

      await ring.stop();
      await ring.snooze();
      await ring.settle();

      expect(ring.scheduler.scheduled, isEmpty);
      expect((await ring.sessions).single.outcome, RingOutcome.stopped);
    });
  });

  group('A ring after Snooze', () {
    Future<Alarm> snoozed() async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      await ring.due(alarm);
      ring.now = ring.now.add(const Duration(seconds: 7));
      await ring.snooze();
      await ring.settle();
      return alarm;
    }

    test(
      'plays at full volume, and not the sound of the Snooze first',
      () async {
        await snoozed();

        await ring.comeBack();

        expect(ring.ringing?.due.snoozedSoundId, 'gentle');
        expect(ring.ringing?.due.scheduledFor, _seven);
        expect(ring.player.plays, hasLength(2));
        expect(ring.player.plays.last.volume, 1);
        expect(ring.player.plays.last.asset, isNot(_asset('gentle')));
        expect(ring.snoozed, isEmpty);
        expect(ring.scheduler.scheduled, isEmpty);
      },
    );

    test('keeps the same session in the log, up to its Stop', () async {
      await snoozed();

      await ring.comeBack();
      final sound = ring.ringing!.sound!.id;
      ring.now = ring.now.add(const Duration(seconds: 4));
      await ring.stop();
      await ring.settle();

      final session = (await ring.sessions).single;
      expect(session.scheduledFor, _seven);
      expect(session.events, [
        _event('gentle', 0, 7, RingAction.snooze),
        RingEvent(
          soundId: sound,
          startedAt: DateTime(2026, 11, 11, 7, 5, 7),
          endedAt: DateTime(2026, 11, 11, 7, 5, 11),
          action: RingAction.stop,
        ),
      ]);
      expect(session.outcome, RingOutcome.stopped);
    });

    test('can be snoozed again', () async {
      await snoozed();

      await ring.comeBack();
      ring.now = ring.now.add(const Duration(seconds: 4));
      await ring.snooze();
      await ring.settle();

      expect(
        ring.scheduler.scheduled.single.startsAt,
        DateTime(2026, 11, 11, 7, 10, 11),
      );
      expect(ring.scheduler.scheduled.single.scheduledFor, _seven);
      final session = (await ring.sessions).single;
      expect(session.events, hasLength(2));
      expect(session.outcome, RingOutcome.snoozed);
    });

    test(
      'found late starts where the clock says, from its own start',
      () async {
        await snoozed();

        await ring.comeBack(late: const Duration(seconds: 25));

        expect(ring.player.plays.last.from, const Duration(seconds: 5));
        expect(ring.player.plays.last.volume, 1);
      },
    );

    test(
      'found after its time cap is missed: no sound, and in the log',
      () async {
        await snoozed();

        await ring.comeBack(late: _cap);

        expect(ring.ringing, isNull);
        expect(ring.player.plays, hasLength(1));
        final session = (await ring.sessions).single;
        expect(session.outcome, RingOutcome.missed);
        expect(session.events.last.action, RingAction.timeout);
      },
    );

    test('has a time cap of its own, then counts as missed', () async {
      await snoozed();
      await ring.comeBack();

      ring.now = ring.now.add(_cap);
      ring.player.finishClip();
      await ring.settle();

      expect(ring.ringing?.over, isTrue);
      expect((await ring.sessions).single.outcome, RingOutcome.missed);
    });

    test('blocked until its time cap is missed too', () async {
      await snoozed();
      ring.player.blocked = true;

      await ring.comeBack(late: _cap - const Duration(milliseconds: 50));
      expect(ring.ringing?.audible, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await ring.settle();

      expect(ring.ringing?.over, isTrue);
      final session = (await ring.sessions).single;
      expect(session.outcome, RingOutcome.missed);
    });

    test('due while another rings is missed, and that one rings on', () async {
      await snoozed();
      final other = await ring.save(_alarm('other', days: _everyDay));
      await ring.due(other, at: DateTime(2026, 11, 11, 7, 5));

      ring.now = ring.scheduler.scheduled.single.startsAt;
      ring.scheduler.ringScheduled();
      await ring.settle();

      expect(ring.ringing?.due.alarm, other);
      expect(ring.player.plays, hasLength(2));
      final session = (await ring.sessions).singleWhere(
        (session) => session.alarmId == 'a',
      );
      expect(session.outcome, RingOutcome.missed);
      expect(session.events, hasLength(2));
    });

    test('of a one-time alarm leaves the alarm as the user set it', () async {
      // The user turned it on again during the snooze, for another day.
      final once = await ring.save(_alarm('once'));
      await ring.due(once);
      await ring.snooze();
      await ring.settle();
      final on = await ring.save(once.copyWith(enabled: true));

      await ring.comeBack();
      await ring.settle();

      expect(await ring.alarms.byId('once'), on);
    });
  });

  group('Stop during a snooze', () {
    test('cancels the ring that would come back', () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      await ring.due(alarm);
      await ring.snooze();
      await ring.settle();

      ring.now = ring.now.add(const Duration(minutes: 2));
      ring.container
          .read(ringingProvider.notifier)
          .stopSnoozed(ring.snoozed.single);
      await ring.settle();

      expect(ring.scheduler.scheduled, isEmpty);
      expect(ring.snoozed, isEmpty);
      expect(ring.ringing, isNull);
    });

    test('is logged without length, and teaches nothing more', () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      await ring.due(alarm);
      await ring.snooze();
      await ring.settle();

      ring.now = ring.now.add(const Duration(minutes: 2));
      ring.container
          .read(ringingProvider.notifier)
          .stopSnoozed(ring.snoozed.single);
      await ring.settle();

      final session = (await ring.sessions).single;
      expect(session.events.last, _event('gentle', 120, 120, RingAction.stop));
      expect(session.outcome, RingOutcome.stopped);
      expect(
        (await ring.weights).weightOf('gentle'),
        SoundWeights.snoozeFactor,
      );
    });
  });

  group('A snooze', () {
    test('ends when its alarm is deleted', () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      await ring.due(alarm);
      await ring.snooze();
      await ring.settle();

      await ring.alarms.delete('a');
      await ring.settle();

      expect(ring.scheduler.scheduled, isEmpty);
      expect(ring.snoozed, isEmpty);
      expect((await ring.sessions).single.outcome, RingOutcome.stopped);
    });

    test('ends when its repeating alarm is switched off', () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      await ring.due(alarm);
      await ring.snooze();
      await ring.settle();

      await ring.save(alarm.copyWith(enabled: false));
      await ring.settle();

      expect(ring.scheduler.scheduled, isEmpty);
      expect(ring.snoozed, isEmpty);
    });

    test(
      'of a one-time alarm holds, though the alarm is off by then',
      () async {
        final once = await ring.save(_alarm('once'));
        await ring.due(once);
        await ring.settle();
        await ring.snooze();
        await ring.settle();

        // Any change to the alarms looks at the snoozes again.
        await ring.save(_alarm('other', days: _everyDay));

        expect(await ring.alarms.byId('once'), once.copyWith(enabled: false));
        expect(ring.scheduler.scheduled, hasLength(1));
        expect(ring.snoozed, hasLength(1));
      },
    );

    test('holds while another alarm changes', () async {
      final alarm = await ring.save(_alarm('a', days: _everyDay));
      await ring.due(alarm);
      await ring.snooze();
      await ring.settle();

      await ring.save(_alarm('other', days: _everyDay));
      await ring.settle();

      expect(ring.scheduler.scheduled, hasLength(1));
    });
  });

  group('After a reload of the app, a snooze', () {
    final saved = RingSession(
      id: 's',
      alarmId: 'a',
      scheduledFor: _seven,
      events: [_event('gentle', 0, 7, RingAction.snooze)],
    );

    test('comes back in its own session', () async {
      final alarm = _alarm('a', days: _everyDay);
      final reloaded = await _Ring.open(alarms: [alarm], history: [saved]);
      addTearDown(reloaded.close);

      final back = DueRing(
        alarm,
        scheduledFor: _seven,
        startsAt: DateTime(2026, 11, 11, 7, 5, 7),
        snoozedSoundId: 'gentle',
      );
      expect(reloaded.scheduler.scheduled, [back]);
      expect(reloaded.snoozed.single.due, back);

      await reloaded.comeBack();
      expect(reloaded.ringing?.due, back);
      expect(reloaded.snoozed, isEmpty);
      await reloaded.stop();
      await reloaded.settle();

      final session = (await reloaded.sessions).single;
      expect(session.id, 's');
      expect(session.events, hasLength(2));
      expect(session.outcome, RingOutcome.stopped);
    });

    test('found after its time cap is missed', () async {
      final reloaded = await _Ring.open(
        alarms: [_alarm('a', days: _everyDay)],
        history: [saved],
      );
      addTearDown(reloaded.close);

      await reloaded.comeBack(late: _cap);

      expect(reloaded.ringing, isNull);
      expect(reloaded.player.plays, isEmpty);
      expect((await reloaded.sessions).single.outcome, RingOutcome.missed);
    });

    test('of an alarm that is gone is over', () async {
      final reloaded = await _Ring.open(history: [saved]);
      addTearDown(reloaded.close);

      expect(reloaded.scheduler.scheduled, isEmpty);
      expect(reloaded.snoozed, isEmpty);
      expect((await reloaded.sessions).single.outcome, RingOutcome.stopped);
    });

    test('of another session does not touch one that is over', () async {
      final over = RingSession(
        id: 'over',
        alarmId: 'a',
        scheduledFor: _seven,
        events: [_event('gentle', 0, 7, RingAction.stop)],
      );
      final reloaded = await _Ring.open(
        alarms: [_alarm('a', days: _everyDay)],
        history: [over],
      );
      addTearDown(reloaded.close);

      expect(reloaded.scheduler.scheduled, isEmpty);
      expect((await reloaded.sessions).single, over);
    });

    test('that cannot be read leaves the app running', () async {
      final broken = await _Ring.open(
        overrides: (db) => [
          ringSessionRepositoryProvider.overrideWithValue(_BrokenLog(db)),
        ],
      );
      addTearDown(broken.close);
      final alarm = await broken.save(_alarm('a', days: _everyDay));

      await broken.due(alarm);

      expect(broken.player.plays, hasLength(1));
    });
  });
}

const _everyDay = {1, 2, 3, 4, 5, 6, 7};
const _cap = Duration(minutes: 10);

/// The time the alarms of these tests are set for.
final DateTime _seven = DateTime(2026, 11, 11, 7);

Alarm _alarm(String id, {Set<int> days = const {}}) =>
    Alarm(id: id, time: ClockTime(hour: 7, minute: 0), repeatDays: days);

String _asset(String id) => 'assets/library/test/$id.wav';

/// One of the three sounds of 20 s of [_Ring].
Sound _sound(String id) => Sound(
  id: id,
  title: id,
  source: SoundSource.builtin,
  genre: 'test',
  intensity: const {'gentle': 1, 'medium': 2, 'strong': 3}[id]!,
  duration: const Duration(seconds: 20),
);

FakePlay _play(
  String id, {
  required double volume,
  Duration from = Duration.zero,
}) => (
  asset: _asset(id),
  from: from,
  to: const Duration(seconds: 20),
  volume: volume,
);

FakePlay _tone({required double volume, required int seconds}) => (
  asset: fakeTone,
  from: Duration.zero,
  to: Duration(seconds: seconds),
  volume: volume,
);

/// A logged sound, with its times in seconds after 07:00.
RingEvent _event(String id, int from, int to, RingAction action) => RingEvent(
  soundId: id,
  startedAt: _seven.add(Duration(seconds: from)),
  endedAt: _seven.add(Duration(seconds: to)),
  action: action,
);

/// A ring log whose database always fails.
class _BrokenLog extends RingSessionRepository {
  _BrokenLog(super._db);

  @override
  Future<List<RingSession>> all() async => throw StateError('Broken');

  @override
  Future<void> save(RingSession session) async => throw StateError('Broken');
}

class _BrokenWeights extends WeightRepository {
  _BrokenWeights(super._db);

  @override
  Future<SoundWeights> load() async => throw StateError('Broken');
}

class _BrokenSounds extends SoundRepository {
  _BrokenSounds(super._db);

  @override
  Future<List<StoredSound>> all() async => throw StateError('Broken');
}

/// A ring controller on a database in memory, by default with three sounds of
/// 20 s, a gentle, a medium and a strong one, and a clock that the test moves.
class _Ring {
  _Ring._(this.db, this.container);

  static Future<_Ring> open({
    bool withSounds = true,
    List<Alarm> alarms = const [],
    List<RingSession> history = const [],
    List<Override> Function(AppDatabase db)? overrides,
  }) async {
    final db = memoryDatabase();
    if (withSounds) {
      final sounds = SoundRepository(db);
      for (final id in ['gentle', 'medium', 'strong']) {
        await sounds.save(StoredSound(_sound(id), audioPath: _asset(id)));
      }
    }
    for (final alarm in alarms) {
      await AlarmRepository(db).save(alarm);
    }
    for (final session in history) {
      await RingSessionRepository(db).save(session);
    }
    late final _Ring ring;
    final container = ProviderContainer.test(
      overrides: [
        databaseProvider.overrideWithValue(db),
        alarmSchedulerProvider.overrideWithValue(FakeAlarmScheduler()),
        soundPlayerProvider.overrideWithValue(FakeSoundPlayer()),
        nowProvider.overrideWithValue(() => ring.now),
        ...?overrides?.call(db),
      ],
    );
    ring = _Ring._(db, container);
    container.listen(ringingProvider, (_, _) {});
    await ring.settle();
    return ring;
  }

  final AppDatabase db;
  final ProviderContainer container;
  DateTime now = _seven;

  late final alarms = AlarmRepository(db);

  FakeAlarmScheduler get scheduler =>
      container.read(alarmSchedulerProvider) as FakeAlarmScheduler;

  FakeSoundPlayer get player =>
      container.read(soundPlayerProvider) as FakeSoundPlayer;

  Ringing? get ringing => container.read(ringingProvider);

  List<SnoozedRing> get snoozed => container.read(snoozedRingsProvider);

  Future<List<RingSession>> get sessions => RingSessionRepository(db).all();

  Future<SoundWeights> get weights => WeightRepository(db).load();

  /// The ring of [alarm] at 07:00 today.
  DueRing dueOf(Alarm alarm) => DueRing(alarm, scheduledFor: _seven);

  /// Lets the writes to the database end.
  Future<void> settle() => pumpEventQueue(times: 100);

  Future<Alarm> save(Alarm alarm) async {
    await alarms.save(alarm);
    await settle();
    return alarm;
  }

  /// [alarm] comes due [at], by default 07:00, found [late].
  Future<void> due(
    Alarm alarm, {
    DateTime? at,
    Duration late = Duration.zero,
  }) async {
    final set = at ?? _seven;
    now = set.add(late);
    scheduler.ring(DueRing(alarm, scheduledFor: set));
    await settle();
  }

  /// The ring that was snoozed comes due, found [late].
  Future<void> comeBack({Duration late = Duration.zero}) async {
    now = scheduler.scheduled.first.startsAt.add(late);
    scheduler.ringScheduled();
    await settle();
  }

  /// The clip that plays ends, 20 s on.
  Future<void> nextClip() async {
    now = now.add(const Duration(seconds: 20));
    player.finishClip();
    await settle();
  }

  Future<void> stop() => container.read(ringingProvider.notifier).stop();

  Future<void> snooze() => container.read(ringingProvider.notifier).snooze();

  Future<void> close() async {
    container.dispose();
    await db.close();
  }
}
