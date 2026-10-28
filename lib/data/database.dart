import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/sound.dart';

part 'database.g.dart';

/// The file in `web/` with SQLite built for the browser (WebAssembly).
const webSqliteFile = 'sqlite3.wasm';

/// The file in `web/` with the drift worker, which runs the database in the
/// background of the browser.
const webWorkerFile = 'drift_worker.js';

/// The app's database: the alarms, the sounds with their weights, and the
/// ring history.
///
/// Read and write it through the repositories in `lib/data/`, which turn its
/// rows into the core models. After a change to the tables, run
/// `dart run build_runner build` to update `database.g.dart`.
@DriftDatabase(tables: [Alarms, Sounds, Weights, RingSessions, RingEvents])
class AppDatabase extends _$AppDatabase {
  /// The database on the executor [e], such as `NativeDatabase.memory()` in
  /// tests.
  AppDatabase(super.e);

  /// The database on this device, named [name]. Open it once, and close it
  /// when the app is done with it.
  ///
  /// On Android, iOS and desktop it is the file `<name>.sqlite` in the app's
  /// support folder. On the web it lives in the browser's storage for the
  /// site, and needs [webWorkerFile] and [webSqliteFile] (docs/DECISIONS.md,
  /// task 2.1).
  AppDatabase.onDevice({String name = 'shuffle_alarm'})
    : this(
        driftDatabase(
          name: name,
          native: const DriftNativeOptions(
            databaseDirectory: getApplicationSupportDirectory,
          ),
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse(webSqliteFile),
            driftWorker: Uri.parse(webWorkerFile),
          ),
        ),
      );

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      // SQLite checks foreign keys only on a connection that asks for it.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

/// Every `Alarm`.
@DataClassName('AlarmRow')
class Alarms extends Table {
  TextColumn get id => text()();
  IntColumn get hour => integer()();
  IntColumn get minute => integer()();

  /// A JSON list in ascending order, such as `[1,3,5]`.
  TextColumn get repeatDays => text().map(const _SetConverter<int>())();
  TextColumn get label => text()();
  BoolColumn get enabled => boolean()();

  /// A JSON list in ascending order, such as `["jazz","pop"]`.
  TextColumn get genres => text().map(const _SetConverter<String>())();
  BoolColumn get gentleStart => boolean()();
  TextColumn get experimentGroup => textEnum<ExperimentGroup>().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Every `Sound`, with where its audio is (`StoredSound`).
@DataClassName('SoundRow')
class Sounds extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get source => textEnum<SoundSource>()();
  TextColumn get genre => text()();
  IntColumn get intensity => integer()();

  /// In microseconds.
  IntColumn get duration => integer().map(const _DurationConverter())();

  /// In microseconds.
  IntColumn get clipStart => integer().map(const _DurationConverter())();
  TextColumn get audioPath => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The adaptive weight (`SoundWeights`) of each sound that has one. A weight
/// goes when its sound is deleted.
@DataClassName('WeightRow')
class Weights extends Table {
  TextColumn get soundId =>
      text().references(Sounds, #id, onDelete: KeyAction.cascade)();
  RealColumn get weight => real()();

  @override
  Set<Column<Object>> get primaryKey => {soundId};
}

/// Every `RingSession`, without its events.
@DataClassName('RingSessionRow')
class RingSessions extends Table {
  TextColumn get id => text()();

  /// The `Alarm.id`, without a foreign key: the ring history stays when the
  /// alarm is deleted.
  TextColumn get alarmId => text()();

  /// In microseconds since 1970 UTC.
  IntColumn get scheduledFor => integer().map(const _TimeConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Every `RingEvent`, by session.
@DataClassName('RingEventRow')
class RingEvents extends Table {
  TextColumn get sessionId =>
      text().references(RingSessions, #id, onDelete: KeyAction.cascade)();

  /// Where the event is in its session, from 0: the order the sounds played.
  /// The times cannot tell it when the clock jumped back during a ring.
  IntColumn get position => integer()();

  /// The `Sound.id`, without a foreign key: the ring history stays when the
  /// sound is deleted.
  TextColumn get soundId => text()();

  /// In microseconds since 1970 UTC.
  IntColumn get startedAt => integer().map(const _TimeConverter())();

  /// In microseconds since 1970 UTC.
  IntColumn get endedAt => integer().map(const _TimeConverter())();
  TextColumn get action => textEnum<RingAction>()();

  @override
  Set<Column<Object>> get primaryKey => {sessionId, position};
}

/// A time as microseconds since 1970 UTC: exact, and in the order of time
/// whatever the time zone. It comes back in local time.
class _TimeConverter extends TypeConverter<DateTime, int> {
  const _TimeConverter();

  @override
  DateTime fromSql(int fromDb) => DateTime.fromMicrosecondsSinceEpoch(fromDb);

  @override
  int toSql(DateTime value) => value.microsecondsSinceEpoch;
}

/// A length of time in microseconds: exact, so that a clip start just before
/// the end of its file stays before it.
class _DurationConverter extends TypeConverter<Duration, int> {
  const _DurationConverter();

  @override
  Duration fromSql(int fromDb) => Duration(microseconds: fromDb);

  @override
  int toSql(Duration value) => value.inMicroseconds;
}

/// A set as a JSON list in ascending order, such as `[1,3,5]`.
class _SetConverter<T extends Comparable<Object>>
    extends TypeConverter<Set<T>, String> {
  const _SetConverter();

  @override
  Set<T> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as List<Object?>).cast<T>().toSet();

  @override
  String toSql(Set<T> value) => jsonEncode(value.toList()..sort());
}
