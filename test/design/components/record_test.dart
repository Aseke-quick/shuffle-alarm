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
      // The ring shows the decorative segments until task 2.5a.
      expect(
        tester.widget<RecordArt>(find.byType(RecordArt)).segments,
        RecordHero.segments,
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
      expect(art.segments, 0);
      expect(art.child, isNull);
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
}
