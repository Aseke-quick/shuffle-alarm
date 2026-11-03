import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/clip_rule.dart';
import 'package:shuffle_alarm/core/due_rings.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/core/ring_sequence.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/features/alarms/arming.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/alarms/mix_preview.dart';
import 'package:shuffle_alarm/features/ringing/ringing_controller.dart';
import 'package:shuffle_alarm/platform/providers.dart';

import '../../data/memory_database.dart';
import '../../platform/fake_platform.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late FakeAlarmScheduler scheduler;
  late FakeSoundPlayer player;
  late FakeScreenWakeLock wakeLock;
  late _SlowPlayer slow;
  var now = DateTime(2026, 11, 12, 7);

  MixPreviewController preview() => container.read(mixPreviewProvider.notifier);
  MixPreview? shown() => container.read(mixPreviewProvider);
  Future<PreviewOutcome> tap(Sound sound, String path, {double volume = 1}) =>
      preview().toggle(sound, audioPath: path, volume: volume);
  Future<void> settle() => pumpEventQueue(times: 100);

  Future<void> open(FakeSoundPlayer fake) async {
    player = fake;
    container =
        ProviderContainer.test(
            overrides: [
              databaseProvider.overrideWithValue(db),
              alarmSchedulerProvider.overrideWithValue(scheduler),
              soundPlayerProvider.overrideWithValue(player),
              screenWakeLockProvider.overrideWithValue(wakeLock),
              nowProvider.overrideWithValue(() => now),
            ],
          )
          ..listen(mixPreviewProvider, (_, _) {})
          ..listen(ringingProvider, (_, _) {})
          ..listen(armingProvider, (_, _) {});
    await settle();
  }

  setUp(() async {
    now = DateTime(2026, 11, 12, 7);
    db = memoryDatabase();
    scheduler = FakeAlarmScheduler();
    wakeLock = FakeScreenWakeLock();
    slow = _SlowPlayer();
    await AlarmRepository(db).save(_alarm);
    await SoundRepository(db).save(_stored);
    await open(FakeSoundPlayer());
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('A preview', () {
    test(
      'plays one clip by the clip rule, at its volume in the ring',
      () async {
        unawaited(tap(_song, _songPath, volume: 0.7));
        await settle();

        final window = ClipWindow.of(_song);
        expect(window.length, ClipWindow.maxLength);
        expect(player.plays, [
          (asset: _songPath, from: window.start, to: window.end, volume: 0.7),
        ]);
        expect(shown(), const MixPreview('song'));
      },
    );

    test('ends by itself when its clip ends', () async {
      final outcome = tap(_song, _songPath);
      await settle();

      player.finishClip();

      expect(await outcome, PreviewOutcome.played);
      expect(shown(), isNull);
    });

    test('a second tap stops it', () async {
      final outcome = tap(_song, _songPath);
      await settle();

      await tap(_song, _songPath);

      expect(player.stopCalls, 1);
      expect(shown(), isNull);
      expect(player.plays, hasLength(1));
      expect(await outcome, PreviewOutcome.played);
    });

    test('of another sound takes over', () async {
      unawaited(tap(_song, _songPath));
      await settle();

      unawaited(tap(_voice, _voicePath));
      await settle();

      expect(shown(), const MixPreview('voice'));
      expect(
        [for (final play in player.plays) play.asset],
        [_songPath, _voicePath],
      );
    });

    test('that stops ends quietly, without touching a later one', () async {
      unawaited(tap(_song, _songPath));
      await settle();
      unawaited(tap(_voice, _voicePath));
      await settle();

      expect(shown(), const MixPreview('voice'));
    });

    test('leaving stops it', () async {
      unawaited(tap(_song, _songPath));
      await settle();

      await preview().stop();

      expect(player.stopCalls, 1);
      expect(shown(), isNull);
    });

    test('leaving without one playing touches nothing', () async {
      await preview().stop();

      expect(player.stopCalls, 0);
    });

    test('says when its sound cannot be read', () async {
      player.broken.add(_songPath);

      final outcome = await tap(_song, _songPath);

      expect(outcome, PreviewOutcome.failed);
      expect(shown(), isNull);
    });

    test('that fails after a newer tap says nothing of it', () async {
      container.dispose();
      final late = _LateFailure();
      await open(late);

      final outcome = tap(_song, _songPath);
      await settle();
      unawaited(tap(_voice, _voicePath));
      await settle();
      late.failNow();
      await settle();

      expect(await outcome, PreviewOutcome.played);
      expect(shown(), const MixPreview('voice'));
    });

    test('says when the platform blocks the sound in the tap', () async {
      player
        ..unlocks = false
        ..blocked = true;

      final outcome = await tap(_song, _songPath);

      expect(outcome, PreviewOutcome.blocked);
      expect(shown(), isNull);
    });

    test('says when the platform blocks the sound after the tap', () async {
      container.dispose();
      await open(FakeSoundPlayer(needsUnlock: false, blocked: true));

      final outcome = await tap(_song, _songPath);

      expect(outcome, PreviewOutcome.blocked);
      expect(shown(), isNull);
    });

    test('plays nothing when arming failed', () async {
      player.unlocks = false;

      final outcome = await tap(_song, _songPath);

      expect(outcome, PreviewOutcome.blocked);
      expect(player.plays, isEmpty);
      expect(player.preloaded, isEmpty);
    });

    test('loads its clip first, and says so meanwhile', () async {
      container.dispose();
      await open(slow);

      unawaited(tap(_song, _songPath));
      await settle();

      expect(shown(), const MixPreview('song', loading: true));
      expect(slow.plays, isEmpty);
      expect(slow.preloaded, [_songPath]);

      slow.finishLoading();
      await settle();

      expect(shown(), const MixPreview('song'));
      expect(slow.plays, hasLength(1));
    });

    test('that stops while it loads never plays', () async {
      container.dispose();
      await open(slow);
      unawaited(tap(_song, _songPath));
      await settle();

      await preview().stop();
      slow.finishLoading();
      await settle();

      expect(slow.plays, isEmpty);
      expect(shown(), isNull);
    });
  });

  group('Before "Arm alarms" (the user\'s choice, 2026-11-02)', () {
    test('a preview arms the alarms, in the tap', () async {
      expect(container.read(armingProvider).armed, isFalse);

      // Nothing to wait for before the unlock, or the browser would refuse.
      unawaited(tap(_song, _songPath));
      expect(player.unlockCalls, 1);
      await settle();

      expect(container.read(armingProvider).armed, isTrue);
      expect(wakeLock.held, isTrue);
      expect(player.preloaded, contains(_storedPath));
      expect(player.plays, hasLength(1));
    });

    test('a preview after that does not arm again', () async {
      await container.read(armingProvider.notifier).arm();
      await settle();

      unawaited(tap(_song, _songPath));
      await settle();

      expect(player.unlockCalls, 1);
      expect(player.plays, hasLength(1));
    });

    test('a platform that needs no tap only plays', () async {
      container.dispose();
      await open(FakeSoundPlayer(needsUnlock: false));

      unawaited(tap(_song, _songPath));
      await settle();

      expect(player.unlockCalls, 0);
      expect(player.plays, hasLength(1));
    });
  });

  group('Never while an alarm rings:', () {
    DueRing due() => DueRing(_alarm, scheduledFor: now);

    test(
      'a ring that starts ends the preview, and plays its own sound',
      () async {
        final outcome = tap(_song, _songPath);
        await settle();

        scheduler.ring(due());
        await settle();

        expect(shown(), isNull);
        expect(await outcome, PreviewOutcome.played);
        expect(player.plays.last.asset, _storedPath);
        // The ring's sound goes on: the preview does not stop it.
        expect(player.stopCalls, 0);
      },
    );

    test(
      'a preview that still loads never plays once a ring started',
      () async {
        container.dispose();
        await open(slow);
        unawaited(tap(_song, _songPath));
        await settle();

        scheduler.ring(due());
        await settle();
        final ringClips = slow.plays.length;
        slow.finishLoading();
        await settle();

        expect(shown(), isNull);
        expect(slow.plays, hasLength(ringClips));
        expect(slow.plays.single.asset, _storedPath);
      },
    );

    test('a tap during a ring plays nothing', () async {
      scheduler.ring(due());
      await settle();
      final before = player.plays.length;

      final outcome = await tap(_song, _songPath);

      expect(outcome, PreviewOutcome.notNow);
      expect(player.plays, hasLength(before));
      expect(shown(), isNull);
    });

    test(
      'a tap on a ring that went quiet, still open, plays nothing',
      () async {
        scheduler.ring(due());
        await settle();
        now = now.add(defaultRingCap);
        player.finishClip();
        await settle();
        expect(container.read(ringingProvider)?.over, isTrue);
        final before = player.plays.length;

        final outcome = await tap(_song, _songPath);

        expect(outcome, PreviewOutcome.notNow);
        expect(player.plays, hasLength(before));
      },
    );

    test('leaving a page after a ring started leaves the ring alone', () async {
      unawaited(tap(_song, _songPath));
      await settle();
      scheduler.ring(due());
      await settle();

      await preview().stop();

      expect(player.stopCalls, 0);
    });

    test('a preview can play again after Stop', () async {
      scheduler.ring(due());
      await settle();
      await container.read(ringingProvider.notifier).stop();
      await settle();

      unawaited(tap(_song, _songPath));
      await settle();

      expect(shown(), const MixPreview('song'));
    });
  });
}

final _alarm = Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0));

const _storedPath = 'assets/library/chime.wav';
final _stored = StoredSound(
  Sound(
    id: 'chime',
    title: 'Chime',
    source: SoundSource.builtin,
    genre: 'calm',
    intensity: 1,
    duration: const Duration(seconds: 20),
  ),
  audioPath: _storedPath,
);

const _songPath = 'sounds/song.mp3';

/// A song of 3 min, whose clip starts after 1 min: longer than a clip may be.
final _song = Sound(
  id: 'song',
  title: 'Song',
  source: SoundSource.user,
  genre: 'pop',
  intensity: 2,
  duration: const Duration(minutes: 3),
  clipStart: const Duration(minutes: 1),
);

const _voicePath = 'sounds/voice.webm';
final _voice = Sound(
  id: 'voice',
  title: 'Voice',
  source: SoundSource.voice,
  genre: 'voice',
  intensity: 1,
  duration: const Duration(seconds: 12),
);

/// A player whose first sound fails when the test says so, later than the
/// tap on another sound.
class _LateFailure extends FakeSoundPlayer {
  _LateFailure() : super(needsUnlock: false);

  final _failure = Completer<void>();
  var _first = true;

  @override
  Future<void> play(
    String asset, {
    required Duration from,
    required Duration to,
    required double volume,
  }) async {
    if (_first) {
      _first = false;
      await _failure.future;
      throw StateError('Cannot read $asset');
    }
    await super.play(asset, from: from, to: to, volume: volume);
  }

  void failNow() => _failure.complete();
}

/// A player whose sounds load until the test says so.
class _SlowPlayer extends FakeSoundPlayer {
  _SlowPlayer() : super(needsUnlock: false);

  Completer<void>? _loading;

  @override
  Future<void> preload(Iterable<String> assets) async {
    await super.preload(assets);
    final loading = _loading ??= Completer<void>();
    await loading.future;
  }

  void finishLoading() {
    final loading = _loading ??= Completer<void>();
    if (!loading.isCompleted) loading.complete();
  }
}
