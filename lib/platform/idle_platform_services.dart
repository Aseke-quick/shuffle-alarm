import 'package:shuffle_alarm/platform/alarm_scheduler.dart';
import 'package:shuffle_alarm/platform/screen_wake_lock.dart';
import 'package:shuffle_alarm/platform/sound_player.dart';

// The platforms where alarms do not ring yet: Android, iOS and the desktop,
// until Phases 4 to 6, and the Dart VM of the tests.

AlarmScheduler createAlarmScheduler() => const IdleAlarmScheduler();

SoundPlayer createSoundPlayer() => const SilentSoundPlayer();

ScreenWakeLock createScreenWakeLock() => const NoScreenWakeLock();
