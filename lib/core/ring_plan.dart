import 'dart:math';

import 'package:meta/meta.dart';

import 'package:shuffle_alarm/core/adaptive_weights.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/core/ring_sequence.dart';

/// The stored plan of one ring of an alarm: Tonight's mix (task 2.5a).
///
/// It holds the order of the sounds, for the whole time cap, and which sounds
/// stay out of this ring, so a ring plays what the list showed, whatever the
/// weights learned since. The sounds themselves stay in the database:
/// [clipsOfPlan] turns a plan and the sounds of the device into clips, by every
/// rule of a ring, so a plan can never break one. A sound deleted since is
/// skipped.
@immutable
class RingPlan {
  RingPlan({
    required this.alarmId,
    required this.ringAt,
    required this.seed,
    required List<String> soundIds,
    Set<String> notTonight = const {},
  }) : soundIds = List.unmodifiable(soundIds),
       notTonight = Set.unmodifiable(notTonight);

  /// The `Alarm.id`.
  final String alarmId;

  /// When the alarm is set to ring: `DueRing.scheduledFor` of the ring it is
  /// for, to the microsecond.
  final DateTime ringAt;

  /// The seed of its order. The sounds after the end of the plan come from it
  /// too, when a sound left the ring and the plan runs out before the cap.
  final int seed;

  /// The ids of the sounds in play order. Each sound is in it once per round,
  /// also a sound of [notTonight], so that it can come back to its place.
  final List<String> soundIds;

  /// The ids of the sounds that stay out of this ring, also after a Snooze.
  final Set<String> notTonight;

  /// This plan for the ring at [ringAt], such as after a change of the alarm's
  /// time: it keeps its mix.
  RingPlan movedTo(DateTime ringAt) => RingPlan(
    alarmId: alarmId,
    ringAt: ringAt,
    seed: seed,
    soundIds: soundIds,
    notTonight: notTonight,
  );

  /// This plan with the sound with [soundId] left out of its ring.
  RingPlan skipping(String soundId) => RingPlan(
    alarmId: alarmId,
    ringAt: ringAt,
    seed: seed,
    soundIds: soundIds,
    notTonight: {...notTonight, soundId},
  );

  /// This plan with the sound with [soundId] back in its place.
  RingPlan bringingBack(String soundId) => RingPlan(
    alarmId: alarmId,
    ringAt: ringAt,
    seed: seed,
    soundIds: soundIds,
    notTonight: {...notTonight}..remove(soundId),
  );

  @override
  bool operator ==(Object other) =>
      other is RingPlan &&
      other.alarmId == alarmId &&
      other.ringAt.isAtSameMomentAs(ringAt) &&
      other.seed == seed &&
      _sameList(other.soundIds, soundIds) &&
      other.notTonight.length == notTonight.length &&
      other.notTonight.containsAll(notTonight);

  @override
  int get hashCode => Object.hash(
    alarmId,
    ringAt.microsecondsSinceEpoch,
    seed,
    Object.hashAll(soundIds),
    Object.hashAllUnordered(notTonight),
  );

  @override
  String toString() =>
      'RingPlan(alarmId: $alarmId, ringAt: $ringAt, seed: $seed, '
      'soundIds: $soundIds, notTonight: $notTonight)';
}

/// A seed for a new ring: a whole number that every platform stores alike.
int newRingSeed(Random random) => random.nextInt(1 << 30);

/// A new plan for the ring of [alarm] at [ringAt]: the order of its ring
/// sequence with [seed], out of every sound of the ring, so a sound of
/// [notTonight] has its place too.
RingPlan buildRingPlan(
  Alarm alarm,
  DateTime ringAt,
  Iterable<Sound> pool,
  SoundWeights weights,
  int seed, {
  Set<String> notTonight = const {},
  Duration cap = defaultRingCap,
}) => RingPlan(
  alarmId: alarm.id,
  ringAt: ringAt,
  seed: seed,
  soundIds: [
    for (final clip in buildRingSequence(alarm, pool, weights, seed, cap: cap))
      clip.sound.id,
  ],
  notTonight: notTonight,
);

/// The clips that the ring of [plan] plays out of [pool], the sounds of the
/// device now. By every rule of `buildRingSequence`, whatever the plan says:
/// each clip within the clip rule, no sound twice in a row, the gentle start,
/// and up to the time [cap].
///
/// With the sounds the plan was made of, it is the plan exactly. A sound of
/// [RingPlan.notTonight] or one deleted since is skipped, and the others keep
/// their order. A plan that is empty, or whose sounds are all gone, still fills
/// the ring.
List<RingClip> clipsOfPlan(
  RingPlan plan,
  Alarm alarm,
  Iterable<Sound> pool,
  SoundWeights weights, {
  Duration cap = defaultRingCap,
}) => buildRingSequence(
  alarm,
  pool,
  weights,
  plan.seed,
  cap: cap,
  planned: plan.soundIds,
  skipped: plan.notTonight,
);

/// The plan for the ring of [alarm] at [ringAt], out of the plans of the alarm
/// that are [stored]:
///
/// - the plan of that ring;
/// - or else the plan of a ring still to come at [now]: the alarm moved, and
///   the mix moves with it;
/// - or else a new one, with a new seed from [random]. The plan of a ring that
///   has come stays out of it, as its Not tonight was for that morning.
///
/// A plan that no longer fits the sounds ([planFits]) gets a new order, with
/// its seed and its [RingPlan.notTonight].
RingPlan planForRing(
  Alarm alarm,
  DateTime ringAt, {
  required List<RingPlan> stored,
  required DateTime now,
  required Iterable<Sound> pool,
  required SoundWeights weights,
  required Random random,
}) {
  final own = stored.where((plan) => plan.ringAt.isAtSameMomentAs(ringAt));
  final ahead = stored.where((plan) => plan.ringAt.isAfter(now));
  final plan = own.firstOrNull ?? ahead.firstOrNull?.movedTo(ringAt);
  if (plan != null && planFits(plan, alarm, pool)) return plan;
  return buildRingPlan(
    alarm,
    ringAt,
    pool,
    weights,
    plan?.seed ?? newRingSeed(random),
    notTonight: plan?.notTonight ?? const {},
  );
}

/// A new order for [plan], with a new seed from [random], which plays another
/// first round. It keeps [RingPlan.notTonight].
///
/// The same [plan] when the rules leave only one order, such as a pool of one
/// sound of each intensity with a gentle start.
RingPlan reshuffled(
  RingPlan plan,
  Alarm alarm,
  Iterable<Sound> pool,
  SoundWeights weights,
  Random random, {
  Duration cap = defaultRingCap,
}) {
  List<String> roundOf(RingPlan plan) => [
    for (final clip in firstRound(
      clipsOfPlan(plan, alarm, pool, weights, cap: cap),
    ))
      clip.sound.id,
  ];
  final round = roundOf(plan);
  for (var tries = 0; tries < _reshuffleTries; tries++) {
    final next = buildRingPlan(
      alarm,
      plan.ringAt,
      pool,
      weights,
      newRingSeed(random),
      notTonight: plan.notTonight,
      cap: cap,
    );
    if (!_sameList(roundOf(next), round)) return next;
  }
  return plan;
}

/// How many new seeds [reshuffled] tries for another first round. With the
/// heaviest and the lightest weight, two sounds change places once in 16 tries,
/// so this many all but always find it.
const _reshuffleTries = 256;

/// Whether [plan] still fits the sounds of its ring. It does not when it names
/// none of them, or when a sound joined the ring since it was made, such as a
/// new voice message or a genre the alarm got: the sound would only come after
/// all the others, so the plan is better made again.
///
/// A sound deleted since does not matter: the ring skips it. A plan that the
/// time cap ended before its second round cannot tell a new sound from one that
/// did not fit, so it holds.
bool planFits(RingPlan plan, Alarm alarm, Iterable<Sound> pool) {
  final sounds = soundsOfRing(alarm, pool);
  final named = plan.soundIds.toSet();
  if (!sounds.any((sound) => named.contains(sound.id))) return false;
  final hasSecondRound = named.length < plan.soundIds.length;
  return !hasSecondRound || sounds.every((sound) => named.contains(sound.id));
}

/// The clips of a ring up to the first sound that plays again: every sound of
/// the ring once, in play order, as far as the time cap allows.
List<RingClip> firstRound(List<RingClip> clips) {
  final seen = <String>{};
  return clips.takeWhile((clip) => seen.add(clip.sound.id)).toList();
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
