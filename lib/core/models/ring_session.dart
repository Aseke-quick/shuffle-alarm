import 'package:meta/meta.dart';

import 'package:shuffle_alarm/core/models/ring_event.dart';

/// How a ring session stands, by its last event.
enum RingOutcome {
  /// The user tapped Stop.
  stopped,

  /// The user tapped Snooze, and the alarm has not rung again yet.
  snoozed,

  /// Nobody tapped anything: it reached its time cap, or it never made a
  /// sound, such as a ring found after its time cap or while another rang.
  /// A tab closed in the middle of a ring leaves a session like this too.
  missed,
}

/// One time an alarm went off, such as Tuesday's 07:00 alarm: every sound it
/// played, from the first one until Stop, including the rings after each
/// Snooze.
///
/// When the alarm is over, its last event is a [RingAction.stop], or a
/// [RingAction.timeout] if the alarm reached its time cap: a missed alarm. A
/// session without events never made a sound, and is missed too.
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

  /// How it stands, by its last event.
  RingOutcome get outcome => switch (events.lastOrNull?.action) {
    RingAction.stop => RingOutcome.stopped,
    RingAction.snooze => RingOutcome.snoozed,
    RingAction.timeout || null => RingOutcome.missed,
  };

  /// This session with [event] as its last event.
  RingSession withEvent(RingEvent event) => RingSession(
    id: id,
    alarmId: alarmId,
    scheduledFor: scheduledFor,
    events: [...events, event],
  );

  /// This session, over at [time] with nobody tapping: missed. One that was
  /// snoozed gets a last event without length, or it would still wait to come
  /// back. Any other has nothing to add.
  RingSession missedAt(DateTime time) => outcome == RingOutcome.snoozed
      ? withEvent(
          RingEvent.silent(
            soundId: events.last.soundId,
            at: time,
            action: RingAction.timeout,
          ),
        )
      : this;

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
