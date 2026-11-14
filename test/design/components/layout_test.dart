import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/layout.dart';
import 'package:shuffle_alarm/design/components/section_label.dart';
import 'package:shuffle_alarm/design/components/status_view.dart';
import 'package:shuffle_alarm/design/components/wide_button.dart';
import 'package:shuffle_alarm/design/components/wordmark.dart';
import 'package:shuffle_alarm/design/tokens.dart';

import '../design_app.dart';

void main() {
  testWidgets('content is at most 560 px wide, in the middle', (tester) async {
    setScreenSize(tester, const Size(1280, 800));
    await pumpDesign(
      tester,
      const ContentWidth(child: SizedBox(height: 100, width: double.infinity)),
    );

    final rect = tester.getRect(find.byType(SizedBox).last);
    expect(rect.width, Layout.maxContentWidth);
    expect(rect.center.dx, 640);
  });

  testWidgets('content keeps its own height where the height is open', (
    tester,
  ) async {
    await pumpDesign(
      tester,
      const Align(
        alignment: Alignment.bottomCenter,
        child: ContentWidth(child: SizedBox(height: 64)),
      ),
    );

    expect(tester.getSize(find.byType(ContentWidth)).height, 64);
  });

  testWidgets('a wide button is full width and 56 px tall, in two kinds', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    var pressed = 0;
    await pumpDesign(
      tester,
      Column(
        children: [
          WideButton(label: 'New alarm', onPressed: () => pressed++),
          WideButton.secondary(label: 'Try again', onPressed: () => pressed++),
        ],
      ),
    );

    for (final (label, kind) in [
      ('New alarm', FilledButton),
      ('Try again', OutlinedButton),
    ]) {
      final button = find.ancestor(
        of: find.text(label),
        matching: find.byType(kind),
      );
      expect(
        tester.getSize(button),
        const Size(390, Layout.wideButtonHeight),
        reason: label,
      );
      await tester.tap(button);
    }
    expect(pressed, 2);
  });

  testWidgets('the bottom action keeps the gutters and the content width', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpDesign(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: BottomAction(
          child: WideButton(label: 'Save alarm', onPressed: () {}),
        ),
      ),
    );

    final rect = tester.getRect(find.byType(FilledButton));
    expect(rect.left, Layout.gutter);
    expect(rect.width, 390 - 2 * Layout.gutter);
  });

  testWidgets('the wordmark is "wakemix", lowercase, read as Wakemix', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpDesign(tester, const Wordmark());

    final text = tester.widget<Text>(find.text('wakemix'));
    expect(text.style!.fontFamily, 'Geist');
    expect(find.bySemanticsLabel('Wakemix'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a section label is a title, and a header for readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpDesign(tester, const SectionLabel('All alarms', trailing: '3'));

    expect(find.text('All alarms'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('All alarms, 3')),
      matchesSemantics(label: 'All alarms, 3', isHeader: true),
    );
    semantics.dispose();
  });

  testWidgets('a status view shows its texts and action', (tester) async {
    var tried = 0;
    await pumpDesign(
      tester,
      StatusView(
        error: true,
        title: 'Alarms are not available',
        message: 'The app could not open its storage.',
        action: WideButton.secondary(
          label: 'Try again',
          onPressed: () => tried++,
        ),
        detail: 'Exception: Storage is blocked',
      ),
    );

    expect(find.text('Alarms are not available'), findsOneWidget);
    expect(find.text('The app could not open its storage.'), findsOneWidget);
    expect(find.text('Exception: Storage is blocked'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(tried, 1);
  });
}
