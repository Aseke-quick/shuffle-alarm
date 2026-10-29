import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/theme.dart';
import 'package:shuffle_alarm/design/tokens.dart';

/// The contrast rule of the design (spec section 1): every text on its
/// background meets WCAG AA, 4.5:1; non-text parts that show a control or
/// its state, such as switch tracks, 3:1. Text that marks an alarm as off
/// (`textDisabled`) and the hairlines (`outline`) are exempt.
void main() {
  test('the contrast ratio is worked out as WCAG 2.2 says', () {
    expect(_contrast(const Color(0xFF000000), const Color(0xFFFFFFFF)), 21);
    expect(_contrast(const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)), 1);
    // Mid grey on white, a known value: 4.48:1, just below AA.
    expect(
      _contrast(const Color(0xFF777777), const Color(0xFFFFFFFF)),
      closeTo(4.48, 0.01),
    );
  });

  for (final (name, colors) in [
    ('dark', WakemixColors.dark),
    ('light', WakemixColors.light),
  ]) {
    group('The $name colors', () {
      test('give text a contrast of 4.5:1 on each background', () {
        final c = colors;
        for (final (what, text, background) in [
          ('text on the page', c.text, c.background),
          ('text on a card', c.text, c.surface),
          ('text on an input or day key', c.text, c.surfaceHigh),
          ('meta text on the page', c.textMuted, c.background),
          ('meta text on a card', c.textMuted, c.surface),
          ('meta text on an input', c.textMuted, c.surfaceHigh),
          ('accent text on the page', c.accentText, c.background),
          ('accent text on a card', c.accentText, c.surface),
          ('accent text on an input', c.accentText, c.surfaceHigh),
          ('text on the accent', c.onAccent, c.accent),
          ('an error on the page', c.danger, c.background),
          ('an error in a dialog', c.danger, c.surface),
          ('text on an error fill', c.onAccent, c.danger),
          ('a snack bar or tooltip', c.background, c.text),
        ]) {
          expect(
            _contrast(text, background),
            greaterThanOrEqualTo(4.5),
            reason: '$what: $text on $background',
          );
        }
      });

      test('give controls and their states a contrast of 3:1', () {
        final c = colors;
        for (final (what, part, background) in [
          ('a switch that is on', c.accent, c.background),
          ('a switch that is on, on a card', c.accent, c.surface),
          ('the thumb of a switch that is on', c.onAccent, c.accent),
          ('the border of a switch that is off', c.textMuted, c.background),
          ('the thumb of a switch that is off', c.textMuted, c.surfaceHigh),
          ('the border of an input', c.textMuted, c.background),
          ('the border of an input on a card', c.textMuted, c.surface),
          (
            'a day key that is on, next to one that is off',
            c.accent,
            c.surfaceHigh,
          ),
          ('the knob of the dial on its ring', c.accent, c.surfaceHigh),
          ('the focus ring', c.accent, c.background),
          ('the outline record of an error', c.danger, c.background),
        ]) {
          expect(
            _contrast(part, background),
            greaterThanOrEqualTo(3),
            reason: '$what: $part on $background',
          );
        }
      });
    });
  }

  test('the themes give Material the tested colors', () {
    for (final (theme, colors) in [
      (WakemixTheme.dark, WakemixColors.dark),
      (WakemixTheme.light, WakemixColors.light),
    ]) {
      final scheme = theme.colorScheme;
      expect(scheme.brightness, colors.brightness);
      expect(theme.scaffoldBackgroundColor, colors.background);
      expect(scheme.surface, colors.background);
      expect(scheme.onSurface, colors.text);
      expect(scheme.onSurfaceVariant, colors.textMuted);
      expect(scheme.primary, colors.accent);
      expect(scheme.onPrimary, colors.onAccent);
      expect(scheme.error, colors.danger);
      // Material draws the borders of fields, chips and switches in
      // `outline`, so it must be the tested control color.
      expect(scheme.outline, colors.textMuted);
      expect(scheme.outlineVariant, colors.outline);
      expect(theme.extension<WakemixColors>(), colors);
    }
  });

  test('the accent stays cobalt', () {
    for (final colors in [WakemixColors.dark, WakemixColors.light]) {
      for (final color in [colors.accent, colors.accentText]) {
        final hue = HSLColor.fromColor(color).hue;
        expect(hue, inInclusiveRange(220, 232), reason: '$color');
      }
    }
    expect(WakemixColors.dark.accent, const Color(0xFF5B8CFF));
  });
}

/// The WCAG contrast ratio of [a] and [b], from 1 to 21.
double _contrast(Color a, Color b) {
  final (la, lb) = (_luminance(a), _luminance(b));
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// The relative luminance of [color], as WCAG defines it.
double _luminance(Color color) {
  double linear(double channel) => channel <= 0.04045
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * linear(color.r) +
      0.7152 * linear(color.g) +
      0.0722 * linear(color.b);
}
