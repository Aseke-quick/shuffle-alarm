import 'dart:async';

import 'package:shuffle_alarm/core/due_rings.dart';
import 'package:shuffle_alarm/core/due_rings.dart' as core show dueRings;
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/platform/alarm_scheduler.dart';

/// An [AlarmScheduler] that checks the clock every second while the app
/// runs: the web version (task 2.4), and later the desktop (task 6.2).
///
/// Each check asks [core.dueRings] for the rings since the check before, so a
/// check that comes late still finds each ring once. A browser runs the
/// timer of a background tab once a second at most, and after some minutes
/// once a minute (`CLAUDE.md`, Gotchas): then a ring comes up to a minute
/// late. [wakeUps], such as a hidden tab coming back into view, make it
/// check at once.
///
/// It starts checking with the first [watch]. A ring that came due before,
/// such as while the app was closed, does not come due.
class TickingAlarmScheduler implements AlarmScheduler {
  TickingAlarmScheduler({
    this.now = DateTime.now,
    this.wakeUps,
    this.interval = const Duration(seconds: 1),
  });

  /// The time now.
  final DateTime Function() now;

  /// When to check at once, such as when a hidden tab comes back.
  final Stream<void>? wakeUps;

  /// How often it checks the clock.
  final Duration interval;

  final _due = StreamController<DueRing>.broadcast(sync: true);
  List<Alarm> _alarms = const [];
  final _scheduled = <DueRing>[];
  DateTime? _lastCheck;
  Timer? _timer;
  StreamSubscription<void>? _wakeUpListener;

  @override
  bool get ringsAlarms => true;

  @override
  Stream<DueRing> get dueRings => _due.stream;

  @override
  void watch(List<Alarm> alarms) {
    _alarms = List.unmodifiable(alarms);
    if (_timer != null || _due.isClosed) return;
    _lastCheck = now();
    _timer = Timer.periodic(interval, (_) => check());
    _wakeUpListener = wakeUps?.listen((_) => check());
  }

  @override
  void schedule(DueRing ring) => _scheduled.add(ring);

  @override
  void cancel(DueRing ring) => _scheduled.remove(ring);

  /// Checks the clock now, and tells about each ring that came due since the
  /// check before, and each scheduled ring whose start has come: the earliest
  /// first.
  void check() {
    final since = _lastCheck;
    if (since == null || _due.isClosed) return;
    final time = now();
    _lastCheck = time;
    bool startedBy(DueRing ring) => !ring.startsAt.isAfter(time);
    final due = [
      ..._scheduled.where(startedBy),
      ...core.dueRings(_alarms, since: since, now: time),
    ];
    _scheduled.removeWhere(startedBy);
    due
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt))
      ..forEach(_due.add);
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    await _wakeUpListener?.cancel();
    await _due.close();
  }
}
