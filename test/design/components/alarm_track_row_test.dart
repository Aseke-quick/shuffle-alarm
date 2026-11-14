import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/alarm_track_row.dart';
import 'package:shuffle_alarm/design/components/mini_waveform.dart';
import 'package:shuffle_alarm/design/tokens.dart';

import '../design_app.dart';

void main() {
  testWidgets('shows the time, the details, the status and the switch', (
    tester,
  ) async {
    final row = await _pumpRow(tester, enabled: true);

    expect(find.text('7:00 AM'), findsOneWidget);
    expect(find.text('Work · Weekdays'), findsOneWidget);
    expect(find.text('Rings in 7 h 20 min'), findsOneWidget);
    expect(find.byType(WaveformTile), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    await tester.tap(find.text('7:00 AM'));
    expect(row.taps, 1);
    await tester.tap(find.byType(Switch));
    expect(row.switches, [false]);
  });

  testWidgets('shows an alarm that is off in grey, with a grey waveform', (
    tester,
  ) async {
    await _pumpRow(tester, enabled: false, status: 'Off');

    const colors = WakemixColors.dark;
    final time = tester.widget<Text>(find.text('7:00 AM'));
    expect(time.style!.color, colors.textDisabled);
    // Never by color alone: the row says "Off" too.
    expect(find.text('Off'), findsOneWidget);
    expect(
      tester.widget<WaveformTile>(find.byType(WaveformTile)).active,
      isFalse,
    );
  });

  testWidgets('names its switch for screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpRow(tester, enabled: true);

    expect(
      tester.getSemantics(find.bySemanticsLabel('7:00 AM alarm')),
      matchesSemantics(
        label: '7:00 AM alarm',
        hasToggledState: true,
        isToggled: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('leaves out the waveform when large text needs the room', (
    tester,
  ) async {
    setScreenSize(tester, const Size(360, 740));
    await _pumpRow(tester, enabled: true);
    expect(find.byType(WaveformTile), findsOneWidget);

    setTextScale(tester, 2);
    await tester.pump();
    expect(find.byType(WaveformTile), findsNothing);
  });
}

class _Row {
  int taps = 0;
  final switches = <bool>[];
}

Future<_Row> _pumpRow(
  WidgetTester tester, {
  required bool enabled,
  String status = 'Rings in 7 h 20 min',
}) async {
  final row = _Row();
  await pumpDesign(
    tester,
    AlarmTrackRow(
      time: const TimeOfDay(hour: 7, minute: 0),
      details: 'Work · Weekdays',
      status: status,
      enabled: enabled,
      waveformSeed: 'a1',
      switchLabel: '7:00 AM alarm',
      onTap: () => row.taps++,
      onEnabledChanged: row.switches.add,
    ),
  );
  return row;
}
