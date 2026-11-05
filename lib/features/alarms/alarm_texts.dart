import 'package:shuffle_alarm/core/bedtime.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/sound.dart';

/// "Rings in 7 h 20 min": how long until an alarm rings, [untilRing],
/// rounded up to whole minutes.
///
/// Rounded up, as the clock counts: at 23:40:30 the clock shows 23:40, and an
/// alarm at 07:00 rings in 7 h 20 min. From 24 hours on it says days too,
/// such as "Rings in 1 d 2 h 5 min", and it leaves out the parts that are 0.
String ringsIn(Duration untilRing) => 'Rings in ${_untilRing(untilRing)}';

/// "in 7 h 20 min": the countdown on the record, rounded up like [ringsIn].
String countdownText(Duration untilRing) => 'in ${_untilRing(untilRing)}';

String _untilRing(Duration untilRing) =>
    _span((untilRing.inMicroseconds / Duration.microsecondsPerMinute).ceil());

/// [minutes] as "1 d 2 h 5 min", without the parts that are 0.
String _span(int minutes) {
  final days = minutes ~/ Duration.minutesPerDay;
  final hours = minutes % Duration.minutesPerDay ~/ Duration.minutesPerHour;
  final rest = minutes % Duration.minutesPerHour;
  return [
    if (days > 0) '$days d',
    if (hours > 0) '$hours h',
    if (rest > 0) '$rest min',
  ].join(' ');
}

/// The line of the sleep calculator for [advice] at [now].
///
/// Before the bedtime, "Bed by 10:30 PM for 8 h of sleep", with the day in
/// front of the time when the bedtime is not today, such as "Bed by Sun
/// 11:00 PM for 8 h of sleep". From the bedtime on, "Sleep now: 7 h 5 min".
/// [clock] writes a time of day as the device shows it.
String sleepText(
  SleepAdvice advice, {
  required DateTime now,
  required String Function(DateTime time) clock,
}) => switch (advice) {
  BedBy(:final bedtime, :final goal) =>
    'Bed by ${_dayUnlessToday(bedtime, now)}${clock(bedtime.toLocal())} '
        'for ${_span(goal.inMinutes)} of sleep',
  SleepNow(:final sleep) when sleep.inMinutes < 1 => 'Sleep now: under 1 min',
  SleepNow(:final sleep) => 'Sleep now: ${_span(sleep.inMinutes)}',
};

/// A sleep goal, such as "8 h".
String sleepGoalText(Duration goal) => _span(goal.inMinutes);

/// The title of the bedtime reminder's notification.
const bedtimeReminderTitle = 'Time for bed';

/// What the bedtime reminder says when it comes at [now] for the ring at
/// [ring], such as "Sleep now for 8 h before your 7:00 AM alarm."
///
/// To the nearest minute, so a reminder a moment after the bedtime says 8 h,
/// and one that came late says how long the night still is. [clock] writes a
/// time of day as the device shows it.
String bedtimeReminderBody({
  required DateTime ring,
  required DateTime now,
  required String Function(DateTime time) clock,
}) {
  final minutes =
      (ring.difference(now).inMilliseconds / Duration.millisecondsPerMinute)
          .round();
  return 'Sleep now for ${_span(minutes)} before your '
      '${clock(ring.toLocal())} alarm.';
}

/// When the bedtime reminder that is on comes next, as [advice] tells it:
/// "Next at 10:45 PM", with the day in front when it is not today, such as
/// "Next at Sun 11:00 PM".
String nextReminderText(
  SleepAdvice advice, {
  required DateTime now,
  required String Function(DateTime time) clock,
}) => switch (advice) {
  BedBy(:final bedtime) =>
    'Next at ${_dayUnlessToday(bedtime, now)}${clock(bedtime.toLocal())}',
  SleepNow() => 'The bedtime of your next alarm has passed',
};

/// "Sun " if [time] is on another day than [now], else nothing.
String _dayUnlessToday(DateTime time, DateTime now) {
  final (a, b) = (time.toLocal(), now.toLocal());
  final today = (a.year, a.month, a.day) == (b.year, b.month, b.day);
  return today ? '' : '${dayName(a.weekday)} ';
}

/// An alarm's label, if it has one, and how often it rings: "Work ·
/// Weekdays", or "Once".
String alarmDetails(Alarm alarm) => [
  if (alarm.label.isNotEmpty) alarm.label,
  repeatText(alarm.repeatDays),
].join(' · ');

/// How often an alarm with these [repeatDays] rings: "Once", "Every day",
/// "Weekdays", "Weekends", or its days from Monday on, such as
/// "Mon, Wed, Fri".
String repeatText(Set<int> repeatDays) {
  final days = repeatDays.toList()..sort();
  return switch (days) {
    [] => 'Once',
    [1, 2, 3, 4, 5, 6, 7] => 'Every day',
    [1, 2, 3, 4, 5] => 'Weekdays',
    [6, 7] => 'Weekends',
    _ => days.map(dayName).join(', '),
  };
}

/// The short name of a [DateTime.weekday]: "Mon" for 1 to "Sun" for 7.
String dayName(int weekday) => _dayNames[weekday - DateTime.monday];

/// The full name of a [DateTime.weekday]: "Monday" for 1 to "Sunday" for 7.
String fullDayName(int weekday) => _fullDayNames[weekday - DateTime.monday];

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const _fullDayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// A genre as the user reads it: its name in the library with a capital
/// first letter, such as "Pop" for `pop` and "Hip-hop" for `hip-hop`.
String genreName(String genre) =>
    genre.isEmpty ? genre : genre[0].toUpperCase() + genre.substring(1);

/// How many sounds these are: "9 sounds", or "1 sound".
String soundCount(int count) => count == 1 ? '1 sound' : '$count sounds';

/// The line under the record: "Tonight's mix · 9 sounds".
String mixCaption(int sounds) => "Tonight's mix · ${soundCount(sounds)}";

/// When a clip starts in a ring, as a tracklist says it: "1:15".
String clipStartText(Duration startsAt) {
  final seconds = (startsAt.inMilliseconds / Duration.millisecondsPerSecond)
      .round();
  final rest = seconds % Duration.secondsPerMinute;
  return '${seconds ~/ Duration.secondsPerMinute}:'
      '${rest.toString().padLeft(2, '0')}';
}

/// How long after the alarm at [alarmTime] someone woke, in the whole minutes
/// the clock shows: "4 min after your 7:00 AM alarm", or "Under 1 min after
/// your 7:00 AM alarm".
String wokeAfterText(Duration afterAlarm, {required String alarmTime}) {
  final minutes = afterAlarm.inMinutes;
  return '${minutes < 1 ? 'Under 1 min' : _span(minutes)} after your '
      '$alarmTime alarm';
}

/// The snoozes and the sounds of a morning: "1 snooze · 4 sounds", or only
/// "No snoozes" when no sound played.
String morningFacts({required int snoozes, required int sounds}) => [
  switch (snoozes) {
    0 => 'No snoozes',
    1 => '1 snooze',
    _ => '$snoozes snoozes',
  },
  if (sounds > 0) soundCount(sounds),
].join(' · ');

/// What a sound is: "Lo-fi · Gentle", "Your song" or "Voice message".
String soundDetails(Sound sound) => switch (sound.source) {
  SoundSource.builtin =>
    '${genreName(sound.genre)} · ${_strengths[sound.intensity - 1]}',
  SoundSource.user => 'Your song',
  SoundSource.voice => 'Voice message',
};

/// The word for each `Sound.intensity`, from gentle to strong.
const _strengths = ['Gentle', 'Medium', 'Strong'];
