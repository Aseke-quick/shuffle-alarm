import 'package:meta/meta.dart';

import 'package:shuffle_alarm/core/models/sound.dart';

/// The part of a sound's audio file that plays when the sound rings.
///
/// This is the clip rule: a clip plays for at most [maxLength], so the next
/// sound starts after 30 s at the latest, and a built-in clip for at most
/// [maxBuiltinLength]. A clip never runs past the end of its file, so it can
/// be shorter, such as a 12-s voice message; the next sound then starts right
/// after it. A window can be cut shorter ([cutTo]), never made longer.
@immutable
class ClipWindow {
  /// The window of [sound]: from its [Sound.clipStart] until the limit for
  /// its source ([maxLengthFor]) is reached or its file ends, whichever comes
  /// first. A longer file is cut, never rejected, so the alarm still rings.
  factory ClipWindow.of(Sound sound) {
    final limitEnd = sound.clipStart + maxLengthFor(sound.source);
    return ClipWindow._(
      sound.clipStart,
      limitEnd < sound.duration ? limitEnd : sound.duration,
    );
  }

  const ClipWindow._(this.start, this.end);

  /// The longest one sound plays before the next one starts.
  static const maxLength = Duration(seconds: 30);

  /// The longest a built-in clip plays. On iOS the built-in files are the
  /// alarm sounds themselves, and AlarmKit only accepts alarm sounds shorter
  /// than 30 s, so the files are cut to this length too.
  static const maxBuiltinLength = Duration(seconds: 29);

  /// The longest a clip from [source] plays.
  static Duration maxLengthFor(SoundSource source) => switch (source) {
    SoundSource.builtin => maxBuiltinLength,
    SoundSource.user || SoundSource.voice => maxLength,
  };

  /// Where the clip starts in the file.
  final Duration start;

  /// Where the clip stops in the file.
  final Duration end;

  /// How long the clip plays.
  Duration get length => end - start;

  /// This window cut so it plays for at most [length], from the same start,
  /// such as the last clip of a ring that reaches its time cap. A window
  /// that is not longer stays as it is.
  ///
  /// Throws an [ArgumentError] if [length] is not positive.
  ClipWindow cutTo(Duration length) {
    if (length <= Duration.zero) {
      throw ArgumentError('Must be positive, was $length', 'length');
    }
    return length < this.length ? ClipWindow._(start, start + length) : this;
  }

  @override
  bool operator ==(Object other) =>
      other is ClipWindow && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'ClipWindow(start: $start, end: $end)';
}
