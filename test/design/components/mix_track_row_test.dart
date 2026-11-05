import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/mix_track_row.dart';
import 'package:shuffle_alarm/design/tokens.dart';

import '../design_app.dart';

void main() {
  testWidgets('shows the sound, its preview and its action', (tester) async {
    final row = await _pump(tester);

    expect(find.text('Warm Tape'), findsOneWidget);
    expect(find.text('0:20 · Lo-fi · Gentle'), findsOneWidget);
    expect(find.text('Not tonight'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow));
    expect(row.previews, 1);
    await tester.tap(find.text('Not tonight'));
    expect(row.actions, 1);
  });

  testWidgets('offers to stop a preview that plays', (tester) async {
    final row = await _pump(tester, preview: MixRowPreview.playing);

    expect(find.byIcon(Icons.stop), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNothing);

    await tester.tap(find.byIcon(Icons.stop));
    expect(row.previews, 1);
  });

  testWidgets('keeps the accent for the preview that plays', (tester) async {
    await _pump(tester, preview: MixRowPreview.playing);

    const colors = WakemixColors.dark;
    expect(
      tester.widget<Icon>(find.byIcon(Icons.stop)).color,
      colors.accentText,
    );
    final action = tester.widget<TextButton>(find.byType(TextButton));
    expect(action.style!.foregroundColor!.resolve(const {}), colors.textMuted);
  });

  testWidgets('gives its action the accent when it is the point of the row', (
    tester,
  ) async {
    await _pump(tester, accentAction: true);

    final action = tester.widget<TextButton>(find.byType(TextButton));
    expect(
      action.style!.foregroundColor!.resolve(const {}),
      WakemixColors.dark.accentText,
    );
  });

  testWidgets('shows that a preview loads, and it can be stopped', (
    tester,
  ) async {
    final row = await _pump(tester, preview: MixRowPreview.loading);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNothing);

    await tester.tap(find.byType(CircularProgressIndicator));
    expect(row.previews, 1);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('stands still while it loads with less motion asked for', (
    tester,
  ) async {
    askForLessMotion(tester);
    await _pump(tester, preview: MixRowPreview.loading);

    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('has no preview button without a preview', (tester) async {
    await _pump(tester, hasPreview: false);

    expect(find.byIcon(Icons.play_arrow), findsNothing);
    expect(find.text('Warm Tape'), findsOneWidget);
  });

  testWidgets('offers an action that cannot run as disabled', (tester) async {
    final row = await _pump(tester, hasAction: false);

    await tester.tap(find.text('Not tonight'));

    expect(row.actions, 0);
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
  });

  testWidgets('gives its buttons targets of 48 px', (tester) async {
    await _pump(tester);

    for (final button in [find.byType(IconButton), find.byType(TextButton)]) {
      final size = tester.getSize(button);
      expect(size.height, greaterThanOrEqualTo(Layout.minTouchTarget));
      expect(size.width, greaterThanOrEqualTo(Layout.minTouchTarget));
    }
  });

  testWidgets('keeps its button apart for screen readers, with no preview', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, hasPreview: false);

    expect(
      tester.getSemantics(find.bySemanticsLabel('Not tonight: Warm Tape')),
      matchesSemantics(
        label: 'Not tonight: Warm Tape',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('reads the sound and its details as one', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    expect(
      find.bySemanticsLabel('Warm Tape\n0:20 · Lo-fi · Gentle'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('names its buttons with the sound for screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    expect(find.byTooltip('Preview Warm Tape'), findsOneWidget);
    expect(find.bySemanticsLabel('Not tonight: Warm Tape'), findsOneWidget);
    // Not a second button with the short name.
    expect(find.bySemanticsLabel('Not tonight'), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Not tonight: Warm Tape')),
      matchesSemantics(
        label: 'Not tonight: Warm Tape',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  for (final (width, scale) in [
    (320.0, 1.0),
    (390.0, 1.0),
    (320.0, 2.0),
    (360.0, 2.0),
    (560.0, 2.0),
  ]) {
    testWidgets('fits a long title $width px wide at text scale $scale', (
      tester,
    ) async {
      await loadWakemixFonts();
      setScreenSize(tester, Size(width, 800));
      setTextScale(tester, scale);

      await _pump(
        tester,
        title:
            'A very long title of a song the user imported, in several words',
      );

      // A widget test fails on any overflow by itself.
      expect(tester.takeException(), isNull);
      expect(find.text('Not tonight'), findsOneWidget);
    });
  }

  testWidgets('keeps its button beside the text while there is room', (
    tester,
  ) async {
    await loadWakemixFonts();
    setScreenSize(tester, const Size(390, 800));

    await _pump(tester);

    final title = tester.getRect(find.text('Warm Tape'));
    final button = tester.getRect(find.byType(TextButton));
    expect(button.left, greaterThan(title.left));
    expect(button.center.dy, lessThan(title.bottom + 24));
  });

  testWidgets('moves its button under the text with large text', (
    tester,
  ) async {
    await loadWakemixFonts();
    setScreenSize(tester, const Size(360, 800));
    setTextScale(tester, 2);

    await _pump(tester);

    final details = tester.getRect(find.text('0:20 · Lo-fi · Gentle'));
    final button = tester.getRect(find.byType(TextButton));
    expect(button.top, greaterThanOrEqualTo(details.bottom));
  });

  for (final brightness in brightnesses) {
    testWidgets('draws in both themes: ${brightness.name}', (tester) async {
      await _pump(tester, brightness: brightness);

      expect(tester.takeException(), isNull);
    });
  }
}

class _Row {
  int previews = 0;
  int actions = 0;
}

Future<_Row> _pump(
  WidgetTester tester, {
  String title = 'Warm Tape',
  MixRowPreview preview = MixRowPreview.idle,
  bool hasPreview = true,
  bool hasAction = true,
  bool accentAction = false,
  Brightness brightness = Brightness.dark,
}) async {
  final row = _Row();
  await pumpDesign(
    tester,
    SingleChildScrollView(
      child: MixTrackRow(
        title: title,
        details: '0:20 · Lo-fi · Gentle',
        preview: preview,
        previewLabel: hasPreview ? 'Preview $title' : null,
        onPreview: hasPreview ? () => row.previews++ : null,
        actionLabel: 'Not tonight',
        actionSemanticsLabel: 'Not tonight: $title',
        onAction: hasAction ? () => row.actions++ : null,
        accentAction: accentAction,
      ),
    ),
    brightness: brightness,
  );
  return row;
}
