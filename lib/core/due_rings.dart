import 'package:meta/meta.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/next_ring.dart';

/// A ring of [alarm] that is due: the alarm was set to ring at
/// [scheduledFor], and that time has come.
@immutable
class DueRing {
  const DueRing(this.alarm, {required this.scheduledFor});

  final Alarm alarm;

  /// When the alarm was set to ring. A check that comes late, such as in a
  /// background tab, finds the ring after this time.
  final DateTime scheduledFor;

  @override
  bool operator ==(Object other) =>
      other is DueRing &&
      other.alarm == alarm &&
      other.scheduledFor == scheduledFor;

  @override
  int get hashCode => Object.hash(alarm, scheduledFor);

  @override
  String toString() => 'DueRing(${alarm.id}, scheduledFor: $scheduledFor)';
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
