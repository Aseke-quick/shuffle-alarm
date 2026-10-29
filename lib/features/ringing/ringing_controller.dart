import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shuffle_alarm/core/due_rings.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/ring_position.dart';
import 'package:shuffle_alarm/core/ring_sequence.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/platform/providers.dart';
import 'package:shuffle_alarm/platform/sound_player.dart';

/// The alarm that rings now.
@immutable
class Ringing {
  const Ringing(this.due, {this.audible = true, this.over = false});

  /// The ring: which alarm, set for when.
  final DueRing due;

  /// Whether its sound plays. False when the platform blocks it, such as a
  /// browser that had no tap on "Arm alarms", or when no clip could be read.
  final bool audible;

  /// Whether it reached its time cap without a Stop, and went quiet: a
  /// missed alarm.
  final bool over;

  Ringing copyWith({bool? audible, bool? over}) =>
      Ringing(due, audible: audible ?? this.audible, over: over ?? this.over);

  @override
  bool operator ==(Object other) =>
      other is Ringing &&
      other.due == due &&
      other.audible == audible &&
      other.over == over;

  @override
  int get hashCode => Object.hash(due, audible, over);

  @override
  String toString() => 'Ringing($due, audible: $audible, over: $over)';
}

/// The alarm that rings now, or null.
final ringingProvider = NotifierProvider<RingingController, Ringing?>(
  RingingController.new,
);

/// Rings the alarms that come due (task 2.4).
///
/// It hands the alarms to the platform's `AlarmScheduler`. When one comes
/// due, it plays the alarm's ring sequence (`buildRingSequence`), one clip
/// after the other, from where the clock says (`ringPosition`), until Stop
/// or the time cap.
///
/// - A one-time alarm switches off when it comes due, so it rings once.
/// - A ring found after its time cap is over is missed: no sound.
/// - One ring at a time: an alarm that comes due while another rings does
///   not ring.
///
/// Task 2.5 builds the ringing screen, Snooze and the ring log on it.
class RingingController extends Notifier<Ringing?> {
  final _random = Random();

  /// Counts the playbacks. Stop and each new playback end the one before.
  var _playback = 0;
  var _starting = false;
  List<RingClip> _clips = const [];
  Map<String, String> _assets = const {};

  @override
  Ringing? build() {
    final scheduler = ref.watch(alarmSchedulerProvider);
    ref.listen(alarmsProvider, (_, next) {
      if (next.value case final alarms?) scheduler.watch(alarms);
    }, fireImmediately: true);
    final due = scheduler.dueRings.listen(_onDue);
    ref.onDispose(() {
      _playback++;
      unawaited(due.cancel());
    });
    return null;
  }

  void _onDue(DueRing due) {
    if (due.alarm.repeatDays.isEmpty) unawaited(_switchOff(due.alarm));
    if (state != null || _starting) return;
    _starting = true;
    unawaited(_start(due).whenComplete(() => _starting = false));
  }

  /// Switches off the one-time [alarm] that came due, unless the user
  /// changed its time or days since.
  Future<void> _switchOff(Alarm alarm) async {
    final alarms = ref.read(alarmRepositoryProvider);
    try {
      final now = await alarms.byId(alarm.id);
      if (now == null || now.time != alarm.time || now.repeatDays.isNotEmpty) {
        return;
      }
      await alarms.save(now.copyWith(enabled: false));
    } on Object catch (error) {
      debugPrint('Could not switch off the one-time alarm: $error');
    }
  }

  Future<void> _start(DueRing due) async {
    try {
      final sounds = await ref.read(soundRepositoryProvider).all();
      final weights = await ref.read(weightRepositoryProvider).load();
      _assets = {
        for (final stored in sounds) stored.sound.id: stored.audioPath,
      };
      _clips = sounds.isEmpty
          ? const []
          : buildRingSequence(
              due.alarm,
              [for (final stored in sounds) stored.sound],
              weights,
              _random.nextInt(1 << 30),
            );
    } on Object catch (error) {
      // It still rings, without sound: better seen than not at all.
      debugPrint('Could not make the ring sequence: $error');
      _clips = const [];
    }
    final elapsed = ref.read(nowProvider)().difference(due.scheduledFor);
    final missed = _clips.isEmpty
        ? elapsed >= defaultRingCap
        : ringPosition(_clips, elapsed) == null;
    // One line in the log for each ring, which says how late the check
    // found it: a tester can read it in the browser's console.
    debugPrint(
      '${missed ? 'Missed' : 'Ringing'} the alarm set for '
      '${due.scheduledFor}, found ${elapsed.inMilliseconds} ms after it',
    );
    if (missed || !ref.mounted) return;
    state = Ringing(due, audible: _clips.isNotEmpty);
    if (_clips.isNotEmpty) unawaited(_play(due));
  }

  /// Plays the clips of the ring from where the clock says, one after the
  /// other, until Stop or the time cap.
  Future<void> _play(DueRing due) async {
    final playback = ++_playback;
    final player = ref.read(soundPlayerProvider);
    final now = ref.read(nowProvider);
    unawaited(
      player.preload({for (final clip in _clips) ?_assets[clip.sound.id]}),
    );
    var next = 0;
    // Whether the last clip it tried could not be read, such as without a
    // network: a ring that ends so has made no sound, and is not over.
    var failed = false;
    while (playback == _playback) {
      final at = ringPosition(_clips, now().difference(due.scheduledFor));
      if (at == null) {
        failed = false;
        break;
      }
      // Never back to a clip that played, such as one that ended a moment
      // early; one that failed to play is skipped.
      final index = max(at.index, next);
      if (index >= _clips.length) break;
      final clip = _clips[index];
      final offset = index == at.index ? at.offset : Duration.zero;
      next = index + 1;
      final asset = _assets[clip.sound.id];
      if (asset == null) continue;
      try {
        await player.play(
          asset,
          from: clip.window.start + offset,
          to: clip.window.end,
          volume: clip.volume,
        );
        failed = false;
      } on SoundBlockedException {
        if (playback == _playback) state = state?.copyWith(audible: false);
        return;
      } on Object catch (error) {
        failed = true;
        debugPrint('Could not play ${clip.sound.id}: $error');
      }
    }
    if (playback != _playback) return;
    state = failed
        ? state?.copyWith(audible: false)
        : state?.copyWith(over: true);
  }

  /// Unlocks the sound and plays the ring from where the clock says. Call it
  /// from a tap, such as on "Play sound" when the browser blocked it.
  Future<void> playSound() async {
    final ringing = state;
    if (ringing == null || ringing.audible || _clips.isEmpty) return;
    if (!await ref.read(soundPlayerProvider).unlock()) return;
    if (!identical(state, ringing)) return;
    state = ringing.copyWith(audible: true);
    unawaited(_play(ringing.due));
  }

  /// Stops the ring.
  Future<void> stop() async {
    _playback++;
    state = null;
    await ref.read(soundPlayerProvider).stop();
  }
}
