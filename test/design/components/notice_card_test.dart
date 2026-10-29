import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/notice_card.dart';
import 'package:shuffle_alarm/design/components/wide_button.dart';
import 'package:shuffle_alarm/design/tokens.dart';

import '../design_app.dart';

void main() {
  for (final brightness in brightnesses) {
    testWidgets('shows its title, message, detail and action, '
        'in ${brightness.name}', (tester) async {
      var taps = 0;
      await pumpDesign(
        tester,
        NoticeCard(
          icon: Icons.alarm_on,
          title: 'Keep this tab open',
          message: 'Alarms ring only while this tab is open.',
          detail: 'The screen stays on.',
          action: WideButton(label: 'Arm alarms', onPressed: () => taps++),
        ),
        brightness: brightness,
      );

      final c = brightness == Brightness.dark
          ? WakemixColors.dark
          : WakemixColors.light;
      expect(find.text('Keep this tab open'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.text('Alarms ring only while this tab is open.'))
            .style!
            .color,
        c.textMuted,
      );
      expect(find.text('The screen stays on.'), findsOneWidget);
      // The accent only on the icon, never as the only sign of anything.
      expect(
        tester.widget<Icon>(find.byIcon(Icons.alarm_on)).color,
        c.accentText,
      );

      await tester.tap(find.text('Arm alarms'));
      expect(taps, 1);
    });
  }

  testWidgets('draws its icon in the danger color for an error', (
    tester,
  ) async {
    await pumpDesign(
      tester,
      const NoticeCard(
        icon: Icons.volume_up_outlined,
        title: 'Arm alarms to hear them',
        message: 'The browser did not let the sound play. Try again.',
        error: true,
      ),
    );

    expect(
      tester.widget<Icon>(find.byIcon(Icons.volume_up_outlined)).color,
      WakemixColors.dark.danger,
    );
  });

  testWidgets('reads as one group, without its icon', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpDesign(
      tester,
      const NoticeCard(
        icon: Icons.alarm_on,
        title: 'Keep this tab open',
        message: 'Alarms ring only while this tab is open.',
      ),
    );

    expect(
      tester.getSemantics(find.text('Keep this tab open')),
      matchesSemantics(
        label: 'Keep this tab open\nAlarms ring only while this tab is open.',
      ),
    );
    expect(find.bySemanticsLabel(RegExp('alarm_on')), findsNothing);
    semantics.dispose();
  });
}
