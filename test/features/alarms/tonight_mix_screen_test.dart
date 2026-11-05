import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/clip_rule.dart';
import 'package:shuffle_alarm/core/due_rings.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/core/ring_plan.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/data/ring_plan_repository.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/design/components/mix_track_row.dart';
import 'package:shuffle_alarm/design/components/record.dart';
import 'package:shuffle_alarm/design/components/status_view.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/alarms/tonight_mix_screen.dart';
import 'package:shuffle_alarm/features/ringing/ringing_screen.dart';
import 'package:shuffle_alarm/platform/providers.dart';
import 'package:shuffle_alarm/router.dart';

import '../../data/memory_database.dart';
import '../../design/design_app.dart';
import '../../platform/fake_platform.dart';
import 'alarms_app.dart';

void main() {
  late AppDatabase db;
  late FakeAlarmScheduler scheduler;
  late FakeSoundPlayer player;
  late FakeScreenWakeLock wakeLock;
  late DateTime now;

  setUp(() {
    db = memoryDatabase();
    scheduler = FakeAlarmScheduler();
    player = FakeSoundPlayer();
    wakeLock = FakeScreenWakeLock();
    now = wednesdayEvening;
  });
  // Not closed: see memoryDatabase().

  List<Override> web() => [
    alarmSchedulerProvider.overrideWithValue(scheduler),
    soundPlayerProvider.overrideWithValue(player),
    screenWakeLockProvider.overrideWithValue(wakeLock),
    nowProvider.overrideWithValue(() => now),
    noMorningCard,
  ];

  /// The app on the Alarms tab, with [count] sounds of different lengths and
  /// an alarm at 07:00 tomorrow, without a gentle start unless told otherwise.
  /// Less motion is asked for, so `pumpAndSettle` ends on the ringing screen.
  Future<TestClock> open(
    WidgetTester tester, {
    int count = 4,
    bool gentleStart = false,
    List<Override> overrides = const [],
  }) async {
    askForLessMotion(tester);
    for (var i = 1; i <= count; i++) {
      await SoundRepository(db).save(
        StoredSound(
          Sound(
            id: 'sound-$i',
            title: 'Song $i',
            source: SoundSource.builtin,
            genre: 'lo-fi',
            intensity: (i - 1) % 3 + 1,
            duration: Duration(seconds: 15 + i),
          ),
          audioPath: 'assets/sound-$i.wav',
        ),
      );
    }
    await AlarmRepository(db).save(
      Alarm(
        id: 'a',
        time: ClockTime(hour: 7, minute: 0),
        repeatDays: const {1, 2, 3, 4, 5, 6, 7},
        label: 'Gym',
        gentleStart: gentleStart,
      ),
    );
    final clock = await openAlarms(
      tester,
      db: db,
      now: now,
      overrides: [...web(), ...overrides],
    );
    await tester.pumpAndSettle();
    return clock;
  }

  Future<void> openMix(WidgetTester tester) async {
    await tester.tap(find.text("Tonight's mix · 4 sounds"));
    await tester.pumpAndSettle();
  }

  /// The titles of the rows of the mix, from the top.
  List<String> rows(WidgetTester tester) => [
    for (final row in tester.widgetList<MixTrackRow>(find.byType(MixTrackRow)))
      row.title,
  ];

  final seven = DateTime(2026, 11, 12, 7);

  /// The titles of the stored plan's first round, for the ring at 07:00.
  Future<List<String>> plannedTitles() async {
    final plan = (await RingPlanRepository(db).forRing('a', seven))!;
    final seen = <String>{};
    return [
      for (final id in plan.soundIds)
        if (!plan.notTonight.contains(id) && seen.add(id))
          'Song ${id.substring('sound-'.length)}',
    ];
  }

  Future<void> tapPreview(WidgetTester tester, String title) async {
    await tester.tap(find.byTooltip('Preview $title'));
    await tester.pumpAndSettle();
  }

  group('The record of the Alarms tab', () {
    testWidgets('shows one segment per sound, and says how many', (
      tester,
    ) async {
      await open(tester);

      final record = tester.widget<RecordArt>(
        find.descendant(
          of: find.byType(RecordHero),
          matching: find.byType(RecordArt),
        ),
      );
      expect(record.segments, hasLength(4));
      expect(find.text("Tonight's mix · 4 sounds"), findsOneWidget);
    });

    testWidgets('shows the lengths of the clips, in play order', (
      tester,
    ) async {
      await open(tester);
      final titles = await plannedTitles();

      final record = tester.widget<RecordArt>(
        find.descendant(
          of: find.byType(RecordHero),
          matching: find.byType(RecordArt),
        ),
      );
      expect(
        [for (final segment in record.segments) segment.length.inSeconds],
        // Song 1 is 16 s long, song 4 is 19 s long.
        [for (final title in titles) 15 + int.parse(title.split(' ').last)],
      );
    });

    testWidgets('opens the mix with a tap on the record', (tester) async {
      await open(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(RecordHero),
          matching: find.byType(RecordArt),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TonightMixScreen), findsOneWidget);
    });

    testWidgets('tells a screen reader about the mix', (tester) async {
      final semantics = tester.ensureSemantics();
      await open(tester);

      expect(
        find.bySemanticsLabel(
          "Next alarm 7:00 AM, in 7 h 20 min. Tonight's mix, 4 sounds",
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('has no mix to open without an alarm that is on', (
      tester,
    ) async {
      await openAlarms(tester, db: db, now: now, overrides: web());

      expect(find.textContaining("Tonight's mix"), findsNothing);
      final record = find.descendant(
        of: find.byType(RecordHero),
        matching: find.byType(RecordArt),
      );
      expect(tester.widget<RecordArt>(record).segments, isEmpty);
      await tester.tap(record);
      await tester.pumpAndSettle();
      expect(find.byType(TonightMixScreen), findsNothing);
    });

    testWidgets('has no mix to open when no plan can be made', (tester) async {
      await open(
        tester,
        overrides: [ringPlanRepositoryProvider.overrideWithValue(_NoPlans(db))],
      );

      expect(find.textContaining("Tonight's mix"), findsNothing);
      expect(find.text('7:00 AM'), findsWidgets);
    });

    testWidgets('changes with a Reshuffle', (tester) async {
      await open(tester);
      final before = await plannedTitles();
      await openMix(tester);

      await tester.tap(find.text('Reshuffle'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(await plannedTitles(), isNot(before));
      final record = tester.widget<RecordArt>(
        find.descendant(
          of: find.byType(RecordHero),
          matching: find.byType(RecordArt),
        ),
      );
      expect(
        [for (final segment in record.segments) segment.length.inSeconds],
        [
          for (final title in await plannedTitles())
            15 + int.parse(title.split(' ').last),
        ],
      );
    });
  });

  group("The Tonight's mix page", () {
    testWidgets('lists every sound once, in play order', (tester) async {
      await open(tester);
      final titles = await plannedTitles();

      await openMix(tester);

      expect(rows(tester), titles);
      expect(rows(tester).toSet(), hasLength(4));
    });

    testWidgets('says when each sound starts, its genre and its strength', (
      tester,
    ) async {
      await open(tester, gentleStart: true, count: 3);
      await tester.tap(find.text("Tonight's mix · 3 sounds"));
      await tester.pumpAndSettle();

      // With a gentle start: gentle, medium and strong.
      expect(find.text('0:00 · Lo-fi · Gentle'), findsOneWidget);
      expect(find.text('0:16 · Lo-fi · Medium'), findsOneWidget);
      expect(find.text('0:33 · Lo-fi · Strong'), findsOneWidget);
    });

    testWidgets('says which alarm it is for', (tester) async {
      await open(tester);

      await openMix(tester);

      expect(find.widgetWithText(AppBar, "Tonight's mix"), findsOneWidget);
      expect(find.text('Gym · Every day'), findsOneWidget);
      expect(find.text('in 7 h 20 min'), findsOneWidget);
      expect(find.text('7:00 AM'), findsOneWidget);
    });

    testWidgets('says what comes after its first round', (tester) async {
      await open(tester);

      await openMix(tester);

      expect(
        find.text('Then again in a new order, for 10 min at most.'),
        findsOneWidget,
      );
    });

    testWidgets('Back returns to the Alarms tab', (tester) async {
      await open(tester);
      await openMix(tester);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(TonightMixScreen), findsNothing);
      expect(find.byType(RecordHero), findsOneWidget);
    });

    testWidgets('its address opens with no alarm too, and says so', (
      tester,
    ) async {
      await openAlarms(tester, db: db, now: now, overrides: web());

      final context = tester.element(find.byType(RecordHero));
      unawaited(context.push<void>(TonightMixScreen.path));
      await tester.pumpAndSettle();

      expect(find.byType(StatusView), findsOneWidget);
      expect(find.text('No alarm set'), findsOneWidget);
    });

    testWidgets('makes way for a ring, and is back after Stop', (tester) async {
      await open(tester);
      await openMix(tester);

      now = seven;
      scheduler.ring(
        DueRing((await AlarmRepository(db).byId('a'))!, scheduledFor: seven),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RingingScreen), findsOneWidget);

      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      expect(find.byType(RingingScreen), findsNothing);
      expect(find.byType(TonightMixScreen), findsOneWidget);
    });
  });

  group('Reshuffle', () {
    testWidgets('makes a new order, which is stored', (tester) async {
      await open(tester);
      await openMix(tester);
      final before = rows(tester);

      await tester.tap(find.text('Reshuffle'));
      await tester.pumpAndSettle();

      expect(rows(tester), isNot(before));
      expect(rows(tester), await plannedTitles());
    });

    testWidgets('says so when the sounds allow one order only', (tester) async {
      await open(tester, count: 3, gentleStart: true);
      await tester.tap(find.text("Tonight's mix · 3 sounds"));
      await tester.pumpAndSettle();
      final before = rows(tester);

      await tester.tap(find.text('Reshuffle'));
      await tester.pumpAndSettle();

      expect(rows(tester), before);
      expect(
        find.text('These sounds have one order only: gentle to strong.'),
        findsOneWidget,
      );
    });

    testWidgets('says so when it cannot be saved, and changes nothing', (
      tester,
    ) async {
      await open(
        tester,
        overrides: [ringPlanRepositoryProvider.overrideWithValue(_NoSaves(db))],
      );
      await openMix(tester);
      final before = rows(tester);

      await tester.tap(find.text('Reshuffle'));
      await tester.pumpAndSettle();

      expect(rows(tester), before);
      expect(find.textContaining('Could not save the mix'), findsOneWidget);
    });

    testWidgets('is off with one sound', (tester) async {
      await open(tester, count: 1);
      await tester.tap(find.text("Tonight's mix · 1 sound"));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FilledButton>(
              find.ancestor(
                of: find.text('Reshuffle'),
                matching: find.bySubtype<FilledButton>(),
              ),
            )
            .onPressed,
        isNull,
      );
    });
  });

  group('Not tonight', () {
    testWidgets('moves a sound out of the order, and stores it', (
      tester,
    ) async {
      await open(tester);
      await openMix(tester);
      final before = rows(tester);
      final skipped = before[1];

      await tester.tap(find.bySemanticsLabel('Not tonight: $skipped'));
      await tester.pumpAndSettle();

      // Three in play order, then the one left out.
      expect(rows(tester), [
        for (final title in before)
          if (title != skipped) title,
        skipped,
      ]);
      expect(find.text('NOT TONIGHT'), findsOneWidget);
      expect(find.text('Bring back'), findsOneWidget);
      expect(await plannedTitles(), hasLength(3));
    });

    testWidgets('takes the sound off the record too', (tester) async {
      await open(tester);
      await openMix(tester);

      await tester.tap(find.text('Not tonight').first);
      await tester.pumpAndSettle();

      expect(
        tester.widget<RecordArt>(find.byType(RecordArt).first).segments,
        hasLength(3),
      );
    });

    testWidgets('Bring back puts it in its place again', (tester) async {
      await open(tester);
      await openMix(tester);
      final before = rows(tester);
      final skipped = before[1];
      await tester.tap(find.bySemanticsLabel('Not tonight: $skipped'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Bring back: $skipped'));
      await tester.pumpAndSettle();

      expect(rows(tester), before);
      expect(find.text('NOT TONIGHT'), findsNothing);
      expect(await plannedTitles(), before);
    });

    testWidgets('keeps one sound: its button is off then, and says why', (
      tester,
    ) async {
      await open(tester, count: 2);
      await tester.tap(find.text("Tonight's mix · 2 sounds"));
      await tester.pumpAndSettle();
      final before = rows(tester);

      await tester.tap(find.bySemanticsLabel('Not tonight: ${before.first}'));
      await tester.pumpAndSettle();

      final last = tester.widget<MixTrackRow>(find.byType(MixTrackRow).first);
      expect(last.title, before.last);
      expect(last.onAction, isNull);
      expect(
        find.text('One sound stays, so the alarm has something to play.'),
        findsOneWidget,
      );
    });

    testWidgets('says so when it cannot be saved, and changes nothing', (
      tester,
    ) async {
      await open(
        tester,
        overrides: [ringPlanRepositoryProvider.overrideWithValue(_NoSaves(db))],
      );
      await openMix(tester);
      final before = rows(tester);

      await tester.tap(find.text('Not tonight').first);
      await tester.pumpAndSettle();

      expect(rows(tester), before);
      expect(find.textContaining('Could not save the mix'), findsOneWidget);
    });

    testWidgets('stops the preview of that sound', (tester) async {
      await open(tester);
      await openMix(tester);
      final first = rows(tester).first;
      await tapPreview(tester, first);
      expect(find.byIcon(Icons.stop), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Not tonight: $first'));
      await tester.pumpAndSettle();

      expect(player.stopCalls, 1);
      expect(find.byIcon(Icons.stop), findsNothing);
    });
  });

  group('A preview', () {
    testWidgets('plays the clip of a sound, at its volume in the ring', (
      tester,
    ) async {
      await open(tester, gentleStart: true, count: 3);
      await tester.tap(find.text("Tonight's mix · 3 sounds"));
      await tester.pumpAndSettle();

      await tapPreview(tester, 'Song 2');

      expect(player.plays.single, (
        asset: 'assets/sound-2.wav',
        from: Duration.zero,
        to: const Duration(seconds: 17),
        volume: 0.7,
      ));
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(
        tester.getSize(find.byTooltip('Stop preview')).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('of a long song stays within the clip rule', (tester) async {
      await SoundRepository(db).save(
        StoredSound(
          Sound(
            id: 'long',
            title: 'Long',
            source: SoundSource.user,
            genre: 'pop',
            intensity: 1,
            duration: const Duration(minutes: 3),
            clipStart: const Duration(minutes: 1),
          ),
          audioPath: 'sounds/long.mp3',
        ),
      );
      await open(tester);
      await tester.tap(find.text("Tonight's mix · 5 sounds"));
      await tester.pumpAndSettle();

      await tapPreview(tester, 'Long');

      final play = player.plays.single;
      expect(play.from, const Duration(minutes: 1));
      expect(play.to - play.from, ClipWindow.maxLength);
    });

    testWidgets('goes back to Play when the clip ends', (tester) async {
      await open(tester);
      await openMix(tester);
      await tapPreview(tester, rows(tester).first);

      player.finishClip();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.stop), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsNWidgets(4));
    });

    testWidgets('stops with a second tap', (tester) async {
      await open(tester);
      await openMix(tester);
      await tapPreview(tester, rows(tester).first);

      await tester.tap(find.byTooltip('Stop preview'));
      await tester.pumpAndSettle();

      expect(player.stopCalls, 1);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('stops when the page closes', (tester) async {
      await open(tester);
      await openMix(tester);
      await tapPreview(tester, rows(tester).first);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(player.stopCalls, 1);
    });

    testWidgets('stops for a Reshuffle', (tester) async {
      await open(tester);
      await openMix(tester);
      await tapPreview(tester, rows(tester).first);

      await tester.tap(find.text('Reshuffle'));
      await tester.pumpAndSettle();

      expect(player.stopCalls, 1);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('arms the alarms before "Arm alarms": the banner says so', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('Arm alarms'), findsOneWidget);
      await openMix(tester);

      await tapPreview(tester, rows(tester).first);
      expect(player.unlockCalls, 1);
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Arm alarms'), findsNothing);
      expect(find.text('Keep this tab open'), findsOneWidget);
      expect(wakeLock.held, isTrue);
    });

    testWidgets('says so when the browser blocks the sound', (tester) async {
      player
        ..unlocks = false
        ..blocked = true;
      await open(tester);
      await openMix(tester);

      await tapPreview(tester, rows(tester).first);

      expect(
        find.text('The browser did not let the sound play. Try again.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('says so when its sound cannot be read', (tester) async {
      await open(tester);
      await openMix(tester);
      player.broken.addAll([
        for (var i = 1; i <= 4; i++) 'assets/sound-$i.wav',
      ]);

      await tapPreview(tester, rows(tester).first);

      expect(find.text('Could not play this sound.'), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('has no button where the platform plays no sound', (
      tester,
    ) async {
      player = FakeSoundPlayer(playsSounds: false, needsUnlock: false);
      await open(tester);
      await openMix(tester);

      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(rows(tester), hasLength(4));
    });

    testWidgets('ends when a ring starts, and the ring plays', (tester) async {
      await open(tester);
      await openMix(tester);
      await tapPreview(tester, rows(tester).first);
      final titles = await plannedTitles();

      now = seven;
      scheduler.ring(
        DueRing((await AlarmRepository(db).byId('a'))!, scheduledFor: seven),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RingingScreen), findsOneWidget);
      expect(player.plays, hasLength(2));
      expect(
        player.plays.last.asset,
        'assets/sound-${titles.first.split(' ').last}.wav',
      );
      // Nothing stopped the sound of the ring.
      expect(player.stopCalls, 0);

      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      expect(find.byType(TonightMixScreen), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);
    });
  });

  testWidgets('the address keeps to the router: a ring takes it over', (
    tester,
  ) async {
    await open(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(RecordHero)),
    );
    final router = container.read(routerProvider)..go(TonightMixScreen.path);
    await tester.pumpAndSettle();
    expect(find.byType(TonightMixScreen), findsOneWidget);

    now = seven;
    scheduler.ring(
      DueRing((await AlarmRepository(db).byId('a'))!, scheduledFor: seven),
    );
    await tester.pumpAndSettle();
    router.go(TonightMixScreen.path);
    await tester.pumpAndSettle();

    expect(find.byType(RingingScreen), findsOneWidget);
  });
}

/// A store of plans that cannot make one.
class _NoPlans extends RingPlanRepository {
  _NoPlans(super._db);

  @override
  Future<RingPlan> settle(
    String alarmId, {
    required DateTime now,
    required RingPlan Function(List<RingPlan> stored) choose,
  }) async => throw StateError('Broken');
}

/// A store of plans that makes them, but cannot save a change.
class _NoSaves extends RingPlanRepository {
  _NoSaves(super._db);

  var _settling = false;

  @override
  Future<void> save(RingPlan plan) async {
    if (!_settling) throw StateError('Broken');
    await super.save(plan);
  }

  @override
  Future<RingPlan> settle(
    String alarmId, {
    required DateTime now,
    required RingPlan Function(List<RingPlan> stored) choose,
  }) async {
    _settling = true;
    try {
      return await super.settle(alarmId, now: now, choose: choose);
    } finally {
      _settling = false;
    }
  }
}
