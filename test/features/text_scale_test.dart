import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/due_rings.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/library_manifest.dart';
import 'package:shuffle_alarm/data/library_sync.dart';
import 'package:shuffle_alarm/design/components/alarm_track_row.dart';
import 'package:shuffle_alarm/design/components/nav_bar.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/ringing/ringing_screen.dart';
import 'package:shuffle_alarm/features/settings/bedtime_reminder_screen.dart';
import 'package:shuffle_alarm/features/settings/settings_screen.dart';
import 'package:shuffle_alarm/platform/providers.dart';
import 'package:shuffle_alarm/platform/system_notifications.dart';

import '../data/memory_database.dart';
import '../design/design_app.dart';
import '../platform/fake_platform.dart';
import 'alarms/alarms_app.dart';
import 'settings/reminder_app.dart';

/// Large text on a small phone (spec section 1): at a text scale of 2.0 on
/// a screen of 360 × 740, every screen lays out without an overflow, with
/// the real fonts. A widget test fails on any overflow by itself.
void main() {
  late AppDatabase db;
  late List<LibraryEntry> library;

  setUpAll(() async {
    await loadWakemixFonts();
    library = await loadLibraryManifest(rootBundle);
  });
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
      // The bundled library, so the editor shows its genres as chips.
      await syncLibrary(db, [
        for (final entry in library) entry.toStoredSound(),
      ]);
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
      expect(find.byType(FilterChip), findsNWidgets(3));
      // A chosen chip gets a check mark, and the chips wrap again.
      final electronic = find.widgetWithText(FilterChip, 'Electronic');
      await tester.tap(electronic);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(electronic).selected, isTrue);
      await _scrollThrough(tester);
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
    expect(find.text('Bedtime reminder'), findsOneWidget);
  });

  testWidgets('the bedtime reminder fits, on and at each answer', (
    tester,
  ) async {
    setTextScale(tester, 2);
    useMemorySettings();
    final notifications = FakeSystemNotifications(
      answer: NotificationAccess.blocked,
    );
    await openWithReminder(
      tester,
      db: db,
      notifications: notifications,
      now: wednesdayEvening,
      size: phone,
    );
    await openSettings(tester);
    expect(find.text('Off'), findsOneWidget);

    // The explanation, from the switch.
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.byType(BedtimeReminderScreen), findsOneWidget);
    await _scrollThrough(tester);
    expect(find.textContaining('this tab is open'), findsOneWidget);

    // A no.
    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();
    await _scrollThrough(tester);
    expect(find.text('Notifications are blocked'), findsOneWidget);

    // No answer.
    notifications
      ..access = NotificationAccess.notAsked
      ..answer = NotificationAccess.notAsked;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    await _scrollThrough(tester);
    expect(find.text('No answer from your browser'), findsOneWidget);

    // A question that stays open.
    notifications.waitsToAnswer = true;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Waiting for your browser'), findsOneWidget);
    notifications
      ..waitsToAnswer = false
      ..answer = NotificationAccess.allowed
      ..answerNow();
    await tester.pumpAndSettle();

    // On, in Settings, with its longest status.
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(
      find.text('The bedtime of your next alarm has passed'),
      findsOneWidget,
    );
  });

  testWidgets('a platform without notifications fits', (tester) async {
    setTextScale(tester, 2);
    useMemorySettings();
    await openWithReminder(
      tester,
      db: db,
      notifications: FakeSystemNotifications(
        access: NotificationAccess.unavailable,
      ),
      now: wednesdayEvening,
      size: phone,
    );
    await openSettings(tester);
    expect(find.text('Not available on this device.'), findsOneWidget);

    GoRouter.of(tester.element(find.byType(SettingsScreen)))
        .go(BedtimeReminderScreen.path);
    await tester.pumpAndSettle();
    await _scrollThrough(tester);
    expect(find.text('Not available on this device'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('the arm card and the ringing screen fit', (tester) async {
    setTextScale(tester, 2);
    askForLessMotion(tester);
    final scheduler = FakeAlarmScheduler();
    // The browser blocks the sound until a tap: the page offers to play it.
    final player = FakeSoundPlayer(blocked: true);
    final ring = DateTime(2026, 11, 12, 10, 45);
    var now = ring;
    final alarm = Alarm(
      id: 'long',
      time: ClockTime(hour: 10, minute: 45),
      label: 'Morning run with the dog, then a swim',
    );
    await AlarmRepository(db).save(alarm);
    await syncLibrary(db, [for (final entry in library) entry.toStoredSound()]);
    await openAlarms(
      tester,
      db: db,
      now: wednesdayEvening,
      size: phone,
      overrides: [
        alarmSchedulerProvider.overrideWithValue(scheduler),
        soundPlayerProvider.overrideWithValue(player),
        screenWakeLockProvider.overrideWithValue(FakeScreenWakeLock()),
        nowProvider.overrideWithValue(() => now),
      ],
    );

    expect(find.text('Arm alarms to hear them'), findsOneWidget);
    player.unlocks = false;
    await tester.tap(find.text('Arm alarms'));
    await tester.pumpAndSettle();
    expect(
      find.text('The browser did not let the sound play. Try again.'),
      findsOneWidget,
    );
    player.unlocks = true;
    await tester.tap(find.text('Arm alarms'));
    await tester.pumpAndSettle();
    expect(find.text('Keep this tab open'), findsOneWidget);
    await _scrollThrough(tester);

    player.blocked = true;
    scheduler.ring(DueRing(alarm, scheduledFor: ring));
    await tester.pumpAndSettle();
    expect(find.byType(RingingScreen), findsOneWidget);
    expect(find.text('Play sound'), findsOneWidget);
    await _scrollThrough(tester);
    expect(find.text('Stop'), findsOneWidget);

    // The sound plays: the clock, the alarm's long label and the sound.
    await tester.tap(find.text('Play sound'));
    await tester.pumpAndSettle();
    expect(find.text('NOW PLAYING'), findsOneWidget);
    await _scrollThrough(tester);
    expect(find.text('Snooze 5 min'), findsOneWidget);

    // Snoozed: its card on the Alarms tab.
    await tester.tap(find.text('Snooze 5 min'));
    await tester.pumpAndSettle();
    await _scrollThrough(tester);
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pump();
    expect(find.text('Snoozed until 10:50 AM'), findsOneWidget);
    expect(find.text('Stop alarm'), findsOneWidget);

    // It comes back, and reaches its time cap.
    now = scheduler.scheduled.single.startsAt;
    scheduler.ringScheduled();
    await tester.pumpAndSettle();
    expect(find.byType(RingingScreen), findsOneWidget);
    now = now.add(const Duration(minutes: 10));
    player.finishClip();
    await tester.pumpAndSettle();
    expect(find.text('Close'), findsOneWidget);
    await _scrollThrough(tester);
  });

  for (final (name, size) in [
    ('a small phone', const Size(320, 568)),
    ('a phone on its side', const Size(844, 390)),
    ('a wide window', const Size(1280, 800)),
  ]) {
    testWidgets('the ringing screen fits $name, at the normal text size', (
      tester,
    ) async {
      askForLessMotion(tester);
      final scheduler = FakeAlarmScheduler();
      final at = DateTime(2026, 11, 12, 12, 45);
      final alarm = Alarm(
        id: 'long',
        time: ClockTime(hour: 12, minute: 45),
        label: 'Morning run with the dog, then a swim',
      );
      await AlarmRepository(db).save(alarm);
      await syncLibrary(db, [
        for (final entry in library) entry.toStoredSound(),
      ]);
      await openAlarms(
        tester,
        db: db,
        now: wednesdayEvening,
        size: size,
        overrides: [
          alarmSchedulerProvider.overrideWithValue(scheduler),
          soundPlayerProvider.overrideWithValue(
            FakeSoundPlayer(needsUnlock: false),
          ),
          screenWakeLockProvider.overrideWithValue(FakeScreenWakeLock()),
          nowProvider.overrideWithValue(() => at),
        ],
      );

      scheduler.ring(DueRing(alarm, scheduledFor: at));
      await tester.pumpAndSettle();

      expect(find.text('12:45'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      await _scrollThrough(tester);
    });
  }

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
