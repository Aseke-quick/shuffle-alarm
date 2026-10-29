import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/fonts.dart';
import 'package:shuffle_alarm/design/theme.dart';
import 'package:shuffle_alarm/design/tokens.dart';

import 'design_app.dart';

void main() {
  for (final (name, theme, colors) in [
    ('dark', WakemixTheme.dark, WakemixColors.dark),
    ('light', WakemixTheme.light, WakemixColors.light),
  ]) {
    group('The $name theme', () {
      test('is Material 3, with 48 dp touch targets on every platform', () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.brightness, colors.brightness);
        expect(theme.visualDensity, VisualDensity.standard);
        expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
      });

      test('sets the wght axis of each text style to its weight', () {
        final type = theme.extension<WakemixType>()!;
        final styles = {
          ..._roles(theme.textTheme),
          'meta': type.meta,
          'caption': type.caption,
        };
        for (final MapEntry(key: role, value: style) in styles.entries) {
          expect(style.fontVariations, [
            FontVariation('wght', style.fontWeight!.value.toDouble()),
          ], reason: role);
        }
      });

      test(
        'uses Unbounded for display, Geist for text, Geist Mono for meta',
        () {
          final text = theme.textTheme;
          for (final style in [
            text.displayLarge,
            text.displayMedium,
            text.headlineSmall,
            text.titleLarge,
          ]) {
            expect(style!.fontFamily, WakemixFonts.display);
          }
          for (final style in [
            text.titleMedium,
            text.bodyLarge,
            text.bodyMedium,
            text.bodySmall,
            text.labelLarge,
            text.labelMedium,
            text.labelSmall,
          ]) {
            expect(style!.fontFamily, WakemixFonts.text);
          }
          final type = theme.extension<WakemixType>()!;
          expect(type.meta.fontFamily, WakemixFonts.meta);
          expect(type.caption.fontFamily, WakemixFonts.meta);
        },
      );

      test('has the type scale of the tokens', () {
        final text = theme.textTheme;
        final type = theme.extension<WakemixType>()!;
        expect(text.displayLarge!.fontSize, TypeScale.dial);
        expect(text.displayMedium!.fontSize, TypeScale.record);
        expect(text.headlineSmall!.fontSize, TypeScale.rowTime);
        expect(text.titleLarge!.fontSize, TypeScale.title);
        expect(text.bodyMedium!.fontSize, TypeScale.body);
        expect(text.labelMedium!.fontSize, TypeScale.label);
        expect(type.meta.fontSize, TypeScale.label);
        expect(type.caption.fontSize, TypeScale.caption);
        for (final MapEntry(key: role, value: style) in _roles(text).entries) {
          expect(
            style.fontSize,
            greaterThanOrEqualTo(TypeScale.caption),
            reason: role,
          );
        }
      });

      test('themes the switch from the tokens', () {
        final switches = theme.switchTheme;
        const on = {WidgetState.selected};
        const off = <WidgetState>{};
        expect(switches.trackColor!.resolve(on), colors.accent);
        expect(switches.thumbColor!.resolve(on), colors.onAccent);
        expect(switches.trackColor!.resolve(off), colors.surfaceHigh);
        expect(switches.thumbColor!.resolve(off), colors.textMuted);
        expect(switches.trackOutlineColor!.resolve(off), colors.textMuted);
      });

      test('themes chips, buttons and app bars flat, from the tokens', () {
        expect(
          theme.chipTheme.color!.resolve({WidgetState.selected}),
          colors.accent,
        );
        expect(theme.chipTheme.color!.resolve({}), colors.surfaceHigh);
        expect(theme.chipTheme.shape, const StadiumBorder());
        final label = theme.inputDecorationTheme.floatingLabelStyle!;
        expect(
          WidgetStateProperty.resolveAs(label, {WidgetState.focused}).color,
          colors.accentText,
        );
        expect(
          WidgetStateProperty.resolveAs(label, {}).color,
          colors.textMuted,
        );
        expect(theme.appBarTheme.elevation, 0);
        expect(theme.appBarTheme.scrolledUnderElevation, 0);
        expect(theme.appBarTheme.backgroundColor, colors.background);
        final filled = theme.filledButtonTheme.style!;
        expect(filled.backgroundColor!.resolve({}), colors.accent);
        expect(filled.foregroundColor!.resolve({}), colors.onAccent);
        expect(
          filled.shape!.resolve({}),
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(Corners.card)),
          ),
        );
      });

      testWidgets('writes a chip label in the text color of its fill', (
        tester,
      ) async {
        await pumpDesign(
          tester,
          Wrap(
            children: [
              FilterChip(
                label: const Text('Lo-fi'),
                selected: true,
                onSelected: (_) {},
              ),
              FilterChip(label: const Text('Acoustic'), onSelected: (_) {}),
            ],
          ),
          brightness: colors.brightness,
        );

        Color? labelColor(String label) => tester
            .widget<RichText>(
              find.descendant(
                of: find.text(label),
                matching: find.byType(RichText),
              ),
            )
            .text
            .style
            ?.color;
        // The pairs of contrast_test.dart: text on the accent, and text on
        // an input or day key.
        expect(labelColor('Lo-fi'), colors.onAccent);
        expect(labelColor('Acoustic'), colors.text);
      });
    });
  }
}

Map<String, TextStyle> _roles(TextTheme text) => {
  'displayLarge': text.displayLarge!,
  'displayMedium': text.displayMedium!,
  'displaySmall': text.displaySmall!,
  'headlineLarge': text.headlineLarge!,
  'headlineMedium': text.headlineMedium!,
  'headlineSmall': text.headlineSmall!,
  'titleLarge': text.titleLarge!,
  'titleMedium': text.titleMedium!,
  'titleSmall': text.titleSmall!,
  'bodyLarge': text.bodyLarge!,
  'bodyMedium': text.bodyMedium!,
  'bodySmall': text.bodySmall!,
  'labelLarge': text.labelLarge!,
  'labelMedium': text.labelMedium!,
  'labelSmall': text.labelSmall!,
};
