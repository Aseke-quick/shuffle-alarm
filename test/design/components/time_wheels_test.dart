import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/time_wheels.dart';

import '../design_app.dart';

void main() {
  const seven = TimeOfDay(hour: 7, minute: 0);

  /// Shows the wheels at [time], and keeps the time they change to. Returns
  /// every time they reported.
  Future<List<TimeOfDay>> pump(
    WidgetTester tester, {
    TimeOfDay time = seven,
    bool use24 = false,
  }) async {
    final changes = <TimeOfDay>[];
    var shown = time;
    await pumpDesign(
      tester,
      MediaQuery(
        data: MediaQueryData(alwaysUse24HourFormat: use24),
        child: StatefulBuilder(
          builder: (context, setState) => Center(
            child: TimeWheels(
              time: shown,
              onChanged: (time) {
                changes.add(time);
                setState(() => shown = time);
              },
            ),
          ),
        ),
      ),
    );
    return changes;
  }

  Finder wheel(int index) => find.byType(ListWheelScrollView).at(index);

  /// Turns the wheel at [index] by [values], forward when positive.
  Future<void> turn(WidgetTester tester, int index, int values) async {
    await tester.drag(
      wheel(index),
      // Past the slop of a drag, and less than half a value too far.
      Offset(0, -(TimeWheels.itemExtent * values + 20.0 * values.sign)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the hour and the minute, each on its wheel', (
    tester,
  ) async {
    await pump(tester);

    expect(
      find.descendant(of: wheel(0), matching: find.text('7')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: wheel(1), matching: find.text('00')),
      findsOneWidget,
    );
    // The values before and after show too.
    expect(find.descendant(of: wheel(0), matching: find.text('6')), findsOne);
    expect(find.descendant(of: wheel(1), matching: find.text('01')), findsOne);
  });

  testWidgets('a drag turns the minutes', (tester) async {
    final changes = await pump(tester);

    await turn(tester, 1, 2);

    expect(changes.last, const TimeOfDay(hour: 7, minute: 2));
  });

  testWidgets('a drag turns the hours', (tester) async {
    final changes = await pump(tester);

    await turn(tester, 0, -1);

    expect(changes.last, const TimeOfDay(hour: 6, minute: 0));
  });

  testWidgets('each wheel goes round', (tester) async {
    final changes = await pump(
      tester,
      time: const TimeOfDay(hour: 23, minute: 59),
    );

    await turn(tester, 1, 1);
    expect(changes.last, const TimeOfDay(hour: 23, minute: 0));

    await turn(tester, 0, 1);
    expect(changes.last, const TimeOfDay(hour: 0, minute: 0));
  });

  testWidgets('the arrow keys change it by a minute, Page keys by an hour', (
    tester,
  ) async {
    final changes = await pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(changes.last, const TimeOfDay(hour: 7, minute: 1));

    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.pumpAndSettle();
    expect(changes.last, const TimeOfDay(hour: 8, minute: 1));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(changes.last, const TimeOfDay(hour: 7, minute: 59));

    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    expect(changes.last, const TimeOfDay(hour: 6, minute: 59));
    // The wheels follow: one report per key, none from their own move.
    expect(changes, hasLength(5));
    expect(find.descendant(of: wheel(1), matching: find.text('59')), findsOne);
  });

  testWidgets('"Type the time" takes a time from the keyboard', (tester) async {
    final changes = await pump(tester);

    await tester.tap(find.text('Type the time'));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), '10');
    await tester.enterText(fields.at(1), '25');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(changes, [const TimeOfDay(hour: 10, minute: 25)]);
    expect(find.descendant(of: wheel(0), matching: find.text('10')), findsOne);
    expect(find.descendant(of: wheel(1), matching: find.text('25')), findsOne);
  });

  testWidgets('typing that is cancelled changes nothing', (tester) async {
    final changes = await pump(tester);

    await tester.tap(find.text('Type the time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(changes, isEmpty);
  });

  testWidgets('AM and PM are keys on a 12-hour device', (tester) async {
    final changes = await pump(tester);

    await tester.tap(find.text('PM'));
    await tester.pumpAndSettle();
    expect(changes.last, const TimeOfDay(hour: 19, minute: 0));

    await tester.tap(find.text('PM'));
    await tester.pumpAndSettle();
    expect(changes, hasLength(1));

    await tester.tap(find.text('AM'));
    await tester.pumpAndSettle();
    expect(changes.last, seven);
  });

  testWidgets('shows 24 hours, and no AM or PM, on a 24-hour device', (
    tester,
  ) async {
    await pump(tester, time: const TimeOfDay(hour: 19, minute: 5), use24: true);

    expect(find.text('AM'), findsNothing);
    expect(find.text('PM'), findsNothing);
    expect(find.descendant(of: wheel(0), matching: find.text('19')), findsOne);
    expect(find.descendant(of: wheel(1), matching: find.text('05')), findsOne);
  });

  testWidgets('is one adjustable value for screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    final changes = await pump(tester);

    final node = tester.getSemantics(find.bySemanticsLabel('Alarm time'));
    final data = node.getSemanticsData();
    expect(data.value, '7:00 AM');
    expect(data.increasedValue, '7:01 AM');
    expect(data.decreasedValue, '6:59 AM');

    /// Does [action] on the wheels, as a screen reader does.
    void act(SemanticsAction action) => tester.binding.performSemanticsAction(
      SemanticsActionEvent(
        type: action,
        viewId: tester.view.viewId,
        nodeId: tester.getSemantics(find.bySemanticsLabel('Alarm time')).id,
      ),
    );

    act(SemanticsAction.increase);
    await tester.pumpAndSettle();
    expect(changes.last, const TimeOfDay(hour: 7, minute: 1));

    act(SemanticsAction.decrease);
    await tester.pumpAndSettle();
    expect(changes.last, seven);
    semantics.dispose();
  });

  testWidgets('its buttons are touch targets of 48 px', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('fits a small phone with large text', (tester) async {
    setScreenSize(tester, const Size(360, 740));
    setTextScale(tester, 2);
    await pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Type the time'), findsOneWidget);
  });
}
