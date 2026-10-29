import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/design/components/alarm_track_row.dart';
import 'package:shuffle_alarm/features/alarms/alarm_editor_screen.dart';
import 'package:shuffle_alarm/features/settings/settings_screen.dart';

import '../data/memory_database.dart';
import '../design/design_app.dart';
import 'alarms/alarms_app.dart';

/// "All motion stops when the platform asks for less motion" (spec section
/// 1): pages, dialogs and new list items are in place in the first frame.
/// Without that ask, the same steps move, so the check can tell.
void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());
  // Not closed: see memoryDatabase().

  for (final lessMotion in [true, false]) {
    final moves = lessMotion ? 'nothing moves' : 'they move';
    testWidgets('pages, dialogs and new alarms: with less motion asked for '
        '$lessMotion, $moves', (tester) async {
      if (lessMotion) askForLessMotion(tester);
      await AlarmRepository(db)
          .save(Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0)));
      await openAlarms(tester, db: db, now: wednesdayEvening);

      // A page above the tabs.
      await tester.tap(find.text('New alarm'));
      await _twoFrames(tester);
      await _expectFinalAtOnce(
        tester,
        find.byType(AlarmEditorScreen),
        still: lessMotion,
      );

      // A dialog.
      await tester.tap(find.byTooltip('Type the time'));
      await _twoFrames(tester);
      await _expectFinalAtOnce(
        tester,
        find.byType(TimePickerDialog),
        still: lessMotion,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // A new alarm in the list, after the page closes.
      await tester.tap(find.text('Save alarm'));
      await _twoFrames(tester);
      final added = find.ancestor(
        of: find.text('11:40 PM'),
        matching: find.byType(AlarmTrackRow),
      );
      expect(added, findsOneWidget);
      await _expectFinalAtOnce(tester, added, still: lessMotion);

      // Settings, from the gear.
      await tester.tap(find.byTooltip('Settings'));
      await _twoFrames(tester);
      await _expectFinalAtOnce(
        tester,
        find.byType(SettingsScreen),
        still: lessMotion,
      );
    });
  }
}

/// The frame of a change, and one 16 ms later: a page that comes in with a
/// transition spends its first frame offstage.
Future<void> _twoFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

/// Checks that [finder] already shows as it will once every animation has
/// ended, if [still]: in the same place, at the same size, and fully
/// opaque. If [still] is false, checks that it does not.
Future<void> _expectFinalAtOnce(
  WidgetTester tester,
  Finder finder, {
  required bool still,
}) async {
  final rect = tester.getRect(finder);
  final opacity = _opacity(tester, finder);
  await tester.pumpAndSettle();
  final atOnce = rect == tester.getRect(finder) && opacity == 1;
  expect(atOnce, still, reason: '$finder: $rect at $opacity');
}

/// How opaque [finder] shows, from every fade and opacity around it.
double _opacity(WidgetTester tester, Finder finder) {
  var opacity = 1.0;
  for (final widget in tester.widgetList(
    find.ancestor(of: finder, matching: find.byWidgetPredicate((_) => true)),
  )) {
    opacity *= switch (widget) {
      FadeTransition(:final opacity) => opacity.value,
      Opacity(:final opacity) => opacity,
      _ => 1,
    };
  }
  return opacity;
}
