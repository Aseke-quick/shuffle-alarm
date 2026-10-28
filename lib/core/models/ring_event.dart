import 'package:meta/meta.dart';

/// How a sound stopped playing while an alarm rang.
enum RingAction {
  /// The user tapped Stop. The alarm is over.
  stop,

  /// The user tapped Snooze. The alarm rings again after the snooze time.
  snooze,

  /// Nobody tapped anything before the sound's time ran out. The next sound
  /// starts, unless the alarm reached its time cap: then it is over, and
  /// counts as missed.
  timeout,
}

/// One sound that played while an alarm rang.
@immutable
class RingEvent {
  /// Accepts an [endedAt] before [startedAt]: the device clock can jump back
  /// while an alarm rings, and logging must never break an alarm.
  const RingEvent({
    required this.soundId,
    required this.startedAt,
    required this.endedAt,
    required this.action,
  });

  /// The `Sound.id` of the sound that played.
  final String soundId;

  final DateTime startedAt;
  final DateTime endedAt;
  final RingAction action;

  @override
  bool operator ==(Object other) =>
      other is RingEvent &&
      other.soundId == soundId &&
      other.startedAt == startedAt &&
      other.endedAt == endedAt &&
      other.action == action;

  @override
  int get hashCode => Object.hash(soundId, startedAt, endedAt, action);

  @override
  String toString() =>
      'RingEvent(soundId: $soundId, startedAt: $startedAt, '
      'endedAt: $endedAt, action: $action)';
}
