import 'package:meta/meta.dart';

/// The answer to "Which sound woke you?" on the Morning card of a ring
/// session (task 2.5b).
@immutable
class MorningAnswer {
  const MorningAnswer({
    required this.sessionId,
    required this.answeredAt,
    this.soundId,
  });

  /// The `RingSession.id` of the morning it is about.
  final String sessionId;

  /// The `Sound.id` of the sound that woke the user, or null for "Not sure".
  final String? soundId;

  final DateTime answeredAt;

  @override
  bool operator ==(Object other) =>
      other is MorningAnswer &&
      other.sessionId == sessionId &&
      other.soundId == soundId &&
      other.answeredAt == answeredAt;

  @override
  int get hashCode => Object.hash(sessionId, soundId, answeredAt);

  @override
  String toString() =>
      'MorningAnswer(sessionId: $sessionId, soundId: $soundId, '
      'answeredAt: $answeredAt)';
}
