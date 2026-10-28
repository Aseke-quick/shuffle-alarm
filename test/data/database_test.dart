import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/ring_session_repository.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';

import 'memory_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());

  tearDown(() => db.close());

  group('AppDatabase', () {
    test('checks foreign keys', () async {
      expect(await _single(db, 'PRAGMA foreign_keys'), 1);
    });

    test('stores each enum by its name, not by its index', () async {
      await AlarmRepository(db).save(
        Alarm(
          id: 'a',
          time: ClockTime(hour: 7, minute: 0),
          experimentGroup: ExperimentGroup.rotation,
        ),
      );
      await SoundRepository(db).save(
        StoredSound(
          Sound(
            id: 'mom',
            title: 'Mom',
            source: SoundSource.voice,
            genre: 'voice',
            intensity: 1,
            duration: const Duration(seconds: 12),
          ),
          audioPath: 'sounds/mom.webm',
        ),
      );
      await RingSessionRepository(db).save(_session(RingAction.snooze));

      expect(
        await _single(db, 'SELECT experiment_group FROM alarms'),
        'rotation',
      );
      expect(await _single(db, 'SELECT source FROM sounds'), 'voice');
      expect(await _single(db, 'SELECT action FROM ring_events'), 'snooze');
    });

    test('deletes the events of a ring session with the session', () async {
      await RingSessionRepository(db).save(_session(RingAction.stop));

      await db.customStatement("DELETE FROM ring_sessions WHERE id = 's1'");

      expect(await _single(db, 'SELECT COUNT(*) FROM ring_events'), 0);
    });
  });
}

/// The one value that [sql] selects from [db].
Future<Object?> _single(AppDatabase db, String sql) async =>
    (await db.customSelect(sql).getSingle()).data.values.single;

/// A session whose one sound ended with [action].
RingSession _session(RingAction action) => RingSession(
  id: 's1',
  alarmId: 'a',
  scheduledFor: DateTime(2026, 10, 29, 7),
  events: [
    RingEvent(
      soundId: 'mom',
      startedAt: DateTime(2026, 10, 29, 7),
      endedAt: DateTime(2026, 10, 29, 7, 0, 12),
      action: action,
    ),
  ],
);
