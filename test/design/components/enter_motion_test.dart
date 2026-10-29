import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/enter_motion.dart';
import 'package:shuffle_alarm/design/tokens.dart';

import '../design_app.dart';

void main() {
  testWidgets('fades the child in while it moves up 8 px, ease-out', (
    tester,
  ) async {
    await pumpDesign(tester, const EnterMotion(child: Text('New')));

    // One frame in: almost invisible, and 8 px low.
    expect(_opacity(tester), lessThan(0.1));
    expect(_offset(tester).dy, closeTo(Motion.enterOffset, 0.5));

    await tester.pump(Motion.slow ~/ 2);
    // Ease-out: more than half the way at half the time.
    expect(_opacity(tester), greaterThan(0.5));
    expect(_offset(tester).dy, lessThan(Motion.enterOffset / 2));

    await tester.pumpAndSettle();
    expect(_opacity(tester), 1);
    expect(_offset(tester), Offset.zero);
  });

  testWidgets('does not move when the platform asks for less motion', (
    tester,
  ) async {
    askForLessMotion(tester);
    await pumpDesign(tester, const EnterMotion(child: Text('New')));

    expect(_inMotion(FadeTransition), findsNothing);
    expect(_inMotion(Transform), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('does not move when it should not animate', (tester) async {
    await pumpDesign(
      tester,
      const EnterMotion(animate: false, child: Text('Old')),
    );

    expect(_inMotion(FadeTransition), findsNothing);
    expect(_inMotion(Transform), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });
}

/// The widgets of [type] that [EnterMotion] puts around its child; the
/// page around it has transitions of its own.
Finder _inMotion(Type type) =>
    find.descendant(of: find.byType(EnterMotion), matching: find.byType(type));

double _opacity(WidgetTester tester) =>
    tester.widget<FadeTransition>(_inMotion(FadeTransition)).opacity.value;

Offset _offset(WidgetTester tester) {
  final translation = tester
      .widget<Transform>(_inMotion(Transform))
      .transform
      .getTranslation();
  return Offset(translation.x, translation.y);
}
