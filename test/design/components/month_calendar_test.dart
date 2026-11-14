import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/bar_chart.dart';
import 'package:shuffle_alarm/design/components/month_calendar.dart';
import 'package:shuffle_alarm/design/tokens.dart';

import '../design_app.dart';

void main() {
  group('MonthCalendar', () {
    Future<List<Object>> pump(
      WidgetTester tester, {
      DateTime? month,
      Map<int, int> marks = const {},
      int? selected,
      int? today,
      bool ends = false,
    }) async {
      final taps = <Object>[];
      await pumpDesign(
        tester,
        Center(
          child: SizedBox(
            width: 360,
            child: MonthCalendar(
              month: month ?? DateTime(2026, 11, 14),
              marks: marks,
              selected: selected,
              today: today,
              dayLabel: (day) => 'Day $day',
              onDaySelected: taps.add,
              onPrevious: ends ? null : () => taps.add('previous'),
              onNext: ends ? null : () => taps.add('next'),
            ),
          ),
        ),
      );
      return taps;
    }

    Offset at(WidgetTester tester, int day) =>
        tester.getCenter(find.text('$day'));

    testWidgets('shows the month, Monday first', (tester) async {
      await pump(tester);

      expect(find.text('November 2026'), findsOneWidget);
      for (var day = 1; day <= 30; day++) {
        expect(find.text('$day'), findsOneWidget);
      }
      expect(find.text('31'), findsNothing);
      // 2026-11-01 is a Sunday: alone at the end of the first row.
      expect(at(tester, 1).dx, greaterThan(at(tester, 7).dx));
      expect(at(tester, 1).dy, lessThan(at(tester, 2).dy));
      // Monday the 2nd to Sunday the 8th are one row.
      expect(at(tester, 2).dy, at(tester, 8).dy);
      expect(at(tester, 2).dx, lessThan(at(tester, 3).dx));
      expect(at(tester, 9).dx, at(tester, 2).dx);
    });

    testWidgets('has the days of a leap February', (tester) async {
      await pump(tester, month: DateTime(2028, 2));

      expect(find.text('February 2028'), findsOneWidget);
      expect(find.text('29'), findsOneWidget);
      expect(find.text('30'), findsNothing);
    });

    testWidgets('a tap chooses a day, the arrows change the month', (
      tester,
    ) async {
      final taps = await pump(tester);

      await tester.tap(find.text('14'));
      await tester.tap(find.byTooltip('Previous month'));
      await tester.tap(find.byTooltip('Next month'));

      expect(taps, [14, 'previous', 'next']);
    });

    testWidgets('an arrow with no month to go to is off', (tester) async {
      await pump(tester, ends: true);

      for (final tooltip in ['Previous month', 'Next month']) {
        expect(
          tester
              .widget<IconButton>(
                find.ancestor(
                  of: find.byTooltip(tooltip),
                  matching: find.byType(IconButton),
                ),
              )
              .onPressed,
          isNull,
        );
      }
    });

    testWidgets('marks days with the color of their strength', (tester) async {
      await pump(tester, marks: const {9: 1, 10: 2, 11: 3}, selected: 10);

      Color? disc(int day) =>
          (tester
                      .widget<Container>(
                        find.ancestor(
                          of: find.text('$day'),
                          matching: find.byType(Container),
                        ),
                      )
                      .decoration!
                  as BoxDecoration)
              .color;
      expect(disc(9), WakemixColors.gentleFill);
      expect(disc(10), WakemixColors.mediumFill);
      expect(disc(11), WakemixColors.strongFill);
      expect(disc(12), isNull);
      expect(
        tester.widget<Text>(find.text('9')).style!.color,
        WakemixColors.onStrength,
      );
    });

    testWidgets('each day is a button for screen readers, by its label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, selected: 14);

      expect(
        tester.getSemantics(find.bySemanticsLabel('Day 14')),
        matchesSemantics(
          label: 'Day 14',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      expect(find.bySemanticsLabel('Day 30'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('fits a small phone with large text', (tester) async {
      setScreenSize(tester, const Size(320, 740));
      setTextScale(tester, 2);
      await pump(tester, marks: const {9: 1}, selected: 9, today: 14);

      expect(tester.takeException(), isNull);
    });
  });

  group('BarChart', () {
    Future<void> pump(WidgetTester tester, List<ChartBar> bars) => pumpDesign(
      tester,
      Center(
        child: SizedBox(
          width: 300,
          child: BarChart(bars: bars, semanticsLabel: 'Time to Stop'),
        ),
      ),
    );

    /// The heights of the bars, from the left.
    List<double> heights(WidgetTester tester) => [
      for (final bar
          in find
              .byWidgetPredicate(
                (widget) =>
                    widget is Container &&
                    (widget.decoration as BoxDecoration?)?.borderRadius != null,
              )
              .evaluate())
        tester.getSize(find.byWidget(bar.widget)).height,
    ];

    testWidgets('draws each bar as tall as its value, of the tallest', (
      tester,
    ) async {
      await pump(tester, const [
        ChartBar(value: 30, label: 'M'),
        ChartBar(value: 60, label: 'T'),
        ChartBar(label: 'W'),
        ChartBar(value: 0, label: 'T'),
      ]);

      expect(heights(tester), [66, 132, 3, 3]);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('T'), findsNWidgets(2));
    });

    testWidgets('marks a flagged bar with a dot', (tester) async {
      await pump(tester, const [ChartBar(value: 30), ChartBar(flagged: true)]);

      final dots = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            (widget.decoration as BoxDecoration?)?.shape == BoxShape.circle,
      );
      expect(dots, findsOneWidget);
      expect(
        (tester.widget<Container>(dots).decoration! as BoxDecoration).color,
        WakemixColors.dark.strong,
      );
    });

    testWidgets('draws no bars and no values without a fault', (tester) async {
      await pump(tester, const []);
      expect(tester.takeException(), isNull);

      await pump(tester, const [ChartBar(), ChartBar()]);
      expect(heights(tester), [3, 3]);
    });

    testWidgets('says what it shows to screen readers, as one image', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, const [ChartBar(value: 30, label: 'M')]);

      expect(
        tester.getSemantics(find.bySemanticsLabel('Time to Stop')),
        matchesSemantics(label: 'Time to Stop', isImage: true),
      );
      semantics.dispose();
    });
  });
}
