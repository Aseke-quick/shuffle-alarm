/// Makes the placeholder library of task 2.3: nine original clips, three
/// genres with a gentle, a medium and a strong clip each, synthesized here
/// without any download, and `assets/library/manifest.json`, which lists
/// them with license `original` (docs/DECISIONS.md, 2.3).
///
/// Run it from the project root after changing a clip in
/// `tool/placeholder_library/`:
///
/// ```sh
/// dart run tool/generate_placeholder_library.dart
/// ```
///
/// The same code makes the same bytes on every run, and
/// `test/tool/generate_placeholder_library_test.dart` fails when the files in
/// `assets/library/` are not what it makes. It writes the whole manifest, so
/// it is for the placeholders only: when real music joins the library
/// (Phase 3), it must keep those entries, or be retired.
library;

import 'dart:io';

import 'placeholder_library/library.dart';
import 'placeholder_library/synth.dart';

void main() {
  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln('Run this from the project root.');
    exitCode = 64;
    return;
  }
  var clipBytes = 0;
  for (final MapEntry(key: path, value: bytes)
      in placeholderLibrary().entries) {
    File(path)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(bytes);
    if (!path.endsWith('.wav')) {
      stdout.writeln('${_column(bytes.length)}  $path');
      continue;
    }
    clipBytes += bytes.length;
    final samples = samplesOf(bytes);
    final seconds = samples.length / sampleRate;
    stdout.writeln(
      '${_column(bytes.length)}  $path  ${seconds.toStringAsFixed(2)} s, '
      '${loudnessOf(samples).toStringAsFixed(1)} LUFS, '
      'peak ${peakOf(samples).toStringAsFixed(1)} dBFS',
    );
  }
  stdout.writeln(
    '${_column(clipBytes)}  in the clips (budget: ${_column(sizeBudget)})',
  );
}

String _column(int bytes) => '$bytes bytes'.padLeft(15);
