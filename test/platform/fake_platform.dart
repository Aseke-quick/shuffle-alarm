import 'dart:async';

import 'package:shuffle_alarm/core/due_rings.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/platform/alarm_scheduler.dart';
import 'package:shuffle_alarm/platform/screen_wake_lock.dart';
import 'package:shuffle_alarm/platform/sound_player.dart';
import 'package:shuffle_alarm/platform/system_notifications.dart';

/// A scheduler that rings when a test says so ([ring]), like the one of the
/// web version, which rings alarms.
class FakeAlarmScheduler implements AlarmScheduler {
  FakeAlarmScheduler({this.ringsAlarms = true});

  @override
  final bool ringsAlarms;

  /// Each list of alarms it was given to watch, oldest first.
  final watched = <List<Alarm>>[];

  final _due = StreamController<DueRing>.broadcast(sync: true);

  @override
  void watch(List<Alarm> alarms) => watched.add(alarms);

  @override
  Stream<DueRing> get dueRings => _due.stream;

  /// Tells that [due] came due.
  void ring(DueRing due) => _due.add(due);

  // Not closed: widget tests run on fake time (docs/DECISIONS.md, 2.2).
  @override
  Future<void> dispose() async {}
}

/// One sound that a [FakeSoundPlayer] played.
typedef FakePlay = ({String asset, Duration from, Duration to, double volume});

/// A player that records what it plays. A clip plays until the test calls
/// [finishClip], or until [stop].
class FakeSoundPlayer implements SoundPlayer {
  FakeSoundPlayer({
    this.playsSounds = true,
    this.needsUnlock = true,
    this.unlocks = true,
    this.blocked = false,
  });

  @override
  bool playsSounds;

  @override
  bool needsUnlock;

  /// Whether [unlock] works.
  bool unlocks;

  /// Whether [play] throws, as a browser that blocks the sound.
  bool blocked;

  /// The assets that cannot be read: [play] throws for them.
  final broken = <String>{};

  int unlockCalls = 0;
  int stopCalls = 0;

  /// The assets it was asked to load ahead.
  final preloaded = <String>[];

  /// What it played, oldest first.
  final plays = <FakePlay>[];

  Completer<void>? _clip;

  @override
  Future<bool> unlock() async {
    unlockCalls++;
    if (unlocks) {
      needsUnlock = false;
      blocked = false;
    }
    return unlocks;
  }

  @override
  Future<void> preload(Iterable<String> assets) async =>
      preloaded.addAll(assets);

  @override
  Future<void> play(
    String asset, {
    required Duration from,
    required Duration to,
    required double volume,
  }) async {
    if (blocked) throw const SoundBlockedException();
    if (broken.contains(asset)) throw StateError('Cannot read $asset');
    plays.add((asset: asset, from: from, to: to, volume: volume));
    final clip = _clip = Completer<void>();
    await clip.future;
  }

  /// Ends the clip that plays, as if it reached its end.
  void finishClip() {
    final clip = _clip;
    _clip = null;
    if (clip != null && !clip.isCompleted) clip.complete();
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    finishClip();
  }

  @override
  Future<void> dispose() async {}
}

/// A wake lock that the test can let go of ([letGo]), as a browser does
/// while the tab is hidden.
class FakeScreenWakeLock implements ScreenWakeLock {
  FakeScreenWakeLock({this.supported = true});

  @override
  final bool supported;

  @override
  bool held = false;

  int holds = 0;
  int releases = 0;

  final _changes = StreamController<bool>.broadcast(sync: true);

  @override
  Stream<bool> get heldChanges => _changes.stream;

  @override
  Future<void> hold() async {
    holds++;
    if (supported && !held) {
      held = true;
      _changes.add(true);
    }
  }

  @override
  Future<void> release() async {
    releases++;
    if (held) {
      held = false;
      _changes.add(false);
    }
  }

  /// Lets go of the screen, as a browser while the tab is hidden.
  void letGo() {
    held = false;
    _changes.add(false);
  }

  @override
  Future<void> dispose() async {}
}

/// One notification that a [FakeSystemNotifications] showed.
typedef FakeNotification = ({String title, String body});

/// Notifications that record what they show, and a person who answers the
/// question as the test says: at once with [answer], or later with
/// [answerNow] when [waitsToAnswer] is set.
class FakeSystemNotifications implements SystemNotifications {
  FakeSystemNotifications({
    this.access = NotificationAccess.notAsked,
    this.answer = NotificationAccess.allowed,
    this.waitsToAnswer = false,
  });

  @override
  NotificationAccess access;

  /// What is true after the person answered the question.
  NotificationAccess answer;

  /// Whether the question stays open until [answerNow].
  bool waitsToAnswer;

  /// Whether [show] throws, as a browser that cannot show one.
  bool broken = false;

  int askCalls = 0;

  /// What it showed, oldest first.
  final shown = <FakeNotification>[];

  Completer<void>? _question;

  @override
  Future<NotificationAccess> ask() async {
    askCalls++;
    if (waitsToAnswer) {
      final question = _question = Completer<void>();
      await question.future;
    }
    return access = answer;
  }

  /// Answers the open question with [answer].
  void answerNow() => _question?.complete();

  @override
  Future<void> show({required String title, required String body}) async {
    if (broken) throw StateError('Cannot show a notification');
    shown.add((title: title, body: body));
  }
}
