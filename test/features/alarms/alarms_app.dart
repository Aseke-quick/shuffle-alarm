import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/app.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';

/// Opens the app on the Alarms tab, with its clock at [now] and [db] as its
/// database. Returns the clock, which moves only when the test moves it.
///
/// Without [db], [overrides] must override the database.
Future<TestClock> openAlarms(
  WidgetTester tester, {
  required DateTime now,
  AppDatabase? db,
  List<Override> overrides = const [],
}) async {
  final clock = TestClock(now);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (db != null) databaseProvider.overrideWithValue(db),
        clockProvider.overrideWith(() => clock),
        ...overrides,
      ],
      child: const ShuffleAlarmApp(),
    ),
  );
  await tester.pumpAndSettle();
  return clock;
}

/// A clock that shows the same time until a test moves it on.
class TestClock extends Clock {
  TestClock(this._time);

  DateTime _time;

  @override
  DateTime build() => _time;

  void moveTo(DateTime time) => state = _time = time;
}

/// A Wednesday evening: 2026-11-11 at 23:40, local time.
final wednesdayEvening = DateTime(2026, 11, 11, 23, 40);
