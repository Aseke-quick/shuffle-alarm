import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/day_keys.dart';
import 'package:shuffle_alarm/design/tokens.dart';

import '../design_app.dart';

void main() {
  testWidgets('shows a key per day, the chosen ones in the accent', (
    tester,
  ) async {
    await _pumpKeys(tester, {DateTime.monday, DateTime.friday});

    for (final day in _short) {
      expect(find.text(day), findsOneWidget);
    }
    const colors = WakemixColors.dark;
    expect(_fill(tester, 'Mon'), colors.accent);
    expect(_fill(tester, 'Fri'), colors.accent);
    expect(_fill(tester, 'Tue'), colors.surfaceHigh);
    expect(_text(tester, 'Mon').style!.color, colors.onAccent);
    expect(_text(tester, 'Tue').style!.color, colors.text);
  });

  testWidgets('a tap turns a day on or off', (tester) async {
    final days = await _pumpKeys(tester, {DateTime.monday});

    await tester.tap(find.text('Wed'));
    await tester.pump();
    expect(days, {DateTime.monday, DateTime.wednesday});

    await tester.tap(find.text('Mon'));
    await tester.pump();
    expect(days, {DateTime.wednesday});
  });

  testWidgets('screen readers hear each key by its full day name', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final days = await _pumpKeys(tester, {DateTime.sunday});

    expect(
      tester.getSemantics(find.bySemanticsLabel('Sunday')),
      matchesSemantics(
        label: 'Sunday',
        isButton: true,
        hasCheckedState: true,
        isChecked: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Monday')),
      matchesSemantics(
        label: 'Monday',
        isButton: true,
        hasCheckedState: true,
        hasTapAction: true,
      ),
    );

    tester.semantics.tap(find.semantics.byLabel('Monday'));
    await tester.pump();
    expect(days, {DateTime.monday, DateTime.sunday});
    semantics.dispose();
  });

  testWidgets('each key is a touch target of 48 dp on a phone 360 px wide', (
    tester,
  ) async {
    setScreenSize(tester, const Size(360, 740));
    // The editor's margins on the sides of the keys.
    final days = await _pumpKeys(tester, {}, padding: Space.s12);

    final semantics = tester.ensureSemantics();
    for (final day in _full) {
      final size = tester.getSemantics(find.bySemanticsLabel(day)).rect.size;
      expect(size.width, greaterThanOrEqualTo(48), reason: day);
      expect(size.height, greaterThanOrEqualTo(48), reason: day);
    }
    // A tap in the gap between two keys still counts, for the key it is
    // in: here 1 px into Tuesday, the second seventh of the row.
    final row = tester.getRect(find.byType(DayKeys));
    await tester.tapAt(Offset(row.left + row.width / 7 + 1, row.center.dy));
    await tester.pump();
    expect(days, {DateTime.tuesday});
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
  });
}

const _short = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _full = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Shows day keys with [selected] days, and returns the days as the keys
/// change them.
Future<Set<int>> _pumpKeys(
  WidgetTester tester,
  Set<int> selected, {
  double padding = 0,
}) async {
  final days = {...selected};
  await pumpDesign(
    tester,
    StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: DayKeys(
          selected: days,
          label: (day) => _short[day - 1],
          semanticsLabel: (day) => _full[day - 1],
          onChanged: (day, {required selected}) => setState(() {
            selected ? days.add(day) : days.remove(day);
          }),
        ),
      ),
    ),
  );
  return days;
}

Color? _fill(WidgetTester tester, String day) {
  final box = tester.widget<AnimatedContainer>(
    find.ancestor(of: find.text(day), matching: find.byType(AnimatedContainer)),
  );
  return (box.decoration! as ShapeDecoration).color;
}

Text _text(WidgetTester tester, String day) =>
    tester.widget<Text>(find.text(day));
