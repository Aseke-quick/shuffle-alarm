import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/setting_switch_row.dart';
import 'package:shuffle_alarm/design/tokens.dart';

import '../design_app.dart';

void main() {
  group('The setting row', () {
    testWidgets('shows its texts', (tester) async {
      await pumpDesign(
        tester,
        SettingSwitchRow(
          title: 'Bedtime reminder',
          description: 'One notification.',
          status: 'Off',
          value: false,
          onChanged: (_) {},
        ),
      );

      expect(find.text('Bedtime reminder'), findsOneWidget);
      expect(find.text('One notification.'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
    });

    testWidgets('tells a tap on its switch', (tester) async {
      final changes = <bool>[];
      await pumpDesign(
        tester,
        SettingSwitchRow(title: 'A', value: false, onChanged: changes.add),
      );

      await tester.tap(find.byType(Switch));

      expect(changes, [true]);
    });

    testWidgets('is one switch for screen readers, named by its texts', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpDesign(
        tester,
        SettingSwitchRow(
          title: 'Bedtime reminder',
          description: 'One notification.',
          status: 'Off',
          value: false,
          onChanged: (_) {},
        ),
      );

      expect(
        tester.getSemantics(find.byType(Switch)),
        matchesSemantics(
          label: 'Bedtime reminder\nOne notification.\nOff',
          hasToggledState: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('without a way to change it, its switch is disabled', (
      tester,
    ) async {
      await pumpDesign(
        tester,
        const SettingSwitchRow(title: 'A', value: false, onChanged: null),
      );

      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    });

    testWidgets('gives its switch a touch target of 48 dp', (tester) async {
      await pumpDesign(
        tester,
        SettingSwitchRow(title: 'A', value: false, onChanged: (_) {}),
      );

      final size = tester.getSize(find.byType(Switch));
      expect(size.height, greaterThanOrEqualTo(Layout.minTouchTarget));
      expect(tester.takeException(), isNull);
    });
  });
}
