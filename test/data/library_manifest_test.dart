import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/clip_rule.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/library_manifest.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/features/alarms/alarm_texts.dart';

void main() {
  // The app reads the library from its assets.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parseLibraryManifest', () {
    test('reads every value of each clip, in the order of the manifest', () {
      final entries = parseLibraryManifest(
        _manifest([
          _entry(),
          _entry(id: 'beat', file: 'lo-fi/beat.wav', durationSec: 16.123456),
        ]),
      );

      expect(entries, [
        const LibraryEntry(
          id: 'calm',
          title: 'Calm',
          artist: 'Wakemix',
          genre: 'acoustic',
          intensity: 1,
          file: 'acoustic/calm.wav',
          duration: Duration(seconds: 21, milliseconds: 500),
          license: 'original',
          sourceUrl: 'tool/generate_placeholder_library.dart',
          attribution: '"Calm" by Wakemix',
        ),
        const LibraryEntry(
          id: 'beat',
          title: 'Calm',
          artist: 'Wakemix',
          genre: 'acoustic',
          intensity: 1,
          file: 'lo-fi/beat.wav',
          duration: Duration(seconds: 16, microseconds: 123456),
          license: 'original',
          sourceUrl: 'tool/generate_placeholder_library.dart',
          attribution: '"Calm" by Wakemix',
        ),
      ]);
    });

    test('rejects a clip with a value that is missing, empty or wrong', () {
      final broken = <String, Map<String, Object?>>{
        for (final key in _entry().keys) 'no $key': _entry()..remove(key),
        for (final key in _entry().keys) 'empty $key': _entry()..[key] = '',
        'a number as the title': _entry()..['title'] = 7,
        'intensity 0': _entry(intensity: 0),
        'intensity 4': _entry(intensity: 4),
        'intensity 2.5': _entry(intensity: 2.5),
        'intensity as text': _entry(intensity: '2'),
        'a duration of 0': _entry(durationSec: 0),
        'a negative duration': _entry(durationSec: -1),
        'a duration as text': _entry(durationSec: '20'),
      };

      for (final MapEntry(key: what, value: entry) in broken.entries) {
        expect(
          () => parseLibraryManifest(_manifest([entry])),
          throwsFormatException,
          reason: what,
        );
      }
    });

    test('rejects two clips with the same id', () {
      expect(
        () => parseLibraryManifest(
          _manifest([_entry(), _entry(file: 'lo-fi/calm.wav')]),
        ),
        throwsFormatException,
      );
    });

    test('rejects what is not a manifest', () {
      for (final text in [
        '[]',
        '{}',
        '{"sounds": {}}',
        '{"sounds": ["calm"]}',
        'not JSON',
      ]) {
        expect(
          () => parseLibraryManifest(text),
          throwsFormatException,
          reason: text,
        );
      }
    });
  });

  group('LibraryEntry', () {
    test('is a built-in sound whose audio is its asset', () {
      final [entry] = parseLibraryManifest(_manifest([_entry()]));

      expect(entry.assetPath, 'assets/library/acoustic/calm.wav');
      expect(
        entry.toStoredSound(),
        StoredSound(
          Sound(
            id: 'calm',
            title: 'Calm',
            source: SoundSource.builtin,
            genre: 'acoustic',
            intensity: 1,
            duration: const Duration(seconds: 21, milliseconds: 500),
          ),
          audioPath: 'assets/library/acoustic/calm.wav',
        ),
      );
    });
  });

  group('The library in assets/library', () {
    late List<LibraryEntry> library;

    setUpAll(() {
      library = parseLibraryManifest(File(libraryManifest).readAsStringSync());
    });

    test('is in the app: its manifest and every clip', () async {
      expect(await loadLibraryManifest(rootBundle), library);
      for (final entry in library) {
        final audio = await rootBundle.load(entry.assetPath);
        expect(audio.lengthInBytes, greaterThan(44), reason: entry.file);
      }
    });

    test('has a clip for every audio file in its folder', () {
      final files = {
        for (final file in Directory(libraryFolder).listSync(recursive: true))
          if (file is File)
            file.path.replaceAll(r'\', '/').substring(libraryFolder.length + 1),
      }..remove('manifest.json');

      expect(files, {for (final entry in library) entry.file});
    });

    test('has only licenses that the product rules allow', () {
      // CLAUDE.md: our own clips, CC0 and CC BY 4.0, by their SPDX ids.
      for (final entry in library) {
        expect(
          entry.license,
          isIn(['original', 'CC0-1.0', 'CC-BY-4.0']),
          reason: entry.id,
        );
      }
    });

    test('has WAV files of at most 29 s, as long as the manifest says', () {
      for (final entry in library) {
        final wav = _WavFormat.of(File(entry.assetPath).readAsBytesSync());

        expect(wav.format, _WavFormat.pcm, reason: entry.file);
        expect(wav.channels, 1, reason: entry.file);
        expect(wav.bits, 16, reason: entry.file);
        expect(wav.sampleRate, lessThanOrEqualTo(22050), reason: entry.file);
        expect(wav.duration, entry.duration, reason: entry.file);
        expect(
          wav.duration,
          lessThanOrEqualTo(ClipWindow.maxBuiltinLength),
          reason: entry.file,
        );
      }
    });

    test('has ids and genres that are lowercase words with hyphens', () {
      final words = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
      for (final entry in library) {
        expect(entry.id, matches(words));
        expect(entry.genre, matches(words));
      }
    });

    test('has genres that read well as the editor shows them', () {
      final names = {for (final entry in library) genreName(entry.genre)};

      expect(names, unorderedEquals(['Acoustic', 'Electronic', 'Lo-fi']));
    });
  });
}

/// One sound of a manifest with every value set, and the values given.
Map<String, Object?> _entry({
  String id = 'calm',
  Object? intensity = 1,
  String file = 'acoustic/calm.wav',
  Object? durationSec = 21.5,
}) => {
  'id': id,
  'title': 'Calm',
  'artist': 'Wakemix',
  'genre': 'acoustic',
  'intensity': intensity,
  'file': file,
  'durationSec': durationSec,
  'license': 'original',
  'sourceUrl': 'tool/generate_placeholder_library.dart',
  'attribution': '"Calm" by Wakemix',
};

String _manifest(List<Map<String, Object?>> sounds) =>
    jsonEncode({'sounds': sounds});

/// What the header of a WAV file says about its audio.
class _WavFormat {
  _WavFormat({
    required this.format,
    required this.channels,
    required this.sampleRate,
    required this.bits,
    required this.dataBytes,
  });

  /// Reads the chunks `fmt ` and `data` of the WAV file [bytes].
  factory _WavFormat.of(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    String tag(int at) => String.fromCharCodes(bytes, at, at + 4);
    if (tag(0) != 'RIFF' || tag(8) != 'WAVE') {
      throw const FormatException('Not a WAV file');
    }
    int? format;
    int? channels;
    int? sampleRate;
    int? bits;
    int? dataBytes;
    for (var at = 12; at + 8 <= bytes.length;) {
      final size = data.getUint32(at + 4, Endian.little);
      switch (tag(at)) {
        case 'fmt ':
          format = data.getUint16(at + 8, Endian.little);
          channels = data.getUint16(at + 10, Endian.little);
          sampleRate = data.getUint32(at + 12, Endian.little);
          bits = data.getUint16(at + 22, Endian.little);
        case 'data':
          dataBytes = size;
      }
      // A chunk of an odd size has one byte of padding.
      at += 8 + size + size % 2;
    }
    return _WavFormat(
      format: format!,
      channels: channels!,
      sampleRate: sampleRate!,
      bits: bits!,
      dataBytes: dataBytes!,
    );
  }

  /// The [format] of uncompressed samples.
  static const pcm = 1;

  final int format;
  final int channels;
  final int sampleRate;
  final int bits;
  final int dataBytes;

  /// How long the audio plays.
  Duration get duration {
    final frames = dataBytes ~/ (channels * bits ~/ 8);
    return Duration(
      microseconds: (frames * Duration.microsecondsPerSecond / sampleRate)
          .round(),
    );
  }
}
