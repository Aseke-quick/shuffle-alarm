/// The placeholder library of task 2.3 as files: a WAV file for each clip of
/// [placeholderClips], and `assets/library/manifest.json`.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'clips.dart';
import 'synth.dart';

/// Where the library is in the project.
const libraryFolder = 'assets/library';

/// The tool that makes the placeholders: the source of our own clips, which
/// the manifest names as their `sourceUrl`.
const generatorPath = 'tool/generate_placeholder_library.dart';

/// The artist of every placeholder clip.
const artist = 'Wakemix';

/// The most bytes the clips may take together (docs/DECISIONS.md, 2.3).
const sizeBudget = 8000000;

/// Every file of the placeholder library, by its path from the project
/// root: the clips in the order of the manifest, then the manifest.
Map<String, Uint8List> placeholderLibrary() {
  final files = <String, Uint8List>{};
  final sounds = <Map<String, Object>>[];
  for (final clip in placeholderClips) {
    final pcm = pcm16(clip.make());
    final file = '${clip.genre}/${clip.id}.wav';
    files['$libraryFolder/$file'] = wav(pcm);
    sounds.add({
      'id': clip.id,
      'title': clip.title,
      'artist': artist,
      'genre': clip.genre,
      'intensity': clip.intensity,
      'file': file,
      'durationSec': pcm.length / sampleRate,
      'license': 'original',
      'sourceUrl': generatorPath,
      'attribution': '"${clip.title}" by $artist, an original placeholder.',
    });
  }
  const json = JsonEncoder.withIndent('  ');
  files['$libraryFolder/manifest.json'] = utf8.encode(
    '${json.convert({'sounds': sounds})}\n',
  );
  return files;
}

/// The samples of a WAV file that [wav] made, from -1 to 1.
List<double> samplesOf(Uint8List file) {
  final data = ByteData.sublistView(file, 44);
  return [
    for (var i = 0; i + 1 < data.lengthInBytes; i += 2)
      data.getInt16(i, Endian.little) / 32767,
  ];
}
