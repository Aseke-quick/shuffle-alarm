import 'package:meta/meta.dart';

import 'package:shuffle_alarm/core/models/morning_answer.dart';
import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/core/morning.dart';

/// How a morning went, from the best to the worst.
enum DayMark {
  /// Stop with no Snooze before it.
  atOnce,

  /// Stop after one or more snoozes.
  snoozed,

  /// No Stop: the ring ran out, or was left.
  missed,
}

/// The span of time that Analytics sums up.
enum AnalyticsPeriod { day, week, month, year }

/// The day of the local calendar that holds [time], as its midnight.
DateTime dayOf(DateTime time) {
  final local = time.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// The first day of the [period] that holds [day], and the first day after
/// it. A week starts on Monday.
///
/// Days are counted on the calendar, not in hours, so a day of 23 or 25 hours
/// (daylight saving time) is one day.
(DateTime start, DateTime end) periodBounds(
  AnalyticsPeriod period,
  DateTime day,
) {
  final date = dayOf(day);
  return switch (period) {
    AnalyticsPeriod.day => (
      date,
      DateTime(date.year, date.month, date.day + 1),
    ),
    AnalyticsPeriod.week => (
      DateTime(date.year, date.month, date.day - (date.weekday - 1)),
      DateTime(date.year, date.month, date.day - (date.weekday - 1) + 7),
    ),
    AnalyticsPeriod.month => (
      DateTime(date.year, date.month),
      DateTime(date.year, date.month + 1),
    ),
    AnalyticsPeriod.year => (DateTime(date.year), DateTime(date.year + 1)),
  };
}

/// One ring of the log, as Analytics reads it.
@immutable
class LoggedMorning {
  const LoggedMorning._({
    required this.session,
    required this.day,
    required this.mark,
    required this.toStop,
    required this.snoozes,
    required this.soundsPlayed,
    required this.wokeSoundId,
  });

  /// Reads [session], with the [answer] of its Morning card when there is one.
  factory LoggedMorning.of(RingSession session, {MorningAnswer? answer}) {
    final morning = Morning.of(session);
    final snoozes = session.events
        .where((event) => event.action == RingAction.snooze)
        .length;
    return LoggedMorning._(
      session: session,
      day: dayOf(session.scheduledFor),
      mark: morning == null
          ? DayMark.missed
          : snoozes == 0
          ? DayMark.atOnce
          : DayMark.snoozed,
      toStop: morning?.afterAlarm,
      snoozes: snoozes,
      soundsPlayed: session.events.where((event) => event.played).length,
      wokeSoundId: answer?.soundId,
    );
  }

  final RingSession session;

  /// The local day the alarm was set to ring on.
  final DateTime day;
  final DayMark mark;

  /// From the alarm to Stop. Null for a missed morning.
  final Duration? toStop;
  final int snoozes;

  /// How many clips played, a sound that came twice counted twice.
  final int soundsPlayed;

  /// The sound named on the Morning card. Null with no answer, or "Not sure".
  final String? wokeSoundId;
}

/// The figures of a period.
@immutable
class AnalyticsSummary {
  const AnalyticsSummary({
    required this.gotUp,
    required this.missed,
    required this.averageToStop,
    required this.snoozes,
    required this.soundsPlayed,
    required this.bestSoundId,
    required this.bestSoundCount,
  });

  /// Mornings that ended in Stop.
  final int gotUp;
  final int missed;

  /// The average time from the alarm to Stop. Null with no Stop.
  final Duration? averageToStop;
  final int snoozes;
  final int soundsPlayed;

  /// The sound named most often on the Morning card: of two named as often,
  /// the one named last. Null when none was named.
  final String? bestSoundId;

  /// How often [bestSoundId] was named.
  final int bestSoundCount;
}

/// One bar of the chart: a day, or a month of a year.
@immutable
class ChartPoint {
  const ChartPoint({
    required this.start,
    required this.average,
    required this.missed,
  });

  /// The day, or the first day of the month.
  final DateTime start;

  /// The average time from the alarm to Stop. Null with no Stop.
  final Duration? average;

  /// How many mornings were missed.
  final int missed;
}

/// What the ring log and the answers of the Morning card say about the
/// user's mornings (ADR-005).
class Analytics {
  Analytics({
    required List<RingSession> sessions,
    required List<MorningAnswer> answers,
  }) : mornings = _read(sessions, answers) {
    for (final morning in mornings) {
      final before = marks[morning.day];
      if (before == null || morning.mark.index > before.index) {
        marks[morning.day] = morning.mark;
      }
    }
  }

  /// Every ring of the log, from the earliest.
  final List<LoggedMorning> mornings;

  /// The mark of each day an alarm rang on: the worst of its mornings.
  final Map<DateTime, DayMark> marks = {};

  /// Whether no alarm has rung yet.
  bool get isEmpty => mornings.isEmpty;

  static List<LoggedMorning> _read(
    List<RingSession> sessions,
    List<MorningAnswer> answers,
  ) {
    final bySession = {for (final answer in answers) answer.sessionId: answer};
    final sorted = [...sessions]
      ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    return List.unmodifiable([
      for (final session in sorted)
        LoggedMorning.of(session, answer: bySession[session.id]),
    ]);
  }

  List<LoggedMorning> _between(DateTime start, DateTime end) => [
    for (final morning in mornings)
      if (!morning.day.isBefore(start) && morning.day.isBefore(end)) morning,
  ];

  /// The mornings of the [period] that holds [day].
  List<LoggedMorning> of(AnalyticsPeriod period, DateTime day) {
    final (start, end) = periodBounds(period, day);
    return _between(start, end);
  }

  /// The figures of the [period] that holds [day].
  AnalyticsSummary summary(AnalyticsPeriod period, DateTime day) {
    final inPeriod = of(period, day);
    final named = <String, int>{};
    String? best;
    for (final morning in inPeriod) {
      final sound = morning.wokeSoundId;
      if (sound == null) continue;
      final count = named[sound] = (named[sound] ?? 0) + 1;
      // From the earliest: with as many, the later one wins.
      if (best == null || count >= named[best]!) best = sound;
    }
    return AnalyticsSummary(
      gotUp: inPeriod.where((morning) => morning.mark != DayMark.missed).length,
      missed: _missed(inPeriod),
      averageToStop: _average(inPeriod),
      snoozes: inPeriod.fold(0, (sum, morning) => sum + morning.snoozes),
      soundsPlayed: inPeriod.fold(
        0,
        (sum, morning) => sum + morning.soundsPlayed,
      ),
      bestSoundId: best,
      bestSoundCount: best == null ? 0 : named[best]!,
    );
  }

  /// The bars of the [period] that holds [day]: one per day of a week or a
  /// month, one per month of a year, none for a day.
  List<ChartPoint> chart(AnalyticsPeriod period, DateTime day) {
    if (period == AnalyticsPeriod.day) return const [];
    final (start, end) = periodBounds(period, day);
    final byMonth = period == AnalyticsPeriod.year;
    final points = <ChartPoint>[];
    var from = start;
    while (from.isBefore(end)) {
      final to = byMonth
          ? DateTime(from.year, from.month + 1)
          : DateTime(from.year, from.month, from.day + 1);
      final inBar = _between(from, to);
      points.add(
        ChartPoint(
          start: from,
          average: _average(inBar),
          missed: _missed(inBar),
        ),
      );
      from = to;
    }
    return points;
  }

  static int _missed(List<LoggedMorning> mornings) =>
      mornings.where((morning) => morning.mark == DayMark.missed).length;

  static Duration? _average(List<LoggedMorning> mornings) {
    final times = [for (final morning in mornings) ?morning.toStop];
    if (times.isEmpty) return null;
    final sum = times.fold(Duration.zero, (sum, time) => sum + time);
    return Duration(microseconds: sum.inMicroseconds ~/ times.length);
  }
}
