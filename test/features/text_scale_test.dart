import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/design/components/alarm_track_row.dart';
import 'package:shuffle_alarm/design/components/nav_bar.dart';

import '../data/memory_database.dart';
import '../design/design_app.dart';
import 'alarms/alarms_app.dart';

/// Large text on a small phone (spec section 1): at a text scale of 2.0 on
/// a screen of 360 × 740, every screen lays out without an overflow, with
/// the real fonts. A widget test fails on any overflow by itself.
void main() {
  late AppDatabase db;

  setUpAll(loadWakemixFonts);
  setUp(() => db = memoryDatabase());
  // Not closed: see memoryDatabase().

  const phone = Size(360, 740);

  for (final brightness in brightnesses) {
    testWidgets('the Alarms tab and the editor fit, in ${brightness.name}', (
      tester,
    ) async {
      setTextScale(tester, 2);
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final alarms = AlarmRepository(db);
      await alarms.save(
        Alarm(
          id: 'long',
          time: ClockTime(hour: 10, minute: 45),
          repeatDays: const {1, 3, 5, 6},
          label: 'Morning run with the dog, then a swim',
        ),
      );
      await alarms.save(
        Alarm(id: 'off', time: ClockTime(hour: 22, minute: 55), enabled: false),
      );
      await openAlarms(tester, db: db, now: wednesdayEvening, size: phone);

      // Through the whole list, to the last alarm.
      await _scrollThrough(tester);
      expect(find.text('10:55 PM'), findsOneWidget);
      expect(find.byType(AlarmTrackRow), findsNWidgets(2));
      expect(find.text('New alarm'), findsOneWidget);

      // The editor of the long alarm, from the dial to the genres.
      await tester.tap(find.text('10:45 AM').last);
      await tester.pumpAndSettle();
      expect(find.text('Edit alarm'), findsOneWidget);
      await _scrollThrough(tester);
      expect(find.text('GENRES'), findsOneWidget);
      expect(find.text('Save alarm'), findsOneWidget);

      // A new alarm, with the time typed in.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('New alarm'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Type the time'));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });
  }

  testWidgets('the other tabs and Settings fit', (tester) async {
    setTextScale(tester, 2);
    await openAlarms(tester, db: db, now: wednesdayEvening, size: phone);

    for (final tab in ['Library', 'Insights']) {
      await tester.tap(
        find.descendant(
          of: find.byType(WakemixNavBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, tab), findsOneWidget);
    }

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('No settings yet.'), findsOneWidget);
  });

  testWidgets('the error view fits', (tester) async {
    setTextScale(tester, 2);
    await openAlarms(
      tester,
      db: brokenDatabase(),
      now: wednesdayEvening,
      size: phone,
    );

    expect(find.text('Alarms are not available'), findsOneWidget);
    await _scrollThrough(tester);
    expect(find.text('Try again'), findsOneWidget);
  });
}

/// Scrolls the open page from its top to its end, 200 px at a time, so
/// that every part of it is laid out. By its scroll position: in the
/// editor a drag could land on the dial and turn it.
Future<void> _scrollThrough(WidgetTester tester) async {
  final position = tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position;
  for (var offset = 0.0; ; offset += 200) {
    position.jumpTo(offset.clamp(0, position.maxScrollExtent));
    await tester.pump();
    if (offset >= position.maxScrollExtent) break;
  }
}
