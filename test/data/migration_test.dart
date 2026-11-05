import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/adaptive_weights.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/morning_answer.dart';
import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/core/ring_plan.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/morning_answer_repository.dart';
import 'package:shuffle_alarm/data/ring_plan_repository.dart';
import 'package:shuffle_alarm/data/ring_session_repository.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/data/weight_repository.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'memory_database.dart';

/// The testers of the web version have real alarms, weights and mornings in
/// the schema versions before this one (docs/DECISIONS.md, 2.1): each update
/// must keep them.
void main() {
  late Directory folder;
  late File file;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    folder = Directory.systemTemp.createTempSync('wakemix_migration');
    file = File('${folder.path}/shuffle_alarm.sqlite');
  });

  tearDown(() => folder.deleteSync(recursive: true));

  AppDatabase open() => AppDatabase(NativeDatabase(file));

  group('From schema version 1', () {
    setUp(() => _writeVersion1(file));

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

    test('moves to the version of this app', () async {
      final db = open();
      addTearDown(db.close);

      expect(db.schemaVersion, _thisVersion);
      await db.customSelect('SELECT 1').get();

      expect(await _userVersion(db), _thisVersion);
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
      expect(await _userVersion(second), _thisVersion);
    });
  });

  group('From schema version 2', () {
    final at = DateTime.utc(2026, 11, 2, 7).toLocal();

    setUp(() => _writeVersion2(file));

    test('it starts as a database of version 2, as the live site has', () {
      final raw = sqlite.sqlite3.open(file.path);
      addTearDown(raw.close);

      expect(raw.userVersion, 2);
      expect(
        _tableNames(raw),
        containsAll([
          'alarms',
          'sounds',
          'weights',
          'ring_sessions',
          'ring_events',
          'ring_plans',
        ]),
      );
      expect(_tableNames(raw), isNot(contains('morning_answers')));
    });

    test('moves to the version of this app', () async {
      final db = open();
      addTearDown(db.close);

      await db.customSelect('SELECT 1').get();

      expect(await _userVersion(db), _thisVersion);
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

    test('keeps the ring log, stopped, snoozed and missed', () async {
      final db = open();
      addTearDown(db.close);

      final sessions = await RingSessionRepository(db).all();
      expect(sessions, [
        RingSession(
          id: 'missed',
          alarmId: 'late',
          scheduledFor: at.subtract(const Duration(days: 1)),
        ),
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
        RingSession(
          id: 'snoozed',
          alarmId: 'work',
          scheduledFor: at.add(const Duration(days: 1)),
          events: [
            RingEvent(
              soundId: 'mom',
              startedAt: at.add(const Duration(days: 1)),
              endedAt: at.add(const Duration(days: 1, seconds: 4)),
              action: RingAction.snooze,
            ),
          ],
        ),
      ]);
      expect(sessions.map((session) => session.outcome), [
        RingOutcome.missed,
        RingOutcome.stopped,
        RingOutcome.snoozed,
      ]);
    });

    test('keeps the plans', () async {
      final db = open();
      addTearDown(db.close);
      final ring = at.add(const Duration(days: 2));

      expect(
        await RingPlanRepository(db).forRing('work', ring),
        RingPlan(
          alarmId: 'work',
          ringAt: ring,
          seed: 42,
          soundIds: const ['warm-tape', 'mom', 'warm-tape'],
          notTonight: const {'mom'},
        ),
      );
    });

    test('starts with no answers, and can save one', () async {
      final db = open();
      addTearDown(db.close);
      final answers = MorningAnswerRepository(db);
      final answer = MorningAnswer(
        sessionId: 'morning',
        soundId: 'mom',
        answeredAt: at.add(const Duration(minutes: 6)),
      );

      expect(await answers.all(), isEmpty);
      await answers.save(answer);
      expect(await answers.all(), [answer]);
    });

    test('foreign keys hold after it', () async {
      final db = open();
      addTearDown(db.close);

      await expectLater(
        MorningAnswerRepository(db)
            .save(MorningAnswer(sessionId: 'no such session', answeredAt: at)),
        throwsA(anything),
      );
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
      await MorningAnswerRepository(first)
          .save(MorningAnswer(sessionId: 'morning', answeredAt: at));
      await first.close();

      final second = open();
      addTearDown(second.close);

      expect(await AlarmRepository(second).all(), hasLength(2));
      expect(await MorningAnswerRepository(second).all(), hasLength(1));
      expect(await _userVersion(second), _thisVersion);
    });

    test('an old build that took the version back does not break it', () async {
      // A tab of version 2 sets the version back to 2 when it opens the
      // database. The next visit must make the same step again, without an
      // error: an error here would mean no alarm at all.
      final first = open();
      await MorningAnswerRepository(first).save(
        MorningAnswer(sessionId: 'morning', soundId: 'mom', answeredAt: at),
      );
      await first.close();
      sqlite.sqlite3.open(file.path)
        ..userVersion = 2
        ..close();

      final second = open();
      addTearDown(second.close);

      expect(await AlarmRepository(second).all(), hasLength(2));
      expect(await RingSessionRepository(second).all(), hasLength(3));
      expect(await MorningAnswerRepository(second).all(), hasLength(1));
      expect(await _userVersion(second), _thisVersion);
    });
  });
}

/// The schema version of this app.
const _thisVersion = 3;

Future<Object?> _userVersion(AppDatabase db) async {
  final version = await db.customSelect('PRAGMA user_version').getSingle();
  return version.data.values.single;
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

/// Writes a database of schema version 2 with rows of every table, by hand: a
/// stopped ring, a snoozed one and a missed one, and a plan. The statements are
/// what version 2 of the app ran, so they must never change.
void _writeVersion2(File file) {
  final raw = sqlite.sqlite3.open(file.path);
  try {
    raw
      ..execute(_version1Tables)
      ..execute(_version2Plans)
      ..userVersion = 2;

    final at = DateTime.utc(2026, 11, 2, 7).microsecondsSinceEpoch;
    const second = 1000000;
    const day = 86400 * second;
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
      )
      ..execute(
        "INSERT INTO ring_sessions VALUES ('snoozed', 'work', ${at + day})",
      )
      ..execute(
        "INSERT INTO ring_events VALUES ('snoozed', 0, 'mom', ${at + day}, "
        "${at + day + 4 * second}, 'snooze')",
      )
      ..execute(
        "INSERT INTO ring_sessions VALUES ('missed', 'late', ${at - day})",
      )
      ..execute(
        "INSERT INTO ring_plans VALUES ('work', ${at + 2 * day}, 42, "
        """'["warm-tape","mom","warm-tape"]', '["mom"]')""",
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

const _version2Plans = '''
CREATE TABLE "ring_plans" ("alarm_id" TEXT NOT NULL REFERENCES alarms (id)
  ON DELETE CASCADE, "ring_at" INTEGER NOT NULL, "seed" INTEGER NOT NULL,
  "sound_ids" TEXT NOT NULL, "not_tonight" TEXT NOT NULL,
  PRIMARY KEY ("alarm_id", "ring_at"));
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
