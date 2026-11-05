import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/record.dart';
import 'package:shuffle_alarm/design/tokens.dart';

import '../design_app.dart';

void main() {
  group('The record hero', () {
    testWidgets('shows the next alarm on the label, and its details below', (
      tester,
    ) async {
      await pumpDesign(
        tester,
        const RecordHero(
          time: TimeOfDay(hour: 7, minute: 0),
          countdown: 'in 7 h 20 min',
          details: 'Work · Weekdays',
          note: 'Bed by 11:00 PM for 8 h of sleep',
          semanticsLabel: 'Next alarm 7:00 AM, in 7 h 20 min',
        ),
      );

      expect(find.text('7:00 AM'), findsOneWidget);
      expect(find.text('in 7 h 20 min'), findsOneWidget);
      expect(find.text('Work · Weekdays'), findsOneWidget);
      expect(find.text('Bed by 11:00 PM for 8 h of sleep'), findsOneWidget);
      // The countdown is the one accent on the Alarms tab.
      expect(
        tester.widget<Text>(find.text('in 7 h 20 min')).style!.color,
        WakemixColors.dark.accentText,
      );
    });

    testWidgets('is one image for screen readers, with its label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpDesign(
        tester,
        const RecordHero(
          time: TimeOfDay(hour: 7, minute: 0),
          countdown: 'in 7 h 20 min',
          semanticsLabel: 'Next alarm 7:00 AM, in 7 h 20 min',
        ),
      );

      expect(
        tester.getSemantics(
          find.bySemanticsLabel('Next alarm 7:00 AM, in 7 h 20 min'),
        ),
        matchesSemantics(
          label: 'Next alarm 7:00 AM, in 7 h 20 min',
          isImage: true,
        ),
      );
      // The texts on the label are not read twice.
      expect(find.bySemanticsLabel('7:00 AM'), findsNothing);
      semantics.dispose();
    });

    testWidgets('without a time is an empty record', (tester) async {
      await pumpDesign(tester, const RecordHero(title: 'No alarm set'));

      expect(find.text('No alarm set'), findsOneWidget);
      final art = tester.widget<RecordArt>(find.byType(RecordArt));
      expect(art.segments, isEmpty);
      expect(art.child, isNull);
    });

    testWidgets('shows the segments of its mix on the edge', (tester) async {
      const segments = [
        RecordSegment(length: Duration(seconds: 20), strength: 0),
        RecordSegment(length: Duration(seconds: 16)),
      ];
      await pumpDesign(
        tester,
        const RecordHero(
          time: TimeOfDay(hour: 7, minute: 0),
          segments: segments,
        ),
      );

      expect(
        tester.widget<RecordArt>(find.byType(RecordArt)).segments,
        segments,
      );
    });

    group('with a mix to open', () {
      Future<List<int>> pumpTappable(WidgetTester tester) async {
        final taps = [0];
        await pumpDesign(
          tester,
          RecordHero(
            time: const TimeOfDay(hour: 7, minute: 0),
            mixLabel: "Tonight's mix · 9 sounds",
            semanticsLabel: 'Next alarm 7:00 AM',
            onTap: () => taps[0]++,
          ),
        );
        return taps;
      }

      testWidgets('opens it with a tap on the record', (tester) async {
        final taps = await pumpTappable(tester);

        await tester.tap(find.byType(RecordArt));

        expect(taps.single, 1);
      });

      testWidgets('opens it with a tap on its line, 48 px tall', (
        tester,
      ) async {
        final taps = await pumpTappable(tester);

        await tester.tap(find.text("Tonight's mix · 9 sounds"));

        expect(taps.single, 1);
        final line = find.ancestor(
          of: find.text("Tonight's mix · 9 sounds"),
          matching: find.byType(InkWell),
        );
        expect(
          tester.getSize(line).height,
          greaterThanOrEqualTo(Layout.minTouchTarget),
        );
      });

      testWidgets('is one button for screen readers, which opens it', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        final taps = await pumpTappable(tester);
        final record = find.bySemanticsLabel('Next alarm 7:00 AM');

        expect(
          tester.getSemantics(record),
          matchesSemantics(
            label: 'Next alarm 7:00 AM',
            isButton: true,
            hasTapAction: true,
            isFocusable: true,
            hasFocusAction: true,
          ),
        );
        expect(find.bySemanticsLabel("Tonight's mix · 9 sounds"), findsNothing);
        expect(find.bySemanticsLabel('7:00 AM'), findsNothing);

        tester
            .getSemantics(record)
            .owner!
            .performAction(tester.getSemantics(record).id, SemanticsAction.tap);
        expect(taps.single, 1);
        semantics.dispose();
      });

      testWidgets('opens from the keyboard, with one stop', (tester) async {
        final taps = await pumpTappable(tester);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();

        expect(taps.single, 1);
        final line = find.ancestor(
          of: find.text("Tonight's mix · 9 sounds"),
          matching: find.byType(InkWell),
        );
        expect(tester.widget<InkWell>(line).canRequestFocus, isFalse);
      });
    });

    testWidgets('is at most 280 px wide, and fits a small screen', (
      tester,
    ) async {
      for (final (width, diameter) in [
        (1280.0, RecordHero.maxDiameter),
        (320.0, 320 - 2 * Layout.gutter - 2 * Space.s16),
      ]) {
        setScreenSize(tester, Size(width, 800));
        await pumpDesign(
          tester,
          const SingleChildScrollView(
            child: RecordHero(time: TimeOfDay(hour: 7, minute: 0)),
          ),
        );

        expect(
          tester.getSize(find.byType(RecordArt)),
          Size.square(diameter),
          reason: 'Screen $width px wide',
        );
      }
    });
  });

  group('drawRecordSegments', () {
    const center = Offset(100, 100);

    List<_Arc> draw(List<RecordSegment> segments) {
      final canvas = _RecordingCanvas();
      drawRecordSegments(
        canvas,
        center: center,
        radius: 100,
        width: 8,
        segments: segments,
        color: const Color(0xFF123456),
      );
      return canvas.arcs;
    }

    test("draws one arc per sound, in play order from 12 o'clock", () {
      final arcs = draw(const [
        RecordSegment(length: Duration(seconds: 20)),
        RecordSegment(length: Duration(seconds: 20)),
        RecordSegment(length: Duration(seconds: 20)),
        RecordSegment(length: Duration(seconds: 20)),
      ]);

      expect(arcs, hasLength(4));
      expect(arcs.first.start, closeTo(-math.pi / 2, 0.05));
      expect(arcs[1].start, closeTo(0, 0.05));
      expect(arcs[2].start, closeTo(math.pi / 2, 0.05));
      expect(arcs[3].start, closeTo(math.pi, 0.05));
      for (final arc in arcs) {
        expect(arc.paint.color, isSameColorAs(const Color(0xFF123456)));
      }
    });

    test('gives a longer clip a longer arc, by its share of the time', () {
      final arcs = draw(const [
        RecordSegment(length: Duration(seconds: 30)),
        RecordSegment(length: Duration(seconds: 10)),
      ]);

      // Each with a small gap of the same size.
      expect(arcs[0].sweep - arcs[1].sweep, closeTo(math.pi, 0.01));
      expect(arcs[0].sweep + arcs[1].sweep, closeTo(2 * math.pi, 0.2));
    });

    test('draws a stronger sound wider, along the same outer edge', () {
      final arcs = draw(const [
        RecordSegment(length: Duration(seconds: 20), strength: 0),
        RecordSegment(length: Duration(seconds: 20), strength: 0.5),
        RecordSegment(length: Duration(seconds: 20)),
      ]);

      expect([for (final arc in arcs) arc.paint.strokeWidth], [4, 6, 8]);
      for (final arc in arcs) {
        expect(arc.rect.center, center);
        expect(
          arc.rect.width / 2 + arc.paint.strokeWidth / 2,
          closeTo(100, 1e-9),
        );
      }
    });

    test('keeps a gap between arcs, however many there are', () {
      for (final count in [1, 2, 9, 200]) {
        final arcs = draw([
          for (var i = 0; i < count; i++)
            const RecordSegment(length: Duration(seconds: 20)),
        ]);

        expect(arcs, hasLength(count));
        for (final arc in arcs) {
          expect(arc.sweep, lessThan(2 * math.pi / count));
          expect(arc.sweep, greaterThan(0));
        }
      }
    });

    test('draws nothing without sounds', () {
      expect(draw(const []), isEmpty);
    });

    test('draws nothing when the sounds together have no length', () {
      // A clock that jumped back can leave a morning like this: an arc would
      // have no number for its angle.
      expect(
        draw(const [
          RecordSegment(length: Duration.zero),
          RecordSegment(length: Duration.zero),
        ]),
        isEmpty,
      );
    });

    test('leaves out only the sound without a length', () {
      final arcs = draw(const [
        RecordSegment(length: Duration.zero),
        RecordSegment(length: Duration(seconds: 20)),
      ]);

      expect(arcs.where((arc) => arc.sweep > 0), hasLength(1));
      for (final arc in arcs) {
        expect(arc.sweep.isNaN, isFalse);
      }
    });
  });

  test('segments are equal by their values', () {
    const a = RecordSegment(length: Duration(seconds: 20), strength: 0.5);

    expect(
      a,
      const RecordSegment(length: Duration(seconds: 20), strength: 0.5),
    );
    expect(
      a.hashCode,
      const RecordSegment(
        length: Duration(seconds: 20),
        strength: 0.5,
      ).hashCode,
    );
    expect(
      a,
      isNot(const RecordSegment(length: Duration(seconds: 21), strength: 0.5)),
    );
    expect(a, isNot(const RecordSegment(length: Duration(seconds: 20))));
  });
}

typedef _Arc = ({Rect rect, double start, double sweep, Paint paint});

/// A canvas that keeps its arcs.
class _RecordingCanvas implements Canvas {
  final arcs = <_Arc>[];

  @override
  void drawArc(
    Rect rect,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    Paint paint,
  ) => arcs.add((
    rect: rect,
    start: startAngle,
    sweep: sweepAngle,
    paint: paint,
  ));

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
