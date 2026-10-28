import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/ring_session_repository.dart';

import 'memory_database.dart';

void main() {
  late AppDatabase db;
  late RingSessionRepository sessions;

  setUp(() {
    db = memoryDatabase();
    sessions = RingSessionRepository(db);
  });

  tearDown(() => db.close());

  group('RingSessionRepository', () {
    test(
      'saves a session with its events and reads back the same session',
      () async {
        final session = _morning();

        await sessions.save(session);

        expect(await sessions.byId('tuesday'), session);
        expect(await sessions.all(), [session]);
      },
    );

    test('reads back a session without events', () async {
      final session = RingSession(
        id: 'just started',
        alarmId: 'work',
        scheduledFor: DateTime(2026, 10, 29, 7),
      );

      await sessions.save(session);

      expect(await sessions.byId('just started'), session);
    });

    test('keeps the times to the microsecond', () async {
      final session = RingSession(
        id: 's1',
        alarmId: 'work',
        scheduledFor: DateTime(2026, 10, 29, 7, 0, 0, 0, 1),
        events: [
          RingEvent(
            soundId: 'sunrise',
            startedAt: DateTime(2026, 10, 29, 7, 0, 0, 3, 7),
            endedAt: DateTime(2026, 10, 29, 7, 0, 28, 999, 999),
            action: RingAction.stop,
          ),
        ],
      );

      await sessions.save(session);

      expect(await sessions.byId('s1'), session);
    });

    test(
      'keeps the order the sounds played, also when the clock jumped back',
      () async {
        // The device clock went back 1 hour (a time-zone change, say) while
        // the second sound played.
        final session = RingSession(
          id: 's1',
          alarmId: 'work',
          scheduledFor: DateTime(2026, 10, 29, 7),
          events: [
            RingEvent(
              soundId: 'first',
              startedAt: DateTime(2026, 10, 29, 7),
              endedAt: DateTime(2026, 10, 29, 7, 0, 29),
              action: RingAction.timeout,
            ),
            RingEvent(
              soundId: 'second',
              startedAt: DateTime(2026, 10, 29, 7, 0, 29),
              endedAt: DateTime(2026, 10, 29, 6, 0, 58),
              action: RingAction.timeout,
            ),
            RingEvent(
              soundId: 'third',
              startedAt: DateTime(2026, 10, 29, 6, 0, 58),
              endedAt: DateTime(2026, 10, 29, 6, 1, 3),
              action: RingAction.stop,
            ),
          ],
        );

        await sessions.save(session);

        final read = await sessions.byId('s1');
        expect(read!.events.map((event) => event.soundId), [
          'first',
          'second',
          'third',
        ]);
        expect(read, session);
      },
    );

    test('saving a session again replaces its values and events', () async {
      await sessions.save(_morning());
      final fewer = RingSession(
        id: 'tuesday',
        alarmId: 'other alarm',
        scheduledFor: DateTime(2026, 10, 27, 7, 30),
        events: [_morning().events.last],
      );

      await sessions.save(fewer);

      expect(await sessions.all(), [fewer]);
    });

    test(
      'lists the sessions by the time their alarm was set to ring',
      () async {
        for (final (id, day) in [
          ('thursday', 29),
          ('monday', 26),
          ('wed', 28),
        ]) {
          await sessions.save(
            RingSession(
              id: id,
              alarmId: 'work',
              scheduledFor: DateTime(2026, 10, day, 7),
            ),
          );
        }

        expect((await sessions.all()).map((session) => session.id), [
          'monday',
          'wed',
          'thursday',
        ]);
      },
    );

    test(
      'gives a time saved in UTC back as the same moment, in local time',
      () async {
        final utc = DateTime.utc(2026, 10, 29, 2, 0, 0, 0, 5);

        await sessions.save(
          RingSession(id: 's1', alarmId: 'work', scheduledFor: utc),
        );

        final read = (await sessions.byId('s1'))!.scheduledFor;
        expect(read.isAtSameMomentAs(utc), isTrue);
        expect(read.isUtc, isFalse);
        expect(read, utc.toLocal());
      },
    );

    test('reads null for a session it does not have', () async {
      expect(await sessions.byId('missing'), isNull);
    });
  });
}

/// A morning with a sound that ran out, a Snooze and a Stop, with times that
/// have milliseconds and microseconds.
RingSession _morning() => RingSession(
  id: 'tuesday',
  alarmId: 'work',
  scheduledFor: DateTime(2026, 10, 28, 7),
  events: [
    RingEvent(
      soundId: 'sunrise',
      startedAt: DateTime(2026, 10, 28, 7, 0, 0, 12, 345),
      endedAt: DateTime(2026, 10, 28, 7, 0, 29, 12, 345),
      action: RingAction.timeout,
    ),
    RingEvent(
      soundId: 'mom',
      startedAt: DateTime(2026, 10, 28, 7, 0, 29, 12, 345),
      endedAt: DateTime(2026, 10, 28, 7, 0, 40, 500),
      action: RingAction.snooze,
    ),
    RingEvent(
      soundId: 'rock-1',
      startedAt: DateTime(2026, 10, 28, 7, 5, 40, 501),
      endedAt: DateTime(2026, 10, 28, 7, 5, 52),
      action: RingAction.stop,
    ),
  ],
);
