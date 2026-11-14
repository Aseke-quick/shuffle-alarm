import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/font_licenses.dart';
import 'package:shuffle_alarm/design/fonts.dart';

/// The bundled font (docs/DECISIONS.md, task 2.2a, and ADR-005): the file is
/// the one recorded there, it comes with its license, and the app registers
/// it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the font files are the ones docs/DECISIONS.md records', () {
    // A changed file needs a new entry there: where it came from, and how
    // it was cut down.
    for (final (path, sha256Hex) in _fonts) {
      final file = File(path);
      expect(
        sha256.convert(file.readAsBytesSync()).toString(),
        sha256Hex,
        reason: path,
      );
    }
  });

  test('the fonts stay within the web download budget of 600 KB', () {
    final bytes = [for (final (path, _) in _fonts) File(path).lengthSync()]
        .reduce((a, b) => a + b);

    expect(bytes, lessThanOrEqualTo(600 * 1000));
  });

  test('each font folder has its license, the same as in the app', () {
    for (final (folder, license) in [('assets/fonts/geist', geistLicense)]) {
      final text = File('$folder/OFL.txt').readAsStringSync();
      expect(license, text, reason: folder);
      expect(text, contains('SIL Open Font License, Version 1.1'));
      // Without a Reserved Font Name, a cut-down font may keep its name.
      expect(text, isNot(contains('with Reserved Font Name')));
    }
  });

  test('only Geist is bundled: the other fonts of ADR-001 are gone', () {
    expect(
      [for (final entry in Directory('assets/fonts').listSync()) entry.path],
      ['assets/fonts/geist'],
    );
  });

  test('the app has the family, and Geist stands in for Roboto', () async {
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
    final families = {
      for (final family in manifest.cast<Map<String, dynamic>>())
        family['family'] as String: [
          for (final font
              in (family['fonts'] as List).cast<Map<String, dynamic>>())
            font['asset'] as String,
        ],
    };

    expect(families, containsPair(WakemixFonts.text, [_geist]));
    expect(families, isNot(contains('Unbounded')));
    expect(families, isNot(contains('Geist Mono')));
    // Flutter's web engine downloads Roboto unless the app has a family of
    // that name.
    expect(families, containsPair('Roboto', [_geist]));
  });

  test('registerFontLicenses adds the license of the font once', () async {
    registerFontLicenses();
    registerFontLicenses();

    final fonts = [
      for (final entry in await LicenseRegistry.licenses.toList())
        if (entry.packages.contains(WakemixFonts.text)) entry,
    ];

    expect(fonts.map((entry) => entry.packages.toList()), [
      [WakemixFonts.text],
    ]);
    final geist = fonts.single.paragraphs.map((p) => p.text).join('\n');
    expect(geist, contains('SIL OPEN FONT LICENSE Version 1.1'));
  });

  test('style sets the wght axis to the weight, for variable fonts', () {
    final style = WakemixFonts.style(
      WakemixFonts.display,
      size: 20,
      weight: FontWeight.w600,
    );

    expect(style.fontWeight, FontWeight.w600);
    expect(style.fontVariations, [const FontVariation('wght', 600)]);
    expect(style.fontFamily, 'Geist');

    final bold = WakemixFonts.weighted(style, FontWeight.w800);
    expect(bold.fontWeight, FontWeight.w800);
    expect(bold.fontVariations, [const FontVariation('wght', 800)]);
  });
}

const _geist = 'assets/fonts/geist/Geist.ttf';

const List<(String, String)> _fonts = [
  (_geist, '73894e0448cae90a92b6c2f8732b7bb9acb7b94c418bff559dad4a18e1de9659'),
];
