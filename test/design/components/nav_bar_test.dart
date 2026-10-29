import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/nav_bar.dart';
import 'package:shuffle_alarm/design/tokens.dart';

import '../design_app.dart';

void main() {
  testWidgets('marks the open tab with the text color and an accent dot', (
    tester,
  ) async {
    await _pumpBar(tester, selected: 1);

    const colors = WakemixColors.dark;
    expect(_labelColor(tester, 'Library'), colors.text);
    expect(_labelColor(tester, 'Alarms'), colors.textMuted);
    expect(_dots(tester), [
      Colors.transparent,
      colors.accent,
      Colors.transparent,
    ]);
  });

  testWidgets('a tap opens a tab', (tester) async {
    final opened = await _pumpBar(tester, selected: 0);

    await tester.tap(find.text('Insights'));
    expect(opened, [2]);
  });

  testWidgets('is flat across the bottom, with a hairline above it', (
    tester,
  ) async {
    await _pumpBar(tester, selected: 0);

    final bar = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(WakemixNavBar),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = bar.decoration as BoxDecoration;
    expect(decoration.borderRadius, isNull);
    expect(decoration.boxShadow, isNull);
    expect(
      decoration.border,
      Border(top: BorderSide(color: WakemixColors.dark.outline)),
    );
  });

  testWidgets(
    'each tab is a button for screen readers, the open one selected',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpBar(tester, selected: 0);

      expect(
        tester.getSemantics(find.bySemanticsLabel('Alarms')),
        matchesSemantics(
          label: 'Alarms',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Library')),
        matchesSemantics(
          label: 'Library',
          isButton: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      semantics.dispose();
    },
  );
}

Future<List<int>> _pumpBar(WidgetTester tester, {required int selected}) async {
  final opened = <int>[];
  await pumpDesign(
    tester,
    Align(
      alignment: Alignment.bottomCenter,
      child: WakemixNavBar(
        selectedIndex: selected,
        onSelected: opened.add,
        destinations: const [
          NavDestination(
            icon: Icons.alarm_outlined,
            selectedIcon: Icons.alarm,
            label: 'Alarms',
          ),
          NavDestination(
            icon: Icons.library_music_outlined,
            selectedIcon: Icons.library_music,
            label: 'Library',
          ),
          NavDestination(
            icon: Icons.insights_outlined,
            selectedIcon: Icons.insights,
            label: 'Insights',
          ),
        ],
      ),
    ),
  );
  return opened;
}

Color? _labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!.color;

List<Color?> _dots(WidgetTester tester) => [
  for (final dot in tester.widgetList<Container>(
    find.descendant(
      of: find.byType(WakemixNavBar),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints ==
                const BoxConstraints.tightFor(width: 4, height: 4),
      ),
    ),
  ))
    (dot.decoration! as BoxDecoration).color,
];
