import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/platform/providers.dart';
import 'package:shuffle_alarm/platform/sound_player.dart';

/// Whether the alarms can make a sound. A browser plays sound only after a
/// tap, so the web version asks for a tap on "Arm alarms" (task 2.4).
@immutable
class Arming {
  const Arming({
    required this.needed,
    this.armed = false,
    this.failed = false,
    this.screenOn = false,
  });

  /// Whether this platform needs the tap: a browser, where alarms ring.
  final bool needed;

  /// Whether a tap unlocked the sound.
  final bool armed;

  /// Whether the last tap could not unlock the sound.
  final bool failed;

  /// Whether the screen is kept on now: while armed and an alarm is on.
  final bool screenOn;

  Arming copyWith({bool? armed, bool? failed, bool? screenOn}) => Arming(
    needed: needed,
    armed: armed ?? this.armed,
    failed: failed ?? this.failed,
    screenOn: screenOn ?? this.screenOn,
  );

  @override
  bool operator ==(Object other) =>
      other is Arming &&
      other.needed == needed &&
      other.armed == armed &&
      other.failed == failed &&
      other.screenOn == screenOn;

  @override
  int get hashCode => Object.hash(needed, armed, failed, screenOn);

  @override
  String toString() =>
      'Arming(needed: $needed, armed: $armed, failed: $failed, '
      'screenOn: $screenOn)';
}

final armingProvider = NotifierProvider<ArmController, Arming>(
  ArmController.new,
);

/// Arms the alarms: unlocks their sound with a tap, and then keeps the
/// screen on while an alarm is on, where the platform can.
class ArmController extends Notifier<Arming> {
  @override
  Arming build() {
    final player = ref.watch(soundPlayerProvider);
    final wakeLock = ref.watch(screenWakeLockProvider);
    final held = wakeLock.heldChanges.listen(
      (on) => state = state.copyWith(screenOn: on),
    );
    ref
      ..onDispose(() => unawaited(held.cancel()))
      ..listen(alarmsProvider, (_, next) {
        if (next.value case final alarms?) unawaited(_keepScreenOn(alarms));
      });
    return Arming(
      needed:
          ref.watch(alarmSchedulerProvider).ringsAlarms &&
          player.playsSounds &&
          player.needsUnlock,
    );
  }

  /// Unlocks the sound of the alarms. Call it from the tap on "Arm alarms":
  /// a browser lets a page unlock its sound only in a tap.
  ///
  /// Then it loads every sound into memory, so a ring needs no network: on
  /// the web a clip downloads only when it plays, and nothing keeps it
  /// offline (`.10x/decisions/sre/placeholder-library.md`).
  Future<void> arm() async {
    final player = ref.read(soundPlayerProvider);
    final unlocked = await player.unlock();
    state = state.copyWith(armed: unlocked, failed: !unlocked);
    if (unlocked) unawaited(_preload(player));
    await _keepScreenOn(ref.read(alarmsProvider).value ?? const []);
  }

  Future<void> _preload(SoundPlayer player) async {
    try {
      final sounds = await ref.read(soundRepositoryProvider).all();
      await player.preload([for (final stored in sounds) stored.audioPath]);
    } on Object catch (error) {
      // A ring loads its clips again when it starts.
      debugPrint('Could not load the sounds ahead: $error');
    }
  }

  /// Keeps the screen on while armed and an alarm is on: a browser may run
  /// a sleeping or hidden tab late, or not at all.
  Future<void> _keepScreenOn(List<Alarm> alarms) async {
    final wakeLock = ref.read(screenWakeLockProvider);
    if (state.armed && alarms.any((alarm) => alarm.enabled)) {
      await wakeLock.hold();
    } else {
      await wakeLock.release();
    }
    state = state.copyWith(screenOn: wakeLock.held);
  }
}
