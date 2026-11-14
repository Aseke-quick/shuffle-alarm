import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shuffle_alarm/core/adaptive_weights.dart';
import 'package:shuffle_alarm/core/due_rings.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/morning_answer.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/morning_answer_repository.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/data/ring_session_repository.dart';
import 'package:shuffle_alarm/data/settings_repository.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/data/weight_repository.dart';
import 'package:shuffle_alarm/design/components/mix_bars.dart';
import 'package:shuffle_alarm/design/components/mix_track_row.dart';
import 'package:shuffle_alarm/design/components/nav_bar.dart';
import 'package:shuffle_alarm/design/components/time_text.dart';
import 'package:shuffle_alarm/features/alarms/alarms_screen.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/alarms/mix_preview.dart';
import 'package:shuffle_alarm/features/alarms/tonight_mix_screen.dart';
import 'package:shuffle_alarm/features/ringing/morning_card_screen.dart';
import 'package:shuffle_alarm/features/ringing/ringing_controller.dart';
import 'package:shuffle_alarm/features/ringing/ringing_screen.dart';
import 'package:shuffle_alarm/platform/providers.dart';
import 'package:shuffle_alarm/router.dart';

import '../../data/memory_database.dart';
import '../../design/design_app.dart';
import '../../platform/fake_platform.dart';
import '../alarms/alarms_app.dart';
import '../settings/reminder_app.dart';

void main() {
  late AppDatabase db;
  late FakeAlarmScheduler scheduler;
  late FakeSoundPlayer player;
  late DateTime now;
  final seven = DateTime(2026, 11, 12, 7);

  setUp(() {
    db = memoryDatabase();
    useMemorySettings();
    scheduler = FakeAlarmScheduler();
    player = FakeSoundPlayer(needsUnlock: false);
    now = seven;
  });
  // Not closed: see memoryDatabase().

  /// The app on the Alarms tab, with two sounds and these alarms.
  Future<TestClock> open(
    WidgetTester tester, {
    List<Alarm>? alarms,
    List<Override> overrides = const [],
  }) async {
    askForLessMotion(tester);
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
    for (final alarm in alarms ?? [_alarm()]) {
      await AlarmRepository(db).save(alarm);
    }
    return await openAlarms(
      tester,
      db: db,
      now: wednesdayEvening,
      overrides: [
        alarmSchedulerProvider.overrideWithValue(scheduler),
        soundPlayerProvider.overrideWithValue(player),
        screenWakeLockProvider.overrideWithValue(FakeScreenWakeLock()),
        nowProvider.overrideWithValue(() => now),
        ...overrides,
      ],
    );
  }

  /// The alarm comes due now, at 07:00 unless the test moved the time.
  Future<void> ring(WidgetTester tester, {Alarm? alarm, DateTime? set}) async {
    scheduler.ring(DueRing(alarm ?? _alarm(), scheduledFor: set ?? seven));
    await tester.pumpAndSettle();
  }

  /// The clip that plays ends, 20 s on.
  Future<void> nextClip(WidgetTester tester) async {
    now = now.add(const Duration(seconds: 20));
    player.finishClip();
    await tester.pumpAndSettle();
  }

  /// Stop, 5 s on: a tap in the same moment as the start of its clip would
  /// mean that no sound played.
  Future<void> stop(WidgetTester tester) async {
    now = now.add(const Duration(seconds: 5));
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();
  }

  /// Snooze, 5 s on.
  Future<void> snooze(WidgetTester tester) async {
    now = now.add(const Duration(seconds: 5));
    await tester.tap(find.text('Snooze 5 min'));
    await tester.pumpAndSettle();
  }

  Future<List<MorningAnswer>> answers() => MorningAnswerRepository(db).all();

  Future<SoundWeights> weights() => WeightRepository(db).load();

  /// What shows on top now: the screens above the tabs, with those below them.
  Finder onScreen(Type screen) => find.byType(screen);

  group('After Stop', () {
    testWidgets('opens above the tabs, and the ring is over', (tester) async {
      await open(tester);
      await ring(tester);

      await stop(tester);

      expect(onScreen(MorningCardScreen), findsOneWidget);
      expect(find.byType(RingingScreen), findsNothing);
      expect(find.byType(WakemixNavBar), findsNothing);
      expect(find.text('Morning card'), findsOneWidget);
      expect(player.stopCalls, 1);
    });

    testWidgets('says when the user woke, and how long after the alarm', (
      tester,
    ) async {
      await open(tester);
      await ring(tester);
      now = DateTime(2026, 11, 12, 7, 4, 50);

      await stop(tester);

      expect(find.text('You woke at'), findsOneWidget);
      final time = tester.widget<TimeText>(find.byType(TimeText));
      expect(time.time, const TimeOfDay(hour: 7, minute: 4));
      expect(find.text('4 min after your 7:00 AM alarm'), findsOneWidget);
    });

    testWidgets('says "Under 1 min" for a Stop in the first minute', (
      tester,
    ) async {
      await open(tester);
      await ring(tester);
      now = now.add(const Duration(seconds: 12));

      await stop(tester);

      expect(find.text('Under 1 min after your 7:00 AM alarm'), findsOneWidget);
    });

    testWidgets('says that there was no snooze', (tester) async {
      await open(tester);
      await ring(tester);

      await stop(tester);

      expect(find.text('No snoozes · 1 sound'), findsOneWidget);
    });

    testWidgets('counts the snoozes and the sounds of the whole morning', (
      tester,
    ) async {
      await open(tester);
      await ring(tester);
      await nextClip(tester);
      await snooze(tester);
      expect(onScreen(MorningCardScreen), findsNothing);
      now = scheduler.scheduled.single.startsAt;
      scheduler.ringScheduled();
      await tester.pumpAndSettle();

      await stop(tester);

      expect(find.text('1 snooze · 2 sounds'), findsOneWidget);
      expect(find.text('5 min after your 7:00 AM alarm'), findsOneWidget);
    });

    testWidgets('lists the sounds in play order, with when they first played', (
      tester,
    ) async {
      await open(tester);
      await ring(tester);
      await nextClip(tester);

      await stop(tester);

      expect(find.text('Which sound woke you?'), findsOneWidget);
      final rows = tester
          .widgetList<MixTrackRow>(find.byType(MixTrackRow))
          .toList();
      expect(rows.map((row) => row.title), ['Chime', 'Bell']);
      expect(rows.map((row) => row.details), [
        '0:00 · Calm · Gentle',
        '0:20 · Calm · Medium',
      ]);
      expect(rows.every((row) => row.accentAction), isTrue);
      expect(find.text('This one'), findsNWidgets(2));
      expect(find.text('Not sure'), findsOneWidget);
    });

    testWidgets('shows the sounds that played on a record', (tester) async {
      await open(tester);
      await ring(tester);
      await nextClip(tester);

      await stop(tester);

      final record = tester.widget<MixBars>(
        find.descendant(
          of: find.byType(MorningCardScreen),
          matching: find.byType(MixBars),
        ),
      );
      expect(record.segments, const [
        MixSegment(length: Duration(seconds: 20), strength: 0),
        MixSegment(length: Duration(seconds: 5), strength: 0.5),
      ]);
    });

    testWidgets('says that it can be turned off', (tester) async {
      await open(tester);
      await ring(tester);

      await stop(tester);

      expect(
        find.text('You can turn this card off in Settings.'),
        findsOneWidget,
      );
    });

    testWidgets('screen readers hear the time whole, and each answer', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await open(tester);
      await ring(tester);
      await stop(tester);

      // One thing to hear, in sentence case, with the time whole.
      expect(
        tester.getSemantics(find.byType(TimeText)).label,
        'You woke at\n7:00 AM\nUnder 1 min after your 7:00 AM alarm\n'
        'No snoozes · 1 sound',
      );
      expect(
        tester
            .getSemantics(find.text('Which sound woke you?'))
            .flagsCollection
            .isHeader,
        isTrue,
      );
      final answer = tester.getSemantics(
        find.bySemanticsLabel('This one woke me: Chime'),
      );
      expect(answer.flagsCollection.isButton, isTrue);
      expect(answer.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      semantics.dispose();
    });
  });

  group('It does not open', () {
    testWidgets('after Snooze', (tester) async {
      await open(tester);
      await ring(tester);

      await snooze(tester);

      expect(onScreen(MorningCardScreen), findsNothing);
      expect(find.byType(AlarmsScreen), findsOneWidget);
    });

    testWidgets('after Close, for a ring that reached its cap', (tester) async {
      await open(tester);
      await ring(tester);
      now = now.add(const Duration(minutes: 10));
      player.finishClip();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(onScreen(MorningCardScreen), findsNothing);
      expect(find.byType(AlarmsScreen), findsOneWidget);
    });

    testWidgets('when it was turned off: Stop goes back to the tabs', (
      tester,
    ) async {
      await SettingsRepository(SharedPreferencesAsync())
          .saveMorningCard(on: false);
      await open(tester);
      await ring(tester);

      await stop(tester);

      expect(onScreen(MorningCardScreen), findsNothing);
      expect(find.byType(AlarmsScreen), findsOneWidget);
      final session = (await RingSessionRepository(db).all()).single;
      expect(session.outcome, RingOutcome.stopped);
      expect((await weights()).weightOf('chime'), SoundWeights.stopFactor);
    });

    testWidgets('at an address of its own without a card', (tester) async {
      await open(tester);

      await tester.binding.handlePushRoute(MorningCardScreen.path);
      await tester.pumpAndSettle();

      expect(onScreen(MorningCardScreen), findsNothing);
      expect(find.byType(AlarmsScreen), findsOneWidget);
    });

    testWidgets('at its address during a ring: the ring stays', (tester) async {
      await open(tester);
      await ring(tester);

      await tester.binding.handlePushRoute(MorningCardScreen.path);
      await tester.pumpAndSettle();

      expect(onScreen(MorningCardScreen), findsNothing);
      expect(find.byType(RingingScreen), findsOneWidget);
    });
  });

  group('Stop alarm during a snooze', () {
    testWidgets('opens the card, with the sounds before the snooze', (
      tester,
    ) async {
      await open(tester);
      await ring(tester);
      await nextClip(tester);
      await snooze(tester);
      now = now.add(const Duration(minutes: 2));

      await tester.tap(find.text('Stop alarm'));
      await tester.pumpAndSettle();

      expect(onScreen(MorningCardScreen), findsOneWidget);
      expect(find.text('2 min after your 7:00 AM alarm'), findsOneWidget);
      expect(find.text('1 snooze · 2 sounds'), findsOneWidget);
      expect(find.byType(MixTrackRow), findsNWidgets(2));
    });

    testWidgets('stays on the tab when the card is turned off', (tester) async {
      await open(tester, overrides: [noMorningCard]);
      await ring(tester);
      await snooze(tester);

      await tester.tap(find.text('Stop alarm'));
      await tester.pumpAndSettle();

      expect(onScreen(MorningCardScreen), findsNothing);
      expect(find.text('Stop alarm'), findsNothing);
      // No page opened on top of the tab either.
      expect(tester.container().read(routerProvider).canPop(), isFalse);
    });

    testWidgets('of a deleted alarm opens nothing', (tester) async {
      await open(tester);
      await ring(tester);
      await snooze(tester);

      await AlarmRepository(db).delete(_alarm().id);
      await tester.pumpAndSettle();

      expect(onScreen(MorningCardScreen), findsNothing);
      expect(find.text('Stop alarm'), findsNothing);
    });
  });

  group('The answer', () {
    testWidgets('one tap on a sound keeps it, and the card closes', (
      tester,
    ) async {
      await open(tester);
      await ring(tester);
      await nextClip(tester);
      await stop(tester);
      final session = (await RingSessionRepository(db).all()).single;
      now = now.add(const Duration(seconds: 9));

      await tester.tap(
        find.descendant(
          of: find.widgetWithText(MixTrackRow, 'Chime'),
          matching: find.text('This one'),
        ),
      );
      await tester.pump();

      expect(find.text('Thanks. Wakemix will remember that.'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(onScreen(MorningCardScreen), findsNothing);
      expect(find.byType(AlarmsScreen), findsOneWidget);
      expect(await answers(), [
        MorningAnswer(sessionId: session.id, soundId: 'chime', answeredAt: now),
      ]);
      final learned = await weights();
      expect(learned.weightOf('chime'), SoundWeights.wokeFactor);
      expect(learned.weightOf('bell'), SoundWeights.stopFactor);
    });

    testWidgets('"Not sure" keeps that, teaches nothing and thanks nobody', (
      tester,
    ) async {
      await open(tester);
      await ring(tester);
      await stop(tester);

      await tester.tap(find.text('Not sure'));
      await tester.pump();

      expect(find.textContaining('Thanks'), findsNothing);
      await tester.pumpAndSettle();
      expect(onScreen(MorningCardScreen), findsNothing);
      expect((await answers()).single.soundId, isNull);
      expect((await weights()).weightOf('chime'), SoundWeights.stopFactor);
    });

    testWidgets('Back keeps no answer, and Stop has taught what it taught', (
      tester,
    ) async {
      await open(tester);
      await ring(tester);
      await stop(tester);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(onScreen(MorningCardScreen), findsNothing);
      expect(find.byType(AlarmsScreen), findsOneWidget);
      expect(await answers(), isEmpty);
      expect((await weights()).weightOf('chime'), SoundWeights.stopFactor);
    });

    testWidgets('goes back to the page below the ring', (tester) async {
      await open(tester);
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      await ring(tester);
      await stop(tester);

      await tester.tap(find.text('Not sure'));
      await tester.pumpAndSettle();

      expect(find.text('No sounds yet.'), findsOneWidget);
    });

    testWidgets("goes back to Tonight's mix when that was open", (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.textContaining("Tonight's mix"));
      await tester.pumpAndSettle();
      await ring(tester);
      await stop(tester);
      expect(onScreen(MorningCardScreen), findsOneWidget);

      await tester.tap(find.text('Not sure'));
      await tester.pumpAndSettle();

      expect(find.byType(TonightMixScreen), findsOneWidget);
    });

    testWidgets('a browser that went Back during the ring: to the Alarms tab', (
      tester,
    ) async {
      // A browser tells the app about its Back as a new address, so the
      // ringing page is alone there, and the card takes its place.
      await open(tester);
      await ring(tester);
      await tester.binding.handlePushRoute('/library');
      await tester.pumpAndSettle();
      await stop(tester);
      expect(onScreen(MorningCardScreen), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);

      await tester.tap(find.text('Not sure'));
      await tester.pumpAndSettle();

      expect(onScreen(MorningCardScreen), findsNothing);
      expect(find.byType(AlarmsScreen), findsOneWidget);
    });

    testWidgets('a card left with Back opens again at its address', (
      tester,
    ) async {
      await open(tester);
      await ring(tester);
      await stop(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.binding.handlePushRoute(MorningCardScreen.path);
      await tester.pumpAndSettle();

      expect(onScreen(MorningCardScreen), findsOneWidget);
      expect(find.byType(MixTrackRow), findsOneWidget);
    });

    testWidgets('a card that was answered does not open again', (tester) async {
      await open(tester);
      await ring(tester);
      await stop(tester);
      await tester.tap(find.text('This one'));
      await tester.pumpAndSettle();

      await tester.binding.handlePushRoute(MorningCardScreen.path);
      await tester.pumpAndSettle();

      expect(onScreen(MorningCardScreen), findsNothing);
      expect(find.byType(AlarmsScreen), findsOneWidget);
    });

    testWidgets('two quick taps close the card, and only the card', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.textContaining("Tonight's mix"));
      await tester.pumpAndSettle();
      await ring(tester);
      await stop(tester);

      await tester.tap(find.text('Not sure'));
      await tester.tap(find.text('Not sure'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(TonightMixScreen), findsOneWidget);
      expect(await answers(), hasLength(1));
    });

    testWidgets('that fails stays out of the way: the card still closes', (
      tester,
    ) async {
      await open(
        tester,
        overrides: [
          morningAnswerRepositoryProvider.overrideWithValue(_BrokenAnswers(db)),
          weightRepositoryProvider.overrideWithValue(_BrokenWeights(db)),
        ],
      );
      await ring(tester);
      await stop(tester);

      await tester.tap(find.text('This one'));
      await tester.pumpAndSettle();

      expect(onScreen(MorningCardScreen), findsNothing);
      expect(find.byType(AlarmsScreen), findsOneWidget);
    });
  });

  group('When no sound played', () {
    testWidgets('says so and what to do: nothing to ask, and Done', (
      tester,
    ) async {
      player = FakeSoundPlayer(blocked: true);
      await open(tester);
      await ring(tester);
      now = now.add(const Duration(minutes: 1));

      await stop(tester);

      expect(find.text('1 min after your 7:00 AM alarm'), findsOneWidget);
      expect(find.text('No snoozes'), findsOneWidget);
      expect(find.text('No sound played'), findsOneWidget);
      expect(
        find.text(
          'So there is nothing to ask this time. Tap Arm alarms before your '
          'next alarm, so that you can hear it.',
        ),
        findsOneWidget,
      );
      expect(find.text('Which sound woke you?'), findsNothing);
      expect(find.byType(MixTrackRow), findsNothing);
      expect(find.text('Not sure'), findsNothing);
      final semantics = tester.ensureSemantics();
      await tester.pump();
      expect(
        tester
            .getSemantics(find.text('No sound played'))
            .flagsCollection
            .isHeader,
        isTrue,
      );
      semantics.dispose();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(onScreen(MorningCardScreen), findsNothing);
      expect(find.byType(AlarmsScreen), findsOneWidget);
      expect(await answers(), isEmpty);
      expect(await weights(), const SoundWeights.start());
    });

    testWidgets('does not ask for a tap where the sound needs none', (
      tester,
    ) async {
      player.blocked = true;
      await open(tester);
      await ring(tester);

      await stop(tester);

      expect(
        find.text('So there is nothing to ask this time.'),
        findsOneWidget,
      );
    });

    testWidgets('does not ask for a tap on a page that is armed', (
      tester,
    ) async {
      player = FakeSoundPlayer();
      await open(tester);
      await tester.tap(find.text('Arm alarms'));
      await tester.pumpAndSettle();
      player.blocked = true;
      await ring(tester);

      await stop(tester);

      expect(
        find.text('So there is nothing to ask this time.'),
        findsOneWidget,
      );
    });

    testWidgets('a sound before a Snooze is still a sound to ask about', (
      tester,
    ) async {
      await open(tester);
      await ring(tester);
      await snooze(tester);
      player.blocked = true;
      now = scheduler.scheduled.single.startsAt;
      scheduler.ringScheduled();
      await tester.pumpAndSettle();

      await stop(tester);

      expect(find.text('Which sound woke you?'), findsOneWidget);
      expect(find.byType(MixTrackRow), findsOneWidget);
    });
  });

  group('The sounds cannot be read', () {
    testWidgets('it still says when the user woke, and Done closes it', (
      tester,
    ) async {
      var broken = false;
      await open(
        tester,
        overrides: [
          ringSoundsProvider.overrideWithValue(() async {
            if (broken) throw StateError('Broken');
            return await SoundRepository(db).all();
          }),
        ],
      );
      await ring(tester);
      broken = true;

      await stop(tester);

      expect(find.text('You woke at'), findsOneWidget);
      expect(find.byType(MixTrackRow), findsNothing);
      expect(find.text('Which sound woke you?'), findsNothing);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(onScreen(MorningCardScreen), findsNothing);
    });

    testWidgets('while they load "Not sure" can already close it', (
      tester,
    ) async {
      var stuck = false;
      await open(
        tester,
        overrides: [
          ringSoundsProvider.overrideWithValue(() async {
            if (stuck) return await Completer<List<StoredSound>>().future;
            return await SoundRepository(db).all();
          }),
        ],
      );
      await ring(tester);
      stuck = true;

      await stop(tester);

      expect(find.byType(MixTrackRow), findsNothing);
      await tester.tap(find.text('Not sure'));
      await tester.pumpAndSettle();
      expect(onScreen(MorningCardScreen), findsNothing);
    });

    testWidgets('a sound deleted since is left out', (tester) async {
      await open(tester);
      await ring(tester);
      await nextClip(tester);
      await SoundRepository(db).delete('chime');

      await stop(tester);

      expect(find.byType(MixTrackRow), findsOneWidget);
      expect(find.text('Bell'), findsOneWidget);
      expect(find.text('Chime'), findsNothing);
    });

    testWidgets('the tone can be named, and has no preview', (tester) async {
      await open(
        tester,
        overrides: [ringSoundsProvider.overrideWithValue(() async => const [])],
      );
      await ring(tester);
      expect(player.plays.single.asset, fakeTone);

      await stop(tester);

      expect(find.text('Alarm tone'), findsOneWidget);
      expect(find.byTooltip('Preview Alarm tone'), findsNothing);
      await tester.tap(find.text('This one'));
      await tester.pumpAndSettle();
      expect((await answers()).single.soundId, 'wakemix-tone');
    });
  });

  group('A preview', () {
    testWidgets('plays the clip of the sound, gently', (tester) async {
      await open(tester);
      await ring(tester);
      await stop(tester);
      player.plays.clear();

      await tester.tap(find.byTooltip('Preview Chime'));
      await tester.pumpAndSettle();

      expect(player.plays.single.asset, 'assets/library/calm/chime.wav');
      expect(player.plays.single.volume, 0.4);
      expect(find.byTooltip('Stop preview'), findsOneWidget);

      await tester.tap(find.byTooltip('Stop preview'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Preview Chime'), findsOneWidget);
    });

    testWidgets('stops with the answer, at once', (tester) async {
      await open(tester);
      await ring(tester);
      await stop(tester);
      await tester.tap(find.byTooltip('Preview Chime'));
      await tester.pumpAndSettle();
      final stops = player.stopCalls;

      await tester.tap(find.text('This one'));

      expect(player.stopCalls, stops + 1);
      await tester.pumpAndSettle();
      expect(player.stopCalls, stops + 1);
    });

    testWidgets('is not there where the platform plays no sounds', (
      tester,
    ) async {
      await open(tester);
      await ring(tester);
      await stop(tester);
      expect(find.byTooltip('Preview Chime'), findsOneWidget);

      player.playsSounds = false;
      // A new page reads the player again.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.binding.handlePushRoute(MorningCardScreen.path);
      await tester.pumpAndSettle();

      expect(find.byType(MixTrackRow), findsOneWidget);
      expect(find.byTooltip('Preview Chime'), findsNothing);
    });

    testWidgets('stops with Back', (tester) async {
      await open(tester);
      await ring(tester);
      await stop(tester);
      await tester.tap(find.byTooltip('Preview Chime'));
      await tester.pumpAndSettle();
      final stops = player.stopCalls;

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(player.stopCalls, stops + 1);
    });

    testWidgets('says when the browser blocks it', (tester) async {
      await open(tester);
      await ring(tester);
      await stop(tester);
      player.blocked = true;

      await tester.tap(find.byTooltip('Preview Chime'));
      await tester.pumpAndSettle();

      expect(
        find.text('The browser did not let the sound play. Try again.'),
        findsOneWidget,
      );
    });

    testWidgets('gives way to a ring, which keeps its sound', (tester) async {
      final next = _alarm(id: 'next');
      await open(tester, alarms: [_alarm(), next]);
      await ring(tester);
      await stop(tester);
      await tester.tap(find.byTooltip('Preview Chime'));
      await tester.pumpAndSettle();
      final stops = player.stopCalls;
      final plays = player.plays.length;
      now = now.add(const Duration(minutes: 1));

      await ring(tester, alarm: next, set: now);

      expect(find.byType(RingingScreen), findsOneWidget);
      expect(player.plays, hasLength(plays + 1));
      // The sound of the ring goes on: closing the card stopped nothing.
      expect(player.stopCalls, stops);
      expect(tester.container().read(mixPreviewProvider), isNull);
    });
  });

  group('A ring while the card shows', () {
    testWidgets('stays when a tap comes in the moment it starts', (
      tester,
    ) async {
      // The ring is there, and the screen has not drawn it yet: a tap still
      // lands on the card, and must not take the ringing page away.
      final next = _alarm(id: 'next');
      await open(tester, alarms: [_alarm(), next]);
      await ring(tester);
      await stop(tester);
      now = now.add(const Duration(minutes: 1));

      scheduler.ring(DueRing(next, scheduledFor: now));
      final app = tester.container();
      while (app.read(ringingProvider) == null) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      }
      await tester.tap(find.text('This one'));
      await tester.pump();

      expect(find.textContaining('Thanks'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byType(RingingScreen), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(app.read(ringingProvider), isNotNull);
      expect(await answers(), isEmpty);
    });

    testWidgets('stays when Done comes in the moment it starts', (
      tester,
    ) async {
      player.blocked = true;
      final next = _alarm(id: 'next');
      await open(tester, alarms: [_alarm(), next]);
      await ring(tester);
      await stop(tester);
      now = now.add(const Duration(minutes: 1));

      scheduler.ring(DueRing(next, scheduledFor: now));
      final app = tester.container();
      while (app.read(ringingProvider) == null) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      }
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.byType(RingingScreen), findsOneWidget);
    });

    testWidgets('takes its place at once, with its sound', (tester) async {
      final next = _alarm(id: 'next', label: 'Gym');
      await open(tester, alarms: [_alarm(), next]);
      await ring(tester);
      await stop(tester);
      expect(onScreen(MorningCardScreen), findsOneWidget);
      final plays = player.plays.length;
      now = now.add(const Duration(minutes: 1));

      await ring(tester, alarm: next, set: now);

      expect(find.byType(RingingScreen), findsOneWidget);
      expect(find.text('Gym'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(player.plays, hasLength(plays + 1));
      expect(find.byType(MorningCardScreen, skipOffstage: false), findsNothing);
    });

    testWidgets(
      'has a card of its own after its Stop, and none is left below',
      (tester) async {
        final next = _alarm(id: 'next');
        await open(tester, alarms: [_alarm(), next]);
        await ring(tester);
        now = now.add(const Duration(minutes: 2));
        await stop(tester);
        now = DateTime(2026, 11, 12, 8);
        await ring(tester, alarm: next, set: now);
        now = DateTime(2026, 11, 12, 8, 3);

        await stop(tester);

        expect(onScreen(MorningCardScreen), findsOneWidget);
        expect(find.text('3 min after your 8:00 AM alarm'), findsOneWidget);

        await tester.tap(find.text('Not sure'));
        await tester.pumpAndSettle();

        expect(onScreen(MorningCardScreen), findsNothing);
        expect(find.byType(AlarmsScreen), findsOneWidget);
        expect(find.byType(WakemixNavBar), findsOneWidget);
      },
    );

    testWidgets('after a Snooze goes back to the tabs, without the old card', (
      tester,
    ) async {
      final next = _alarm(id: 'next');
      await open(tester, alarms: [_alarm(), next]);
      await ring(tester);
      await stop(tester);
      now = now.add(const Duration(minutes: 1));
      await ring(tester, alarm: next, set: now);

      await snooze(tester);

      expect(onScreen(MorningCardScreen), findsNothing);
      expect(find.byType(AlarmsScreen), findsOneWidget);
      expect(find.textContaining('Snoozed until'), findsOneWidget);
    });

    testWidgets('that goes quiet at its cap closes without the old card', (
      tester,
    ) async {
      final next = _alarm(id: 'next');
      await open(tester, alarms: [_alarm(), next]);
      await ring(tester);
      await stop(tester);
      now = now.add(const Duration(minutes: 1));
      await ring(tester, alarm: next, set: now);
      now = now.add(const Duration(minutes: 10));
      player.finishClip();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(onScreen(MorningCardScreen), findsNothing);
      expect(find.byType(AlarmsScreen), findsOneWidget);
    });

    testWidgets('a ring found after its cap leaves the card open', (
      tester,
    ) async {
      final next = _alarm(id: 'next');
      await open(tester, alarms: [_alarm(), next]);
      await ring(tester);
      await stop(tester);
      now = now.add(const Duration(minutes: 11));

      await ring(tester, alarm: next, set: seven);

      expect(onScreen(MorningCardScreen), findsOneWidget);
      expect(find.byType(RingingScreen), findsNothing);
    });

    testWidgets('in a card opened from a snooze ends the card too', (
      tester,
    ) async {
      final next = _alarm(id: 'next');
      await open(tester, alarms: [_alarm(), next]);
      await ring(tester);
      await snooze(tester);
      await tester.tap(find.text('Stop alarm'));
      await tester.pumpAndSettle();
      expect(onScreen(MorningCardScreen), findsOneWidget);
      now = now.add(const Duration(minutes: 1));

      await ring(tester, alarm: next, set: now);
      await snooze(tester);

      expect(onScreen(MorningCardScreen), findsNothing);
      expect(find.byType(AlarmsScreen), findsOneWidget);
    });
  });

  testWidgets('with its answer it reads from the log after a reload', (
    tester,
  ) async {
    // What 2.8 reads: the session and its answer, from the database.
    await open(tester);
    await ring(tester);
    await stop(tester);
    await tester.tap(find.text('This one'));
    await tester.pumpAndSettle();

    final session = (await RingSessionRepository(db).all()).single;
    expect((await answers()).single.sessionId, session.id);
  });
}

Alarm _alarm({String id = 'a', String label = ''}) => Alarm(
  id: id,
  time: ClockTime(hour: 7, minute: 0),
  label: label,
  repeatDays: const {1, 2, 3, 4, 5, 6, 7},
);

class _BrokenAnswers extends MorningAnswerRepository {
  _BrokenAnswers(super._db);

  @override
  Future<void> save(MorningAnswer answer) async => throw StateError('Broken');
}

class _BrokenWeights extends WeightRepository {
  _BrokenWeights(super._db);

  @override
  Future<SoundWeights> load() async => throw StateError('Broken');
}
