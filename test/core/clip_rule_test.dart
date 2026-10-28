import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/clip_rule.dart';
import 'package:shuffle_alarm/core/models/sound.dart';

void main() {
  group('ClipWindow', () {
    test('lasts at most 30 s, or 29 s for a built-in clip', () {
      expect(ClipWindow.maxLength, const Duration(seconds: 30));
      expect(ClipWindow.maxBuiltinLength, const Duration(seconds: 29));
      expect(
        ClipWindow.maxLengthFor(SoundSource.builtin),
        ClipWindow.maxBuiltinLength,
      );
      expect(ClipWindow.maxLengthFor(SoundSource.user), ClipWindow.maxLength);
      expect(ClipWindow.maxLengthFor(SoundSource.voice), ClipWindow.maxLength);
    });

    test('plays a built-in clip of 29 s whole', () {
      final window = ClipWindow.of(
        _sound(
          source: SoundSource.builtin,
          duration: const Duration(seconds: 29),
        ),
      );

      expect(window.start, Duration.zero);
      expect(window.end, const Duration(seconds: 29));
      expect(window.length, const Duration(seconds: 29));
    });

    test('plays only the first 29 s of a longer built-in file', () {
      final window = ClipWindow.of(
        _sound(
          source: SoundSource.builtin,
          duration: const Duration(seconds: 29, milliseconds: 500),
        ),
      );

      expect(window.start, Duration.zero);
      expect(window.end, const Duration(seconds: 29));
    });

    test('plays 30 s of a song, from where its clip starts', () {
      final window = ClipWindow.of(
        _sound(clipStart: const Duration(minutes: 1)),
      );

      expect(window.start, const Duration(minutes: 1));
      expect(window.end, const Duration(minutes: 1, seconds: 30));
      expect(window.length, const Duration(seconds: 30));
    });

    test('ends with the file when less than 30 s of it are left', () {
      final window = ClipWindow.of(
        _sound(clipStart: const Duration(minutes: 2, seconds: 50)),
      );

      expect(window.start, const Duration(minutes: 2, seconds: 50));
      expect(window.end, const Duration(minutes: 3));
      expect(window.length, const Duration(seconds: 10));
    });

    test('plays a voice message shorter than 30 s whole', () {
      final window = ClipWindow.of(
        _sound(
          source: SoundSource.voice,
          duration: const Duration(seconds: 12),
        ),
      );

      expect(window.start, Duration.zero);
      expect(window.end, const Duration(seconds: 12));
    });

    test('cuts a voice message that runs past 30 s', () {
      final window = ClipWindow.of(
        _sound(
          source: SoundSource.voice,
          duration: const Duration(seconds: 30, milliseconds: 400),
        ),
      );

      expect(window.start, Duration.zero);
      expect(window.end, const Duration(seconds: 30));
    });

    test('stays inside its file and plays as much as its limit allows', () {
      for (final sound in _soundsAroundTheLimits()) {
        final window = ClipWindow.of(sound);

        expect(window.start, sound.clipStart, reason: '$sound');
        expect(window.end, lessThanOrEqualTo(sound.duration), reason: '$sound');
        expect(window.length, greaterThan(Duration.zero), reason: '$sound');
        expect(
          window.length == ClipWindow.maxLengthFor(sound.source) ||
              window.end == sound.duration,
          isTrue,
          reason: 'A window shorter than its limit ends with the file: $sound',
        );
      }
    });

    test('equals the window of another sound with the same clip', () {
      final song = ClipWindow.of(_sound());
      final voiceMessage = ClipWindow.of(_sound(source: SoundSource.voice));

      expect(voiceMessage, song);
      expect(voiceMessage.hashCode, song.hashCode);
    });

    test('differs from a window with another start or another end', () {
      final lastPart = ClipWindow.of(
        _sound(clipStart: const Duration(minutes: 2, seconds: 40)),
      );
      final shorterLastPart = ClipWindow.of(
        _sound(clipStart: const Duration(minutes: 2, seconds: 45)),
      );
      final song = ClipWindow.of(_sound(clipStart: const Duration(minutes: 1)));
      final builtIn = ClipWindow.of(
        _sound(
          source: SoundSource.builtin,
          clipStart: const Duration(minutes: 1),
        ),
      );

      expect(shorterLastPart.end, lastPart.end);
      expect(shorterLastPart, isNot(lastPart));
      expect(builtIn.start, song.start);
      expect(builtIn, isNot(song));
    });
  });

  group('ClipWindow.cutTo', () {
    test('cuts a window short, from the same start', () {
      final cut = ClipWindow.of(_sound(clipStart: const Duration(minutes: 1)))
          .cutTo(const Duration(seconds: 12));

      expect(cut.start, const Duration(minutes: 1));
      expect(cut.end, const Duration(minutes: 1, seconds: 12));
      expect(cut.length, const Duration(seconds: 12));
    });

    test('never makes a window longer', () {
      final window = ClipWindow.of(
        _sound(
          source: SoundSource.voice,
          duration: const Duration(seconds: 12),
        ),
      );

      expect(window.cutTo(const Duration(seconds: 12)), window);
      expect(window.cutTo(const Duration(minutes: 10)), window);
    });

    test('rejects a length that is not positive', () {
      final window = ClipWindow.of(_sound());

      for (final length in const [Duration.zero, Duration(seconds: -1)]) {
        expect(
          () => window.cutTo(length),
          throwsA(
            isArgumentError.having((error) => error.name, 'name', 'length'),
          ),
          reason: 'Length $length',
        );
      }
    });
  });

  test('no clip over 30 s, and no built-in clip over 29 s', () {
    for (final sound in _soundsAroundTheLimits()) {
      final limit = sound.source == SoundSource.builtin
          ? const Duration(seconds: 29)
          : const Duration(seconds: 30);

      expect(
        ClipWindow.of(sound).length,
        lessThanOrEqualTo(limit),
        reason: '$sound',
      );
    }
  });
}

/// A 3-minute song the user imported, with its clip at the start of the file.
/// A test can change each value the clip rule looks at.
Sound _sound({
  SoundSource source = SoundSource.user,
  Duration duration = const Duration(minutes: 3),
  Duration clipStart = Duration.zero,
}) => Sound(
  id: 'song-1',
  title: 'My song',
  source: source,
  genre: 'rock',
  intensity: 2,
  duration: duration,
  clipStart: clipStart,
);

/// Sounds from every source, with files from 1 ms to 1 hour long, and clips
/// that start anywhere from the start to the last millisecond of their file.
Iterable<Sound> _soundsAroundTheLimits() sync* {
  for (final source in SoundSource.values) {
    for (final fileLength in _fileLengths) {
      for (final clipStart in _clipStartsIn(fileLength)) {
        yield _sound(
          source: source,
          duration: fileLength,
          clipStart: clipStart,
        );
      }
    }
  }
}

/// File lengths from 1 ms to 1 hour, with the ones next to 29 s and 30 s.
const _fileLengths = [
  Duration(milliseconds: 1),
  Duration(seconds: 12),
  Duration(seconds: 28, milliseconds: 999),
  Duration(seconds: 29),
  Duration(seconds: 29, milliseconds: 1),
  Duration(seconds: 29, milliseconds: 999),
  Duration(seconds: 30),
  Duration(seconds: 30, milliseconds: 1),
  Duration(minutes: 3),
  Duration(hours: 1),
];

/// Clip starts in a file of [fileLength], from its start to its last
/// millisecond, with the ones where 31 s, 30 s and 29 s of it are left.
Set<Duration> _clipStartsIn(Duration fileLength) => {
  for (final start in [
    Duration.zero,
    const Duration(milliseconds: 1),
    fileLength ~/ 2,
    fileLength - const Duration(seconds: 31),
    fileLength - const Duration(seconds: 30),
    fileLength - const Duration(seconds: 29),
    fileLength - const Duration(milliseconds: 1),
  ])
    if (start >= Duration.zero && start < fileLength) start,
};
