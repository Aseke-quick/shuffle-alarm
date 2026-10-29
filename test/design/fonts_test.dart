import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/font_licenses.dart';
import 'package:shuffle_alarm/design/fonts.dart';

/// The bundled fonts (docs/DECISIONS.md, task 2.2a): the files are those
/// recorded there, each comes with its license, and the app registers it.
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
    for (final (folder, license) in [
      ('assets/fonts/unbounded', unboundedLicense),
      ('assets/fonts/geist', geistLicense),
      ('assets/fonts/geist_mono', geistLicense),
    ]) {
      final text = File('$folder/OFL.txt').readAsStringSync();
      expect(license, text, reason: folder);
      expect(text, contains('SIL Open Font License, Version 1.1'));
      // Without a Reserved Font Name, a cut-down font may keep its name.
      expect(text, isNot(contains('with Reserved Font Name')));
    }
  });

  test('the app has each family, and Geist stands in for Roboto', () async {
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

    expect(families, containsPair(WakemixFonts.display, [_unbounded]));
    expect(families, containsPair(WakemixFonts.text, [_geist]));
    expect(families, containsPair(WakemixFonts.meta, [_geistMono]));
    // Flutter's web engine downloads Roboto unless the app has a family of
    // that name.
    expect(families, containsPair('Roboto', [_geist]));
  });

  test('registerFontLicenses adds the license of each font once', () async {
    registerFontLicenses();
    registerFontLicenses();

    final fonts = [
      for (final entry in await LicenseRegistry.licenses.toList())
        if (entry.packages.any(
          {WakemixFonts.display, WakemixFonts.text}.contains,
        ))
          entry,
    ];

    expect(fonts.map((entry) => entry.packages.toList()), [
      [WakemixFonts.display],
      [WakemixFonts.text, WakemixFonts.meta],
    ]);
    final unbounded = fonts.first.paragraphs.map((p) => p.text).join('\n');
    expect(unbounded, startsWith('Copyright 2022 The Unbounded Project'));
    expect(unbounded, contains('SIL OPEN FONT LICENSE Version 1.1'));
  });

  test('style sets the wght axis to the weight, for variable fonts', () {
    final style = WakemixFonts.style(
      WakemixFonts.display,
      size: 20,
      weight: FontWeight.w600,
    );

    expect(style.fontWeight, FontWeight.w600);
    expect(style.fontVariations, [const FontVariation('wght', 600)]);
    expect(style.fontFamilyFallback, [WakemixFonts.text]);
    expect(
      WakemixFonts.style(WakemixFonts.text, size: 15).fontFamilyFallback,
      isNull,
    );

    final bold = WakemixFonts.weighted(style, FontWeight.w800);
    expect(bold.fontWeight, FontWeight.w800);
    expect(bold.fontVariations, [const FontVariation('wght', 800)]);
  });
}

const _unbounded = 'assets/fonts/unbounded/Unbounded-Latin.ttf';
const _geist = 'assets/fonts/geist/Geist.ttf';
const _geistMono = 'assets/fonts/geist_mono/GeistMono-Latin.ttf';

const List<(String, String)> _fonts = [
  (
    _unbounded,
    '4dfcb604ac8bf8dacaa647c239ca5deebf7769ccc447489d2a9ae2614e73455f',
  ),
  (_geist, '73894e0448cae90a92b6c2f8732b7bb9acb7b94c418bff559dad4a18e1de9659'),
  (
    _geistMono,
    'ea7d3de6b0599609700b266b2936a6af17f6a5227fb078fb06d04164349f9e90',
  ),
];
