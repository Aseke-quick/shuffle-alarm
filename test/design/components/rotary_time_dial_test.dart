import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/rotary_time_dial.dart';

import '../design_app.dart';

void main() {
  group('Dragging the dial', () {
    testWidgets('puts the knob, and the minute, where the finger points', (
      tester,
    ) async {
      final dial = await _pumpDial(tester, const TimeOfDay(hour: 6, minute: 0));

      final gesture = await tester.startGesture(dial.at(10));
      await gesture.moveTo(dial.at(15));
      await tester.pump();
      expect(dial.time, const TimeOfDay(hour: 6, minute: 15));
      expect(find.text('6:15 AM'), findsOneWidget);

      await dial.turn(gesture, from: 15, to: 45);
      await gesture.up();
      await tester.pump();

      expect(dial.time, const TimeOfDay(hour: 6, minute: 45));
      expect(find.text('6:45 AM'), findsOneWidget);
    });

    testWidgets("clockwise past 12 o'clock goes on to the next hour", (
      tester,
    ) async {
      final dial = await _pumpDial(
        tester,
        const TimeOfDay(hour: 6, minute: 50),
      );

      final gesture = await tester.startGesture(dial.at(49));
      await dial.turn(gesture, from: 50, to: 70);
      await gesture.up();

      expect(dial.time, const TimeOfDay(hour: 7, minute: 10));
    });

    testWidgets("counter-clockwise past 12 o'clock goes to the hour before", (
      tester,
    ) async {
      final dial = await _pumpDial(
        tester,
        const TimeOfDay(hour: 7, minute: 10),
      );

      final gesture = await tester.startGesture(dial.at(11));
      await dial.turn(gesture, from: 10, to: -10);
      await gesture.up();

      expect(dial.time, const TimeOfDay(hour: 6, minute: 50));
    });

    testWidgets('turns over midnight, both ways', (tester) async {
      final dial = await _pumpDial(
        tester,
        const TimeOfDay(hour: 23, minute: 55),
      );

      var gesture = await tester.startGesture(dial.at(54));
      await dial.turn(gesture, from: 55, to: 65);
      await gesture.up();
      expect(dial.time, const TimeOfDay(hour: 0, minute: 5));

      gesture = await tester.startGesture(dial.at(6));
      await dial.turn(gesture, from: 5, to: -5);
      await gesture.up();
      expect(dial.time, const TimeOfDay(hour: 23, minute: 55));
    });

    testWidgets('turns two whole hours in two turns', (tester) async {
      final dial = await _pumpDial(tester, const TimeOfDay(hour: 5, minute: 0));

      final gesture = await tester.startGesture(dial.at(59));
      await dial.turn(gesture, from: 0, to: 120);
      await gesture.up();

      expect(dial.time, const TimeOfDay(hour: 7, minute: 0));
    });

    testWidgets('in the middle does not turn it', (tester) async {
      final dial = await _pumpDial(tester, const TimeOfDay(hour: 6, minute: 0));

      final gesture = await tester.startGesture(dial.at(10, radius: 40));
      await gesture.moveTo(dial.at(30, radius: 40));
      await gesture.up();
      await tester.pump();

      expect(dial.time, const TimeOfDay(hour: 6, minute: 0));
    });

    testWidgets('in a list turns the dial, and does not scroll the list', (
      tester,
    ) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final dial = await _pumpDial(
        tester,
        const TimeOfDay(hour: 6, minute: 15),
        inList: scroll,
      );

      // At 3 o'clock the finger moves straight down, as in a scroll.
      final gesture = await tester.startGesture(dial.at(14));
      await dial.turn(gesture, from: 15, to: 20);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(dial.time, const TimeOfDay(hour: 6, minute: 20));
      expect(scroll.offset, 0);

      // Elsewhere the list still scrolls.
      await tester.drag(find.text('Below the dial'), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(scroll.offset, greaterThan(0));
    });

    testWidgets(
      'ticks every 5 minutes on a phone',
      (tester) async {
        final ticks = _countHaptics(tester);
        final dial = await _pumpDial(
          tester,
          const TimeOfDay(hour: 6, minute: 0),
        );

        final gesture = await tester.startGesture(dial.at(59));
        await dial.turn(gesture, from: 0, to: 12);
        await gesture.up();

        expect(dial.time, const TimeOfDay(hour: 6, minute: 12));
        // At 6:05 and at 6:10.
        expect(ticks(), switch (defaultTargetPlatform) {
          TargetPlatform.android || TargetPlatform.iOS => 2,
          _ => 0,
        });
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      }),
    );
  });

  group('The keyboard', () {
    testWidgets('changes the time by a minute or an hour', (tester) async {
      final dial = await _pumpDial(
        tester,
        const TimeOfDay(hour: 6, minute: 45),
      );
      // The dial comes first in the focus order.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      for (final (key, time) in [
        (LogicalKeyboardKey.arrowUp, const TimeOfDay(hour: 6, minute: 46)),
        (LogicalKeyboardKey.arrowRight, const TimeOfDay(hour: 6, minute: 47)),
        (LogicalKeyboardKey.arrowDown, const TimeOfDay(hour: 6, minute: 46)),
        (LogicalKeyboardKey.arrowLeft, const TimeOfDay(hour: 6, minute: 45)),
        (LogicalKeyboardKey.pageUp, const TimeOfDay(hour: 7, minute: 45)),
        (LogicalKeyboardKey.pageDown, const TimeOfDay(hour: 6, minute: 45)),
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pump();
        expect(dial.time, time, reason: '$key');
      }
    });

    testWidgets('turns over midnight', (tester) async {
      final dial = await _pumpDial(
        tester,
        const TimeOfDay(hour: 23, minute: 59),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(dial.time, const TimeOfDay(hour: 0, minute: 0));
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      expect(dial.time, const TimeOfDay(hour: 23, minute: 0));
    });
  });

  group('For screen readers', () {
    testWidgets('the dial is an adjustable value', (tester) async {
      final semantics = tester.ensureSemantics();
      final dial = await _pumpDial(
        tester,
        const TimeOfDay(hour: 6, minute: 45),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Alarm time')),
        matchesSemantics(
          label: 'Alarm time',
          value: '6:45 AM',
          increasedValue: '6:46 AM',
          decreasedValue: '6:44 AM',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );

      tester.semantics.increase(find.semantics.byLabel('Alarm time'));
      await tester.pump();
      expect(dial.time, const TimeOfDay(hour: 6, minute: 46));

      for (var i = 0; i < 2; i++) {
        tester.semantics.decrease(find.semantics.byLabel('Alarm time'));
        await tester.pump();
      }
      expect(dial.time, const TimeOfDay(hour: 6, minute: 44));
      semantics.dispose();
    });

    testWidgets('the time is a button that opens keyboard entry', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpDial(tester, const TimeOfDay(hour: 6, minute: 45));

      expect(
        tester.getSemantics(find.bySemanticsLabel('Type the time')),
        matchesSemantics(
          label: 'Type the time',
          isButton: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('uses the 24-hour clock where the device does', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpDial(
        tester,
        const TimeOfDay(hour: 18, minute: 5),
        use24HourFormat: true,
      );

      expect(find.text('18:05'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Alarm time')),
        matchesSemantics(
          label: 'Alarm time',
          value: '18:05',
          increasedValue: '18:06',
          decreasedValue: '18:04',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );
      semantics.dispose();
    });
  });

  group('A tap on the time', () {
    testWidgets('opens the time picker for typing, and takes the time', (
      tester,
    ) async {
      final dial = await _pumpDial(
        tester,
        const TimeOfDay(hour: 6, minute: 45),
      );

      await tester.tap(find.byTooltip('Type the time'));
      await tester.pumpAndSettle();

      // Typing only: no dial in the picker, and no switch to one.
      expect(find.byType(TimePickerDialog), findsOneWidget);
      expect(find.byTooltip('Switch to dial picker mode'), findsNothing);
      final fields = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), '7');
      await tester.enterText(fields.at(1), '05');
      await tester.tap(find.text('PM'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(dial.time, const TimeOfDay(hour: 19, minute: 5));
      expect(find.text('7:05 PM'), findsOneWidget);
    });

    testWidgets('keeps the time when the picker is cancelled', (tester) async {
      final dial = await _pumpDial(
        tester,
        const TimeOfDay(hour: 6, minute: 45),
      );

      await tester.tap(find.byTooltip('Type the time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(dial.time, const TimeOfDay(hour: 6, minute: 45));
    });
  });
}

/// A dial on a page, with the time it was last changed to.
class _Dial {
  _Dial(this.tester, this.time);

  final WidgetTester tester;
  TimeOfDay time;

  Offset get center => tester.getCenter(find.byType(RotaryTimeDial));

  /// The point on the ring at [minute] of the hour, [radius] px from the
  /// middle. The ring takes drags from 102 to 160 px out.
  Offset at(num minute, {double radius = 130}) {
    final angle = minute / 60 * 2 * math.pi;
    return center + Offset(math.sin(angle), -math.cos(angle)) * radius;
  }

  /// Moves [gesture] around the ring a minute at a time, from [from] to
  /// [to], which can be past 60 or below 0.
  Future<void> turn(
    TestGesture gesture, {
    required int from,
    required int to,
  }) async {
    final step = to > from ? 1 : -1;
    for (var minute = from; minute != to + step; minute += step) {
      await gesture.moveTo(at(minute));
      await tester.pump();
    }
  }
}

Future<_Dial> _pumpDial(
  WidgetTester tester,
  TimeOfDay time, {
  ScrollController? inList,
  bool use24HourFormat = false,
}) async {
  final dial = _Dial(tester, time);
  Widget page(Widget child) => inList == null
      ? Center(child: child)
      : ListView(
          controller: inList,
          children: [
            child,
            const SizedBox(height: 400, child: Text('Below the dial')),
            const SizedBox(height: 800),
          ],
        );
  await pumpDesign(
    tester,
    MediaQuery(
      data: MediaQueryData(alwaysUse24HourFormat: use24HourFormat),
      child: StatefulBuilder(
        builder: (context, setState) => page(
          RotaryTimeDial(
            time: dial.time,
            onChanged: (time) => setState(() => dial.time = time),
          ),
        ),
      ),
    ),
  );
  return dial;
}

/// Counts the haptic clicks of the platform, from now until the test ends.
int Function() _countHaptics(WidgetTester tester) {
  var count = 0;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') count++;
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return () => count;
}
