/// Plays the sounds of a ring. Each platform has its own way (`CLAUDE.md`),
/// and the app reaches it only through this interface.
abstract interface class SoundPlayer {
  /// Whether this platform plays sounds yet. Until Phases 4 to 6, only the
  /// web version does.
  bool get playsSounds;

  /// Whether sounds can play only after a tap runs [unlock]: in a browser,
  /// until a tap unlocks the sound of the page.
  bool get needsUnlock;

  /// Unlocks the sound, so it can play later without a tap. Call it from a
  /// tap, such as on "Arm alarms". Returns whether sound can play now.
  Future<bool> unlock();

  /// Loads the sounds at [assets] ahead, so they start without a gap.
  Future<void> preload(Iterable<String> assets);

  /// Plays the part from [from] to [to] of the sound at [asset], an asset
  /// path such as `assets/library/lo-fi/warm-tape.wav`, at [volume] from 0
  /// to 1. Completes when it ends, or when [stop] ends it.
  ///
  /// Throws a [SoundBlockedException] when the platform does not let it
  /// play, such as a browser before a tap. Throws another error when the
  /// sound cannot be read, or not in a moment, such as a file that still loads
  /// on a slow network: a ring must not wait for it in silence.
  Future<void> play(
    String asset, {
    required Duration from,
    required Duration to,
    required double volume,
  });

  /// Plays a tone of [length] that needs no file and no network, at [volume]
  /// from 0 to 1, for a ring that has no sound it can read. Completes when it
  /// ends, or when [stop] ends it.
  ///
  /// Throws a [SoundBlockedException] when the platform does not let it play.
  Future<void> playTone({required Duration length, required double volume});

  /// Stops the sound that plays, if any.
  Future<void> stop();

  /// Stops for good.
  Future<void> dispose();
}

/// The platform does not let a sound play, such as a browser before a tap
/// unlocked the sound of the page.
class SoundBlockedException implements Exception {
  const SoundBlockedException([this.message = 'Sound is blocked']);

  final String message;

  @override
  String toString() => 'SoundBlockedException: $message';
}

/// The player of a platform that does not play sounds yet.
class SilentSoundPlayer implements SoundPlayer {
  const SilentSoundPlayer();

  @override
  bool get playsSounds => false;

  @override
  bool get needsUnlock => false;

  @override
  Future<bool> unlock() async => false;

  @override
  Future<void> preload(Iterable<String> assets) async {}

  @override
  Future<void> play(
    String asset, {
    required Duration from,
    required Duration to,
    required double volume,
  }) => throw const SoundBlockedException('This platform plays no sound yet');

  @override
  Future<void> playTone({required Duration length, required double volume}) =>
      throw const SoundBlockedException('This platform plays no sound yet');

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
