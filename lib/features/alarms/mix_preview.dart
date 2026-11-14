import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shuffle_alarm/core/clip_rule.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/features/alarms/arming.dart';
import 'package:shuffle_alarm/features/ringing/ringing_controller.dart';
import 'package:shuffle_alarm/l10n/texts.dart';
import 'package:shuffle_alarm/platform/providers.dart';
import 'package:shuffle_alarm/platform/sound_player.dart';

/// The preview that plays or loads now, of a sound of Tonight's mix or of the
/// Morning card.
@immutable
class MixPreview {
  const MixPreview(this.soundId, {this.loading = false});

  final String soundId;

  /// Whether its clip still loads: nothing plays yet.
  final bool loading;

  @override
  bool operator ==(Object other) =>
      other is MixPreview &&
      other.soundId == soundId &&
      other.loading == loading;

  @override
  int get hashCode => Object.hash(soundId, loading);

  @override
  String toString() => 'MixPreview($soundId, loading: $loading)';
}

/// How a tap on a preview ended.
enum PreviewOutcome {
  /// It played or stopped.
  played,

  /// The platform did not let a sound play.
  blocked,

  /// Its sound could not be read.
  failed,

  /// An alarm rings, so nothing played.
  notNow,
}

/// What to tell the person after a tap on a preview that ended as [outcome],
/// or null when it played.
String? previewProblem(PreviewOutcome outcome) => switch (outcome) {
  PreviewOutcome.blocked => tr.browserBlockedSound,
  PreviewOutcome.failed => tr.couldNotPlaySound,
  PreviewOutcome.played || PreviewOutcome.notNow => null,
};

/// The preview that plays or loads now, or null.
final mixPreviewProvider = NotifierProvider<MixPreviewController, MixPreview?>(
  MixPreviewController.new,
);

/// Plays a preview of a sound: one clip, by the clip rule, and never while an
/// alarm rings. A ring that starts takes the player over.
class MixPreviewController extends Notifier<MixPreview?> {
  /// Counts the taps. A newer tap or a ring ends the one before.
  var _request = 0;

  @override
  MixPreview? build() {
    ref.listen(ringingProvider, (_, ringing) {
      if (ringing == null) return;
      // Without a stop: the sound of the ring has taken over.
      _request++;
      state = null;
    });
    return null;
  }

  /// Plays the clip of [sound], whose audio is at [audioPath], at [volume]; or
  /// stops it if it plays. Call it from a tap: on the web it arms the alarms
  /// first, as a browser unlocks the sound only in a tap (the user's choice,
  /// 2026-11-02): whoever hears a sound believes the alarm can ring, so it
  /// must.
  Future<PreviewOutcome> toggle(
    Sound sound, {
    required String audioPath,
    required double volume,
  }) async {
    if (state?.soundId == sound.id) {
      await stop();
      return PreviewOutcome.played;
    }
    if (ref.read(ringingProvider) != null) return PreviewOutcome.notNow;
    final request = ++_request;
    state = MixPreview(sound.id, loading: true);
    final player = ref.read(soundPlayerProvider);
    try {
      if (ref.read(armingProvider) case Arming(needed: true, armed: false)) {
        await ref.read(armingProvider.notifier).arm();
        if (!ref.read(armingProvider).armed) return PreviewOutcome.blocked;
      }
      // Without the limit of a ring: a person can wait for a preview.
      await player.preload([audioPath]);
      if (request != _request) return PreviewOutcome.played;
      state = MixPreview(sound.id);
      final window = ClipWindow.of(sound);
      await player.play(
        audioPath,
        from: window.start,
        to: window.end,
        volume: volume,
      );
      return PreviewOutcome.played;
    } on SoundBlockedException {
      return PreviewOutcome.blocked;
    } on Object catch (error) {
      debugPrint('Could not play the preview of ${sound.id}: $error');
      // A tap or a ring came first: nobody waits for this one any more.
      return request == _request
          ? PreviewOutcome.failed
          : PreviewOutcome.played;
    } finally {
      if (ref.mounted && request == _request) state = null;
    }
  }

  /// Stops the preview, if one plays or loads. It can come after the app has
  /// closed, from a page that closes with it.
  Future<void> stop() async {
    if (!ref.mounted || state == null) return;
    _request++;
    state = null;
    await ref.read(soundPlayerProvider).stop();
  }
}
