import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/library_manifest.dart';
import 'package:shuffle_alarm/data/library_sync.dart';
import 'package:shuffle_alarm/design/components/alarm_track_row.dart';
import 'package:shuffle_alarm/design/components/nav_bar.dart';
import 'package:shuffle_alarm/design/components/next_alarm_card.dart';
import 'package:shuffle_alarm/design/components/sound_deck.dart';
import 'package:shuffle_alarm/design/components/time_wheels.dart';
import 'package:shuffle_alarm/design/components/wordmark.dart';
import 'package:shuffle_alarm/design/tokens.dart';
import 'package:shuffle_alarm/features/alarms/tonight_mix_screen.dart';

import '../data/memory_database.dart';
import '../design/design_app.dart';
import 'alarms/alarms_app.dart';

/// The wide layout (ADR-005): on a laptop, 1280 × 800, the tabs are in a top
/// bar and the pages lay out two columns; also with large text. A widget
/// test fails on any overflow by itself.
void main() {
  late AppDatabase db;
  late List<LibraryEntry> library;

  // Wednesday 23:40.
  final now = DateTime(2026, 11, 11, 23, 40);
  const laptop = Size(1280, 800);

  setUpAll(() async {
    await loadWakemixFonts();
    library = await loadLibraryManifest(rootBundle);
  });
  setUp(() => db = memoryDatabase());

  Future<void> open(WidgetTester tester, {Size size = laptop}) async {
    final alarms = AlarmRepository(db);
    await alarms.save(
      Alarm(
        id: 'work',
        time: ClockTime(hour: 7, minute: 0),
        repeatDays: const {1, 2, 3, 4, 5},
        label: 'Work',
      ),
    );
    await alarms.save(
      Alarm(id: 'off', time: ClockTime(hour: 22, minute: 15), enabled: false),
    );
    await syncLibrary(db, [for (final entry in library) entry.toStoredSound()]);
    await openAlarms(tester, db: db, now: now, size: size);
    await tester.pumpAndSettle();
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('the Alarms tab has a top bar and two columns, at text scale '
        '$scale', (tester) async {
      setTextScale(tester, scale);
      await open(tester);

      final bar = tester.widget<WakemixNavBar>(find.byType(WakemixNavBar));
      expect(bar.top, isTrue);
      expect(tester.getRect(find.byType(WakemixNavBar)).top, 0);
      expect(find.byType(Wordmark), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      // The next alarm on the left, the list on the right.
      final next = tester.getRect(find.byType(NextAlarmCard));
      final row = tester.getRect(find.byType(AlarmTrackRow).first);
      expect(next.right, lessThan(row.left));
      // "New alarm" sits in the header of the list, not across the bottom.
      final add = tester.getRect(find.text('New alarm'));
      expect(add.top, lessThan(row.top));
      expect(add.left, greaterThan(next.right));
    });

    testWidgets('the editor and the mix lay out wide, at text scale $scale', (
      tester,
    ) async {
      setTextScale(tester, scale);
      await open(tester);

      await tester.tap(find.text('New alarm'));
      await tester.pumpAndSettle();
      // The wheels on the left, Save in the column on the right.
      final wheels = tester.getRect(find.byType(TimeWheels));
      final save = tester.getRect(find.text('Save alarm'));
      expect(wheels.right, lessThan(save.left));
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.textContaining("Tonight's mix"));
      await tester.tap(find.textContaining("Tonight's mix"));
      await tester.pumpAndSettle();
      expect(find.byType(TonightMixScreen), findsOneWidget);
      expect(find.byType(SoundDeck), findsOneWidget);
      // Room for the fan of cards, unless large text needs a row.
      if (scale == 1) expect(find.byType(AnimatedPositioned), findsWidgets);
    });
  }

  testWidgets('the tabs are across the bottom below 1000 px', (tester) async {
    await open(tester, size: const Size(Layout.wideBreakpoint - 1, 800));

    final bar = tester.widget<WakemixNavBar>(find.byType(WakemixNavBar));
    expect(bar.top, isFalse);
    expect(tester.getRect(find.byType(WakemixNavBar)).bottom, 800);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('a wide tab opens the other tabs and Settings', (tester) async {
    await open(tester);

    for (final (tab, text) in [
      ('Library', 'No sounds yet.'),
      ('Analytics', 'No mornings to show yet.'),
    ]) {
      await tester.tap(
        find.descendant(
          of: find.byType(WakemixNavBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(text), findsOneWidget, reason: tab);
    }

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
    expect(find.text('Morning card'), findsOneWidget);
  });
}
