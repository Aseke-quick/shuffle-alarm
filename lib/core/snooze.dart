import 'package:shuffle_alarm/core/due_rings.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';

/// How long Snooze silences an alarm, unless the user sets another time.
const defaultSnooze = Duration(minutes: 5);

/// The ring that comes back after the user tapped Snooze at [at] while [due]
/// rang and the sound with [soundId] played: [snooze] after the tap, with the
/// time the alarm was set for.
DueRing ringAfterSnooze(
  DueRing due, {
  required String soundId,
  required DateTime at,
  Duration snooze = defaultSnooze,
}) => DueRing(
  due.alarm,
  scheduledFor: due.scheduledFor,
  startsAt: at.add(snooze),
  snoozedSoundId: soundId,
);

/// The ring that [session] of [alarm] still waits for, or null if it is not
/// snoozed: its last event says when the user tapped Snooze. So a snooze
/// outlives a reload of the app, without being saved anywhere else.
DueRing? snoozedRingOf(
  RingSession session,
  Alarm alarm, {
  Duration snooze = defaultSnooze,
}) {
  if (session.outcome != RingOutcome.snoozed) return null;
  final RingEvent(:soundId, :endedAt) = session.events.last;
  return ringAfterSnooze(
    DueRing(alarm, scheduledFor: session.scheduledFor),
    soundId: soundId,
    at: endedAt,
    snooze: snooze,
  );
}
