import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shuffle_alarm/core/fallback_tone.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/core/morning.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/design/components/record.dart';
import 'package:shuffle_alarm/features/alarms/tonight_mix.dart';

/// The ring session of the Morning card that is open or opens now: a ring that
/// a Stop ended. Null without one. It lives in memory only, so a reload ends
/// the card, and the session stays in the log without an answer.
final morningCardProvider = NotifierProvider<MorningCard, RingSession?>(
  MorningCard.new,
);

/// The card behind [morningCardProvider], which `RingingController` keeps.
class MorningCard extends Notifier<RingSession?> {
  @override
  RingSession? build() => null;

  /// The session of the card, or null without one.
  RingSession? get session => state;

  /// Opens the card of [session], or ends the card with null.
  set session(RingSession? session) => state = session;
}

/// Whether the Morning card opens after a Stop: on until the person turns it
/// off, and also when the setting cannot be read.
final morningCardOnProvider = NotifierProvider<MorningCardSetting, bool>(
  MorningCardSetting.new,
);

/// Reads and saves that choice. A ring never waits for it: a Stop reads what it
/// holds now, and a failure here only goes to the debug log.
class MorningCardSetting extends Notifier<bool> {
  @override
  bool build() {
    unawaited(_load());
    return true;
  }

  Future<void> _load() async {
    try {
      final on = await ref.read(settingsRepositoryProvider).morningCard();
      if (ref.mounted) state = on;
    } on Object catch (error) {
      debugPrint('Could not read the Morning card setting: $error');
    }
  }

  /// Turns the card [on] or off. If that cannot be saved, the choice holds
  /// until the app closes.
  Future<void> turn({required bool on}) async {
    state = on;
    try {
      await ref.read(settingsRepositoryProvider).saveMorningCard(on: on);
    } on Object catch (error) {
      debugPrint('Could not save the Morning card setting: $error');
    }
  }
}

/// The sounds a ring can play, for the card to name: none when they cannot be
/// read, as the card then still says when the user woke.
final FutureProvider<List<StoredSound>> morningSoundsProvider =
    FutureProvider.autoDispose((ref) async {
      try {
        return await ref.read(ringSoundsProvider)();
      } on Object catch (error) {
        debugPrint('Could not read the sounds of the Morning card: $error');
        return const [];
      }
    });

/// One sound on the Morning card.
@immutable
class MorningCardSound {
  const MorningCardSound({
    required this.sound,
    required this.played,
    this.audioPath,
  });

  final Sound sound;

  /// When it played.
  final MorningSound played;

  /// Where its audio is, or null without a file, such as the tone.
  final String? audioPath;
}

/// The sounds of [morning] that the card can name, in the order they played,
/// out of the sounds in [stored]. A sound deleted since is left out, as nothing
/// says its title any more. The tone is saved nowhere, and is there too.
List<MorningCardSound> morningCardSounds(
  Morning morning,
  List<StoredSound> stored,
) {
  final byId = {for (final sound in stored) sound.sound.id: sound};
  return [
    for (final played in morning.sounds)
      if (byId[played.soundId] case final sound?)
        MorningCardSound(
          sound: sound.sound,
          played: played,
          audioPath: sound.audioPath,
        )
      else if (played.soundId == fallbackTone.id)
        MorningCardSound(sound: fallbackTone, played: played),
  ];
}

/// The segments of a record for [sounds]: how long each one played, and how
/// strong it is.
List<RecordSegment> morningRecordSegments(List<MorningCardSound> sounds) => [
  for (final sound in sounds)
    RecordSegment(
      length: sound.played.played,
      strength: recordStrengthOf(sound.sound),
    ),
];
