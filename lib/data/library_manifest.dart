import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';

/// Where the built-in library is among the app's assets: `manifest.json`,
/// and a folder of clips for each genre (task 2.3).
const libraryFolder = 'assets/library';

/// The asset that lists every clip of the built-in library.
const libraryManifest = '$libraryFolder/manifest.json';

/// One clip of the built-in library, as `manifest.json` lists it.
@immutable
class LibraryEntry {
  const LibraryEntry({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    required this.intensity,
    required this.file,
    required this.duration,
    required this.license,
    required this.sourceUrl,
    required this.attribution,
  });

  /// The entry in [json], one sound of the manifest.
  ///
  /// Throws a [FormatException] if a value is missing, empty or of the wrong
  /// kind.
  factory LibraryEntry.fromJson(Map<String, Object?> json) {
    String text(String key) => switch (json[key]) {
      final String value when value.isNotEmpty => value,
      _ => throw FormatException('"$key" must be a text, not empty', json),
    };
    return LibraryEntry(
      id: text('id'),
      title: text('title'),
      artist: text('artist'),
      genre: text('genre'),
      intensity: switch (json['intensity']) {
        final int level
            when level >= Sound.minIntensity && level <= Sound.maxIntensity =>
          level,
        _ => throw FormatException('"intensity" must be 1, 2 or 3', json),
      },
      file: text('file'),
      duration: switch (json['durationSec']) {
        final num seconds when seconds > 0 => Duration(
          microseconds: (seconds * Duration.microsecondsPerSecond).round(),
        ),
        _ => throw FormatException('"durationSec" must be above 0', json),
      },
      license: text('license'),
      sourceUrl: text('sourceUrl'),
      attribution: text('attribution'),
    );
  }

  /// Unique in the library. The sound keeps it in the database, with its
  /// weight.
  final String id;

  final String title;
  final String artist;
  final String genre;

  /// From 1 (gentle) to 3 (strong), as `Sound.intensity`.
  final int intensity;

  /// Where the clip is in [libraryFolder], such as
  /// `acoustic/quiet-strings.wav`.
  final String file;

  /// The length of the clip (`durationSec` in the manifest).
  final Duration duration;

  /// `original` for our own clips, or the license of the clip (`CLAUDE.md`).
  final String license;

  /// Where the clip comes from: for our own clips, the tool that made them.
  final String sourceUrl;

  /// The credit for the Credits screen (task 3.6).
  final String attribution;

  /// The asset of [file], such as `assets/library/acoustic/quiet-strings.wav`.
  String get assetPath => '$libraryFolder/$file';

  /// This clip as a built-in sound, with its asset as where its audio is.
  StoredSound toStoredSound() => StoredSound(
    Sound(
      id: id,
      title: title,
      source: SoundSource.builtin,
      genre: genre,
      intensity: intensity,
      duration: duration,
    ),
    audioPath: assetPath,
  );

  @override
  bool operator ==(Object other) =>
      other is LibraryEntry &&
      other.id == id &&
      other.title == title &&
      other.artist == artist &&
      other.genre == genre &&
      other.intensity == intensity &&
      other.file == file &&
      other.duration == duration &&
      other.license == license &&
      other.sourceUrl == sourceUrl &&
      other.attribution == attribution;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    artist,
    genre,
    intensity,
    file,
    duration,
    license,
    sourceUrl,
    attribution,
  );

  @override
  String toString() =>
      'LibraryEntry(id: $id, title: $title, artist: $artist, genre: $genre, '
      'intensity: $intensity, file: $file, duration: $duration, '
      'license: $license, sourceUrl: $sourceUrl, attribution: $attribution)';
}

/// The clips that the manifest [text] lists, in its order: a JSON object
/// whose `sounds` are [LibraryEntry]s.
///
/// Throws a [FormatException] if [text] is not such a manifest, if an entry
/// is not complete, or if two entries have the same id.
List<LibraryEntry> parseLibraryManifest(String text) {
  final Object? json = jsonDecode(text);
  if (json case {'sounds': final List<Object?> sounds}) {
    final entries = [
      for (final sound in sounds)
        switch (sound) {
          final Map<String, Object?> entry => LibraryEntry.fromJson(entry),
          _ => throw FormatException('A sound must be an object', sound),
        },
    ];
    final ids = <String>{};
    for (final entry in entries) {
      if (!ids.add(entry.id)) {
        throw FormatException('Two sounds have the id "${entry.id}"');
      }
    }
    return entries;
  }
  throw const FormatException('A manifest is an object with "sounds"');
}

/// The clips of the built-in library, from the app's [assets], such as
/// `rootBundle`.
Future<List<LibraryEntry>> loadLibraryManifest(AssetBundle assets) async =>
    parseLibraryManifest(await assets.loadString(libraryManifest));
