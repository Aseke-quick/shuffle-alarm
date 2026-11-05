import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/settings_repository.dart';
import 'package:shuffle_alarm/design/components/setting_switch_row.dart';
import 'package:shuffle_alarm/features/settings/bedtime_reminder_screen.dart';
import 'package:shuffle_alarm/features/settings/settings_screen.dart';
import 'package:shuffle_alarm/platform/system_notifications.dart';

import '../../data/memory_database.dart';
import '../../platform/fake_platform.dart';
import 'reminder_app.dart';

void main() {
  late AppDatabase db;
  final evening = DateTime(2026, 11, 11, 20);

  setUp(() {
    db = memoryDatabase();
    useMemorySettings();
  });
  // Not closed: see memoryDatabase().

  Future<void> open(
    WidgetTester tester,
    FakeSystemNotifications notifications, {
    bool? saved,
    DateTime? now,
    List<Alarm>? alarms,
  }) async {
    await openWithReminder(
      tester,
      db: db,
      notifications: notifications,
      now: now ?? evening,
      saved: saved,
      alarms: alarms,
    );
    await openSettings(tester);
  }

  /// The first switch of the page.
  final reminder = find.byType(Switch).first;

  Switch reminderSwitch(WidgetTester tester) => tester.widget<Switch>(reminder);

  group('The Morning card row', () {
    Finder cardSwitch() => find.descendant(
      of: find.widgetWithText(SettingSwitchRow, 'Morning card'),
      matching: find.byType(Switch),
    );

    testWidgets('is on until someone turns it off', (tester) async {
      await open(tester, FakeSystemNotifications());

      expect(find.text('Morning card'), findsOneWidget);
      expect(
        find.text(
          'After Stop: when you woke, your snoozes, the sounds that played, '
          'and which one woke you.',
        ),
        findsOneWidget,
      );
      expect(find.text('On'), findsOneWidget);
      expect(tester.widget<Switch>(cardSwitch()).value, isTrue);
    });

    testWidgets('turns off, says so, and saves it', (tester) async {
      await open(tester, FakeSystemNotifications());

      await tester.tap(cardSwitch());
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(cardSwitch()).value, isFalse);
      expect(find.text('On'), findsNothing);
      expect(
        await SettingsRepository(SharedPreferencesAsync()).morningCard(),
        isFalse,
      );
    });

    testWidgets('turns on again', (tester) async {
      await SettingsRepository(SharedPreferencesAsync())
          .saveMorningCard(on: false);
      await open(tester, FakeSystemNotifications());
      expect(tester.widget<Switch>(cardSwitch()).value, isFalse);

      await tester.tap(cardSwitch());
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(cardSwitch()).value, isTrue);
      expect(
        await SettingsRepository(SharedPreferencesAsync()).morningCard(),
        isTrue,
      );
    });

    testWidgets('leaves the bedtime reminder as it is', (tester) async {
      final notifications = FakeSystemNotifications();
      await open(tester, notifications);

      await tester.tap(cardSwitch());
      await tester.pumpAndSettle();

      expect(find.byType(BedtimeReminderScreen), findsNothing);
      expect(notifications.askCalls, 0);
      expect(await savedReminder(), isFalse);
    });
  });

  group('The bedtime reminder row', () {
    testWidgets('is off until someone turns it on', (tester) async {
      await open(tester, FakeSystemNotifications());

      expect(find.text('Bedtime reminder'), findsOneWidget);
      expect(
        find.text(
          'One notification at the bedtime of your next alarm, while this '
          'tab is open.',
        ),
        findsOneWidget,
      );
      expect(find.text('Off'), findsOneWidget);
      expect(reminderSwitch(tester).value, isFalse);
    });

    testWidgets('opens the explanation when the browser must be asked', (
      tester,
    ) async {
      final notifications = FakeSystemNotifications();
      await open(tester, notifications, saved: false);

      await tester.tap(reminder);
      await tester.pumpAndSettle();

      expect(find.byType(BedtimeReminderScreen), findsOneWidget);
      expect(notifications.askCalls, 0);
      expect(await savedReminder(), isFalse);
    });

    testWidgets('opens the explanation when the browser blocks it', (
      tester,
    ) async {
      await open(
        tester,
        FakeSystemNotifications(access: NotificationAccess.blocked),
      );

      expect(
        find.text('Your browser blocks notifications for this site.'),
        findsOneWidget,
      );

      await tester.tap(reminder);
      await tester.pumpAndSettle();

      expect(find.text('Notifications are blocked'), findsOneWidget);
    });

    testWidgets('turns on at once when the browser allows it already', (
      tester,
    ) async {
      final notifications = allowedNotifications();
      await open(tester, notifications, saved: false);

      await tester.tap(reminder);
      await tester.pumpAndSettle();

      expect(find.byType(BedtimeReminderScreen), findsNothing);
      expect(reminderSwitch(tester).value, isTrue);
      expect(notifications.askCalls, 0);
      expect(await savedReminder(), isTrue);
    });

    testWidgets('turns off, and saves that', (tester) async {
      await open(tester, allowedNotifications(), saved: true);
      expect(reminderSwitch(tester).value, isTrue);

      await tester.tap(reminder);
      await tester.pumpAndSettle();

      expect(reminderSwitch(tester).value, isFalse);
      expect(find.text('Off'), findsOneWidget);
      expect(await savedReminder(), isFalse);
    });

    testWidgets('cannot be changed on a platform that cannot show it', (
      tester,
    ) async {
      await open(
        tester,
        FakeSystemNotifications(access: NotificationAccess.unavailable),
        saved: true,
      );

      expect(find.text('Not available on this device.'), findsOneWidget);
      expect(reminderSwitch(tester).value, isFalse);
      expect(reminderSwitch(tester).onChanged, isNull);
    });

    testWidgets('says when it comes next', (tester) async {
      await open(tester, allowedNotifications(), saved: true);

      expect(find.text('Next at 11:00 PM'), findsOneWidget);
    });

    testWidgets('says when no alarm is on', (tester) async {
      await open(
        tester,
        allowedNotifications(),
        saved: true,
        alarms: [sevenOClock(enabled: false)],
      );

      expect(find.text('No alarm is on'), findsOneWidget);
    });

    testWidgets('says when the bedtime has passed', (tester) async {
      await open(
        tester,
        allowedNotifications(),
        saved: true,
        now: DateTime(2026, 11, 11, 23, 30),
      );

      expect(find.text('The bedtime of your next alarm has passed'), findsOne);
    });

    testWidgets('follows the browser when it takes the permission back', (
      tester,
    ) async {
      final notifications = allowedNotifications();
      final clock = await openWithReminder(
        tester,
        db: db,
        notifications: notifications,
        now: evening,
        saved: true,
      );
      await openSettings(tester);

      notifications.access = NotificationAccess.blocked;
      clock.moveTo(evening.add(const Duration(minutes: 1)));
      await tester.pumpAndSettle();

      expect(reminderSwitch(tester).value, isFalse);
      expect(
        find.text('Your browser blocks notifications for this site.'),
        findsOneWidget,
      );
    });
  });

  testWidgets('without notifications, Settings still opens', (tester) async {
    // The other platforms, until Phases 4 to 6, and the tests' Dart VM.
    await open(
      tester,
      FakeSystemNotifications(access: NotificationAccess.unavailable),
    );

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Bedtime reminder'), findsOneWidget);
  });
}
