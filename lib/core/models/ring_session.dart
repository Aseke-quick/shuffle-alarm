import 'package:meta/meta.dart';

import 'package:shuffle_alarm/core/models/ring_event.dart';

/// One time an alarm went off, such as Tuesday's 07:00 alarm: every sound it
/// played, from the first one until Stop, including the rings after each
/// Snooze.
///
/// When the alarm is over, its last event is a [RingAction.stop], or a
/// [RingAction.timeout] if the alarm reached its time cap: a missed alarm.
@immutable
class RingSession {
  RingSession({
    required this.id,
    required this.alarmId,
    required this.scheduledFor,
    List<RingEvent> events = const [],
  }) : events = List.unmodifiable(events);

  final String id;

  /// The `Alarm.id` of the alarm that rang.
  final String alarmId;

  /// When the alarm was set to ring. The rings after a Snooze keep this time.
  final DateTime scheduledFor;

  /// Every sound that played, in the order they played.
  final List<RingEvent> events;

  @override
  bool operator ==(Object other) =>
      other is RingSession &&
      other.id == id &&
      other.alarmId == alarmId &&
      other.scheduledFor == scheduledFor &&
      _sameEvents(other.events, events);

  @override
  int get hashCode =>
      Object.hash(id, alarmId, scheduledFor, Object.hashAll(events));

  @override
  String toString() =>
      'RingSession(id: $id, alarmId: $alarmId, scheduledFor: $scheduledFor, '
      'events: $events)';
}

bool _sameEvents(List<RingEvent> a, List<RingEvent> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
