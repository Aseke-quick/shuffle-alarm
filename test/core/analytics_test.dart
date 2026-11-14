import 'package:flutter_test/flutter_test.dart';
import 'package:shuffle_alarm/core/analytics.dart';
import 'package:shuffle_alarm/core/models/morning_answer.dart';
import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';

/// A ring at [at] that played [sounds] one after the other, [seconds] each.
/// All but the last end in a Snooze; the last ends in [last].
RingSession ring(
  String id,
  DateTime at, {
  List<String> sounds = const ['a'],
  int seconds = 20,
  RingAction last = RingAction.stop,
}) {
  var time = at;
  final events = <RingEvent>[];
  for (final (index, sound) in sounds.indexed) {
    final end = time.add(Duration(seconds: seconds));
    events.add(
      RingEvent(
        soundId: sound,
        startedAt: time,
        endedAt: end,
        action: index == sounds.length - 1 ? last : RingAction.snooze,
      ),
    );
    // A snooze of 5 minutes.
    time = end.add(const Duration(minutes: 5));
  }
  return RingSession(
    id: id,
    alarmId: 'alarm',
    scheduledFor: at,
    events: events,
  );
}

MorningAnswer answer(String sessionId, String? soundId, DateTime at) =>
    MorningAnswer(sessionId: sessionId, soundId: soundId, answeredAt: at);

void main() {
  group('dayOf', () {
    test('is the start of the local day', () {
      expect(dayOf(DateTime(2026, 11, 14, 23, 59)), DateTime(2026, 11, 14));
      expect(dayOf(DateTime(2026, 11, 14)), DateTime(2026, 11, 14));
    });

    test('takes a UTC time to the local calendar', () {
      final local = DateTime(2026, 11, 14, 0, 30);
      expect(dayOf(local.toUtc()), DateTime(2026, 11, 14));
    });
  });

  group('periodBounds', () {
    // 2026-11-14 is a Saturday.
    final day = DateTime(2026, 11, 14);

    test('a day is that day', () {
      expect(periodBounds(AnalyticsPeriod.day, day), (
        DateTime(2026, 11, 14),
        DateTime(2026, 11, 15),
      ));
    });

    test('a week starts on Monday', () {
      expect(periodBounds(AnalyticsPeriod.week, day), (
        DateTime(2026, 11, 9),
        DateTime(2026, 11, 16),
      ));
      expect(periodBounds(AnalyticsPeriod.week, DateTime(2026, 11, 9)), (
        DateTime(2026, 11, 9),
        DateTime(2026, 11, 16),
      ));
      expect(periodBounds(AnalyticsPeriod.week, DateTime(2026, 11, 15)), (
        DateTime(2026, 11, 9),
        DateTime(2026, 11, 16),
      ));
    });

    test('a week can cross a month and a year', () {
      expect(periodBounds(AnalyticsPeriod.week, DateTime(2027)), (
        DateTime(2026, 12, 28),
        DateTime(2027, 1, 4),
      ));
    });

    test('a month and a year are those of the calendar', () {
      expect(periodBounds(AnalyticsPeriod.month, day), (
        DateTime(2026, 11),
        DateTime(2026, 12),
      ));
      expect(periodBounds(AnalyticsPeriod.month, DateTime(2026, 12, 31)), (
        DateTime(2026, 12),
        DateTime(2027),
      ));
      expect(periodBounds(AnalyticsPeriod.year, day), (
        DateTime(2026),
        DateTime(2027),
      ));
    });
  });

  group('LoggedMorning', () {
    final at = DateTime(2026, 11, 14, 7);

    test('a Stop with no Snooze is got up at once', () {
      final morning = LoggedMorning.of(ring('s', at));
      expect(morning.mark, DayMark.atOnce);
      expect(morning.day, DateTime(2026, 11, 14));
      expect(morning.toStop, const Duration(seconds: 20));
      expect(morning.snoozes, 0);
      expect(morning.soundsPlayed, 1);
      expect(morning.wokeSoundId, isNull);
    });

    test('a Stop after a Snooze is snoozed', () {
      final morning = LoggedMorning.of(ring('s', at, sounds: ['a', 'b', 'c']));
      expect(morning.mark, DayMark.snoozed);
      // Three clips of 20 s and two snoozes of 5 min.
      expect(morning.toStop, const Duration(minutes: 11));
      expect(morning.snoozes, 2);
      expect(morning.soundsPlayed, 3);
    });

    test('a ring that ran out, or has no end yet, is missed', () {
      final ranOut = LoggedMorning.of(ring('s', at, last: RingAction.timeout));
      expect(ranOut.mark, DayMark.missed);
      expect(ranOut.toStop, isNull);

      final open = LoggedMorning.of(ring('s', at, last: RingAction.snooze));
      expect(open.mark, DayMark.missed);
      expect(open.snoozes, 1);

      final empty = LoggedMorning.of(
        RingSession(id: 's', alarmId: 'alarm', scheduledFor: at),
      );
      expect(empty.mark, DayMark.missed);
      expect(empty.soundsPlayed, 0);
    });

    test('a silent event is not a sound played', () {
      final session = RingSession(
        id: 's',
        alarmId: 'alarm',
        scheduledFor: at,
        events: [
          RingEvent.silent(soundId: 'a', at: at, action: RingAction.stop),
        ],
      );
      final morning = LoggedMorning.of(session);
      expect(morning.soundsPlayed, 0);
      expect(morning.mark, DayMark.atOnce);
      expect(morning.toStop, Duration.zero);
    });

    test('keeps the sound of its answer', () {
      final morning = LoggedMorning.of(
        ring('s', at),
        answer: answer('s', 'a', at),
      );
      expect(morning.wokeSoundId, 'a');
    });
  });

  group('Analytics', () {
    // The week of Monday 2026-11-09.
    final monday = ring('mon', DateTime(2026, 11, 9, 7));
    final tuesday = ring('tue', DateTime(2026, 11, 10, 7), sounds: ['a', 'b']);
    final wednesday = ring(
      'wed',
      DateTime(2026, 11, 11, 7),
      last: RingAction.timeout,
    );
    final saturday = ring('sat', DateTime(2026, 11, 14, 9), seconds: 40);
    final lateSaturday = ring(
      'sat2',
      DateTime(2026, 11, 14, 15),
      sounds: ['c', 'a'],
    );
    final october = ring('oct', DateTime(2026, 10, 3, 7), seconds: 10);
    final lastYear = ring('old', DateTime(2025, 11, 14, 7));
    final sessions = [
      saturday,
      monday,
      lastYear,
      wednesday,
      october,
      tuesday,
      lateSaturday,
    ];
    final answers = [
      answer('mon', 'a', DateTime(2026, 11, 9, 7, 1)),
      answer('tue', 'b', DateTime(2026, 11, 10, 7, 6)),
      answer('sat', null, DateTime(2026, 11, 14, 9, 1)),
      answer('sat2', 'a', DateTime(2026, 11, 14, 15, 6)),
      answer('oct', 'z', DateTime(2026, 10, 3, 7, 1)),
      answer('gone', 'z', DateTime(2026, 11, 12)),
    ];
    final analytics = Analytics(sessions: sessions, answers: answers);
    final day = DateTime(2026, 11, 14);

    test('lists the mornings from the earliest', () {
      expect(analytics.mornings.map((morning) => morning.session.id), [
        'old',
        'oct',
        'mon',
        'tue',
        'wed',
        'sat',
        'sat2',
      ]);
      expect(analytics.isEmpty, isFalse);
      expect(Analytics(sessions: const [], answers: const []).isEmpty, isTrue);
    });

    test('marks each day with the worst of its mornings', () {
      expect(analytics.marks, {
        DateTime(2025, 11, 14): DayMark.atOnce,
        DateTime(2026, 10, 3): DayMark.atOnce,
        DateTime(2026, 11, 9): DayMark.atOnce,
        DateTime(2026, 11, 10): DayMark.snoozed,
        DateTime(2026, 11, 11): DayMark.missed,
        DateTime(2026, 11, 14): DayMark.snoozed,
      });
    });

    test('gives the mornings of a period', () {
      expect(
        analytics
            .of(AnalyticsPeriod.day, day)
            .map((morning) => morning.session.id),
        ['sat', 'sat2'],
      );
      expect(
        analytics.of(AnalyticsPeriod.day, DateTime(2026, 11, 13)),
        isEmpty,
      );
      expect(analytics.of(AnalyticsPeriod.week, day), hasLength(5));
      expect(analytics.of(AnalyticsPeriod.month, day), hasLength(5));
      expect(analytics.of(AnalyticsPeriod.year, day), hasLength(6));
    });

    test('sums up a week', () {
      final summary = analytics.summary(AnalyticsPeriod.week, day);
      expect(summary.gotUp, 4);
      expect(summary.missed, 1);
      // 20 s, 5 min 40 s, 40 s and 5 min 40 s.
      expect(summary.averageToStop, const Duration(seconds: 185));
      expect(summary.snoozes, 2);
      expect(summary.soundsPlayed, 7);
      // "a" was named twice, "b" once.
      expect(summary.bestSoundId, 'a');
      expect(summary.bestSoundCount, 2);
    });

    test('sums up a day, a month and a year', () {
      final ofDay = analytics.summary(AnalyticsPeriod.day, day);
      expect(ofDay.gotUp, 2);
      expect(ofDay.missed, 0);
      expect(ofDay.averageToStop, const Duration(seconds: 190));
      expect(ofDay.bestSoundId, 'a');
      expect(ofDay.bestSoundCount, 1);

      expect(analytics.summary(AnalyticsPeriod.month, day).gotUp, 4);
      final ofYear = analytics.summary(AnalyticsPeriod.year, day);
      expect(ofYear.gotUp, 5);
      expect(ofYear.soundsPlayed, 8);
    });

    test('an empty period has no average and no best sound', () {
      final summary = analytics.summary(
        AnalyticsPeriod.day,
        DateTime(2026, 11, 13),
      );
      expect(summary.gotUp, 0);
      expect(summary.missed, 0);
      expect(summary.averageToStop, isNull);
      expect(summary.snoozes, 0);
      expect(summary.soundsPlayed, 0);
      expect(summary.bestSoundId, isNull);
      expect(summary.bestSoundCount, 0);
    });

    test('a period of missed mornings only has no average', () {
      final summary = analytics.summary(
        AnalyticsPeriod.day,
        DateTime(2026, 11, 11),
      );
      expect(summary.missed, 1);
      expect(summary.averageToStop, isNull);
    });

    test('of two sounds named as often, the one named last is best', () {
      final tied = Analytics(
        sessions: [monday, tuesday],
        answers: [
          answer('mon', 'a', DateTime(2026, 11, 9, 7, 1)),
          answer('tue', 'b', DateTime(2026, 11, 10, 7, 6)),
        ],
      );
      final summary = tied.summary(AnalyticsPeriod.week, day);
      expect(summary.bestSoundId, 'b');
      expect(summary.bestSoundCount, 1);
    });

    test('charts a week per day', () {
      final chart = analytics.chart(AnalyticsPeriod.week, day);
      expect(chart.map((point) => point.start), [
        for (var date = 9; date <= 15; date++) DateTime(2026, 11, date),
      ]);
      expect(chart.map((point) => point.average), [
        const Duration(seconds: 20),
        const Duration(seconds: 340),
        null,
        null,
        null,
        const Duration(seconds: 190),
        null,
      ]);
      expect(chart[2].missed, 1);
      expect(chart[0].missed, 0);
    });

    test('charts a month per day and a year per month', () {
      final month = analytics.chart(AnalyticsPeriod.month, day);
      expect(month, hasLength(30));
      expect(month.first.start, DateTime(2026, 11));
      expect(month[13].average, const Duration(seconds: 190));

      final year = analytics.chart(AnalyticsPeriod.year, day);
      expect(year.map((point) => point.start), [
        for (var month = 1; month <= 12; month++) DateTime(2026, month),
      ]);
      expect(year[9].average, const Duration(seconds: 10));
      expect(year[10].average, const Duration(seconds: 185));
      expect(year[10].missed, 1);
      expect(year[0].average, isNull);
    });

    test('charts nothing for a day', () {
      expect(analytics.chart(AnalyticsPeriod.day, day), isEmpty);
    });

    test('a month of 31 days and a February have their days', () {
      expect(
        analytics.chart(AnalyticsPeriod.month, DateTime(2026, 12, 5)),
        hasLength(31),
      );
      expect(
        analytics.chart(AnalyticsPeriod.month, DateTime(2028, 2, 5)),
        hasLength(29),
      );
    });
  });

  group('daylight saving time', () {
    // Europe/Berlin: clocks go back on 2026-10-25, forward on 2026-03-29.
    final inBerlin =
        DateTime(2026, 3, 29, 12).difference(DateTime(2026, 3, 29)) ==
        const Duration(hours: 11);

    test('a week with a change of the clocks has seven days', () {
      final (start, end) = periodBounds(
        AnalyticsPeriod.week,
        DateTime(2026, 10, 25),
      );
      expect(start, DateTime(2026, 10, 19));
      expect(end, DateTime(2026, 10, 26));
      final chart = Analytics(
        sessions: [ring('s', DateTime(2026, 10, 25, 7))],
        answers: const [],
      ).chart(AnalyticsPeriod.week, DateTime(2026, 10, 25));
      expect(chart.map((point) => point.start.day), [
        19,
        20,
        21,
        22,
        23,
        24,
        25,
      ]);
      expect(chart.last.average, const Duration(seconds: 20));
    }, skip: inBerlin ? false : 'needs TZ=Europe/Berlin');
  });
}
