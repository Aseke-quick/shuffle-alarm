/// Checks that the database works in a browser, opened the way the app opens
/// it (docs/DECISIONS.md, task 2.1).
///
/// Run it in Chrome:
///
/// ```sh
/// flutter run -d chrome -t tool/web_database_check.dart
/// ```
///
/// Or build it like the site, and serve the parent of the output folder:
///
/// ```sh
/// flutter build web --release -t tool/web_database_check.dart \
///   --base-href /shuffle-alarm-web/ -o <folder>/shuffle-alarm-web
/// ```
///
/// It saves an alarm, a sound, a weight and a ring session through the
/// repositories and reads each one back. It also says whether it found what
/// the visit before saved: reload the page to see that the data stays. It
/// uses a database of its own, so it never touches the app's data. Every line
/// goes to the browser console too. Run it after changing drift, sqlite3 or
/// the files in `web/`.
library;

import 'package:flutter/widgets.dart';

import 'package:shuffle_alarm/core/adaptive_weights.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/ring_session_repository.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/data/weight_repository.dart';

Future<void> main() async {
  final lines = <String>[];
  var failures = 0;
  void log(String line) {
    lines.add(line);
    debugPrint(line);
  }

  void check(String what, Object? read, Object saved) {
    if (read == saved) {
      log('OK: $what read back the same.');
    } else {
      failures++;
      log('FAIL: $what read back $read, saved $saved.');
    }
  }

  runApp(const _Report(['Checking the database...']));
  try {
    final db = AppDatabase.onDevice(name: 'shuffle_alarm_web_check');
    final alarms = AlarmRepository(db);
    final sounds = SoundRepository(db);
    final weights = WeightRepository(db);
    final sessions = RingSessionRepository(db);

    final earlier = await alarms.byId('check');
    log(
      earlier == null
          ? 'No data from a visit before: a first visit, or the browser '
                'cleared it.'
          : 'Found the data of the visit before, saved at ${earlier.label}.',
    );

    final now = DateTime.now();
    final alarm = Alarm(
      id: 'check',
      time: ClockTime(hour: 7, minute: 30),
      repeatDays: const {DateTime.monday, DateTime.friday},
      label: now.toIso8601String(),
      genres: const {'pop', 'jazz'},
      experimentGroup: ExperimentGroup.rotation,
    );
    await alarms.save(alarm);
    check('The alarm', await alarms.byId(alarm.id), alarm);

    final sound = StoredSound(
      Sound(
        id: 'check',
        title: 'Check',
        source: SoundSource.voice,
        genre: 'voice',
        intensity: 2,
        duration: const Duration(seconds: 12, microseconds: 345),
        clipStart: const Duration(milliseconds: 1500),
      ),
      audioPath: 'sounds/check.webm',
    );
    await sounds.save(sound);
    check('The sound', await sounds.byId(sound.sound.id), sound);

    final learned = const SoundWeights.start().afterSnooze('check');
    await weights.save(learned, soundId: 'check');
    check('The weights', await weights.load(), learned);

    final session = RingSession(
      id: 'check',
      alarmId: alarm.id,
      scheduledFor: now,
      events: [
        RingEvent(
          soundId: sound.sound.id,
          startedAt: now,
          endedAt: now.add(const Duration(seconds: 12)),
          action: RingAction.snooze,
        ),
      ],
    );
    await sessions.save(session);
    check('The ring session', await sessions.byId(session.id), session);

    await db.close();
    log(
      failures == 0
          ? 'PASS: the database works here.'
          : 'FAIL: $failures of 4 checks failed.',
    );
  } on Object catch (error, stackTrace) {
    log('FAIL: $error\n$stackTrace');
  }
  runApp(_Report(lines));
}

/// The lines of the check, as plain text.
class _Report extends StatelessWidget {
  const _Report(this.lines);

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFFFFFFFF),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            lines.join('\n'),
            style: const TextStyle(color: Color(0xFF000000), fontSize: 16),
          ),
        ),
      ),
    );
  }
}
