import 'package:shuffle_alarm/core/models/alarm.dart';

/// When [alarm] rings next: the first time after [now] that the local clock
/// shows the alarm's time, on one of its repeat days, or on any day if it has
/// none. Null if the alarm is switched off.
///
/// The ring is after [now] also when [now] is the alarm's time to the
/// microsecond, so an alarm rings once a day at most: the ring after a ring
/// is the next one. It is in local time; [now] can be in UTC.
///
/// The days are days of the calendar, not 24 hours, so an alarm keeps its
/// clock time when the clock changes to or from daylight saving time. On the
/// day of the change, `DateTime` finds the moment, the same way on every
/// platform (docs/DECISIONS.md, task 2.2):
///
/// - A time the clock skips rings as much later as the clock jumps: when it
///   jumps from 02:00 to 03:00, 02:30 rings at 03:30.
/// - A time the clock shows twice, when it goes back an hour, rings the first
///   time only.
DateTime? nextRing(Alarm alarm, DateTime now) {
  if (!alarm.enabled) return null;
  final today = now.toLocal();
  // Every weekday comes once in the next 7 days, and the alarm's time a week
  // from today is after now.
  for (var days = 0; days <= DateTime.daysPerWeek; days++) {
    // In UTC, so that only the date counts.
    final weekday = DateTime.utc(
      today.year,
      today.month,
      today.day + days,
    ).weekday;
    if (alarm.repeatDays.isNotEmpty && !alarm.repeatDays.contains(weekday)) {
      continue;
    }
    final ring = DateTime(
      today.year,
      today.month,
      today.day + days,
      alarm.time.hour,
      alarm.time.minute,
    );
    if (ring.isAfter(now)) return ring;
  }
  throw StateError('No ring of $alarm found after $now');
}
