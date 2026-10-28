import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/data/database.dart';

/// On the web, the database needs two files in `web/` that come from the
/// releases of the drift and sqlite3 packages: the drift worker talks to the
/// app's drift, and both run against the same SQLite build. So they must come
/// from the versions in `pubspec.lock` (docs/DECISIONS.md, task 2.1).
void main() {
  group('The web database files', () {
    test('are the ones the database opens', () {
      expect(File('web/$webWorkerFile').existsSync(), isTrue);
      expect(File('web/$webSqliteFile').existsSync(), isTrue);
    });

    test('come from the locked drift and sqlite3 releases', () {
      final lock = File('pubspec.lock').readAsStringSync();

      expect(_lockedVersion(lock, 'drift'), '2.35.3', reason: _howToUpdate);
      expect(_lockedVersion(lock, 'sqlite3'), '3.8.0', reason: _howToUpdate);
      // The SHA-256 that GitHub lists for each file of those releases.
      expect(
        _sha256('web/$webWorkerFile'),
        'a54b81412d4c4ab56653bb9e4c02912b0820bb37e2bba00722ddef4d78083d4a',
        reason: _howToUpdate,
      );
      expect(
        _sha256('web/$webSqliteFile'),
        'efd308be92a34f3aa15f289a37f213b0230fd80888a1364326ee29579d892d37',
        reason: _howToUpdate,
      );
    });
  });
}

const _howToUpdate =
    'A new drift or sqlite3 version needs the web files of its release: '
    'replace web/drift_worker.js and web/sqlite3.wasm, then the versions and '
    'hashes in this test (docs/DECISIONS.md, task 2.1).';

/// The version of [package] in the text of a `pubspec.lock` file.
String? _lockedVersion(String lock, String package) => RegExp(
  '^  $package:\n(?:    .*\n)*?    version: "([^"]+)"',
  multiLine: true,
).firstMatch(lock)?[1];

String _sha256(String path) =>
    sha256.convert(File(path).readAsBytesSync()).toString();
