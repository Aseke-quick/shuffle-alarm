import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shuffle_alarm/platform/alarm_scheduler.dart';
import 'package:shuffle_alarm/platform/idle_platform_services.dart'
    if (dart.library.js_interop) 'package:shuffle_alarm/platform/web/web_platform_services.dart';
import 'package:shuffle_alarm/platform/screen_wake_lock.dart';
import 'package:shuffle_alarm/platform/sound_player.dart';

/// The [AlarmScheduler] of the platform the app runs on. Tests override it.
final alarmSchedulerProvider = Provider<AlarmScheduler>((ref) {
  final scheduler = createAlarmScheduler();
  ref.onDispose(() => unawaited(scheduler.dispose()));
  return scheduler;
});

/// The [SoundPlayer] of the platform the app runs on. Tests override it.
final soundPlayerProvider = Provider<SoundPlayer>((ref) {
  final player = createSoundPlayer();
  ref.onDispose(() => unawaited(player.dispose()));
  return player;
});

/// The [ScreenWakeLock] of the platform the app runs on. Tests override it.
final screenWakeLockProvider = Provider<ScreenWakeLock>((ref) {
  final wakeLock = createScreenWakeLock();
  ref.onDispose(() => unawaited(wakeLock.dispose()));
  return wakeLock;
});
