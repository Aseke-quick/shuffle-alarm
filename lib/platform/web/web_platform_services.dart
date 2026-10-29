import 'package:shuffle_alarm/platform/alarm_scheduler.dart';
import 'package:shuffle_alarm/platform/screen_wake_lock.dart';
import 'package:shuffle_alarm/platform/sound_player.dart';
import 'package:shuffle_alarm/platform/ticking_alarm_scheduler.dart';
import 'package:shuffle_alarm/platform/web/web_screen_wake_lock.dart';
import 'package:shuffle_alarm/platform/web/web_sound_player.dart';
import 'package:web/web.dart' as web;

/// The in-tab scheduler of the web version: it checks the clock every
/// second, and at once when the tab comes back into view, because a hidden
/// tab may run its timer once a minute only.
AlarmScheduler createAlarmScheduler() => TickingAlarmScheduler(
  wakeUps: web.document.onVisibilityChange.where(
    (_) => web.document.visibilityState == 'visible',
  ),
);

SoundPlayer createSoundPlayer() => WebSoundPlayer();

ScreenWakeLock createScreenWakeLock() => WebScreenWakeLock();
