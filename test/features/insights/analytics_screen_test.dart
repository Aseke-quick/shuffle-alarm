import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/fallback_tone.dart';
import 'package:shuffle_alarm/core/models/morning_answer.dart';
import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/morning_answer_repository.dart';
import 'package:shuffle_alarm/data/ring_session_repository.dart';
import 'package:shuffle_alarm/design/components/bar_chart.dart';
import 'package:shuffle_alarm/design/components/month_calendar.dart';
import 'package:shuffle_alarm/design/components/nav_bar.dart';
import 'package:shuffle_alarm/design/components/wordmark.dart';
import 'package:shuffle_alarm/features/insights/analytics_screen.dart';
import 'package:shuffle_alarm/router.dart';

import '../../data/memory_database.dart';
import '../../design/design_app.dart';
import '../alarms/alarms_app.dart';

void main() {
  late AppDatabase db;

  // Saturday noon.
  final now = DateTime(2026, 11, 14, 12);

  setUpAll(loadWakemixFonts);

  setUp(() {
    db = memoryDatabase();
    addTearDown(db.close);
  });

  /// Logs a ring at [at] that played the tone [clips] times, 20 s each: all
  /// but the last end in a Snooze of 5 min, the last in [last].
  Future<void> log(
    String id,
    DateTime at, {
    int clips = 1,
    RingAction last = RingAction.stop,
    bool answered = false,
  }) async {
    var time = at;
    final events = <RingEvent>[];
    for (var clip = 1; clip <= clips; clip++) {
      final end = time.add(const Duration(seconds: 20));
      events.add(
        RingEvent(
          soundId: fallbackTone.id,
          startedAt: time,
          endedAt: end,
          action: clip == clips ? last : RingAction.snooze,
        ),
      );
      time = end.add(const Duration(minutes: 5));
    }
    await RingSessionRepository(db).save(
      RingSession(id: id, alarmId: 'alarm', scheduledFor: at, events: events),
    );
    if (answered) {
      await MorningAnswerRepository(db).save(
        MorningAnswer(
          sessionId: id,
          soundId: fallbackTone.id,
          answeredAt: at.add(const Duration(minutes: 1)),
        ),
      );
    }
  }

  /// A week of mornings, and one in October.
  Future<void> logWeek() async {
    await log('oct', DateTime(2026, 10, 3, 7));
    await log('mon', DateTime(2026, 11, 9, 7), answered: true);
    await log('tue', DateTime(2026, 11, 10, 7), clips: 2, answered: true);
    await log('wed', DateTime(2026, 11, 11, 7), last: RingAction.timeout);
    await log('sat', DateTime(2026, 11, 14, 9));
  }

  Future<void> open(
    WidgetTester tester, {
    Size size = const Size(800, 2400),
  }) async {
    await openAlarms(tester, db: db, now: now, size: size);
    await tester.tap(
      find.descendant(
        of: find.byType(WakemixNavBar),
        matching: find.text('Analytics'),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The big number of the tile called [label].
  String figure(WidgetTester tester, String label) {
    final tile = find.ancestor(
      of: find.text(label),
      matching: find.byType(Column),
    );
    return tester
        .widget<Text>(
          find.descendant(of: tile.first, matching: find.byType(Text)).at(1),
        )
        .data!;
  }

  testWidgets('says so when no alarm has rung yet', (tester) async {
    await open(tester);

    expect(find.text('No mornings to show yet.'), findsOneWidget);
    expect(find.byType(MonthCalendar), findsNothing);
  });

  testWidgets('sums up the week of today, with the calendar of the month', (
    tester,
  ) async {
    await logWeek();
    await open(tester);

    expect(find.text('November 2026'), findsOneWidget);
    expect(find.text('Nov 9 – Nov 15'), findsOneWidget);
    expect(figure(tester, 'Got up'), '3');
    expect(find.text('1 missed'), findsOneWidget);
    // 20 s, 5 min 40 s and 20 s.
    expect(figure(tester, 'Alarm to Stop'), '2 min 6 s');
    expect(figure(tester, 'Snoozes'), '1');
    expect(figure(tester, 'Sounds played'), '5');
    expect(tester.widget<BarChart>(find.byType(BarChart)).bars, hasLength(7));
    expect(find.text('Wakes you best'), findsOneWidget);
    expect(find.text('Alarm tone'), findsOneWidget);
    expect(find.text('Named 2 times on the Morning card'), findsOneWidget);
  });

  testWidgets('says what happened on the chosen day: today at first', (
    tester,
  ) async {
    await logWeek();
    await open(tester);

    expect(find.text('Saturday, November 14, 2026'), findsOneWidget);
    expect(find.text('9:00 AM alarm'), findsOneWidget);
    expect(find.text('Got up at once, 20 s after the alarm'), findsOneWidget);
    expect(find.text('Played: Alarm tone'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp('^Tuesday, November 10')));
    await tester.pumpAndSettle();
    expect(find.text('Tuesday, November 10, 2026'), findsOneWidget);
    expect(
      find.text('Stop after 1 snooze, 5 min 40 s after the alarm'),
      findsOneWidget,
    );
    expect(find.text('Woke you: Alarm tone'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp('^Wednesday, November 11')));
    await tester.pumpAndSettle();
    expect(find.text('Missed: no Stop'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp('^Thursday, November 12')));
    await tester.pumpAndSettle();
    expect(find.text('No alarm rang on this day.'), findsOneWidget);
  });

  testWidgets('marks the days of the calendar, in words too', (tester) async {
    final semantics = tester.ensureSemantics();
    await logWeek();
    await open(tester);

    expect(tester.widget<MonthCalendar>(find.byType(MonthCalendar)).marks, {
      9: 1,
      10: 2,
      11: 3,
      14: 1,
    });
    for (final label in [
      'Monday, November 9, 2026, Got up at once',
      'Tuesday, November 10, 2026, Snoozed',
      'Wednesday, November 11, 2026, Missed',
      'Thursday, November 12, 2026, no alarm',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    semantics.dispose();
  });

  testWidgets('shows a day, a month and a year', (tester) async {
    await logWeek();
    await open(tester);

    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();
    expect(find.text('Sat, Nov 14'), findsOneWidget);
    expect(figure(tester, 'Got up'), '1');
    expect(find.text('none missed'), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
    expect(find.text('Not known yet'), findsOneWidget);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(figure(tester, 'Got up'), '3');
    expect(tester.widget<BarChart>(find.byType(BarChart)).bars, hasLength(30));

    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();
    expect(find.text('2026'), findsOneWidget);
    expect(figure(tester, 'Got up'), '4');
    expect(tester.widget<BarChart>(find.byType(BarChart)).bars, hasLength(12));
  });

  testWidgets('goes back to the month of the first ring, and no further', (
    tester,
  ) async {
    await logWeek();
    await open(tester);
    IconButton arrow(String tooltip) => tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip(tooltip),
        matching: find.byType(IconButton),
      ),
    );
    // No month after this one.
    expect(arrow('Next month').onPressed, isNull);

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('October 2026'), findsOneWidget);
    expect(arrow('Previous month').onPressed, isNull);
    // The chosen day stays until a day is tapped.
    expect(find.text('Saturday, November 14, 2026'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp('^Saturday, October 3,')));
    await tester.pumpAndSettle();
    expect(find.text('Saturday, October 3, 2026'), findsOneWidget);
    expect(find.text('7:00 AM alarm'), findsOneWidget);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('November 2026'), findsOneWidget);
  });

  testWidgets('reads the log again when the tab opens', (tester) async {
    await log('mon', DateTime(2026, 11, 9, 7));
    await open(tester);
    expect(figure(tester, 'Got up'), '1');

    await log('tue', DateTime(2026, 11, 10, 7));
    await tester.tap(
      find.descendant(
        of: find.byType(WakemixNavBar),
        matching: find.text('Alarms'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(WakemixNavBar),
        matching: find.text('Analytics'),
      ),
    );
    await tester.pumpAndSettle();

    expect(figure(tester, 'Got up'), '2');
  });

  testWidgets('the address of the Insights tab opens Analytics', (
    tester,
  ) async {
    await openAlarms(tester, db: db, now: now);

    ProviderScope.containerOf(tester.element(find.byType(WakemixNavBar)))
        .read(routerProvider)
        .go('/insights');
    await tester.pumpAndSettle();

    expect(find.byType(AnalyticsScreen), findsOneWidget);
  });

  testWidgets('fits a small phone with large text', (tester) async {
    await logWeek();
    setTextScale(tester, 2);
    await open(tester, size: const Size(360, 740));

    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    for (var offset = 0.0; ; offset += 200) {
      position.jumpTo(offset.clamp(0, position.maxScrollExtent));
      await tester.pump();
      if (offset >= position.maxScrollExtent) break;
    }
    for (final period in ['Day', 'Month', 'Year']) {
      position.jumpTo(0);
      await tester.pump();
      await tester.ensureVisible(find.text(period));
      await tester.tap(find.text(period));
      await tester.pumpAndSettle();
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out two columns under a top bar on a laptop', (
    tester,
  ) async {
    await logWeek();
    await open(tester, size: const Size(1280, 800));

    expect(
      tester.widget<WakemixNavBar>(find.byType(WakemixNavBar)).top,
      isTrue,
    );
    expect(find.byType(Wordmark), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    // The calendar on the left, the figures on the right, side by side.
    final calendar = tester.getRect(find.byType(MonthCalendar));
    final chart = tester.getRect(find.byType(BarChart));
    expect(calendar.right, lessThan(chart.left));
    expect(calendar.top, lessThan(chart.bottom));
    expect(tester.takeException(), isNull);

    setTextScale(tester, 2);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
