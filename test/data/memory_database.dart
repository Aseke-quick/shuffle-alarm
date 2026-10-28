import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:shuffle_alarm/data/database.dart';

/// A new, empty database in memory, for one test. Close it in `tearDown`.
AppDatabase memoryDatabase() {
  // Each test opens a database of its own, which drift warns about by
  // default.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}
