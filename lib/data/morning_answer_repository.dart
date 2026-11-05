import 'package:drift/drift.dart';

import 'package:shuffle_alarm/core/models/morning_answer.dart';
import 'package:shuffle_alarm/data/database.dart';

/// Saves and reads the answers of the Morning card (task 2.5b), which Insights
/// reads (task 2.8).
///
/// Times come back in local time, as the same moment they were saved.
class MorningAnswerRepository {
  MorningAnswerRepository(this._db);

  final AppDatabase _db;

  /// Every answer, the oldest first.
  Future<List<MorningAnswer>> all() async {
    final rows =
        await (_db.select(_db.morningAnswers)..orderBy([
              (answer) => OrderingTerm(expression: answer.answeredAt),
              (answer) => OrderingTerm(expression: answer.sessionId),
            ]))
            .get();
    return [
      for (final row in rows)
        MorningAnswer(
          sessionId: row.sessionId,
          soundId: row.soundId,
          answeredAt: row.answeredAt,
        ),
    ];
  }

  /// Saves [answer], in the place of the answer its session had. Throws if its
  /// session is not in the log.
  Future<void> save(MorningAnswer answer) => _db
      .into(_db.morningAnswers)
      .insertOnConflictUpdate(
        MorningAnswersCompanion.insert(
          sessionId: answer.sessionId,
          soundId: Value(answer.soundId),
          answeredAt: answer.answeredAt,
        ),
      );
}
