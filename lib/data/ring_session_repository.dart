import 'package:drift/drift.dart';

import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/data/database.dart';

/// Saves and reads the ring history: each ring session with its events.
///
/// Times come back in local time, as the same moment they were saved.
class RingSessionRepository {
  RingSessionRepository(this._db);

  final AppDatabase _db;

  /// Every ring session, by the time its alarm was set to ring.
  Future<List<RingSession>> all() => _db.transaction(() async {
    final sessions =
        await (_db.select(_db.ringSessions)..orderBy([
              (session) => OrderingTerm(expression: session.scheduledFor),
              (session) => OrderingTerm(expression: session.id),
            ]))
            .get();
    final events =
        await (_db.select(_db.ringEvents)..orderBy([
              (event) => OrderingTerm(expression: event.sessionId),
              (event) => OrderingTerm(expression: event.position),
            ]))
            .get();

    final eventsBySession = <String, List<RingEvent>>{};
    for (final row in events) {
      (eventsBySession[row.sessionId] ??= []).add(_eventFromRow(row));
    }
    return [
      for (final row in sessions)
        _sessionFromRow(row, eventsBySession[row.id] ?? const []),
    ];
  });

  /// The ring session with [id] and its events, or null if there is none.
  Future<RingSession?> byId(String id) => _db.transaction(() async {
    final session = await (_db.select(
      _db.ringSessions,
    )..where((session) => session.id.equals(id))).getSingleOrNull();
    if (session == null) return null;

    final events =
        await (_db.select(_db.ringEvents)
              ..where((event) => event.sessionId.equals(id))
              ..orderBy([(event) => OrderingTerm(expression: event.position)]))
            .get();
    return _sessionFromRow(session, [
      for (final row in events) _eventFromRow(row),
    ]);
  });

  /// Saves [session] with its events: a new session, or new values and events
  /// for the session with its id.
  Future<void> save(RingSession session) => _db.transaction(() async {
    await _db
        .into(_db.ringSessions)
        .insertOnConflictUpdate(
          RingSessionsCompanion.insert(
            id: session.id,
            alarmId: session.alarmId,
            scheduledFor: session.scheduledFor,
          ),
        );
    await (_db.delete(
      _db.ringEvents,
    )..where((event) => event.sessionId.equals(session.id))).go();
    await _db.batch(
      (batch) => batch.insertAll(_db.ringEvents, [
        for (final (position, event) in session.events.indexed)
          RingEventsCompanion.insert(
            sessionId: session.id,
            position: position,
            soundId: event.soundId,
            startedAt: event.startedAt,
            endedAt: event.endedAt,
            action: event.action,
          ),
      ]),
    );
  });
}

RingSession _sessionFromRow(RingSessionRow row, List<RingEvent> events) =>
    RingSession(
      id: row.id,
      alarmId: row.alarmId,
      scheduledFor: row.scheduledFor,
      events: events,
    );

RingEvent _eventFromRow(RingEventRow row) => RingEvent(
  soundId: row.soundId,
  startedAt: row.startedAt,
  endedAt: row.endedAt,
  action: row.action,
);
