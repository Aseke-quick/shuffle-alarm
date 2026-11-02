import 'package:meta/meta.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/next_ring.dart';

/// A ring of [alarm] that is due: the alarm was set to ring at
/// [scheduledFor], and the time of this ring, [startsAt], has come.
@immutable
class DueRing {
  /// A first ring starts at [scheduledFor]. A ring after Snooze gets its own
  /// [startsAt] and [snoozedSoundId] (`ringAfterSnooze`).
  const DueRing(
    this.alarm, {
    required this.scheduledFor,
    DateTime? startsAt,
    this.snoozedSoundId,
  }) : startsAt = startsAt ?? scheduledFor;

  final Alarm alarm;

  /// When the alarm was set to ring. The rings after a Snooze keep this time.
  /// A check that comes late, such as in a background tab, finds the ring
  /// after [startsAt].
  final DateTime scheduledFor;

  /// When this ring starts, which its time cap counts from: [scheduledFor],
  /// or the end of the snooze.
  final DateTime startsAt;

  /// The `Sound.id` of the sound that played at the Snooze before this ring,
  /// or null for a first ring.
  final String? snoozedSoundId;

  @override
  bool operator ==(Object other) =>
      other is DueRing &&
      other.alarm == alarm &&
      other.scheduledFor == scheduledFor &&
      other.startsAt == startsAt &&
      other.snoozedSoundId == snoozedSoundId;

  @override
  int get hashCode =>
      Object.hash(alarm, scheduledFor, startsAt, snoozedSoundId);

  @override
  String toString() =>
      'DueRing(${alarm.id}, scheduledFor: $scheduledFor, startsAt: $startsAt, '
      'snoozedSoundId: $snoozedSoundId)';
}

/// The rings that came due after [since] and at [now] or before: for each
/// alarm of [alarms] that is on, its last ring in that time ([nextRing]).
/// Earliest first, then by alarm id.
///
/// A scheduler checks the clock again and again, each time with the time of
/// its check before as [since], so each ring comes due once, also when a
/// check comes late, such as in a background tab or after the device slept.
/// An alarm that would have rung more than once in that time, such as a
/// daily alarm while the device slept for two days, comes due for its last
/// ring only.
///
/// Nothing comes due when [now] is not after [since], such as when the
/// clock was set back.
List<DueRing> dueRings(
  Iterable<Alarm> alarms, {
  required DateTime since,
  required DateTime now,
}) {
  if (!now.isAfter(since)) return const [];
  final due = <DueRing>[];
  for (final alarm in alarms) {
    var ring = nextRing(alarm, since);
    if (ring == null || ring.isAfter(now)) continue;
    for (
      var next = nextRing(alarm, ring);
      next != null && !next.isAfter(now);
      next = nextRing(alarm, next)
    ) {
      ring = next;
    }
    due.add(DueRing(alarm, scheduledFor: ring!));
  }
  return due..sort((a, b) {
    final byTime = a.scheduledFor.compareTo(b.scheduledFor);
    return byTime != 0 ? byTime : a.alarm.id.compareTo(b.alarm.id);
  });
}
