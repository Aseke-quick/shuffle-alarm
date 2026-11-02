import 'package:shuffle_alarm/core/models/sound.dart';

/// The sound a ring falls back on when it has no other, such as when the
/// database has no sounds and the library cannot be read: a tone the player
/// makes itself, without a file or a network (`SoundPlayer.playTone`).
///
/// It is not saved anywhere, so it has no weight. As a built-in sound it
/// follows the clip rule, and one tone after the other is what a pool of one
/// sound plays (`ShuffleBag`).
final fallbackTone = Sound(
  id: 'wakemix-tone',
  title: 'Alarm tone',
  source: SoundSource.builtin,
  genre: 'tone',
  intensity: Sound.maxIntensity,
  duration: const Duration(seconds: 29),
);
