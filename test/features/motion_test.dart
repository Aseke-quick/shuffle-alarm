import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/due_rings.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/design/components/alarm_track_row.dart';
import 'package:shuffle_alarm/features/alarms/alarm_editor_screen.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/alarms/tonight_mix_screen.dart';
import 'package:shuffle_alarm/features/ringing/ringing_screen.dart';
import 'package:shuffle_alarm/features/settings/bedtime_reminder_screen.dart';
import 'package:shuffle_alarm/features/settings/settings_screen.dart';
import 'package:shuffle_alarm/platform/providers.dart';

import '../data/memory_database.dart';
import '../design/design_app.dart';
import '../platform/fake_platform.dart';
import 'alarms/alarms_app.dart';
import 'settings/reminder_app.dart';

/// "All motion stops when the platform asks for less motion" (spec section
/// 1): pages, dialogs and new list items are in place in the first frame.
/// Without that ask, the same steps move, so the check can tell.
void main() {
  _ringingScreenTest();
  _mixTest();

  late AppDatabase db;

  setUp(() => db = memoryDatabase());
  // Not closed: see memoryDatabase().

  for (final lessMotion in [true, false]) {
    final moves = lessMotion ? 'nothing moves' : 'they move';
    testWidgets('pages, dialogs and new alarms: with less motion asked for '
        '$lessMotion, $moves', (tester) async {
      if (lessMotion) askForLessMotion(tester);
      useMemorySettings();
      await openWithReminder(
        tester,
        db: db,
        notifications: FakeSystemNotifications(),
        now: wednesdayEvening,
        alarms: [Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0))],
      );

      // A page above the tabs.
      await tester.tap(find.text('New alarm'));
      await _twoFrames(tester);
      await _expectFinalAtOnce(
        tester,
        find.byType(AlarmEditorScreen),
        still: lessMotion,
      );

      // A dialog.
      await tester.tap(find.byTooltip('Type the time'));
      await _twoFrames(tester);
      await _expectFinalAtOnce(
        tester,
        find.byType(TimePickerDialog),
        still: lessMotion,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // A new alarm in the list, after the page closes.
      await tester.tap(find.text('Save alarm'));
      await _twoFrames(tester);
      final added = find.ancestor(
        of: find.text('11:40 PM'),
        matching: find.byType(AlarmTrackRow),
      );
      expect(added, findsOneWidget);
      await _expectFinalAtOnce(tester, added, still: lessMotion);

      // Settings, from the gear.
      await tester.tap(find.byTooltip('Settings'));
      await _twoFrames(tester);
      await _expectFinalAtOnce(
        tester,
        find.byType(SettingsScreen),
        still: lessMotion,
      );

      // The explanation of the bedtime reminder, from its switch.
      await tester.tap(find.byType(Switch));
      await _twoFrames(tester);
      await _expectFinalAtOnce(
        tester,
        find.byType(BedtimeReminderScreen),
        still: lessMotion,
      );
    });
  }
}

/// Tonight's mix: its page, and a new order of its list.
void _mixTest() {
  for (final lessMotion in [true, false]) {
    final moves = lessMotion ? 'nothing moves' : 'they move';
    testWidgets("Tonight's mix and a new order: with less motion asked for "
        '$lessMotion, $moves', (tester) async {
      if (lessMotion) askForLessMotion(tester);
      final db = memoryDatabase();
      for (var i = 1; i <= 6; i++) {
        await SoundRepository(db).save(
          StoredSound(
            Sound(
              id: 'sound-$i',
              title: 'Song $i',
              source: SoundSource.builtin,
              genre: 'calm',
              intensity: 1,
              duration: const Duration(seconds: 20),
            ),
            audioPath: 'assets/sound-$i.wav',
          ),
        );
      }
      await AlarmRepository(db)
          .save(Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0)));
      await openAlarms(
        tester,
        db: db,
        now: wednesdayEvening,
        overrides: [
          soundPlayerProvider.overrideWithValue(
            FakeSoundPlayer(needsUnlock: false),
          ),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text("Tonight's mix · 6 sounds"));
      await _twoFrames(tester);
      await _expectFinalAtOnce(
        tester,
        find.byType(TonightMixScreen),
        still: lessMotion,
      );

      await tester.tap(find.text('Reshuffle'));
      // Up to the frame with the new order, which the database gives.
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 1));
        if (tester.hasRunningAnimations) break;
      }
      expect(tester.hasRunningAnimations, !lessMotion);
      await tester.pumpAndSettle();
    });
  }
}

/// The ringing screen with less motion asked for, on its own: without that
/// ask its record never stops, so the same steps could not end.
void _ringingScreenTest() {
  testWidgets('the ringing screen and its sounds: with less motion asked for, '
      'nothing moves', (tester) async {
    askForLessMotion(tester);
    final db = memoryDatabase();
    final scheduler = FakeAlarmScheduler();
    final player = FakeSoundPlayer(needsUnlock: false);
    var now = DateTime(2026, 11, 12, 7);
    for (final (id, intensity) in [('chime', 1), ('bell', 2)]) {
      await SoundRepository(db).save(
        StoredSound(
          Sound(
            id: id,
            title: id,
            source: SoundSource.builtin,
            genre: 'calm',
            intensity: intensity,
            duration: const Duration(seconds: 20),
          ),
          audioPath: 'assets/library/calm/$id.wav',
        ),
      );
    }
    final alarm = Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0));
    await AlarmRepository(db).save(alarm);
    await openAlarms(
      tester,
      db: db,
      now: wednesdayEvening,
      overrides: [
        alarmSchedulerProvider.overrideWithValue(scheduler),
        soundPlayerProvider.overrideWithValue(player),
        screenWakeLockProvider.overrideWithValue(FakeScreenWakeLock()),
        nowProvider.overrideWithValue(() => now),
      ],
    );

    scheduler.ring(DueRing(alarm, scheduledFor: now));
    while (find.byType(RingingScreen).evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await _twoFrames(tester);
    await _expectFinalAtOnce(tester, find.byType(RingingScreen), still: true);
    expect(find.text('chime'), findsOneWidget);

    // The next sound: its title takes the place of the one before at once.
    now = now.add(const Duration(seconds: 20));
    player.finishClip();
    while (find.text('bell').evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump();
    expect(find.text('chime'), findsNothing);
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.hasRunningAnimations, isFalse);
  });
}

/// The frame of a change, and one 16 ms later: a page that comes in with a
/// transition spends its first frame offstage.
Future<void> _twoFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

/// Checks that [finder] already shows as it will once every animation has
/// ended, if [still]: in the same place, at the same size, and fully
/// opaque. If [still] is false, checks that it does not.
Future<void> _expectFinalAtOnce(
  WidgetTester tester,
  Finder finder, {
  required bool still,
}) async {
  final rect = tester.getRect(finder);
  final opacity = _opacity(tester, finder);
  await tester.pumpAndSettle();
  final atOnce = rect == tester.getRect(finder) && opacity == 1;
  expect(atOnce, still, reason: '$finder: $rect at $opacity');
}

/// How opaque [finder] shows, from every fade and opacity around it.
double _opacity(WidgetTester tester, Finder finder) {
  var opacity = 1.0;
  for (final widget in tester.widgetList(
    find.ancestor(of: finder, matching: find.byWidgetPredicate((_) => true)),
  )) {
    opacity *= switch (widget) {
      FadeTransition(:final opacity) => opacity.value,
      Opacity(:final opacity) => opacity,
      _ => 1,
    };
  }
  return opacity;
}
