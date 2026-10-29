import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/mini_waveform.dart';

import '../design_app.dart';

void main() {
  group('waveformHeights', () {
    test('gives the same bars for the same seed, every time', () {
      // Fixed values: the web and the app must draw the same waveform, so
      // no platform hash or random number generator may slip in. A copy
      // compiled to JavaScript gave the same numbers in Chrome.
      expect(waveformHeights('a1', 4).map((h) => h.toStringAsFixed(6)), [
        '0.401486',
        '0.667714',
        '0.671299',
        '0.415491',
      ]);
      expect(waveformHeights('a1', 14), waveformHeights('a1', 14));
    });

    test('gives other bars for another seed', () {
      expect(waveformHeights('a1', 14), isNot(waveformHeights('a2', 14)));
      expect(waveformHeights('', 14), hasLength(14));
    });

    test('keeps every bar from 0.2 to 1 of the height', () {
      for (var i = 0; i < 500; i++) {
        for (final height in waveformHeights('${i * 7919}', 14)) {
          expect(height, inInclusiveRange(0.2, 1));
        }
      }
    });
  });

  testWidgets('is decoration: screen readers skip it', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpDesign(
      tester,
      const Center(child: MiniWaveform(seed: 'a1', active: true)),
    );

    expect(tester.getSize(find.byType(MiniWaveform)), MiniWaveform.size);
    expect(
      find.descendant(
        of: find.byType(MiniWaveform),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
