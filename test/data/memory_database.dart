import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:shuffle_alarm/data/database.dart';

/// A new, empty database in memory, for one test. Close it in `tearDown`,
/// but not in a widget test: after a failed widget test the app still uses
/// it, and closing it would wait forever for the test's fake time. It goes
/// with the test run.
///
/// Its query streams stop as soon as nobody listens. By default drift waits
/// on a timer first, and a widget test fails when a timer still waits at its
/// end.
AppDatabase memoryDatabase() {
  // Each test opens a database of its own, which drift warns about by
  // default.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
}
