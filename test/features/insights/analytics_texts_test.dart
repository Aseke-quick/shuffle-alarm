import 'package:flutter_test/flutter_test.dart';
import 'package:shuffle_alarm/core/analytics.dart';
import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/features/insights/analytics_texts.dart';

void main() {
  test('spanText says a length of time in short words', () {
    expect(spanText(Duration.zero), '0 s');
    expect(spanText(const Duration(seconds: 42)), '42 s');
    expect(spanText(const Duration(minutes: 1)), '1 min');
    expect(spanText(const Duration(minutes: 5, seconds: 40)), '5 min 40 s');
    expect(spanText(const Duration(hours: 1)), '1 h');
    expect(
      spanText(const Duration(hours: 1, minutes: 2, seconds: 30)),
      '1 h 2 min',
    );
  });

  test('names the periods and the marks', () {
    expect(AnalyticsPeriod.values.map(periodName), [
      'Day',
      'Week',
      'Month',
      'Year',
    ]);
    expect(DayMark.values.map(markName), [
      'Got up at once',
      'Snoozed',
      'Missed',
    ]);
  });

  group('morningLine', () {
    final at = DateTime(2026, 11, 14, 7);
    LoggedMorning morning(List<RingAction> actions) {
      var time = at;
      return LoggedMorning.of(
        RingSession(
          id: 's',
          alarmId: 'a',
          scheduledFor: at,
          events: [
            for (final action in actions)
              RingEvent(
                soundId: 'x',
                startedAt: time,
                endedAt: time = time.add(const Duration(seconds: 30)),
                action: action,
              ),
          ],
        ),
      );
    }

    test('says how a morning went', () {
      expect(
        morningLine(morning([RingAction.stop])),
        'Got up at once, 30 s after the alarm',
      );
      expect(
        morningLine(morning([RingAction.snooze, RingAction.stop])),
        'Stop after 1 snooze, 1 min after the alarm',
      );
      expect(
        morningLine(
          morning([RingAction.snooze, RingAction.snooze, RingAction.stop]),
        ),
        'Stop after 2 snoozes, 1 min 30 s after the alarm',
      );
      expect(morningLine(morning([RingAction.timeout])), 'Missed: no Stop');
    });
  });

  test('counts mornings and answers in words', () {
    expect(morningCount(1), '1 morning');
    expect(morningCount(3), '3 mornings');
    expect(namedText(1), 'Named once on the Morning card');
    expect(namedText(4), 'Named 4 times on the Morning card');
  });

  test('chartSummary says the chart in words', () {
    AnalyticsSummary summary({Duration? average, int missed = 0}) =>
        AnalyticsSummary(
          gotUp: 1,
          missed: missed,
          averageToStop: average,
          snoozes: 0,
          soundsPlayed: 0,
          bestSoundId: null,
          bestSoundCount: 0,
        );
    expect(
      chartSummary(summary(average: const Duration(seconds: 90))),
      'Time from the alarm to Stop. On average 1 min 30 s.',
    );
    expect(
      chartSummary(summary(missed: 2)),
      'Time from the alarm to Stop. No Stop in this period. 2 mornings '
      'missed.',
    );
  });
}
