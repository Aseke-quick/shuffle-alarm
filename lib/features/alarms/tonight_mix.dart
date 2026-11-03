import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shuffle_alarm/core/adaptive_weights.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/core/next_ring.dart';
import 'package:shuffle_alarm/core/ring_plan.dart';
import 'package:shuffle_alarm/core/ring_sequence.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/design/components/record.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';

/// The alarm that rings next and when, or null if no alarm is on: again when
/// that changes, not at each minute.
final nextRingProvider = Provider<({Alarm alarm, DateTime ring})?>((ref) {
  final alarms = ref.watch(alarmsProvider).value;
  return alarms == null ? null : soonestRing(alarms, ref.watch(clockProvider));
});

/// Tonight's mix (task 2.5a): the stored plan of the next ring, and the clips
/// it plays out of the sounds of the device now, as the ring will.
@immutable
class TonightMix {
  TonightMix({
    required this.alarm,
    required this.plan,
    required List<StoredSound> sounds,
    required SoundWeights weights,
  }) : _sounds = sounds,
       _weights = weights,
       clips = clipsOfPlan(plan, alarm, [
         for (final stored in sounds) stored.sound,
       ], weights);

  /// The alarm that rings.
  final Alarm alarm;

  /// The stored plan of its next ring.
  final RingPlan plan;

  /// The clips of the ring, in play order, up to the time cap.
  final List<RingClip> clips;

  final List<StoredSound> _sounds;
  final SoundWeights _weights;

  /// When the alarm rings.
  DateTime get ringAt => plan.ringAt;

  /// Every sound of the ring once, in play order.
  late final List<RingClip> round = firstRound(clips);

  List<Sound> get _pool => [for (final stored in _sounds) stored.sound];

  late final List<Sound> _playing = soundsOfRing(
    alarm,
    _pool,
    skipped: plan.notTonight,
  );

  /// The sounds of the ring that stay out of it tonight, by title.
  late final List<Sound> notTonight = () {
    final playing = {for (final sound in _playing) sound.id};
    return [
      for (final sound in soundsOfRing(alarm, _pool))
        if (!playing.contains(sound.id)) sound,
    ]..sort((a, b) => a.title.compareTo(b.title));
  }();

  /// This mix if it is the one of the ring of [alarm] at [ring], or else null.
  TonightMix? takeIf({required Alarm alarm, required DateTime ring}) =>
      this.alarm.id == alarm.id && ringAt.isAtSameMomentAs(ring) ? this : null;

  /// Whether a sound can stay out: the ring must keep one to play.
  bool get canSkip => _playing.length > 1;

  /// Where the audio of the sound with [soundId] is.
  String audioPathOf(String soundId) =>
      _sounds.firstWhere((stored) => stored.sound.id == soundId).audioPath;

  TonightMix _with(RingPlan plan, {SoundWeights? weights}) => TonightMix(
    alarm: alarm,
    plan: plan,
    sounds: _sounds,
    weights: weights ?? _weights,
  );
}

/// The segments of a record for the clips of [round]: how long each sound plays
/// and how strong it is.
List<RecordSegment> recordSegmentsOf(List<RingClip> round) => [
  for (final clip in round)
    RecordSegment(
      length: clip.window.length,
      strength:
          (clip.sound.intensity - Sound.minIntensity) /
          (Sound.maxIntensity - Sound.minIntensity),
    ),
];

/// The mix of the next ring, or null without one: no alarm is on, there is no
/// sound, or its plan cannot be read or saved. A ring then makes its own, so
/// this never stands in the way of an alarm.
final tonightMixProvider =
    AsyncNotifierProvider<TonightMixController, TonightMix?>(
      TonightMixController.new,
    );

/// Keeps the stored plan of the next ring, and changes it.
///
/// It makes the plan when a ring becomes the next one, and looks at it again
/// when the sounds change, such as after the library sync at start.
class TonightMixController extends AsyncNotifier<TonightMix?> {
  final _random = Random();

  @override
  Future<TonightMix?> build() async {
    final next = ref.watch(nextRingProvider);
    ref.watch(storedSoundsProvider);
    if (next == null) return null;
    final (:alarm, :ring) = next;
    final readSounds = ref.read(ringSoundsProvider);
    final weightsRepository = ref.read(weightRepositoryProvider);
    final plans = ref.read(ringPlanRepositoryProvider);
    // The clock of the next ring, so the two agree on what has come.
    final now = ref.read(clockProvider);
    try {
      final sounds = await readSounds();
      if (sounds.isEmpty) return null;
      final weights = await weightsRepository.load();
      final plan = await plans.settle(
        alarm.id,
        now: now,
        choose: (stored) => planForRing(
          alarm,
          ring,
          stored: stored,
          now: now,
          pool: [for (final stored in sounds) stored.sound],
          weights: weights,
          random: _random,
        ),
      );
      return TonightMix(
        alarm: alarm,
        plan: plan,
        sounds: sounds,
        weights: weights,
      );
    } on Object catch (error) {
      debugPrint("Could not make tonight's mix: $error");
      return null;
    }
  }

  /// Makes a new order with a new seed, and returns whether it did: the sounds
  /// can allow one order only. Throws if it cannot be saved.
  Future<bool> reshuffle() async {
    final mix = state.value;
    if (mix == null) return false;
    final weights = await ref.read(weightRepositoryProvider).load();
    final plan = reshuffled(mix.plan, mix.alarm, mix._pool, weights, _random);
    if (plan == mix.plan) return false;
    await _save(mix._with(plan, weights: weights));
    return true;
  }

  /// Keeps the sound with [soundId] out of this ring, unless it is the last
  /// one. Throws if it cannot be saved.
  Future<void> skip(String soundId) async {
    final mix = state.value;
    if (mix == null || !mix.canSkip) return;
    await _save(mix._with(mix.plan.skipping(soundId)));
  }

  /// Brings the sound with [soundId] back to its place in this ring. Throws if
  /// it cannot be saved.
  Future<void> bringBack(String soundId) async {
    final mix = state.value;
    if (mix == null) return;
    await _save(mix._with(mix.plan.bringingBack(soundId)));
  }

  Future<void> _save(TonightMix mix) async {
    await ref.read(ringPlanRepositoryProvider).save(mix.plan);
    if (ref.mounted) state = AsyncData(mix);
  }
}
