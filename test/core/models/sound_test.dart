import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/models/sound.dart';

void main() {
  group('Sound', () {
    test('keeps every value it was given', () {
      final sound = Sound(
        id: 'song-1',
        title: 'My song',
        source: SoundSource.user,
        genre: 'rock',
        intensity: 3,
        duration: const Duration(minutes: 3),
        clipStart: const Duration(seconds: 75),
      );

      expect(sound.id, 'song-1');
      expect(sound.title, 'My song');
      expect(sound.source, SoundSource.user);
      expect(sound.genre, 'rock');
      expect(sound.intensity, 3);
      expect(sound.duration, const Duration(minutes: 3));
      expect(sound.clipStart, const Duration(seconds: 75));
    });

    test('its clip starts at the beginning of the file by default', () {
      final sound = Sound(
        id: 'pop-01',
        title: 'Sunrise',
        source: SoundSource.builtin,
        genre: 'pop',
        intensity: 1,
        duration: const Duration(seconds: 29),
      );

      expect(sound.clipStart, Duration.zero);
    });

    test('accepts intensity 1 (gentle) to 3 (strong)', () {
      expect(Sound.minIntensity, 1);
      expect(Sound.maxIntensity, 3);
      for (final intensity in [1, 2, 3]) {
        expect(_sound(intensity: intensity).intensity, intensity);
      }
    });

    test('rejects an intensity outside 1 to 3', () {
      expect(() => _sound(intensity: 0), _throwsArgumentErrorFor('intensity'));
      expect(() => _sound(intensity: 4), _throwsArgumentErrorFor('intensity'));
    });

    test('rejects a file without length', () {
      expect(
        () => _sound(duration: Duration.zero, clipStart: Duration.zero),
        _throwsArgumentErrorFor('duration'),
      );
      expect(
        () => _sound(
          duration: const Duration(seconds: -1),
          clipStart: Duration.zero,
        ),
        _throwsArgumentErrorFor('duration'),
      );
    });

    test('rejects a clip that starts outside its file', () {
      for (final clipStart in const [
        Duration(seconds: -1),
        Duration(minutes: 3),
        Duration(minutes: 4),
      ]) {
        expect(
          () => _sound(clipStart: clipStart),
          _throwsArgumentErrorFor('clipStart'),
        );
      }
    });

    test('accepts a clip that starts just before the end of its file', () {
      const lastMillisecond = Duration(
        minutes: 2,
        seconds: 59,
        milliseconds: 999,
      );

      expect(_sound(clipStart: lastMillisecond).clipStart, lastMillisecond);
    });

    test('equals a sound with the same values', () {
      expect(_sound(), _sound());
      expect(_sound().hashCode, _sound().hashCode);
    });

    test('differs from a sound with one other value', () {
      final sound = _sound();

      for (final other in [
        _sound(id: 'song-2'),
        _sound(title: 'Other song'),
        _sound(source: SoundSource.voice),
        _sound(genre: 'jazz'),
        _sound(intensity: 3),
        _sound(duration: const Duration(minutes: 4)),
        _sound(clipStart: const Duration(seconds: 30)),
      ]) {
        expect(other, isNot(sound));
      }
    });
  });

  test('a sound is built in, imported by the user, or a voice message', () {
    expect(SoundSource.values.map((source) => source.name), [
      'builtin',
      'user',
      'voice',
    ]);
  });
}

/// A 3-minute song the user imported, with a value in every field, so a test
/// can change any one of them.
Sound _sound({
  String id = 'song-1',
  String title = 'My song',
  SoundSource source = SoundSource.user,
  String genre = 'rock',
  int intensity = 2,
  Duration duration = const Duration(minutes: 3),
  Duration clipStart = const Duration(minutes: 1),
}) => Sound(
  id: id,
  title: title,
  source: source,
  genre: genre,
  intensity: intensity,
  duration: duration,
  clipStart: clipStart,
);

/// Throws an [ArgumentError] about the argument named [name].
Matcher _throwsArgumentErrorFor(String name) =>
    throwsA(isArgumentError.having((error) => error.name, 'name', name));
