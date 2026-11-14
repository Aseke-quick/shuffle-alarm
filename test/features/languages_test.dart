import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shuffle_alarm/core/due_rings.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/library_manifest.dart';
import 'package:shuffle_alarm/data/library_sync.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/data/ring_session_repository.dart';
import 'package:shuffle_alarm/data/settings_repository.dart';
import 'package:shuffle_alarm/design/components/month_calendar.dart';
import 'package:shuffle_alarm/design/components/nav_bar.dart';
import 'package:shuffle_alarm/design/components/time_wheels.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/alarms/tonight_mix_screen.dart';
import 'package:shuffle_alarm/features/insights/analytics_screen.dart';
import 'package:shuffle_alarm/features/ringing/morning_card_screen.dart';
import 'package:shuffle_alarm/features/ringing/ringing_screen.dart';
import 'package:shuffle_alarm/features/settings/bedtime_reminder_screen.dart';
import 'package:shuffle_alarm/features/settings/settings_screen.dart';
import 'package:shuffle_alarm/l10n/app_localizations.dart';
import 'package:shuffle_alarm/l10n/texts.dart';
import 'package:shuffle_alarm/platform/providers.dart';

import '../data/memory_database.dart';
import '../design/design_app.dart';
import '../platform/fake_platform.dart';
import 'alarms/alarms_app.dart';
import 'settings/reminder_app.dart';

/// The three languages of the app (task 2.9): it follows the device, the
/// Language setting chooses another, and every page lays out in Russian and
/// in Kazakh, also with large text on a small phone. A widget test fails on
/// any overflow by itself.
void main() {
  late AppDatabase db;
  late List<LibraryEntry> library;

  // Wednesday 23:40.
  final now = DateTime(2026, 11, 11, 23, 40);

  setUpAll(() async {
    await loadWakemixFonts();
    library = await loadLibraryManifest(rootBundle);
  });
  setUp(() {
    db = memoryDatabase();
    useMemorySettings();
  });
  // Back to English, which the tests of other files expect.
  tearDown(() => useTexts(lookupAppLocalizations(const Locale('en'))));

  /// Makes [locale] the language of the device until the test ends.
  void useDevice(WidgetTester tester, Locale locale) {
    tester.platformDispatcher
      ..localeTestValue = locale
      ..localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  }

  Future<void> open(
    WidgetTester tester, {
    Size size = const Size(800, 1600),
    List<Override> overrides = const [],
  }) async {
    await openAlarms(
      tester,
      db: db,
      now: now,
      size: size,
      overrides: overrides,
    );
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(WakemixNavBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('The language of the device', () {
    testWidgets('Russian: the app is in Russian, with a 24-hour clock', (
      tester,
    ) async {
      useDevice(tester, const Locale('ru', 'KZ'));
      await AlarmRepository(db)
          .save(Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0)));
      await open(tester);

      expect(find.text('Будильники'), findsWidgets);
      expect(find.text('Следующий будильник'), findsOneWidget);
      expect(find.text('Новый будильник'), findsOneWidget);
      expect(find.text('Зазвонит через 7 ч 20 мин'), findsOneWidget);
      expect(find.text('7:00'), findsWidgets);
      expect(find.textContaining('AM'), findsNothing);
      expect(find.text('New alarm'), findsNothing);
    });

    testWidgets('Kazakh: the app is in Kazakh', (tester) async {
      useDevice(tester, const Locale('kk', 'KZ'));
      await open(tester);

      expect(find.text('Оятқыштар'), findsWidgets);
      expect(find.text('Оятқыш қойылмаған'), findsOneWidget);
      expect(find.text('Жаңа оятқыш'), findsOneWidget);
    });

    testWidgets('any other language: the app is in English', (tester) async {
      useDevice(tester, const Locale('de', 'DE'));
      await open(tester);

      expect(find.text('No alarm set'), findsOneWidget);
      expect(find.text('New alarm'), findsOneWidget);
    });

    testWidgets('the texts of Flutter itself follow: the back button and the '
        'keys of the time entry', (tester) async {
      useDevice(tester, const Locale('ru'));
      await open(tester);

      await tester.tap(find.text('Новый будильник'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Назад'), findsOneWidget);
      // 24 hours: no AM and PM keys next to the wheels.
      expect(
        find.descendant(
          of: find.byType(TimeWheels),
          matching: find.byType(SegmentedButton<DayPeriod>),
        ),
        findsNothing,
      );
      await tester.tap(find.text('Ввести время'));
      await tester.pumpAndSettle();
      expect(find.text('Отмена'), findsOneWidget);
    });
  });

  group('The Language setting', () {
    Future<void> choose(WidgetTester tester, String name) async {
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byType(Dialog), matching: find.text(name)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('changes the language of every page at once, and keeps it', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Same as the device'), findsOneWidget);

      await choose(tester, 'Русский');

      // Still on Settings, now in Russian.
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Настройки'), findsOneWidget);
      expect(find.text('Русский'), findsOneWidget);
      expect(find.text('Утренняя карточка'), findsOneWidget);
      expect(
        await ProviderScope.containerOf(
          tester.element(find.byType(SettingsScreen)),
        ).read(settingsRepositoryProvider).language(),
        'ru',
      );

      // The back button is Flutter's own, and in Russian too.
      await tester.tap(find.byTooltip('Назад'));
      await tester.pumpAndSettle();
      expect(find.text('Будильник не задан'), findsOneWidget);
      await openTab(tester, 'Аналитика');
      expect(find.text('Пока нет ни одного утра.'), findsOneWidget);
    });

    testWidgets('offers Kazakh, and the way back to the device', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      await choose(tester, 'Қазақша');
      expect(find.widgetWithText(AppBar, 'Баптаулар'), findsOneWidget);
      expect(find.text('Қазақша'), findsOneWidget);

      await choose(tester, 'Құрылғыдағыдай');
      expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
      expect(find.text('Same as the device'), findsOneWidget);
      expect(
        await ProviderScope.containerOf(
          tester.element(find.byType(SettingsScreen)),
        ).read(settingsRepositoryProvider).language(),
        isNull,
      );
    });

    testWidgets('a kept choice wins over the device at the next start', (
      tester,
    ) async {
      useDevice(tester, const Locale('ru'));
      await SettingsRepository(SharedPreferencesAsync()).saveLanguage('kk');

      await open(tester);

      expect(find.text('Оятқыш қойылмаған'), findsOneWidget);
    });

    testWidgets('closing the list keeps the language', (tester) async {
      await open(tester);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
    });
  });

  for (final code in ['ru', 'kk']) {
    for (final (size, scale) in [
      (const Size(360, 740), 2.0),
      (const Size(1280, 800), 1.0),
    ]) {
      testWidgets('every page fits ${size.width.round()} px wide at text '
          'scale $scale, in $code', (tester) async {
        useDevice(tester, Locale(code));
        setTextScale(tester, scale);
        askForLessMotion(tester);
        final scheduler = FakeAlarmScheduler();
        final player = FakeSoundPlayer();
        final ring = DateTime(2026, 11, 12, 10, 45);
        var time = now;
        final alarm = Alarm(
          id: 'long',
          time: ClockTime(hour: 10, minute: 45),
          repeatDays: const {1, 3, 5, 6},
          label: 'Morning run with the dog, then a swim',
        );
        final alarms = AlarmRepository(db);
        await alarms.save(alarm);
        await alarms.save(
          Alarm(
            id: 'off',
            time: ClockTime(hour: 22, minute: 55),
            enabled: false,
          ),
        );
        await syncLibrary(db, [
          for (final entry in library) entry.toStoredSound(),
        ]);
        // Two mornings for Analytics: one snoozed, one missed.
        final sessions = RingSessionRepository(db);
        for (final (id, day, last) in [
          ('one', 9, RingAction.stop),
          ('two', 10, RingAction.timeout),
        ]) {
          final at = DateTime(2026, 11, day, 7);
          await sessions.save(
            RingSession(
              id: id,
              alarmId: 'long',
              scheduledFor: at,
              events: [
                RingEvent(
                  soundId: library.first.toStoredSound().sound.id,
                  startedAt: at,
                  endedAt: at.add(const Duration(seconds: 20)),
                  action: RingAction.snooze,
                ),
                RingEvent(
                  soundId: library.last.toStoredSound().sound.id,
                  startedAt: at.add(const Duration(minutes: 5)),
                  endedAt: at.add(const Duration(minutes: 5, seconds: 20)),
                  action: last,
                ),
              ],
            ),
          );
        }
        await open(
          tester,
          size: size,
          overrides: [
            alarmSchedulerProvider.overrideWithValue(scheduler),
            soundPlayerProvider.overrideWithValue(player),
            screenWakeLockProvider.overrideWithValue(FakeScreenWakeLock()),
            nowProvider.overrideWithValue(() => time),
          ],
        );
        expect(tr.localeName, code);

        // Scrolls the page that is open from its top to its end.
        Future<void> scroll() async {
          for (final element in find.byType(Scrollable).evaluate()) {
            final position = (element as StatefulElement).state;
            if (position is! ScrollableState) continue;
            final scrolled = position.position;
            if (scrolled.axis != Axis.vertical) continue;
            for (var offset = 0.0; ; offset += 200) {
              scrolled.jumpTo(offset.clamp(0, scrolled.maxScrollExtent));
              await tester.pump();
              if (offset >= scrolled.maxScrollExtent) break;
            }
            scrolled.jumpTo(0);
            await tester.pump();
          }
        }

        // Taps [text], after scrolling the page until it is in the middle.
        Future<void> tapText(String text) async {
          final target = find.text(text);
          if (target.evaluate().isEmpty) {
            await tester.scrollUntilVisible(
              target,
              200,
              scrollable: find.byType(Scrollable).first,
            );
          }
          await Scrollable.ensureVisible(
            tester.element(target),
            alignment: 0.5,
          );
          await tester.pump();
          await tester.tap(target);
          await tester.pumpAndSettle();
        }

        final router = GoRouter.of(tester.element(find.byType(WakemixNavBar)));
        Future<void> go(String path) async {
          router.go(path);
          await tester.pumpAndSettle();
          await scroll();
        }

        // The Alarms tab, unarmed and armed.
        expect(find.text(tr.newAlarm), findsOneWidget);
        await scroll();
        await tapText(tr.armAlarms);
        expect(find.text(tr.keepTabOpen), findsOneWidget);
        await scroll();

        // The editor, Tonight's mix, Analytics, the Library and Settings.
        await go('/alarms/new');
        expect(find.byType(TimeWheels), findsOneWidget);
        await go(TonightMixScreen.path);
        expect(find.text(tr.reshuffle), findsOneWidget);
        await go(AnalyticsScreen.path);
        expect(find.byType(MonthCalendar), findsOneWidget);
        for (final period in [tr.periodDay, tr.periodMonth, tr.periodYear]) {
          await tapText(period);
          await scroll();
        }
        await go('/library');
        await go(SettingsScreen.path);
        expect(find.byType(SettingsScreen), findsOneWidget);
        await go(BedtimeReminderScreen.path);
        expect(find.byType(BedtimeReminderScreen), findsOneWidget);
        await go('/alarms');

        // A ring, a Snooze, and the Morning card after Stop.
        time = ring;
        scheduler.ring(DueRing(alarm, scheduledFor: ring));
        await tester.pumpAndSettle();
        expect(find.byType(RingingScreen), findsOneWidget);
        await scroll();
        await tester.tap(find.text(tr.snoozeMinutes(5)));
        await tester.pumpAndSettle();
        expect(find.byType(RingingScreen), findsNothing);
        await scroll();
        time = scheduler.scheduled.single.startsAt;
        scheduler.ringScheduled();
        await tester.pumpAndSettle();
        time = time.add(const Duration(minutes: 1, seconds: 5));
        await tester.tap(find.text(tr.stop));
        await tester.pumpAndSettle();
        expect(find.byType(MorningCardScreen), findsOneWidget);
        await scroll();

        expect(tester.takeException(), isNull);
      });
    }
  }
}
