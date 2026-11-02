import 'package:shuffle_alarm/core/due_rings.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';

/// Tells when an alarm is due to ring. Each platform has its own way
/// (`CLAUDE.md`), and the app reaches it only through this interface.
abstract interface class AlarmScheduler {
  /// Whether alarms ring on this platform yet. Until Phases 4 to 6, only the
  /// web version rings.
  bool get ringsAlarms;

  /// Watches [alarms] from now on, instead of the alarms it watched before.
  void watch(List<Alarm> alarms);

  /// Each ring that comes due, once.
  Stream<DueRing> get dueRings;

  /// Rings [ring] when its time comes, [DueRing.startsAt], such as a ring
  /// after Snooze: it comes out of [dueRings] once.
  void schedule(DueRing ring);

  /// Forgets [ring], if it was given to [schedule] and has not come due.
  void cancel(DueRing ring);

  /// Stops watching for good.
  Future<void> dispose();
}

/// The scheduler of a platform where alarms do not ring yet: it watches
/// nothing, and nothing comes due.
class IdleAlarmScheduler implements AlarmScheduler {
  const IdleAlarmScheduler();

  @override
  bool get ringsAlarms => false;

  @override
  void watch(List<Alarm> alarms) {}

  @override
  Stream<DueRing> get dueRings => const Stream.empty();

  @override
  void schedule(DueRing ring) {}

  @override
  void cancel(DueRing ring) {}

  @override
  Future<void> dispose() async {}
}
