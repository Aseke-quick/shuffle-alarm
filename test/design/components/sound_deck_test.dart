import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/mix_track_row.dart';
import 'package:shuffle_alarm/design/components/sound_deck.dart';

import '../design_app.dart';

void main() {
  const titles = ['Warm Tape', 'Glass Bells', 'Night Bus', 'Big Drums'];

  /// What the cards did: the titles of the sounds acted on and previewed.
  final actions = <String>[];
  final previews = <String>[];

  setUp(() {
    actions.clear();
    previews.clear();
  });

  List<DeckCard> cards(
    List<String> order, {
    bool hasAction = true,
    bool hasPreview = true,
  }) => [
    for (final title in order)
      DeckCard(
        id: title,
        title: title,
        details: '0:20 · Lo-fi · Gentle',
        intensity: 1 + titles.indexOf(title) % 3,
        actionLabel: 'Not tonight',
        actionSemanticsLabel: 'Not tonight: $title',
        onAction: hasAction ? () => actions.add(title) : null,
        previewLabel: 'Preview $title',
        onPreview: hasPreview ? () => previews.add(title) : null,
      ),
  ];

  Future<void> pump(
    WidgetTester tester,
    List<DeckCard> cards, {
    Size size = const Size(1000, 800),
  }) async {
    setScreenSize(tester, size);
    await pumpDesign(tester, Center(child: SoundDeck(cards: cards)));
  }

  double left(WidgetTester tester, String title) =>
      tester.getTopLeft(find.text(title)).dx;

  testWidgets('lays the cards out in play order, each with its place', (
    tester,
  ) async {
    await pump(tester, cards(titles));

    for (final title in titles) {
      expect(find.text(title), findsOneWidget);
    }
    expect([for (final title in titles) left(tester, title)], isSorted());
    for (var place = 1; place <= 4; place++) {
      expect(find.text('$place'), findsOneWidget);
    }
    expect(find.text('0:20 · Lo-fi · Gentle'), findsNWidgets(4));
  });

  testWidgets('is a fan where there is room, a row to scroll where not', (
    tester,
  ) async {
    await pump(tester, cards(titles));
    expect(find.byType(AnimatedPositioned), findsNWidgets(4));
    expect(find.byType(ListView), findsNothing);

    await pump(tester, cards(titles), size: const Size(360, 740));
    expect(find.byType(AnimatedPositioned), findsNothing);
    expect(find.byType(ListView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('moves each card to its place when the order changes', (
    tester,
  ) async {
    await pump(tester, cards(titles));
    final before = left(tester, 'Warm Tape');

    await pumpDesign(
      tester,
      Center(child: SoundDeck(cards: cards(titles.reversed.toList()))),
    );
    // On its way: neither where it was, nor where it will be.
    await tester.pump(const Duration(milliseconds: 200));
    final onTheWay = left(tester, 'Warm Tape');
    await tester.pumpAndSettle();
    final after = left(tester, 'Warm Tape');

    expect(after, greaterThan(before));
    expect(onTheWay, greaterThan(before));
    expect(onTheWay, lessThan(after));
    expect([
      for (final title in titles.reversed) left(tester, title),
    ], isSorted());
  });

  testWidgets('changes the order at once when less motion is asked for', (
    tester,
  ) async {
    askForLessMotion(tester);
    await pump(tester, cards(titles));

    await pumpDesign(
      tester,
      Center(child: SoundDeck(cards: cards(titles.reversed.toList()))),
    );
    await tester.pump();

    expect(tester.hasRunningAnimations, isFalse);
    expect([
      for (final title in titles.reversed) left(tester, title),
    ], isSorted());
  });

  testWidgets('a card does its action with its button, and its preview', (
    tester,
  ) async {
    await pump(tester, cards(titles));

    await tester.tap(find.bySemanticsLabel('Not tonight: Glass Bells'));
    await tester.tap(find.byTooltip('Preview Night Bus'));

    expect(actions, ['Glass Bells']);
    expect(previews, ['Night Bus']);
  });

  testWidgets('a card flicked up and away does its action', (tester) async {
    await pump(tester, cards(titles));

    await tester.fling(find.text('Big Drums'), const Offset(0, -200), 1200);
    await tester.pumpAndSettle();
    expect(actions, ['Big Drums']);

    // Not down, and not a slow drag.
    await tester.fling(find.text('Big Drums'), const Offset(0, 200), 1200);
    await tester.drag(find.text('Big Drums'), const Offset(0, -30));
    await tester.pumpAndSettle();
    expect(actions, ['Big Drums']);
  });

  testWidgets('an action that cannot run is off, also for a flick', (
    tester,
  ) async {
    await pump(tester, cards(['Warm Tape'], hasAction: false));

    await tester.fling(find.text('Warm Tape'), const Offset(0, -200), 1200);
    await tester.tap(find.text('Not tonight'), warnIfMissed: false);

    expect(actions, isEmpty);
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
    // One card alone is laid out too.
    expect(tester.takeException(), isNull);
  });

  testWidgets('has no preview button without a preview', (tester) async {
    await pump(tester, cards(titles, hasPreview: false));

    expect(find.byIcon(Icons.play_arrow), findsNothing);
    expect(find.text('Warm Tape'), findsOneWidget);
  });

  testWidgets('shows a preview that plays, and one that loads', (tester) async {
    askForLessMotion(tester);
    await pump(tester, [
      for (final (index, card) in cards(titles).indexed)
        DeckCard(
          id: card.id,
          title: card.title,
          details: card.details,
          intensity: card.intensity,
          actionLabel: card.actionLabel,
          actionSemanticsLabel: card.actionSemanticsLabel,
          onAction: card.onAction,
          preview: switch (index) {
            0 => MixRowPreview.playing,
            1 => MixRowPreview.loading,
            _ => MixRowPreview.idle,
          },
          previewLabel: index == 0 ? 'Stop preview' : card.previewLabel,
          onPreview: card.onPreview,
        ),
    ]);

    expect(find.byIcon(Icons.stop), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNWidgets(2));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('each card is read as one, with buttons of its own', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, cards(titles));

    expect(
      find.bySemanticsLabel('Number 1\nWarm Tape\n0:20 · Lo-fi · Gentle'),
      findsOneWidget,
    );
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
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
  });

  for (final (width, scale) in [(320.0, 1.0), (360.0, 2.0), (1280.0, 2.0)]) {
    testWidgets('fits $width px wide at text scale $scale', (tester) async {
      setTextScale(tester, scale);
      await pump(tester, [
        ...cards(titles),
        DeckCard(
          id: 'long',
          title: 'A very long title of a song that someone brought',
          details: '1:40 · Your songs · Strong, from the chorus on',
          intensity: 3,
          actionLabel: 'Not tonight',
          actionSemanticsLabel: 'Not tonight: long',
          onAction: () {},
          onPreview: () {},
          previewLabel: 'Preview long',
        ),
      ], size: Size(width, 800));

      expect(tester.takeException(), isNull);
    });
  }
}

/// Matches numbers that grow from one to the next.
Matcher isSorted() => predicate<List<double>>((values) {
  for (var index = 1; index < values.length; index++) {
    if (values[index] <= values[index - 1]) return false;
  }
  return true;
}, 'grows from left to right');
