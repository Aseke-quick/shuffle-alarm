import 'package:shuffle_alarm/core/analytics.dart';
import 'package:shuffle_alarm/l10n/texts.dart';

/// A length of time in short words, such as "42 s", "5 min 40 s" and
/// "1 h 2 min". Seconds are left out from an hour on.
String spanText(Duration span) {
  final seconds = span.inSeconds;
  if (seconds < 60) return tr.spanSeconds(seconds);
  final minutes = span.inMinutes;
  if (minutes < 60) {
    final rest = seconds % 60;
    return rest == 0
        ? tr.spanMinutes(minutes)
        : '${tr.spanMinutes(minutes)} ${tr.spanSeconds(rest)}';
  }
  final rest = minutes % 60;
  return rest == 0
      ? tr.spanHours(span.inHours)
      : '${tr.spanHours(span.inHours)} ${tr.spanMinutes(rest)}';
}

/// The name of [period] on its key.
String periodName(AnalyticsPeriod period) => switch (period) {
  AnalyticsPeriod.day => tr.periodDay,
  AnalyticsPeriod.week => tr.periodWeek,
  AnalyticsPeriod.month => tr.periodMonth,
  AnalyticsPeriod.year => tr.periodYear,
};

/// What a [mark] means, such as in the legend of the calendar.
String markName(DayMark mark) => switch (mark) {
  DayMark.atOnce => tr.markAtOnce,
  DayMark.snoozed => tr.markSnoozed,
  DayMark.missed => tr.markMissed,
};

/// How [morning] went, in one line.
String morningLine(LoggedMorning morning) {
  final toStop = morning.toStop;
  if (toStop == null) return tr.morningMissed;
  final span = spanText(toStop);
  return morning.snoozes == 0
      ? tr.morningAtOnce(span)
      : tr.morningSnoozed(morning.snoozes, span);
}

/// "1 morning", "3 mornings".
String morningCount(int count) => tr.morningCount(count);

/// How often a sound was named on the Morning card.
String namedText(int count) => tr.namedOnCard(count);

/// What the chart of a period says, for screen readers.
String chartSummary(AnalyticsSummary summary) {
  final average = summary.averageToStop;
  return [
    tr.chartTitle,
    if (average == null) tr.chartNoStop else tr.chartAverage(spanText(average)),
    if (summary.missed > 0) tr.chartMissed(morningCount(summary.missed)),
  ].join(' ');
}
