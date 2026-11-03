import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/adaptive_weights.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/core/ring_plan.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/ring_plan_repository.dart';
import 'package:shuffle_alarm/data/ring_session_repository.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/data/weight_repository.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'memory_database.dart';

/// The testers of the web version have real alarms, weights and mornings in
/// schema version 1 (docs/DECISIONS.md, 2.1): each update must keep them.
void main() {
  late Directory folder;
  late File file;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    folder = Directory.systemTemp.createTempSync('wakemix_migration');
    file = File('${folder.path}/shuffle_alarm.sqlite');
    _writeVersion1(file);
  });

  tearDown(() => folder.deleteSync(recursive: true));

  AppDatabase open() => AppDatabase(NativeDatabase(file));

  group('From schema version 1', () {
    test('it starts as a database of version 1, as the live site has', () {
      final raw = sqlite.sqlite3.open(file.path);
      addTearDown(raw.close);

      expect(raw.userVersion, 1);
      expect(
        _tableNames(raw),
        containsAll(['alarms', 'sounds', 'weights', 'ring_sessions']),
      );
      expect(_tableNames(raw), isNot(contains('ring_plans')));
    });

    test('moves to version 2', () async {
      final db = open();
      addTearDown(db.close);

      expect(db.schemaVersion, 2);
      await db.customSelect('SELECT 1').get();

      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.data.values.single, 2);
    });

    test('keeps the alarms', () async {
      final db = open();
      addTearDown(db.close);

      expect(await AlarmRepository(db).all(), [
        Alarm(
          id: 'work',
          time: ClockTime(hour: 7, minute: 0),
          repeatDays: const {1, 2, 3, 4, 5},
          label: 'Work',
          genres: const {'acoustic', 'lo-fi'},
        ),
        Alarm(
          id: 'late',
          time: ClockTime(hour: 22, minute: 15),
          enabled: false,
          gentleStart: false,
          experimentGroup: ExperimentGroup.rotation,
        ),
      ]);
    });

    test('keeps the sounds', () async {
      final db = open();
      addTearDown(db.close);

      expect(await SoundRepository(db).all(), [
        StoredSound(
          Sound(
            id: 'mom',
            title: 'Mom',
            source: SoundSource.voice,
            genre: 'voice',
            intensity: 2,
            duration: const Duration(seconds: 12),
          ),
          audioPath: 'sounds/mom.webm',
        ),
        StoredSound(
          Sound(
            id: 'warm-tape',
            title: 'Warm Tape',
            source: SoundSource.builtin,
            genre: 'lo-fi',
            intensity: 1,
            duration: const Duration(seconds: 19, milliseconds: 500),
          ),
          audioPath: 'assets/library/lo-fi/warm-tape.wav',
        ),
      ]);
    });

    test('keeps the weights', () async {
      final db = open();
      addTearDown(db.close);

      final weights = await WeightRepository(db).load();
      expect(weights, SoundWeights(const {'warm-tape': 0.8, 'mom': 1.1}));
    });

    test('keeps the ring log', () async {
      final db = open();
      addTearDown(db.close);
      // As the log reads it: the same moment, in local time.
      final at = DateTime.utc(2026, 11, 2, 7).toLocal();

      final sessions = await RingSessionRepository(db).all();
      expect(sessions, [
        RingSession(
          id: 'morning',
          alarmId: 'work',
          scheduledFor: at,
          events: [
            RingEvent(
              soundId: 'warm-tape',
              startedAt: at,
              endedAt: at.add(const Duration(seconds: 19)),
              action: RingAction.snooze,
            ),
            RingEvent(
              soundId: 'mom',
              startedAt: at.add(const Duration(minutes: 5)),
              endedAt: at.add(const Duration(minutes: 5, seconds: 3)),
              action: RingAction.stop,
            ),
          ],
        ),
      ]);
      expect(sessions.single.outcome, RingOutcome.stopped);
    });

    test('starts with no plans, and can save one', () async {
      final db = open();
      addTearDown(db.close);
      final plans = RingPlanRepository(db);
      final at = DateTime(2026, 11, 12, 7);
      final plan = RingPlan(
        alarmId: 'work',
        ringAt: at,
        seed: 1,
        soundIds: const ['warm-tape', 'mom'],
        notTonight: const {'mom'},
      );

      expect(await plans.forRing('work', at), isNull);
      await plans.save(plan);
      expect(await plans.forRing('work', at), plan);
    });

    test('the plan goes with its alarm: foreign keys hold after it', () async {
      final db = open();
      addTearDown(db.close);
      final plans = RingPlanRepository(db);
      final at = DateTime(2026, 11, 12, 7);
      await plans.save(
        RingPlan(alarmId: 'work', ringAt: at, seed: 1, soundIds: const ['mom']),
      );

      await AlarmRepository(db).delete('work');

      expect(await plans.forRing('work', at), isNull);
    });

    test('has the same tables as a new database', () async {
      final db = open();
      addTearDown(db.close);
      final fresh = memoryDatabase();
      addTearDown(fresh.close);

      expect(await _schema(db), await _schema(fresh));
    });

    test('opens again after moving, with its data', () async {
      final first = open();
      await AlarmRepository(first).all();
      await first.close();

      final second = open();
      addTearDown(second.close);

      expect(await AlarmRepository(second).all(), hasLength(2));
      final version = await second
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.data.values.single, 2);
    });
  });
}

/// Writes a database of schema version 1 with rows of every table, by hand:
/// the statements below are what version 1 of the app ran
/// (`SELECT sql FROM sqlite_master`), so they must never change.
void _writeVersion1(File file) {
  final raw = sqlite.sqlite3.open(file.path);
  try {
    raw
      ..execute(_version1Tables)
      ..userVersion = 1;

    final at = DateTime.utc(2026, 11, 2, 7).microsecondsSinceEpoch;
    const second = 1000000;
    raw
      ..execute(
        "INSERT INTO alarms VALUES ('work', 7, 0, '[1,2,3,4,5]', 'Work', 1, "
        """'["acoustic","lo-fi"]', 1, NULL)""",
      )
      ..execute(
        "INSERT INTO alarms VALUES ('late', 22, 15, '[]', '', 0, '[]', 0, "
        "'rotation')",
      )
      ..execute(
        "INSERT INTO sounds VALUES ('warm-tape', 'Warm Tape', 'builtin', "
        "'lo-fi', 1, 19500000, 0, 'assets/library/lo-fi/warm-tape.wav')",
      )
      ..execute(
        "INSERT INTO sounds VALUES ('mom', 'Mom', 'voice', 'voice', 2, "
        "12000000, 0, 'sounds/mom.webm')",
      )
      ..execute("INSERT INTO weights VALUES ('warm-tape', 0.8)")
      ..execute("INSERT INTO weights VALUES ('mom', 1.1)")
      ..execute("INSERT INTO ring_sessions VALUES ('morning', 'work', $at)")
      ..execute(
        "INSERT INTO ring_events VALUES ('morning', 0, 'warm-tape', $at, "
        "${at + 19 * second}, 'snooze')",
      )
      ..execute(
        "INSERT INTO ring_events VALUES ('morning', 1, 'mom', "
        "${at + 300 * second}, ${at + 303 * second}, 'stop')",
      );
  } finally {
    raw.close();
  }
}

const _version1Tables = '''
CREATE TABLE "alarms" ("id" TEXT NOT NULL, "hour" INTEGER NOT NULL,
  "minute" INTEGER NOT NULL, "repeat_days" TEXT NOT NULL,
  "label" TEXT NOT NULL,
  "enabled" INTEGER NOT NULL CHECK ("enabled" IN (0, 1)),
  "genres" TEXT NOT NULL,
  "gentle_start" INTEGER NOT NULL CHECK ("gentle_start" IN (0, 1)),
  "experiment_group" TEXT NULL, PRIMARY KEY ("id"));
CREATE TABLE "sounds" ("id" TEXT NOT NULL, "title" TEXT NOT NULL,
  "source" TEXT NOT NULL, "genre" TEXT NOT NULL,
  "intensity" INTEGER NOT NULL, "duration" INTEGER NOT NULL,
  "clip_start" INTEGER NOT NULL, "audio_path" TEXT NOT NULL,
  PRIMARY KEY ("id"));
CREATE TABLE "weights" ("sound_id" TEXT NOT NULL REFERENCES sounds (id)
  ON DELETE CASCADE, "weight" REAL NOT NULL, PRIMARY KEY ("sound_id"));
CREATE TABLE "ring_sessions" ("id" TEXT NOT NULL,
  "alarm_id" TEXT NOT NULL, "scheduled_for" INTEGER NOT NULL,
  PRIMARY KEY ("id"));
CREATE TABLE "ring_events" ("session_id" TEXT NOT NULL
  REFERENCES ring_sessions (id) ON DELETE CASCADE,
  "position" INTEGER NOT NULL, "sound_id" TEXT NOT NULL,
  "started_at" INTEGER NOT NULL, "ended_at" INTEGER NOT NULL,
  "action" TEXT NOT NULL, PRIMARY KEY ("session_id", "position"));
''';

List<String> _tableNames(sqlite.Database raw) => [
  for (final row in raw.select(
    "SELECT name FROM sqlite_master WHERE type = 'table'",
  ))
    row['name'] as String,
];

/// Every table of [db] with how it was made, by name, whatever the line breaks.
Future<Map<String, String>> _schema(AppDatabase db) async => {
  for (final row
      in await db
          .customSelect(
            "SELECT name, sql FROM sqlite_master WHERE type = 'table'",
          )
          .get())
    row.read<String>('name'): row
        .read<String>('sql')
        .replaceAll(RegExp(r'\s+'), ' '),
};
