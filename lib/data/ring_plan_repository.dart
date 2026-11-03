import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'package:shuffle_alarm/core/ring_plan.dart';
import 'package:shuffle_alarm/data/database.dart';

/// Saves and reads the stored plans of the rings (`RingPlan`).
///
/// A row that cannot be read counts as no plan, so it can never stop a ring.
/// Times come back in local time, as the same moment they were saved.
class RingPlanRepository {
  RingPlanRepository(this._db);

  final AppDatabase _db;

  /// How long a plan stays after its ring: a ring after Snooze still needs its
  /// Not tonight.
  static const keptFor = Duration(days: 2);

  /// The plan of the ring of the alarm with [alarmId] at [ringAt], or null if
  /// there is none, or none that can be read.
  Future<RingPlan?> forRing(String alarmId, DateTime ringAt) async {
    final row =
        await (_db.select(_db.ringPlans)..where(
              (plan) =>
                  plan.alarmId.equals(alarmId) &
                  plan.ringAt.equalsValue(ringAt),
            ))
            .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Saves [plan]: a new plan, or new values for the plan of its ring.
  Future<void> save(RingPlan plan) async {
    await _db.into(_db.ringPlans).insertOnConflictUpdate(_toRow(plan));
  }

  /// Saves and returns the plan that [choose] makes of the plans stored for
  /// the alarm with [alarmId], oldest first.
  ///
  /// All in one transaction, so two at once agree on one plan. An alarm keeps
  /// one plan for a ring still to come at [now], as it has one next ring: the
  /// others are deleted, such as when a plan moved with its alarm. The plans of
  /// rings that have come stay for [keptFor], for a ring after Snooze.
  Future<RingPlan> settle(
    String alarmId, {
    required DateTime now,
    required RingPlan Function(List<RingPlan> stored) choose,
  }) => _db.transaction(() async {
    await (_db.delete(_db.ringPlans)..where(
          (plan) => plan.ringAt.isSmallerOrEqualValue(
            now.subtract(keptFor).microsecondsSinceEpoch,
          ),
        ))
        .go();
    final stored = await _ofAlarm(alarmId);
    final plan = choose(stored);
    await (_db.delete(_db.ringPlans)..where(
          (row) =>
              row.alarmId.equals(alarmId) &
              row.ringAt.isBiggerThanValue(now.microsecondsSinceEpoch) &
              row.ringAt.equalsValue(plan.ringAt).not(),
        ))
        .go();
    if (!stored.contains(plan)) await save(plan);
    return plan;
  });

  Future<List<RingPlan>> _ofAlarm(String alarmId) async {
    final rows =
        await (_db.select(_db.ringPlans)
              ..where((plan) => plan.alarmId.equals(alarmId))
              ..orderBy([(plan) => OrderingTerm(expression: plan.ringAt)]))
            .get();
    return [for (final row in rows) ?_fromRow(row)];
  }
}

/// [row] as a plan, or null if its lists cannot be read.
RingPlan? _fromRow(RingPlanRow row) {
  try {
    return RingPlan(
      alarmId: row.alarmId,
      ringAt: row.ringAt,
      seed: row.seed,
      soundIds: _idsOf(row.soundIds),
      notTonight: _idsOf(row.notTonight).toSet(),
    );
  } on Object catch (error) {
    debugPrint('Could not read the plan of a ring: $error');
    return null;
  }
}

/// The ids in the JSON list [json]. Throws if it is not one.
List<String> _idsOf(String json) =>
    List<String>.from(jsonDecode(json) as List<Object?>);

RingPlansCompanion _toRow(RingPlan plan) => RingPlansCompanion.insert(
  alarmId: plan.alarmId,
  ringAt: plan.ringAt,
  seed: plan.seed,
  soundIds: jsonEncode(plan.soundIds),
  notTonight: jsonEncode(plan.notTonight.toList()..sort()),
);
