import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/ring_session_repository.dart';

import 'memory_database.dart';

void main() {
  late AppDatabase db;
  late AlarmRepository alarms;

  setUp(() {
    db = memoryDatabase();
    alarms = AlarmRepository(db);
  });

  tearDown(() => db.close());

  group('AlarmRepository', () {
    test('saves an alarm and reads back the same alarm', () async {
      final alarm = Alarm(
        id: 'gym',
        time: ClockTime(hour: 6, minute: 45),
        repeatDays: const {
          DateTime.monday,
          DateTime.wednesday,
          DateTime.friday,
        },
        label: 'Gym',
        enabled: false,
        genres: const {'rock', 'hip-hop'},
        gentleStart: false,
        experimentGroup: ExperimentGroup.sameSound,
      );

      await alarms.save(alarm);

      expect(await alarms.byId('gym'), alarm);
      expect(await alarms.all(), [alarm]);
    });

    test('reads back an alarm with every default value', () async {
      final alarm = Alarm(id: 'once', time: ClockTime(hour: 7, minute: 0));

      await alarms.save(alarm);

      final read = await alarms.byId('once');
      expect(read, alarm);
      expect(read!.repeatDays, isEmpty);
      expect(read.genres, isEmpty);
      expect(read.experimentGroup, isNull);
    });

    test('saving an alarm again replaces all its values', () async {
      await alarms.save(
        Alarm(
          id: 'a',
          time: ClockTime(hour: 7, minute: 0),
          repeatDays: const {DateTime.monday},
          label: 'Work',
          enabled: false,
          genres: const {'pop'},
          gentleStart: false,
          experimentGroup: ExperimentGroup.rotation,
        ),
      );
      // Every value differs from the alarm saved first.
      final changed = Alarm(id: 'a', time: ClockTime(hour: 8, minute: 30));

      await alarms.save(changed);

      expect(await alarms.all(), [changed]);
    });

    test('lists the alarms by time of day', () async {
      for (final (id, hour, minute) in [
        ('late', 22, 0),
        ('half past six', 6, 30),
        ('five past six', 6, 5),
      ]) {
        await alarms.save(
          Alarm(
            id: id,
            time: ClockTime(hour: hour, minute: minute),
          ),
        );
      }

      expect((await alarms.all()).map((alarm) => alarm.id), [
        'five past six',
        'half past six',
        'late',
      ]);
    });

    test('reads null for an alarm it does not have', () async {
      expect(await alarms.byId('missing'), isNull);
    });

    test('deletes an alarm, and keeps its ring history', () async {
      final sessions = RingSessionRepository(db);
      final session = RingSession(
        id: 's1',
        alarmId: 'a',
        scheduledFor: DateTime(2026, 10, 29, 7),
      );
      await alarms.save(Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0)));
      await alarms.save(Alarm(id: 'b', time: ClockTime(hour: 9, minute: 0)));
      await sessions.save(session);

      await alarms.delete('a');

      expect(await alarms.byId('a'), isNull);
      expect((await alarms.all()).map((alarm) => alarm.id), ['b']);
      expect(await sessions.byId('s1'), session);
    });

    test('tells a listener the alarms again after each change', () async {
      final a = Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0));
      final b = Alarm(id: 'b', time: ClockTime(hour: 6, minute: 0));
      final updates = StreamIterator(alarms.watchAll());

      expect(await updates.moveNext(), isTrue);
      expect(updates.current, isEmpty);

      await alarms.save(a);
      expect(await updates.moveNext(), isTrue);
      expect(updates.current, [a]);

      await alarms.save(b);
      expect(await updates.moveNext(), isTrue);
      expect(updates.current, [b, a]);

      await alarms.delete('a');
      expect(await updates.moveNext(), isTrue);
      expect(updates.current, [b]);

      await updates.cancel();
    });
  });
}
