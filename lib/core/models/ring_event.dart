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

  /// An event without length, at [at]: a ring that ended while no sound
  /// played, such as a Stop during a snooze or while the browser blocks the
  /// sound. [soundId] is the sound of that moment; Insights counts only the
  /// events with a length as sounds that played.
  const RingEvent.silent({
    required String soundId,
    required DateTime at,
    required RingAction action,
  }) : this(soundId: soundId, startedAt: at, endedAt: at, action: action);

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
