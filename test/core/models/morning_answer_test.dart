import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/models/morning_answer.dart';

void main() {
  group('MorningAnswer', () {
    test('keeps the sound that woke the user', () {
      final answer = _answer();

      expect(answer.sessionId, 's1');
      expect(answer.soundId, 'pop-01');
      expect(answer.answeredAt, DateTime(2026, 11, 3, 7, 5));
    });

    test('without a sound means "Not sure"', () {
      final answer = MorningAnswer(
        sessionId: 's1',
        answeredAt: DateTime(2026, 11, 3, 7, 5),
      );

      expect(answer.soundId, isNull);
    });

    test('equals an answer with the same values', () {
      expect(_answer(), _answer());
      expect(_answer().hashCode, _answer().hashCode);
    });

    test('differs from an answer with one other value', () {
      final answer = _answer();

      for (final other in [
        _answer(sessionId: 's2'),
        _answer(soundId: 'pop-02'),
        MorningAnswer(sessionId: 's1', answeredAt: DateTime(2026, 11, 3, 7, 5)),
        _answer(answeredAt: DateTime(2026, 11, 3, 7, 6)),
      ]) {
        expect(other, isNot(answer));
      }
    });

    test('says what it holds', () {
      expect(_answer().toString(), contains('pop-01'));
    });
  });
}

MorningAnswer _answer({
  String sessionId = 's1',
  String soundId = 'pop-01',
  DateTime? answeredAt,
}) => MorningAnswer(
  sessionId: sessionId,
  soundId: soundId,
  answeredAt: answeredAt ?? DateTime(2026, 11, 3, 7, 5),
);
