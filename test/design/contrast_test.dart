import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/theme.dart';
import 'package:shuffle_alarm/design/tokens.dart';

/// The contrast rule of the design (spec of redesign 2, section 1): every
/// text on its background meets WCAG AA, 4.5:1; non-text parts that show a
/// control or its state, such as switch tracks, 3:1. A page is its color
/// with a color field over it, and a glass card the glass over that. Text
/// that marks an alarm as off (`textDisabled`) and the hairlines (`outline`,
/// `glassLine`) are exempt.
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
      // A glass card over each color field at its strongest, and over the
      // bare page: the lightest and the darkest a card can be.
      final pages = [
        colors.background,
        for (final field in [
          colors.fieldOlive,
          colors.fieldPine,
          colors.fieldBronze,
        ])
          Color.alphaBlend(field, colors.background),
      ];
      final cards = [
        for (final page in pages) Color.alphaBlend(colors.glass, page),
      ];

      test('give text a contrast of 4.5:1 on each background', () {
        final c = colors;
        for (final (what, text, background) in [
          ('text on a solid card', c.text, c.surface),
          ('text on an input or day key', c.text, c.surfaceHigh),
          ('meta text on a solid card', c.textMuted, c.surface),
          ('meta text on an input', c.textMuted, c.surfaceHigh),
          ('accent text on a solid card', c.accentText, c.surface),
          ('accent text on an input', c.accentText, c.surfaceHigh),
          ('text on the accent', c.onAccent, c.accent),
          ('an error in a dialog', c.danger, c.surface),
          ('text on an error fill', c.onAccent, c.danger),
          ('a snack bar or tooltip', c.background, c.text),
          for (final page in pages) ...[
            ('text on the page', c.text, page),
            ('meta text on the page', c.textMuted, page),
            ('accent text on the page', c.accentText, page),
            ('an error on the page', c.danger, page),
          ],
          for (final card in cards) ...[
            ('text on a glass card', c.text, card),
            ('meta text on a glass card', c.textMuted, card),
            ('accent text on a glass card', c.accentText, card),
          ],
          for (final fill in [
            WakemixColors.gentleFill,
            WakemixColors.mediumFill,
            WakemixColors.strongFill,
          ])
            ('text on a sound card', WakemixColors.onStrength, fill),
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
          ('a switch that is on, on a solid card', c.accent, c.surface),
          ('the thumb of a switch that is on', c.onAccent, c.accent),
          ('the thumb of a switch that is off', c.textMuted, c.surfaceHigh),
          ('the border of an input on a solid card', c.textMuted, c.surface),
          (
            'a day key that is on, next to one that is off',
            c.accent,
            c.surfaceHigh,
          ),
          for (final surface in [...pages, ...cards]) ...[
            ('a switch that is on', c.accent, surface),
            ('the border of a switch or an input', c.textMuted, surface),
            ('the focus ring', c.accent, surface),
            ('the mark of an error', c.danger, surface),
            ('the mark of a gentle sound', c.gentle, surface),
            ('the mark of a medium sound', c.medium, surface),
            ('the mark of a strong sound', c.strong, surface),
          ],
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

  test('the look is soft: no pure black or white page, a cream accent', () {
    // What the user chose on 2026-11-14 (ADR-005): rich, quiet colors.
    expect(WakemixColors.dark.background, isNot(const Color(0xFF000000)));
    expect(WakemixColors.light.background, isNot(const Color(0xFFFFFFFF)));
    expect(WakemixColors.dark.accent, const Color(0xFFE2D398));
    for (final colors in [WakemixColors.dark, WakemixColors.light]) {
      // Olive to sand: a warm hue, never a blue or a neon.
      final hue = HSLColor.fromColor(colors.accent).hue;
      expect(hue, inInclusiveRange(40, 80), reason: '${colors.accent}');
    }
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
