import 'package:shuffle_alarm/core/analytics.dart';

/// A length of time in short words, such as "42 s", "5 min 40 s" and
/// "1 h 2 min". Seconds are left out from an hour on.
String spanText(Duration span) {
  final seconds = span.inSeconds;
  if (seconds < 60) return '$seconds s';
  final minutes = span.inMinutes;
  if (minutes < 60) {
    final rest = seconds % 60;
    return rest == 0 ? '$minutes min' : '$minutes min $rest s';
  }
  final rest = minutes % 60;
  return rest == 0 ? '${span.inHours} h' : '${span.inHours} h $rest min';
}

/// The name of [period] on its key.
String periodName(AnalyticsPeriod period) => switch (period) {
  AnalyticsPeriod.day => 'Day',
  AnalyticsPeriod.week => 'Week',
  AnalyticsPeriod.month => 'Month',
  AnalyticsPeriod.year => 'Year',
};

/// What a [mark] means, such as in the legend of the calendar.
String markName(DayMark mark) => switch (mark) {
  DayMark.atOnce => 'Got up at once',
  DayMark.snoozed => 'Snoozed',
  DayMark.missed => 'Missed',
};

/// How [morning] went, in one line.
String morningLine(LoggedMorning morning) {
  final toStop = morning.toStop;
  if (toStop == null) return 'Missed: no Stop';
  final after = '${spanText(toStop)} after the alarm';
  return switch (morning.snoozes) {
    0 => 'Got up at once, $after',
    1 => 'Stop after 1 snooze, $after',
    final snoozes => 'Stop after $snoozes snoozes, $after',
  };
}

/// "1 morning", "3 mornings".
String morningCount(int count) => count == 1 ? '1 morning' : '$count mornings';

/// How often a sound was named on the Morning card.
String namedText(int count) => count == 1
    ? 'Named once on the Morning card'
    : 'Named $count times on the Morning card';

/// What the chart of a period says, for screen readers.
String chartSummary(AnalyticsSummary summary) {
  final average = summary.averageToStop;
  return [
    'Time from the alarm to Stop.',
    if (average == null)
      'No Stop in this period.'
    else
      'On average ${spanText(average)}.',
    if (summary.missed > 0) '${morningCount(summary.missed)} missed.',
  ].join(' ');
}
