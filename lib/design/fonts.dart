import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/font_licenses.dart';

/// The three bundled font families (`pubspec.yaml`, `assets/fonts/`). The
/// app never downloads a font.
abstract final class WakemixFonts {
  /// Unbounded: times, screen titles and the wordmark. Latin only.
  static const display = 'Unbounded';

  /// Geist: body text, buttons, labels, and anything people type. It also
  /// has Cyrillic and Vietnamese.
  static const text = 'Geist';

  /// Geist Mono: small counters and captions, whose fixed-width digits keep
  /// a countdown steady. Latin only.
  static const meta = 'Geist Mono';

  /// A text style in [family] at [size] and [weight].
  ///
  /// The fonts are variable fonts, and some platforms draw them at their
  /// default weight unless the `wght` axis is set too, so [weight] goes into
  /// both `fontWeight` and `fontVariations`. Glyphs that the Latin-only
  /// fonts lack, such as Cyrillic, come from Geist.
  static TextStyle style(
    String family, {
    required double size,
    FontWeight weight = FontWeight.w400,
    double? height,
    double? letterSpacing,
    Color? color,
  }) => TextStyle(
    fontFamily: family,
    fontFamilyFallback: family == text ? null : const [text],
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

/// Adds the Open Font License of each bundled font to the app's licenses,
/// which the Credits screen (task 3.6) lists. Only the first call does
/// anything.
void registerFontLicenses() {
  if (_licensesAdded) return;
  _licensesAdded = true;
  LicenseRegistry.addLicense(
    () => Stream.fromIterable(const [
      LicenseEntryWithLineBreaks([WakemixFonts.display], unboundedLicense),
      LicenseEntryWithLineBreaks([
        WakemixFonts.text,
        WakemixFonts.meta,
      ], geistLicense),
    ]),
  );
}
