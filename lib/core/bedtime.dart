import 'package:meta/meta.dart';

/// How long a night's sleep should be, until a setting can change it.
const defaultSleepGoal = Duration(hours: 8);

/// When to go to bed to sleep [goal] before [ring]: the moment [goal] before
/// it.
///
/// A moment, not a time on the clock, so a night across a change to or from
/// daylight saving time still has [goal] of sleep: the morning after the
/// clock jumps forward, a ring at 07:00 gives 22:00, not 23:00.
///
/// Throws an [ArgumentError] if [goal] is not positive.
DateTime bedtimeFor(DateTime ring, {Duration goal = defaultSleepGoal}) {
  if (goal <= Duration.zero) {
    throw ArgumentError.value(goal, 'goal', 'Must be positive');
  }
  return ring.subtract(goal);
}

/// What the sleep calculator says at [now] about the ring at [ring]: before
/// the bedtime, when to go to bed ([BedBy]); from the bedtime on, how long
/// the night still is ([SleepNow]).
///
/// [now] can be in UTC. Throws an [ArgumentError] if [ring] is not after
/// [now], or if [goal] is not positive.
SleepAdvice sleepAdvice({
  required DateTime ring,
  required DateTime now,
  Duration goal = defaultSleepGoal,
}) {
  if (!ring.isAfter(now)) {
    throw ArgumentError.value(ring, 'ring', 'Must be after $now');
  }
  final bedtime = bedtimeFor(ring, goal: goal);
  if (now.isBefore(bedtime)) return BedBy(bedtime, goal: goal);
  // Rounded down: nobody sleeps longer than the time that is left.
  return SleepNow(Duration(minutes: ring.difference(now).inMinutes));
}

/// What the sleep calculator says: [BedBy] or [SleepNow].
@immutable
sealed class SleepAdvice {
  const SleepAdvice();
}

/// Go to bed at [bedtime] to sleep [goal] before the ring.
final class BedBy extends SleepAdvice {
  const BedBy(this.bedtime, {required this.goal});

  final DateTime bedtime;
  final Duration goal;

  @override
  bool operator ==(Object other) =>
      other is BedBy && other.bedtime == bedtime && other.goal == goal;

  @override
  int get hashCode => Object.hash(bedtime, goal);

  @override
  String toString() => 'BedBy($bedtime, goal: $goal)';
}

/// The bedtime has come: going to sleep now gives [sleep] until the ring, in
/// whole minutes.
final class SleepNow extends SleepAdvice {
  const SleepNow(this.sleep);

  final Duration sleep;

  @override
  bool operator ==(Object other) => other is SleepNow && other.sleep == sleep;

  @override
  int get hashCode => sleep.hashCode;

  @override
  String toString() => 'SleepNow($sleep)';
}
