import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/data/library_manifest.dart';

import '../../tool/placeholder_library/clips.dart';
import '../../tool/placeholder_library/library.dart' hide libraryFolder;
import '../../tool/placeholder_library/synth.dart';

void main() {
  late Map<String, Uint8List> made;
  late List<LibraryEntry> manifest;

  setUpAll(() {
    made = placeholderLibrary();
    manifest = parseLibraryManifest(utf8.decode(made[libraryManifest]!));
  });

  test('makes the same bytes on every run', () {
    expect(placeholderLibrary(), made);
  });

  test('made the files in assets/library', () {
    const remake = 'Run: dart run tool/generate_placeholder_library.dart';
    for (final MapEntry(key: path, value: bytes) in made.entries) {
      final file = File(path).readAsBytesSync();
      if (!path.endsWith('.wav')) {
        expect(utf8.decode(file), utf8.decode(bytes), reason: remake);
        continue;
      }
      expect(file.length, bytes.length, reason: '$path. $remake');
      expect(file.sublist(0, 44), bytes.sublist(0, 44), reason: path);
      // Another computer's maths library can round the last bit of a sine
      // differently, so a sample may be one step off there.
      final committed = ByteData.sublistView(file);
      final again = ByteData.sublistView(bytes);
      var furthest = 0;
      for (var i = 44; i < file.length; i += 2) {
        final step =
            committed.getInt16(i, Endian.little) -
            again.getInt16(i, Endian.little);
        furthest = math.max(furthest, step.abs());
      }
      expect(furthest, lessThanOrEqualTo(1), reason: '$path. $remake');
    }
  });

  test('makes a gentle, a medium and a strong clip for 3 genres', () {
    final intensities = <String, List<int>>{};
    for (final entry in manifest) {
      (intensities[entry.genre] ??= []).add(entry.intensity);
    }

    expect(intensities, {
      'acoustic': [1, 2, 3],
      'electronic': [1, 2, 3],
      'lo-fi': [1, 2, 3],
    });
    expect(
      [for (final clip in placeholderClips) clip.id],
      [for (final entry in manifest) entry.id],
    );
  });

  test('makes clips of our own, made by this tool', () {
    for (final entry in manifest) {
      expect(entry.license, 'original');
      expect(entry.artist, 'Wakemix');
      expect(entry.sourceUrl, generatorPath);
      expect(entry.attribution, contains(entry.title));
    }
    expect(File(generatorPath).existsSync(), isTrue);
  });

  test('makes WAV files, PCM 16-bit mono at 22.05 kHz, within budget', () {
    var total = 0;
    for (final entry in manifest) {
      final bytes = made['$libraryFolder/${entry.file}']!;
      final header = ByteData.sublistView(bytes, 0, 44);
      expect(header.getUint16(20, Endian.little), 1, reason: 'PCM');
      expect(header.getUint16(22, Endian.little), 1, reason: 'mono');
      expect(header.getUint32(24, Endian.little), 22050);
      expect(header.getUint16(34, Endian.little), 16, reason: 'bits');
      total += bytes.length;
    }

    expect(total, lessThanOrEqualTo(sizeBudget));
  });

  test('makes each genre louder and brighter from gentle to strong', () {
    for (final genre in ['acoustic', 'electronic', 'lo-fi']) {
      final clips = [
        for (final entry in manifest)
          if (entry.genre == genre)
            samplesOf(made['$libraryFolder/${entry.file}']!),
      ];
      final loudness = [for (final clip in clips) loudnessOf(clip)];
      final brightness = [for (final clip in clips) _brightness(clip)];

      expect(loudness, _rising, reason: '$genre: $loudness');
      expect(brightness, _rising, reason: '$genre: $brightness');
    }
  });
}

/// A list of numbers in which each is above the one before.
final Matcher _rising = predicate<List<double>>(
  (values) =>
      [for (var i = 1; i < values.length; i++) values[i] > values[i - 1]]
          .every((rises) => rises),
  'rising',
);

/// The share of the energy of [samples] above about 2 kHz.
double _brightness(List<double> samples) {
  final high = Biquad.highPass(2000);
  var above = 0.0;
  var all = 0.0;
  for (final x in samples) {
    final y = high.process(x);
    above += y * y;
    all += x * x;
  }
  return above / all;
}
