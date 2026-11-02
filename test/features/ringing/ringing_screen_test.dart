import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/due_rings.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/ring_session_repository.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/design/components/spinning_record.dart';
import 'package:shuffle_alarm/design/tokens.dart';
import 'package:shuffle_alarm/features/alarms/alarms_screen.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/ringing/ringing_screen.dart';
import 'package:shuffle_alarm/platform/providers.dart';

import '../../data/memory_database.dart';
import '../../design/design_app.dart';
import '../../platform/fake_platform.dart';
import '../alarms/alarms_app.dart';

void main() {
  late AppDatabase db;
  late FakeAlarmScheduler scheduler;
  late FakeSoundPlayer player;
  late DateTime now;

  setUp(() {
    db = memoryDatabase();
    scheduler = FakeAlarmScheduler();
    player = FakeSoundPlayer(needsUnlock: false);
    now = DateTime(2026, 11, 12, 7);
  });
  // Not closed: see memoryDatabase().

  List<Override> web() => [
    alarmSchedulerProvider.overrideWithValue(scheduler),
    soundPlayerProvider.overrideWithValue(player),
    screenWakeLockProvider.overrideWithValue(FakeScreenWakeLock()),
    nowProvider.overrideWithValue(() => now),
  ];

  /// The app on the Alarms tab, with two sounds and [alarm].
  ///
  /// Less motion is asked for, so `pumpAndSettle` ends: the record of the
  /// ringing screen turns for as long as it shows.
  Future<TestClock> open(
    WidgetTester tester,
    Alarm alarm, {
    bool lessMotion = true,
  }) async {
    if (lessMotion) askForLessMotion(tester);
    for (final (id, title, intensity) in [
      ('chime', 'Chime', 1),
      ('bell', 'Bell', 2),
    ]) {
      await SoundRepository(db).save(
        StoredSound(
          Sound(
            id: id,
            title: title,
            source: SoundSource.builtin,
            genre: 'calm',
            intensity: intensity,
            duration: const Duration(seconds: 20),
          ),
          audioPath: 'assets/library/calm/$id.wav',
        ),
      );
    }
    await AlarmRepository(db).save(alarm);
    return await openAlarms(
      tester,
      db: db,
      now: wednesdayEvening,
      overrides: web(),
    );
  }

  /// [alarm] comes due at 07:00 on Thursday.
  Future<void> ring(WidgetTester tester, Alarm alarm) async {
    scheduler.ring(DueRing(alarm, scheduledFor: DateTime(2026, 11, 12, 7)));
    await tester.pumpAndSettle();
  }

  Finder inScreen(Finder finder) =>
      find.descendant(of: find.byType(RingingScreen), matching: finder);

  group('The ringing screen', () {
    testWidgets(
      'opens above the tabs, with the clock, the alarm and its sound',
      (tester) async {
        final alarm = _alarm(label: 'Gym');
        await open(tester, alarm);

        await ring(tester, alarm);

        expect(find.byType(RingingScreen), findsOneWidget);
        expect(find.text('7:00'), findsOneWidget);
        expect(find.text('AM'), findsOneWidget);
        expect(find.text('ALARM 7:00 AM'), findsOneWidget);
        expect(find.text('Gym'), findsOneWidget);
        expect(find.text('NOW PLAYING'), findsOneWidget);
        expect(find.text('Chime'), findsOneWidget);
        expect(find.text('Snooze 5 min'), findsOneWidget);
        expect(find.text('Stop'), findsOneWidget);
        expect(player.plays, hasLength(1));
      },
    );

    testWidgets('shows the time now, not the time of the alarm', (
      tester,
    ) async {
      final alarm = _alarm();
      await open(tester, alarm);
      now = DateTime(2026, 11, 12, 7, 3);

      await ring(tester, alarm);

      expect(find.text('7:03'), findsOneWidget);
      expect(find.text('ALARM 7:00 AM'), findsOneWidget);
    });

    testWidgets('keeps its clock on time, at each minute', (tester) async {
      final alarm = _alarm();
      final clock = await open(tester, alarm);
      await ring(tester, alarm);

      now = DateTime(2026, 11, 12, 7, 1);
      clock.moveTo(now);
      await tester.pumpAndSettle();

      expect(find.text('7:01'), findsOneWidget);
    });

    testWidgets('says which sound plays, as the sounds change', (tester) async {
      final alarm = _alarm();
      await open(tester, alarm);
      await ring(tester, alarm);
      expect(find.text('Chime'), findsOneWidget);

      now = now.add(const Duration(seconds: 20));
      player.finishClip();
      await tester.pumpAndSettle();

      expect(find.text('Chime'), findsNothing);
      expect(find.text('Bell'), findsOneWidget);
    });

    for (final brightness in brightnesses) {
      testWidgets('fills the screen with the accent, in ${brightness.name}', (
        tester,
      ) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final alarm = _alarm();
        await open(tester, alarm);
        await ring(tester, alarm);

        final colors = brightness == Brightness.dark
            ? WakemixColors.dark
            : WakemixColors.light;
        final page = tester.widget<Scaffold>(inScreen(find.byType(Scaffold)));
        final theme = Theme.of(tester.element(inScreen(find.byType(Scaffold))));
        expect(
          page.backgroundColor ?? theme.scaffoldBackgroundColor,
          colors.accent,
        );
        expect(
          tester
              .widget<RichText>(
                find.descendant(
                  of: find.widgetWithText(FilledButton, 'Stop'),
                  matching: find.byType(RichText),
                ),
              )
              .text
              .style
              ?.color,
          colors.accent,
        );
      });
    }

    testWidgets('Stop ends the ring, and goes back to the tabs', (
      tester,
    ) async {
      final alarm = _alarm();
      await open(tester, alarm);
      await ring(tester, alarm);

      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      expect(find.byType(RingingScreen), findsNothing);
      expect(find.byType(AlarmsScreen), findsOneWidget);
      expect(player.stopCalls, 1);
      final session = (await RingSessionRepository(db).all()).single;
      expect(session.outcome, RingOutcome.stopped);
    });

    testWidgets('keeps showing the alarm while it closes', (tester) async {
      final alarm = _alarm(label: 'Gym');
      await open(tester, alarm, lessMotion: false);
      scheduler.ring(DueRing(alarm, scheduledFor: now));
      while (find.byType(SpinningRecord).evaluate().isEmpty) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Stop'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byType(RingingScreen), findsOneWidget);
      expect(find.text('Gym'), findsOneWidget);
      expect(find.text('ALARM 7:00 AM'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(RingingScreen), findsNothing);
    });

    testWidgets('Back does not end a ring', (tester) async {
      final alarm = _alarm();
      await open(tester, alarm);
      await ring(tester, alarm);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(RingingScreen), findsOneWidget);
    });

    testWidgets(
      'the Back of a browser leaves it in place, and Stop still works',
      (tester) async {
        // A browser tells the app about its Back as a new address.
        final alarm = _alarm();
        await open(tester, alarm);
        await tester.tap(find.text('Library'));
        await tester.pumpAndSettle();
        await ring(tester, alarm);

        await tester.binding.handlePushRoute('/library');
        await tester.pumpAndSettle();

        expect(find.byType(RingingScreen), findsOneWidget);
        expect(find.text('Stop'), findsOneWidget);
        expect(player.stopCalls, 0);

        await tester.tap(find.text('Stop'));
        await tester.pumpAndSettle();

        expect(find.byType(RingingScreen), findsNothing);
        expect(find.byType(AlarmsScreen), findsOneWidget);
        expect(player.stopCalls, 1);
      },
    );

    testWidgets('its address without a ring goes to the Alarms tab', (
      tester,
    ) async {
      // The Forward of a browser after a Stop, or an address typed by hand.
      await open(tester, _alarm());

      await tester.binding.handlePushRoute(RingingScreen.path);
      await tester.pumpAndSettle();

      expect(find.byType(RingingScreen), findsNothing);
      expect(find.byType(AlarmsScreen), findsOneWidget);
    });

    testWidgets('a one-time alarm is off after its ring', (tester) async {
      final alarm = _alarm();
      await open(tester, alarm);

      await ring(tester, alarm);
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      expect(find.text('Off'), findsOneWidget);
    });

    testWidgets('a blocked sound offers to play it; Snooze and Stop stay', (
      tester,
    ) async {
      player.blocked = true;
      final alarm = _alarm();
      await open(tester, alarm);

      await ring(tester, alarm);

      expect(find.text('The sound did not play.'), findsOneWidget);
      expect(find.text('NOW PLAYING'), findsNothing);
      expect(find.text('Snooze 5 min'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      await tester.tap(find.text('Play sound'));
      await tester.pumpAndSettle();

      expect(player.unlockCalls, 1);
      expect(player.plays, hasLength(1));
      expect(find.text('Play sound'), findsNothing);
      expect(find.text('NOW PLAYING'), findsOneWidget);
    });

    testWidgets('a ring that reached its cap says so, and only Close stays', (
      tester,
    ) async {
      final alarm = _alarm();
      await open(tester, alarm);
      await ring(tester, alarm);

      now = now.add(const Duration(minutes: 10));
      player.finishClip();
      await tester.pumpAndSettle();

      expect(
        find.text('It rang for 10 min, and nobody stopped it.'),
        findsOneWidget,
      );
      expect(find.text('NOW PLAYING'), findsNothing);
      expect(find.text('Snooze 5 min'), findsNothing);
      expect(find.text('Stop'), findsNothing);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(RingingScreen), findsNothing);
    });

    testWidgets('screen readers hear the clock whole, and each button', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final alarm = _alarm();
      await open(tester, alarm);
      await ring(tester, alarm);

      expect(find.bySemanticsLabel('7:00 AM'), findsOneWidget);
      expect(find.bySemanticsLabel('Alarm 7:00 AM'), findsOneWidget);
      expect(find.bySemanticsLabel('Now playing'), findsOneWidget);
      expect(find.bySemanticsLabel('Chime'), findsOneWidget);
      for (final label in ['Snooze 5 min', 'Stop']) {
        final node = tester.getSemantics(find.text(label));
        expect(node.label, label);
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      }
      semantics.dispose();
    });

    group('The record', () {
      double turns(WidgetTester tester) => tester
          .widget<RotationTransition>(
            find.descendant(
              of: find.byType(SpinningRecord),
              matching: find.byType(RotationTransition),
            ),
          )
          .turns
          .value;

      testWidgets('spins while it rings', (tester) async {
        final alarm = _alarm();
        await open(tester, alarm, lessMotion: false);
        scheduler.ring(DueRing(alarm, scheduledFor: now));
        // The ring reads its sounds first, and `pumpAndSettle` never ends
        // here.
        while (find.byType(SpinningRecord).evaluate().isEmpty) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pump(const Duration(milliseconds: 500));

        final before = turns(tester);
        await tester.pump(const Duration(milliseconds: 500));

        expect(turns(tester), isNot(before));

        // So the test can end: nothing keeps turning without the screen.
        await tester.tap(find.text('Stop'));
        await tester.pumpAndSettle();
        expect(find.byType(SpinningRecord), findsNothing);
      });

      testWidgets('stands still when no sound plays', (tester) async {
        player.blocked = true;
        final alarm = _alarm();
        await open(tester, alarm, lessMotion: false);
        await ring(tester, alarm);
        expect(find.text('The sound did not play.'), findsOneWidget);

        final before = turns(tester);
        await tester.pump(const Duration(seconds: 1));

        expect(turns(tester), before);
        expect(tester.hasRunningAnimations, isFalse);
      });

      testWidgets('stands still once the ring went quiet at its cap', (
        tester,
      ) async {
        final alarm = _alarm();
        await open(tester, alarm, lessMotion: false);
        scheduler.ring(DueRing(alarm, scheduledFor: now));
        while (find.byType(SpinningRecord).evaluate().isEmpty) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        now = now.add(const Duration(minutes: 10));
        player.finishClip();
        await tester.pumpAndSettle();

        expect(find.text('Close'), findsOneWidget);
        expect(tester.hasRunningAnimations, isFalse);
      });

      testWidgets('stands still when less motion is asked for', (tester) async {
        final alarm = _alarm();
        await open(tester, alarm);
        await ring(tester, alarm);

        final before = turns(tester);
        await tester.pump(const Duration(seconds: 1));

        expect(turns(tester), before);
        expect(tester.hasRunningAnimations, isFalse);
      });

      testWidgets('is not on the Alarms tab: it spins only here', (
        tester,
      ) async {
        await open(tester, _alarm());

        expect(find.byType(SpinningRecord), findsNothing);
      });
    });
  });

  group('Snooze', () {
    testWidgets('closes the screen, and a card says when it comes back', (
      tester,
    ) async {
      final alarm = _alarm(label: 'Gym');
      await open(tester, alarm);
      await ring(tester, alarm);
      now = DateTime(2026, 11, 12, 7, 0, 30);

      await tester.tap(find.text('Snooze 5 min'));
      await tester.pumpAndSettle();

      expect(find.byType(RingingScreen), findsNothing);
      expect(find.byType(AlarmsScreen), findsOneWidget);
      expect(player.stopCalls, 1);
      expect(find.text('Snoozed until 7:05 AM'), findsOneWidget);
      expect(
        find.text('Gym rings again then, while this tab is open.'),
        findsOneWidget,
      );
      expect(find.text('Stop alarm'), findsOneWidget);
      final session = (await RingSessionRepository(db).all()).single;
      expect(session.outcome, RingOutcome.snoozed);
    });

    testWidgets('comes back: the screen opens again, and the card goes', (
      tester,
    ) async {
      final alarm = _alarm();
      await open(tester, alarm);
      await ring(tester, alarm);
      await tester.tap(find.text('Snooze 5 min'));
      await tester.pumpAndSettle();

      now = scheduler.scheduled.single.startsAt;
      scheduler.ringScheduled();
      await tester.pumpAndSettle();

      expect(find.byType(RingingScreen), findsOneWidget);
      expect(find.text('7:05'), findsOneWidget);
      expect(find.text('ALARM 7:00 AM'), findsOneWidget);
      expect(player.plays, hasLength(2));
      expect(player.plays.last.volume, 1);
      expect(
        find.text('Snoozed until 7:05 AM', skipOffstage: false),
        findsNothing,
      );

      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      expect(find.byType(RingingScreen), findsNothing);
      final session = (await RingSessionRepository(db).all()).single;
      expect(session.outcome, RingOutcome.stopped);
      expect(session.events.map((event) => event.action), [
        RingAction.snooze,
        RingAction.stop,
      ]);
    });

    testWidgets('Stop alarm on the card ends the snooze', (tester) async {
      final alarm = _alarm();
      await open(tester, alarm);
      await ring(tester, alarm);
      await tester.tap(find.text('Snooze 5 min'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Stop alarm'));
      await tester.pumpAndSettle();

      expect(find.text('Stop alarm'), findsNothing);
      expect(scheduler.scheduled, isEmpty);
      final session = (await RingSessionRepository(db).all()).single;
      expect(session.outcome, RingOutcome.stopped);
    });

    testWidgets('an alarm without a label has a card of its own words', (
      tester,
    ) async {
      final alarm = _alarm();
      await open(tester, alarm);
      await ring(tester, alarm);

      await tester.tap(find.text('Snooze 5 min'));
      await tester.pumpAndSettle();

      expect(
        find.text('The alarm rings again then, while this tab is open.'),
        findsOneWidget,
      );
    });

    testWidgets('a snooze from before a reload shows its card', (tester) async {
      final alarm = _alarm();
      await RingSessionRepository(db).save(
        RingSession(
          id: 's',
          alarmId: alarm.id,
          scheduledFor: DateTime(2026, 11, 12, 7),
          events: [
            RingEvent(
              soundId: 'chime',
              startedAt: DateTime(2026, 11, 12, 7),
              endedAt: DateTime(2026, 11, 12, 7, 0, 30),
              action: RingAction.snooze,
            ),
          ],
        ),
      );

      await open(tester, alarm);

      expect(find.text('Snoozed until 7:05 AM'), findsOneWidget);
      expect(scheduler.scheduled, hasLength(1));
    });
  });

  testWidgets('no card without a snooze', (tester) async {
    await open(tester, _alarm());

    expect(find.textContaining('Snoozed until'), findsNothing);
  });
}

Alarm _alarm({String label = ''}) =>
    Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0), label: label);
