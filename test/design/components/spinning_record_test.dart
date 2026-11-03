import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/record.dart';
import 'package:shuffle_alarm/design/components/spinning_record.dart';

import '../design_app.dart';

void main() {
  Finder turning() => find.descendant(
    of: find.byType(SpinningRecord),
    matching: find.byType(RotationTransition),
  );

  RotationTransition rotation(WidgetTester tester) =>
      tester.widget<RotationTransition>(turning());

  Widget record() => const Center(
    child: SizedBox.square(
      dimension: 300,
      child: SpinningRecord(child: Text('7:00')),
    ),
  );

  testWidgets('turns, one turn in its time, over and over', (tester) async {
    await pumpDesign(tester, record());

    final start = rotation(tester).turns.value;
    await tester.pump(SpinningRecord.turn ~/ 4);
    expect(rotation(tester).turns.value, closeTo(start + 0.25, 0.01));

    await tester.pump(SpinningRecord.turn);
    expect(rotation(tester).turns.value, closeTo(start + 0.25, 0.01));
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('keeps its label still: the child does not turn', (tester) async {
    await pumpDesign(tester, record());
    final before = tester.getRect(find.text('7:00'));

    await tester.pump(SpinningRecord.turn ~/ 4);

    expect(
      find.ancestor(
        of: find.text('7:00'),
        matching: find.byType(RotationTransition),
      ),
      findsNothing,
    );
    expect(tester.getRect(find.text('7:00')), before);

    await tester.pumpWidget(const SizedBox());
  });

  for (final (name, width, height) in [
    ('wide', 1000.0, 400.0),
    ('tall', 400.0, 1000.0),
    ('large', 1000.0, 1000.0),
  ]) {
    testWidgets('fits its child inside the round label, however $name', (
      tester,
    ) async {
      askForLessMotion(tester);
      const child = Key('child');
      await pumpDesign(
        tester,
        Center(
          child: SizedBox.square(
            dimension: 300,
            child: SpinningRecord(
              child: SizedBox(key: child, width: width, height: height),
            ),
          ),
        ),
      );

      final record = tester.getRect(find.byType(SpinningRecord));
      final labelRadius = record.width / 2 * SpinningRecord.labelShare;
      final box = tester.getRect(find.byKey(child));
      for (final corner in [
        box.topLeft,
        box.topRight,
        box.bottomLeft,
        box.bottomRight,
      ]) {
        expect(
          (corner - record.center).distance,
          lessThanOrEqualTo(labelRadius + 0.01),
        );
      }
    });
  }

  testWidgets('stands still when less motion is asked for', (tester) async {
    askForLessMotion(tester);
    await pumpDesign(tester, record());

    final start = rotation(tester).turns.value;
    await tester.pump(SpinningRecord.turn ~/ 4);

    expect(rotation(tester).turns.value, start);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('stops when less motion is asked for while it turns', (
    tester,
  ) async {
    await pumpDesign(tester, record());
    await tester.pump(SpinningRecord.turn ~/ 4);
    expect(tester.hasRunningAnimations, isTrue);

    askForLessMotion(tester);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('stops when it is told to, and turns on from there', (
    tester,
  ) async {
    Widget told({required bool turning}) => Center(
      child: SizedBox.square(
        dimension: 300,
        child: SpinningRecord(turning: turning, child: const Text('7:00')),
      ),
    );
    await pumpDesign(tester, told(turning: true));
    await tester.pump(SpinningRecord.turn ~/ 4);
    expect(tester.hasRunningAnimations, isTrue);

    await pumpDesign(tester, told(turning: false));
    final stopped = rotation(tester).turns.value;
    await tester.pump(SpinningRecord.turn ~/ 4);
    expect(tester.hasRunningAnimations, isFalse);
    expect(rotation(tester).turns.value, stopped);

    await pumpDesign(tester, told(turning: true));
    await tester.pump(SpinningRecord.turn ~/ 4);
    expect(tester.hasRunningAnimations, isTrue);
    expect(rotation(tester).turns.value, closeTo(stopped + 0.25, 0.02));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('turns again when motion is allowed again', (tester) async {
    askForLessMotion(tester);
    await pumpDesign(tester, record());
    expect(tester.hasRunningAnimations, isFalse);

    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('takes the segments of its mix', (tester) async {
    const segments = [RecordSegment(length: Duration(seconds: 20))];
    await pumpDesign(
      tester,
      const Center(
        child: SizedBox.square(
          dimension: 300,
          child: SpinningRecord(segments: segments, child: Text('7:00')),
        ),
      ),
    );

    expect(
      tester.widget<SpinningRecord>(find.byType(SpinningRecord)).segments,
      segments,
    );
    expect(
      tester.renderObject(
        find.descendant(of: turning(), matching: find.byType(CustomPaint)),
      ),
      paints
        ..circle()
        ..arc(),
    );

    await tester.pumpWidget(const SizedBox());
  });

  for (final brightness in brightnesses) {
    testWidgets('draws its disc in both themes: ${brightness.name}', (
      tester,
    ) async {
      askForLessMotion(tester);
      await pumpDesign(tester, record(), brightness: brightness);

      expect(
        find.descendant(of: turning(), matching: find.byType(CustomPaint)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
