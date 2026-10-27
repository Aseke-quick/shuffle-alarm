import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the layer rules from the Architecture section of CLAUDE.md, and the
/// Material import rule from docs/DECISIONS.md.
void main() {
  group('Layer rules', () {
    test('lib/core is pure Dart: no Flutter, no other app layer', () {
      final violations = _violationsIn(
        'lib/core',
        (target) =>
            target == 'dart:ui' ||
            _flutterLibraries.any(target.startsWith) ||
            (target.startsWith('lib/') && !target.startsWith('lib/core/')),
      );

      expect(violations, isEmpty);
    });

    test('lib/features imports no platform implementation directly', () {
      final violations = _violationsIn(
        'lib/features',
        (target) => _platformImplementations.any(target.startsWith),
      );

      expect(violations, isEmpty);
    });
  });

  test('lib takes Material and Cupertino from their packages, not the SDK', () {
    final violations = _violationsIn(
      'lib',
      (target) =>
          target == 'package:flutter/material.dart' ||
          target == 'package:flutter/cupertino.dart',
    );

    expect(violations, isEmpty);
  });

  test('the import scanner sees every kind of import', () {
    const source = '''
import 'dart:ui';
import 'package:flutter/material.dart' show Colors;
import 'package:shuffle_alarm/data/database.dart';
export '../platform/web/web_alarm_scheduler.dart';
import 'clip_rule.dart'
    if (dart.library.js_interop) '../platform/web/clip_rule_web.dart';
// import 'package:flutter/widgets.dart';
''';

    expect(_importsIn(source, path: 'lib/core/rotation_engine.dart'), [
      'dart:ui',
      'package:flutter/material.dart',
      'lib/data/database.dart',
      'lib/platform/web/web_alarm_scheduler.dart',
      'lib/core/clip_rule.dart',
      'lib/platform/web/clip_rule_web.dart',
    ]);
  });
}

/// Flutter, including its Material and Cupertino libraries, which Flutter
/// 3.47 moved out of the SDK into the `material_ui` and `cupertino_ui`
/// packages.
const _flutterLibraries = [
  'package:flutter',
  'package:material_ui/',
  'package:cupertino_ui/',
];

/// Platform-specific code. Features reach it only through the interfaces
/// in `lib/platform/`.
const _platformImplementations = [
  'lib/platform/android/',
  'lib/platform/ios/',
  'lib/platform/desktop/',
  'lib/platform/web/',
];

/// Every import in the Dart files under [folder] that [isForbidden] rejects.
List<String> _violationsIn(String folder, bool Function(String) isForbidden) {
  final dir = Directory(folder);
  if (!dir.existsSync()) return const [];
  return [
    for (final file in dir.listSync(recursive: true).whereType<File>())
      if (file.path.endsWith('.dart'))
        for (final target in _importsIn(
          file.readAsStringSync(),
          path: file.path.replaceAll(r'\', '/'),
        ))
          if (isForbidden(target)) '${file.path} imports $target',
  ];
}

final _directive = RegExp(r'^\s*(?:import|export)\s([^;]*);', multiLine: true);
final _uriLiteral = RegExp('''['"]([^'"]*)['"]''');

/// The URIs that [source] imports or exports, conditional ones included.
///
/// Files of this app come back as paths from the project root, such as
/// `lib/core/clip_rule.dart`, whether the import uses a package URI or a URI
/// relative to [path].
List<String> _importsIn(String source, {required String path}) => [
  for (final directive in _directive.allMatches(source))
    for (final literal in _uriLiteral.allMatches(directive[1]!))
      _normalize(literal[1]!, from: path),
];

String _normalize(String uri, {required String from}) {
  const package = 'package:shuffle_alarm/';
  if (uri.startsWith(package)) return 'lib/${uri.substring(package.length)}';
  if (Uri.parse(uri).hasScheme) return uri;
  return Uri(path: from).resolve(uri).path;
}
