import 'package:meta/meta.dart';

import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';

/// One sound that played in a [Morning].
@immutable
class MorningSound {
  const MorningSound({
    required this.soundId,
    required this.firstAt,
    required this.played,
  });

  /// The `Sound.id`.
  final String soundId;

  /// How long after the alarm it first played.
  final Duration firstAt;

  /// How long it played in all.
  final Duration played;

  @override
  bool operator ==(Object other) =>
      other is MorningSound &&
      other.soundId == soundId &&
      other.firstAt == firstAt &&
      other.played == played;

  @override
  int get hashCode => Object.hash(soundId, firstAt, played);

  @override
  String toString() =>
      'MorningSound($soundId, firstAt: $firstAt, played: $played)';
}

/// What a ring that a Stop ended came to, read from its session: what the
/// Morning card shows (task 2.5b).
///
/// Times count from when the alarm was set to ring, as moments, so they hold
/// across a change of the clock. A clock that jumped back during the ring can
/// make them negative, so they stop at nothing.
@immutable
class Morning {
  Morning._({
    required this.wokeAt,
    required this.afterAlarm,
    required this.snoozes,
    required List<MorningSound> sounds,
  }) : sounds = List.unmodifiable(sounds);

  /// When the user woke: the moment of the Stop.
  final DateTime wokeAt;

  /// How long after the alarm they woke.
  final Duration afterAlarm;

  /// How many times they tapped Snooze.
  final int snoozes;

  /// Each sound that played once, in the order they first played. Only the
  /// events with a length count, so none when no sound played, such as with
  /// the sound blocked.
  final List<MorningSound> sounds;

  /// The morning of [session], or null unless a Stop ended it: a ring that is
  /// snoozed or was missed has no morning yet.
  static Morning? of(RingSession session) {
    if (session.outcome != RingOutcome.stopped) return null;
    final alarm = session.scheduledFor;
    final wokeAt = session.events.last.endedAt;
    final sounds = <String, MorningSound>{};
    for (final event in session.events.where((event) => event.played)) {
      final length = _notNegative(event.endedAt.difference(event.startedAt));
      final before = sounds[event.soundId];
      sounds[event.soundId] = MorningSound(
        soundId: event.soundId,
        firstAt:
            before?.firstAt ?? _notNegative(event.startedAt.difference(alarm)),
        played: (before?.played ?? Duration.zero) + length,
      );
    }
    return Morning._(
      wokeAt: wokeAt,
      afterAlarm: _notNegative(wokeAt.difference(alarm)),
      snoozes: session.events
          .where((event) => event.action == RingAction.snooze)
          .length,
      sounds: sounds.values.toList(),
    );
  }
}

Duration _notNegative(Duration length) =>
    length.isNegative ? Duration.zero : length;
