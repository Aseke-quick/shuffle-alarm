import 'package:drift/drift.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/data/database.dart';

/// Saves and reads the alarms.
class AlarmRepository {
  AlarmRepository(this._db);

  final AppDatabase _db;

  /// Every alarm, by time of day.
  Future<List<Alarm>> all() => _byTimeOfDay().get();

  /// Every alarm, by time of day: now, and again after each change.
  Stream<List<Alarm>> watchAll() => _byTimeOfDay().watch();

  /// The alarm with [id], or null if there is none.
  Future<Alarm?> byId(String id) async {
    final row = await (_db.select(
      _db.alarms,
    )..where((alarm) => alarm.id.equals(id))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Saves [alarm]: a new alarm, or new values for the alarm with its id.
  Future<void> save(Alarm alarm) async {
    await _db.into(_db.alarms).insertOnConflictUpdate(_toRow(alarm));
  }

  /// Deletes the alarm with [id], if there is one. Its ring history stays.
  Future<void> delete(String id) async {
    await (_db.delete(_db.alarms)..where((alarm) => alarm.id.equals(id))).go();
  }

  Selectable<Alarm> _byTimeOfDay() =>
      (_db.select(_db.alarms)..orderBy([
            (alarm) => OrderingTerm(expression: alarm.hour),
            (alarm) => OrderingTerm(expression: alarm.minute),
            (alarm) => OrderingTerm(expression: alarm.id),
          ]))
          .map(_fromRow);
}

Alarm _fromRow(AlarmRow row) => Alarm(
  id: row.id,
  time: ClockTime(hour: row.hour, minute: row.minute),
  repeatDays: row.repeatDays,
  label: row.label,
  enabled: row.enabled,
  genres: row.genres,
  gentleStart: row.gentleStart,
  experimentGroup: row.experimentGroup,
);

AlarmsCompanion _toRow(Alarm alarm) => AlarmsCompanion.insert(
  id: alarm.id,
  hour: alarm.time.hour,
  minute: alarm.time.minute,
  repeatDays: alarm.repeatDays,
  label: alarm.label,
  enabled: alarm.enabled,
  genres: alarm.genres,
  gentleStart: alarm.gentleStart,
  // Also a null, so that saving an alarm again can take it out of an
  // experiment.
  experimentGroup: Value(alarm.experimentGroup),
);
