import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

import 'package:shuffle_alarm/core/due_rings.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/ringing/ringing_screen.dart';
import 'package:shuffle_alarm/platform/providers.dart';
import 'package:shuffle_alarm/platform/system_notifications.dart';

import '../../data/memory_database.dart';
import '../../platform/fake_platform.dart';
import '../alarms/alarms_app.dart';
import 'reminder_app.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = memoryDatabase();
    useMemorySettings();
  });
  // Not closed: see memoryDatabase().

  DateTime evening(int hour, int minute) =>
      DateTime(2026, 11, 11, hour, minute);

  group('The reminder comes', () {
    testWidgets('once, at the bedtime of the next alarm', (tester) async {
      final notifications = allowedNotifications();
      final clock = await openWithReminder(
        tester,
        db: db,
        notifications: notifications,
        now: evening(22, 59),
        saved: true,
      );
      expect(notifications.shown, isEmpty);

      clock.moveTo(evening(23, 0));
      await tester.pump();

      expect(notifications.shown, [
        (
          title: 'Time for bed',
          body: 'Sleep now for 8 h before your 7:00 AM alarm.',
        ),
      ]);

      clock.moveTo(evening(23, 1));
      await tester.pump();
      clock.moveTo(evening(23, 2));
      await tester.pump();

      expect(notifications.shown, hasLength(1));
    });

    testWidgets('also when the app opens on another tab', (tester) async {
      // Such as after a reload on the Library tab: no screen asks for it.
      tester.platformDispatcher.defaultRouteNameTestValue = '/library';
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
      final notifications = allowedNotifications();
      final clock = await openWithReminder(
        tester,
        db: db,
        notifications: notifications,
        now: evening(22, 59),
        saved: true,
      );

      clock.moveTo(evening(23, 0));
      await tester.pump();

      expect(notifications.shown, hasLength(1));
    });

    testWidgets('again on the next night', (tester) async {
      final notifications = allowedNotifications();
      final clock = await openWithReminder(
        tester,
        db: db,
        notifications: notifications,
        now: evening(22, 59),
        saved: true,
      );
      clock.moveTo(evening(23, 0));
      await tester.pump();

      clock.moveTo(DateTime(2026, 11, 12, 22, 59));
      await tester.pump();
      clock.moveTo(DateTime(2026, 11, 12, 23));
      await tester.pump();

      expect(notifications.shown, hasLength(2));
    });

    testWidgets('late, saying how long the night still is', (tester) async {
      // Such as a laptop that slept, or a hidden tab.
      final notifications = allowedNotifications();
      final clock = await openWithReminder(
        tester,
        db: db,
        notifications: notifications,
        now: evening(22, 40),
        saved: true,
      );

      clock.moveTo(evening(23, 20));
      await tester.pump();

      expect(
        notifications.shown.single.body,
        startsWith('Sleep now for 7 h 40'),
      );
    });

    for (final saved in [null, false]) {
      testWidgets('never when it is off, which is how it starts: $saved', (
        tester,
      ) async {
        final notifications = allowedNotifications();
        final clock = await openWithReminder(
          tester,
          db: db,
          notifications: notifications,
          now: evening(22, 59),
          saved: saved,
        );

        clock.moveTo(evening(23, 0));
        await tester.pump();

        expect(notifications.shown, isEmpty);
      });
    }

    testWidgets('never after the browser took the permission back', (
      tester,
    ) async {
      final notifications = allowedNotifications();
      final clock = await openWithReminder(
        tester,
        db: db,
        notifications: notifications,
        now: evening(22, 59),
        saved: true,
      );

      notifications.access = NotificationAccess.blocked;
      clock.moveTo(evening(23, 0));
      await tester.pump();

      expect(notifications.shown, isEmpty);
    });

    testWidgets('for the alarms of now, not the ones of the start', (
      tester,
    ) async {
      final notifications = allowedNotifications();
      final clock = await openWithReminder(
        tester,
        db: db,
        notifications: notifications,
        now: evening(22, 59),
        saved: true,
      );

      await AlarmRepository(db).save(sevenOClock(enabled: false));
      await tester.pumpAndSettle();
      clock.moveTo(evening(23, 0));
      await tester.pump();

      expect(notifications.shown, isEmpty);
    });

    testWidgets('after a failure to show one, the next night', (tester) async {
      final notifications = allowedNotifications()..broken = true;
      final clock = await openWithReminder(
        tester,
        db: db,
        notifications: notifications,
        now: evening(22, 59),
        saved: true,
      );

      clock.moveTo(evening(23, 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      notifications.broken = false;
      clock.moveTo(DateTime(2026, 11, 12, 23));
      await tester.pump();

      expect(notifications.shown, hasLength(1));
    });
  });

  group('The alarms ring the same', () {
    late FakeAlarmScheduler scheduler;
    late FakeSoundPlayer player;
    final ring = DateTime(2026, 11, 12, 7);

    setUp(() async {
      scheduler = FakeAlarmScheduler();
      player = FakeSoundPlayer(needsUnlock: false);
      await SoundRepository(db).save(
        StoredSound(
          Sound(
            id: 'chime',
            title: 'Chime',
            source: SoundSource.builtin,
            genre: 'calm',
            intensity: 1,
            duration: const Duration(seconds: 20),
          ),
          audioPath: 'assets/library/calm/chime.wav',
        ),
      );
    });

    /// The app at 22:59, on a platform where alarms ring.
    Future<TestClock> open(
      WidgetTester tester,
      FakeSystemNotifications notifications, {
      bool? saved,
    }) => openWithReminder(
      tester,
      db: db,
      notifications: notifications,
      now: evening(22, 59),
      saved: saved,
      overrides: [
        alarmSchedulerProvider.overrideWithValue(scheduler),
        soundPlayerProvider.overrideWithValue(player),
        screenWakeLockProvider.overrideWithValue(FakeScreenWakeLock()),
        nowProvider.overrideWithValue(() => ring),
      ],
    );

    /// Opens the explanation from the switch in Settings.
    Future<void> openExplanation(WidgetTester tester) async {
      await openSettings(tester);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
    }

    Future<void> expectItRings(WidgetTester tester) async {
      scheduler.ring(DueRing(sevenOClock(), scheduledFor: ring));
      await tester.pumpAndSettle();

      expect(find.byType(RingingScreen), findsOneWidget);
      expect(player.plays, hasLength(1));
    }

    testWidgets('after the person says no', (tester) async {
      final notifications = FakeSystemNotifications(
        answer: NotificationAccess.blocked,
      );
      await open(tester, notifications);
      await openExplanation(tester);

      await tester.tap(find.text('Turn on'));
      await tester.pumpAndSettle();

      expect(notifications.askCalls, 1);
      await expectItRings(tester);
    });

    testWidgets('when nobody answers the question', (tester) async {
      final notifications = FakeSystemNotifications(waitsToAnswer: true);
      await open(tester, notifications);
      await openExplanation(tester);

      await tester.tap(find.text('Turn on'));
      await tester.pump();

      await expectItRings(tester);
    });

    testWidgets('when a notification cannot be shown', (tester) async {
      final notifications = allowedNotifications()..broken = true;
      final clock = await open(tester, notifications, saved: true);

      clock.moveTo(evening(23, 0));
      await tester.pumpAndSettle();

      await expectItRings(tester);
    });

    testWidgets('and the reminder asks nothing of the scheduler', (
      tester,
    ) async {
      final notifications = allowedNotifications();
      final clock = await open(tester, notifications, saved: true);
      final watched = scheduler.watched.length;

      clock.moveTo(evening(23, 0));
      await tester.pumpAndSettle();

      expect(notifications.shown, hasLength(1));
      expect(scheduler.watched, hasLength(watched));
      expect(player.plays, isEmpty);
      await expectItRings(tester);
    });
  });

  testWidgets('a settings store that fails leaves the reminder off, for now', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance = _BrokenSettingsStore();
    final notifications = allowedNotifications();
    final clock = await openWithReminder(
      tester,
      db: db,
      notifications: notifications,
      now: evening(22, 59),
    );

    clock.moveTo(evening(23, 0));
    await tester.pumpAndSettle();
    expect(notifications.shown, isEmpty);
    expect(tester.takeException(), isNull);

    // Turned on, it still works until the app closes.
    await openSettings(tester);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    clock.moveTo(DateTime(2026, 11, 12, 23));
    await tester.pump();

    expect(notifications.shown, hasLength(1));
  });

  testWidgets('an alarm that was set after its bedtime stays quiet', (
    tester,
  ) async {
    final notifications = allowedNotifications();
    final clock = await openWithReminder(
      tester,
      db: db,
      notifications: notifications,
      now: evening(23, 40),
      saved: true,
      alarms: const [],
    );

    await AlarmRepository(db)
        .save(Alarm(id: 'new', time: ClockTime(hour: 7, minute: 0)));
    await tester.pumpAndSettle();
    clock.moveTo(evening(23, 41));
    await tester.pump();

    expect(notifications.shown, isEmpty);
  });
}

/// A settings store that cannot be read or written, such as a browser that
/// blocks the local storage of the site.
base class _BrokenSettingsStore extends InMemorySharedPreferencesAsync {
  _BrokenSettingsStore() : super.empty();

  @override
  Future<bool?> getBool(String key, SharedPreferencesOptions options) =>
      Future.error(StateError('Storage is blocked'));

  @override
  Future<bool> setBool(
    String key,
    bool value,
    SharedPreferencesOptions options,
  ) => Future.error(StateError('Storage is blocked'));
}
