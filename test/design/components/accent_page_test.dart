import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/accent_page.dart';
import 'package:shuffle_alarm/design/components/wide_button.dart';
import 'package:shuffle_alarm/design/theme.dart';
import 'package:shuffle_alarm/design/tokens.dart';

import '../design_app.dart';

void main() {
  for (final brightness in brightnesses) {
    final colors = brightness == Brightness.dark
        ? WakemixColors.dark
        : WakemixColors.light;

    group('In ${brightness.name}, the accent page', () {
      Future<void> pump(WidgetTester tester) => pumpDesign(
        tester,
        AccentPage(
          body: Builder(
            builder: (context) => Column(
              children: [
                const Text('Body'),
                Text(
                  'Display',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                Text('Title', style: Theme.of(context).textTheme.titleLarge),
                Text('Caption', style: WakemixType.of(context).caption),
                Text('Meta', style: WakemixType.of(context).meta),
              ],
            ),
          ),
          bottomAction: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WideButton.secondary(label: 'Later', onPressed: () {}),
              WideButton(label: 'Now', onPressed: () {}),
            ],
          ),
        ),
        brightness: brightness,
      );

      Color? textColor(WidgetTester tester, String text) => tester
          .widget<RichText>(
            find.descendant(
              of: find.text(text),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style
          ?.color;

      testWidgets('is filled with the accent', (tester) async {
        await pump(tester);

        final page = find.byType(AccentPage);
        final scaffold = find.descendant(
          of: page,
          matching: find.byType(Scaffold),
        );
        expect(
          Theme.of(tester.element(scaffold)).scaffoldBackgroundColor,
          colors.accent,
        );
      });

      testWidgets('draws every text in the color on the accent', (
        tester,
      ) async {
        await pump(tester);

        for (final text in ['Body', 'Display', 'Title', 'Caption', 'Meta']) {
          expect(textColor(tester, text), colors.onAccent, reason: text);
        }
      });

      testWidgets('turns the buttons around', (tester) async {
        await pump(tester);

        expect(textColor(tester, 'Now'), colors.accent);
        expect(textColor(tester, 'Later'), colors.onAccent);
        final filled = tester.widget<FilledButton>(find.byType(FilledButton));
        final style = Theme.of(tester.element(find.byType(FilledButton)))
            .filledButtonTheme
            .style;
        expect(filled.style?.backgroundColor, isNull);
        expect(style?.backgroundColor?.resolve(const {}), colors.onAccent);
        final outlined = Theme.of(tester.element(find.byType(OutlinedButton)))
            .outlinedButtonTheme
            .style;
        expect(outlined?.side?.resolve(const {})?.color, colors.onAccent);
      });

      testWidgets('keeps the size of the buttons of the theme', (tester) async {
        await pump(tester);

        expect(
          tester.getSize(find.byType(FilledButton)).height,
          greaterThanOrEqualTo(Layout.wideButtonHeight),
        );
      });
    });
  }
}
