import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/app.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/ringing/morning_card.dart';

/// Opens the app on the Alarms tab, with its clock at [now] and [db] as its
/// database. Returns the clock, which moves only when the test moves it.
///
/// Without [db], [overrides] must override the database. The screen is
/// [size], by default tall enough to show a whole list.
Future<TestClock> openAlarms(
  WidgetTester tester, {
  required DateTime now,
  AppDatabase? db,
  List<Override> overrides = const [],
  Size size = const Size(800, 1600),
}) async {
  tester.view
    ..physicalSize = size * tester.view.devicePixelRatio
    ..viewInsets = FakeViewPadding.zero;
  addTearDown(tester.view.reset);
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

/// For the tests of what comes before the Morning card: it is turned off, so
/// Stop goes back to the page below the ring.
final Override noMorningCard = morningCardOnProvider.overrideWith(_CardOff.new);

class _CardOff extends MorningCardSetting {
  @override
  bool build() => false;
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

/// A database that cannot open, as in a browser that blocks the storage of
/// the site. Do not close it: it never opened, and its close would wait for
/// the failed opening on the fake time of the test, which is over by then.
AppDatabase brokenDatabase() => AppDatabase(
  DatabaseConnection(
    LazyDatabase(() => throw Exception('Storage is blocked')),
    closeStreamsSynchronously: true,
  ),
);
