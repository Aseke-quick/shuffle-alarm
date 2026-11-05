import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/models/morning_answer.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/morning_answer_repository.dart';
import 'package:shuffle_alarm/data/ring_session_repository.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';

import 'memory_database.dart';

void main() {
  late AppDatabase db;
  late MorningAnswerRepository answers;
  late RingSessionRepository sessions;
  final seven = DateTime(2026, 11, 3, 7);
  final at = DateTime(2026, 11, 3, 7, 5);

  setUp(() async {
    db = memoryDatabase();
    answers = MorningAnswerRepository(db);
    sessions = RingSessionRepository(db);
    await sessions.save(
      RingSession(id: 'morning', alarmId: 'a', scheduledFor: seven),
    );
  });

  tearDown(() => db.close());

  group('MorningAnswerRepository', () {
    test('has no answers at first', () async {
      expect(await answers.all(), isEmpty);
    });

    test('keeps the sound that woke the user', () async {
      final answer = MorningAnswer(
        sessionId: 'morning',
        soundId: 'chime',
        answeredAt: at,
      );

      await answers.save(answer);

      expect(await answers.all(), [answer]);
    });

    test('keeps "Not sure": an answer without a sound', () async {
      final answer = MorningAnswer(sessionId: 'morning', answeredAt: at);

      await answers.save(answer);

      final saved = (await answers.all()).single;
      expect(saved, answer);
      expect(saved.soundId, isNull);
    });

    test('gives the moment back to the microsecond, in local time', () async {
      final exact = DateTime.utc(2026, 11, 3, 7, 5, 1, 2, 3);

      await answers.save(
        MorningAnswer(sessionId: 'morning', answeredAt: exact),
      );

      final saved = (await answers.all()).single.answeredAt;
      expect(saved.isAtSameMomentAs(exact), isTrue);
      expect(saved.isUtc, isFalse);
    });

    test('has one answer per session: a new one takes its place', () async {
      await answers.save(
        MorningAnswer(sessionId: 'morning', soundId: 'chime', answeredAt: at),
      );
      final later = MorningAnswer(sessionId: 'morning', answeredAt: seven);

      await answers.save(later);

      expect(await answers.all(), [later]);
    });

    test('lists the answers from the oldest on', () async {
      await sessions.save(
        RingSession(id: 'next', alarmId: 'a', scheduledFor: seven),
      );
      final first = MorningAnswer(sessionId: 'next', answeredAt: seven);
      final second = MorningAnswer(sessionId: 'morning', answeredAt: at);

      await answers.save(second);
      await answers.save(first);

      expect(await answers.all(), [first, second]);
    });

    test('fails for a session that is not in the log', () async {
      await expectLater(
        answers.save(MorningAnswer(sessionId: 'nothing', answeredAt: at)),
        throwsA(anything),
      );
      expect(await answers.all(), isEmpty);
    });

    test('an answer goes with its session', () async {
      await answers.save(MorningAnswer(sessionId: 'morning', answeredAt: at));

      await db.delete(db.ringSessions).go();

      expect(await answers.all(), isEmpty);
    });

    test('an answer stays when its sound is deleted', () async {
      final sounds = SoundRepository(db);
      await sounds.save(
        StoredSound(
          Sound(
            id: 'chime',
            title: 'Chime',
            source: SoundSource.user,
            genre: 'mine',
            intensity: 1,
            duration: const Duration(seconds: 20),
          ),
          audioPath: 'sounds/chime.mp3',
        ),
      );
      final answer = MorningAnswer(
        sessionId: 'morning',
        soundId: 'chime',
        answeredAt: at,
      );
      await answers.save(answer);

      await sounds.delete('chime');

      expect(await answers.all(), [answer]);
    });

    test('saving the session again leaves its answer', () async {
      final answer = MorningAnswer(sessionId: 'morning', answeredAt: at);
      await answers.save(answer);

      await sessions.save(
        RingSession(id: 'morning', alarmId: 'a', scheduledFor: seven),
      );

      expect(await answers.all(), [answer]);
    });
  });
}
