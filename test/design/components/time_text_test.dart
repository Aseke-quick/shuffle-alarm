import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/time_text.dart';
import 'package:shuffle_alarm/design/tokens.dart';

import '../design_app.dart';

void main() {
  testWidgets('shows the AM or PM smaller, and reads the time whole', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpDesign(
      tester,
      const TimeText(
        TimeOfDay(hour: 19, minute: 5),
        style: TextStyle(fontSize: 34),
      ),
    );

    expect(find.text('7:05 PM'), findsOneWidget);
    final span = tester.widget<Text>(find.text('7:05 PM')).textSpan!;
    final period = (span as TextSpan).children!.single as TextSpan;
    expect(period.text, ' PM');
    expect(period.style!.fontSize, closeTo(34 * 0.42, 0.01));
    expect(find.bySemanticsLabel('7:05 PM'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('never makes the AM or PM smaller than a caption', (
    tester,
  ) async {
    await pumpDesign(
      tester,
      const TimeText(
        TimeOfDay(hour: 7, minute: 0),
        style: TextStyle(fontSize: 15),
      ),
    );

    final span = tester.widget<Text>(find.text('7:00 AM')).textSpan!;
    final period = (span as TextSpan).children!.single as TextSpan;
    expect(period.style!.fontSize, TypeScale.caption);
  });

  testWidgets('timeParts splits the time as the device shows it', (
    tester,
  ) async {
    late (String, String?) twelve;
    late (String, String?) twentyFour;
    await pumpDesign(
      tester,
      Builder(
        builder: (context) {
          twelve = timeParts(context, const TimeOfDay(hour: 0, minute: 30));
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: Builder(
              builder: (context) {
                twentyFour = timeParts(
                  context,
                  const TimeOfDay(hour: 0, minute: 30),
                );
                return const SizedBox();
              },
            ),
          );
        },
      ),
    );

    expect(twelve, ('12:30', 'AM'));
    expect(twentyFour, ('00:30', null));
  });
}
