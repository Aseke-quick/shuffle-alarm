import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/features/alarms/alarms_screen.dart';
import 'package:shuffle_alarm/features/settings/bedtime_reminder_screen.dart';
import 'package:shuffle_alarm/features/settings/settings_screen.dart';
import 'package:shuffle_alarm/platform/system_notifications.dart';

import '../../data/memory_database.dart';
import '../../platform/fake_platform.dart';
import 'reminder_app.dart';

void main() {
  late AppDatabase db;
  final now = DateTime(2026, 11, 11, 20);

  setUp(() {
    db = memoryDatabase();
    useMemorySettings();
  });
  // Not closed: see memoryDatabase().

  /// The app on Settings, with the screen open from its switch.
  Future<void> openScreen(
    WidgetTester tester,
    FakeSystemNotifications notifications, {
    bool? saved,
  }) async {
    await openWithReminder(
      tester,
      db: db,
      notifications: notifications,
      now: now,
      saved: saved,
    );
    await openSettings(tester);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
  }

  group('Before it asks', () {
    testWidgets('the screen explains it, and the browser asks nothing', (
      tester,
    ) async {
      final notifications = FakeSystemNotifications();
      await openScreen(tester, notifications);

      expect(find.byType(BedtimeReminderScreen), findsOneWidget);
      expect(find.text('Go to bed on time'), findsOneWidget);
      expect(
        find.text(
          'Get one notification at the bedtime of your next alarm, so you '
          'still sleep 8 h.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Your browser will ask to allow notifications. If you say no, your '
          'alarms still ring.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('It works only while this tab is open, like your alarms.'),
        findsOneWidget,
      );
      expect(notifications.askCalls, 0);
    });

    testWidgets('screen readers hear a heading, then each thing to know', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openScreen(tester, FakeSystemNotifications());

      expect(
        tester.getSemantics(find.text('Go to bed on time')),
        matchesSemantics(label: 'Go to bed on time', isHeader: true),
      );
      final lead = tester.getSemantics(
        find.textContaining('Get one notification'),
      );
      expect(
        lead.label,
        'Get one notification at the bedtime of your next alarm, so you still '
        'sleep 8 h.',
      );
      // A node of its own, or it would be read before the heading.
      expect(lead.childrenCount, 0);
      expect(
        tester.getSemantics(find.textContaining('will ask')).label,
        'Your browser will ask to allow notifications. If you say no, your '
        'alarms still ring.',
      );
      expect(
        tester.getSemantics(find.textContaining('this tab is open')).label,
        'It works only while this tab is open, like your alarms.',
      );
      handle.dispose();
    });

    testWidgets('both answers are wide buttons, one above the other', (
      tester,
    ) async {
      await openScreen(tester, FakeSystemNotifications());

      final turnOn = tester.getRect(find.text('Turn on').hitTestable());
      final notNow = tester.getRect(find.text('Not now').hitTestable());
      final buttons = [
        tester.getSize(find.widgetWithText(FilledButton, 'Turn on')),
        tester.getSize(find.widgetWithText(OutlinedButton, 'Not now')),
      ];

      expect(turnOn.bottom, lessThan(notNow.top));
      // No dark pattern: saying no is as easy to find as saying yes.
      expect(buttons.first, buttons.last);
    });

    testWidgets('a browser that said yes before is not asked again', (
      tester,
    ) async {
      // The switch turns it on at once then, so this is the page by its
      // address.
      final notifications = allowedNotifications();
      await openWithReminder(
        tester,
        db: db,
        notifications: notifications,
        now: now,
      );
      GoRouter.of(tester.element(find.byType(AlarmsScreen)))
          .go(BedtimeReminderScreen.path);
      await tester.pumpAndSettle();

      expect(find.textContaining('will ask'), findsNothing);

      await tester.tap(find.text('Turn on'));
      await tester.pumpAndSettle();

      expect(notifications.askCalls, 0);
      expect(await savedReminder(), isTrue);
    });
  });

  group('After a tap on Turn on', () {
    testWidgets('a yes turns it on, saves that and goes back', (tester) async {
      final notifications = FakeSystemNotifications();
      await openScreen(tester, notifications);

      await tester.tap(find.text('Turn on'));
      await tester.pumpAndSettle();

      expect(notifications.askCalls, 1);
      expect(await savedReminder(), isTrue);
      expect(find.byType(BedtimeReminderScreen), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
    });

    testWidgets('a no keeps it off, saves that and says what it means', (
      tester,
    ) async {
      final notifications = FakeSystemNotifications(
        answer: NotificationAccess.blocked,
      );
      await openScreen(tester, notifications);

      await tester.tap(find.text('Turn on'));
      await tester.pumpAndSettle();

      expect(await savedReminder(), isFalse);
      expect(find.byType(BedtimeReminderScreen), findsOneWidget);
      expect(find.text('Notifications are blocked'), findsOneWidget);
      expect(find.textContaining('your alarms still ring'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.textContaining('will ask'), findsNothing);
    });

    testWidgets('a no ends an earlier yes too', (tester) async {
      // Someone wanted it, the browser forgot its answer, and now they say no:
      // if they allow it later in the browser, it does not turn on by itself.
      final notifications = FakeSystemNotifications(
        answer: NotificationAccess.blocked,
      );
      await openScreen(tester, notifications, saved: true);

      await tester.tap(find.text('Turn on'));
      await tester.pumpAndSettle();

      expect(await savedReminder(), isFalse);
    });

    testWidgets('Try again turns it on once the browser allows it', (
      tester,
    ) async {
      final notifications = FakeSystemNotifications(
        answer: NotificationAccess.blocked,
      );
      await openScreen(tester, notifications);
      await tester.tap(find.text('Turn on'));
      await tester.pumpAndSettle();

      // The person allows it in the settings of the browser.
      notifications.answer = NotificationAccess.allowed;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(await savedReminder(), isTrue);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
    });

    testWidgets('no answer keeps it off, and says so', (tester) async {
      final notifications = FakeSystemNotifications(
        answer: NotificationAccess.notAsked,
      );
      await openScreen(tester, notifications);

      await tester.tap(find.text('Turn on'));
      await tester.pumpAndSettle();

      expect(await savedReminder(), isFalse);
      expect(find.text('No answer from your browser'), findsOneWidget);
      expect(
        find.textContaining('The reminder stays off, and your alarms still'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('no answer changes no earlier choice', (tester) async {
      // Someone wanted it, and the browser forgot its answer.
      final notifications = FakeSystemNotifications(
        answer: NotificationAccess.notAsked,
      );
      await openScreen(tester, notifications, saved: true);

      await tester.tap(find.text('Turn on'));
      await tester.pumpAndSettle();

      expect(await savedReminder(), isTrue);
    });

    testWidgets('while the question is open, it does not ask again', (
      tester,
    ) async {
      final notifications = FakeSystemNotifications(waitsToAnswer: true);
      await openScreen(tester, notifications);

      await tester.tap(find.text('Turn on'));
      await tester.pumpAndSettle();

      final waiting = find.widgetWithText(
        FilledButton,
        'Waiting for your browser',
      );
      expect(tester.widget<FilledButton>(waiting).onPressed, isNull);
      expect(notifications.askCalls, 1);

      notifications.answerNow();
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(await savedReminder(), isTrue);
    });

    testWidgets('leaving while the question is open still takes the answer', (
      tester,
    ) async {
      final notifications = FakeSystemNotifications(waitsToAnswer: true);
      await openScreen(tester, notifications);
      await tester.tap(find.text('Turn on'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      notifications.answerNow();
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(await savedReminder(), isTrue);
      expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
    });
  });

  group('Not now', () {
    testWidgets('asks nothing and goes back, with the reminder off', (
      tester,
    ) async {
      final notifications = FakeSystemNotifications();
      await openScreen(tester, notifications);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(notifications.askCalls, 0);
      expect(await savedReminder(), isFalse);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
    });

    testWidgets('goes to Settings from a page opened by its address', (
      tester,
    ) async {
      await openWithReminder(
        tester,
        db: db,
        notifications: FakeSystemNotifications(),
        now: now,
      );
      GoRouter.of(tester.element(find.byType(AlarmsScreen)))
          .go(BedtimeReminderScreen.path);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('does not turn off a reminder that is on', (tester) async {
      // Only by its address: the switch of a reminder that is on turns it off.
      await openWithReminder(
        tester,
        db: db,
        notifications: allowedNotifications(),
        now: now,
        saved: true,
      );
      GoRouter.of(tester.element(find.byType(AlarmsScreen)))
          .go(BedtimeReminderScreen.path);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(await savedReminder(), isTrue);
      expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
    });
  });

  testWidgets('a browser that cannot show it offers only the way back', (
    tester,
  ) async {
    final notifications = FakeSystemNotifications(
      access: NotificationAccess.unavailable,
    );
    await openWithReminder(
      tester,
      db: db,
      notifications: notifications,
      now: now,
    );
    await openSettings(tester);
    GoRouter.of(tester.element(find.byType(SettingsScreen)))
        .go(BedtimeReminderScreen.path);
    await tester.pumpAndSettle();

    expect(find.text('Not available on this device'), findsOneWidget);
    expect(find.text('Turn on'), findsNothing);
    expect(find.text('Try again'), findsNothing);
    expect(notifications.askCalls, 0);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(await savedReminder(), isFalse);
  });
}
