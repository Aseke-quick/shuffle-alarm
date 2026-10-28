import 'package:meta/meta.dart';

/// Where a sound comes from.
enum SoundSource {
  /// A clip from the built-in library in `assets/library/`.
  builtin,

  /// A song the user imported. It stays on the device.
  user,

  /// A voice message the user recorded. It stays on the device.
  voice,
}

/// A sound an alarm can play: a clip from an audio file.
///
/// The clip starts at [clipStart]; `ClipWindow.of` in
/// `lib/core/clip_rule.dart` says where it ends.
@immutable
class Sound {
  /// Throws an [ArgumentError] if [intensity] is not 1–3, [duration] is not
  /// positive, or [clipStart] is not inside the file.
  Sound({
    required this.id,
    required this.title,
    required this.source,
    required this.genre,
    required this.intensity,
    required this.duration,
    this.clipStart = Duration.zero,
  }) {
    RangeError.checkValueInInterval(
      intensity,
      minIntensity,
      maxIntensity,
      'intensity',
    );
    if (duration <= Duration.zero) {
      throw ArgumentError('Must be positive, was $duration', 'duration');
    }
    if (clipStart < Duration.zero || clipStart >= duration) {
      throw ArgumentError(
        'Must be from 0 to before the end of the file ($duration), '
            'was $clipStart',
        'clipStart',
      );
    }
  }

  /// The gentlest [intensity]: soft and melodic.
  static const minIntensity = 1;

  /// The strongest [intensity].
  static const maxIntensity = 3;

  /// Unique among all sounds. A built-in sound keeps the id from
  /// `assets/library/manifest.json`.
  final String id;

  final String title;
  final SoundSource source;

  /// The genre it belongs to. An alarm plays the built-in sounds of its
  /// `genres`, and the user's own sounds whatever their genre.
  final String genre;

  /// From [minIntensity] (gentle, melodic) to [maxIntensity] (strong).
  final int intensity;

  /// The length of the whole audio file.
  final Duration duration;

  /// Where the clip starts in the file. Built-in clips are cut already, so
  /// theirs is zero.
  final Duration clipStart;

  @override
  bool operator ==(Object other) =>
      other is Sound &&
      other.id == id &&
      other.title == title &&
      other.source == source &&
      other.genre == genre &&
      other.intensity == intensity &&
      other.duration == duration &&
      other.clipStart == clipStart;

  @override
  int get hashCode =>
      Object.hash(id, title, source, genre, intensity, duration, clipStart);

  @override
  String toString() =>
      'Sound(id: $id, title: $title, source: $source, genre: $genre, '
      'intensity: $intensity, duration: $duration, clipStart: $clipStart)';
}
