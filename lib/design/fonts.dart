import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/font_licenses.dart';

/// The bundled font (`pubspec.yaml`, `assets/fonts/`): Geist, for everything
/// (ADR-005). The app never downloads a font.
abstract final class WakemixFonts {
  /// Geist: text, buttons, labels, the big numerals and anything people type.
  /// It also has Cyrillic and Vietnamese.
  static const text = 'Geist';

  /// The family of times, titles and the wordmark: Geist, heavier and
  /// tighter.
  static const String display = text;

  /// The family of small counters and captions: Geist.
  static const String meta = text;

  /// A text style in [family] at [size] and [weight].
  ///
  /// Geist is a variable font, and some platforms draw one at its default
  /// weight unless the `wght` axis is set too, so [weight] goes into both
  /// `fontWeight` and `fontVariations`.
  static TextStyle style(
    String family, {
    required double size,
    FontWeight weight = FontWeight.w400,
    double? height,
    double? letterSpacing,
    Color? color,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );

  /// [style] at [weight], with the `wght` axis set to match (see [style]).
  /// Use it instead of `copyWith(fontWeight: ...)`.
  static TextStyle weighted(TextStyle style, FontWeight weight) =>
      style.copyWith(
        fontWeight: weight,
        fontVariations: [FontVariation.weight(weight.value.toDouble())],
      );
}

var _licensesAdded = false;

/// Adds the Open Font License of the bundled font to the app's licenses,
/// which the Credits screen (task 3.6) lists. Only the first call does
/// anything.
void registerFontLicenses() {
  if (_licensesAdded) return;
  _licensesAdded = true;
  LicenseRegistry.addLicense(
    () => Stream.fromIterable(const [
      LicenseEntryWithLineBreaks([WakemixFonts.text], geistLicense),
    ]),
  );
}
