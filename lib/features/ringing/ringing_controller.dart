import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shuffle_alarm/core/adaptive_weights.dart';
import 'package:shuffle_alarm/core/due_rings.dart';
import 'package:shuffle_alarm/core/fallback_tone.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/morning_answer.dart';
import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/core/ring_plan.dart';
import 'package:shuffle_alarm/core/ring_position.dart';
import 'package:shuffle_alarm/core/ring_sequence.dart';
import 'package:shuffle_alarm/core/snooze.dart';
import 'package:shuffle_alarm/data/ids.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/ringing/morning_card.dart';
import 'package:shuffle_alarm/platform/providers.dart';
import 'package:shuffle_alarm/platform/sound_player.dart';

/// The alarm that rings now.
@immutable
class Ringing {
  const Ringing(this.due, {this.sound, this.audible = true, this.over = false});

  /// The ring: which alarm, set for when.
  final DueRing due;

  /// The sound that plays now, or null while none does.
  final Sound? sound;

  /// Whether its sound plays. False when the platform blocks it, such as a
  /// browser that had no tap on "Arm alarms".
  final bool audible;

  /// Whether it reached its time cap without a Stop, and went quiet: a
  /// missed alarm.
  final bool over;

  @override
  bool operator ==(Object other) =>
      other is Ringing &&
      other.due == due &&
      other.sound == sound &&
      other.audible == audible &&
      other.over == over;

  @override
  int get hashCode => Object.hash(due, sound, audible, over);

  @override
  String toString() =>
      'Ringing($due, sound: ${sound?.id}, audible: $audible, over: $over)';
}

/// An alarm that was snoozed: the ring that comes back, and its session so
/// far.
@immutable
class SnoozedRing {
  const SnoozedRing(this.due, this.session);

  /// The ring that comes back, at [DueRing.startsAt].
  final DueRing due;

  final RingSession session;

  @override
  bool operator ==(Object other) =>
      other is SnoozedRing && other.due == due && other.session == session;

  @override
  int get hashCode => Object.hash(due, session);

  @override
  String toString() => 'SnoozedRing($due)';
}

/// The alarm that rings now, or null.
final ringingProvider = NotifierProvider<RingingController, Ringing?>(
  RingingController.new,
);

/// The alarms that were snoozed and come back, soonest first.
final snoozedRingsProvider = NotifierProvider<SnoozedRings, List<SnoozedRing>>(
  SnoozedRings.new,
);

/// The list behind [snoozedRingsProvider], which [RingingController] keeps.
class SnoozedRings extends Notifier<List<SnoozedRing>> {
  @override
  List<SnoozedRing> build() => const [];

  void add(SnoozedRing ring) {
    state = [...state, ring]
      ..sort((a, b) => a.due.startsAt.compareTo(b.due.startsAt));
  }

  void remove(SnoozedRing ring) {
    state = [
      for (final other in state)
        if (other != ring) other,
    ];
  }
}

/// Rings the alarms that come due (task 2.4), and logs each ring (task 2.5).
///
/// It hands the alarms to the platform's `AlarmScheduler`. When one comes
/// due, it plays the clips of the ring's stored plan (`clipsOfPlan`, Tonight's
/// mix), or else a new ring sequence (`buildRingSequence`), one clip after the
/// other, from where the clock says (`ringPosition`), until Stop, Snooze or
/// the time cap. A plan never keeps an alarm from ringing: one that is missing,
/// or cannot be read in time, only means a new sequence.
///
/// - A one-time alarm switches off when it comes due, so it rings once.
/// - A ring found after its time cap is over is missed: no sound.
/// - One ring at a time: an alarm that comes due while another rings does
///   not ring, and is missed. A ring that went quiet at its cap holds back
///   nothing.
/// - Snooze gives the `AlarmScheduler` a ring after Snooze, which comes due
///   like any other, also after a late check. Each ring has a time cap of its
///   own. A snooze ends with `stopSnoozed`, when its alarm is deleted, or
///   when its repeating alarm is switched off, and it outlives a reload of
///   the app: the log says what still comes back.
///
/// Every sound goes in the log when it ends, so a tab closed in the middle of
/// a ring leaves it as missed. A log or a weight that cannot be written only
/// goes to the debug log: an alarm never fails for its log.
///
/// A ring always has something to play: the sounds of the device, the library
/// straight from its files when there are none (`ringSoundsProvider`), or
/// else the tone that the player makes itself ([fallbackTone]), which also
/// takes the place of a clip that cannot be read. Only a platform that blocks
/// the sound makes it ring without one, and says so ([Ringing.audible]).
///
/// A Stop leaves a Morning card, unless the person turned it off, and a ring
/// that starts takes its place: the card never holds a ring up. Its answer goes
/// through [answerMorning], with the other writes.
class RingingController extends Notifier<Ringing?> {
  /// How long a ring waits for its stored plan.
  static const planLimit = Duration(seconds: 2);

  final _random = Random();

  /// Counts the playbacks. Stop and each new playback end the one before.
  var _playback = 0;

  /// The starts of the rings that came due, one after the other.
  Future<void> _starts = Future.value();
  List<RingClip> _clips = const [];
  Map<String, String> _assets = const {};

  /// The session of the ring that rings, or that went quiet last.
  late RingSession _session;

  /// The sound that plays now, and when it started.
  ({Sound sound, DateTime startedAt})? _playing;

  /// Ends the ring at its time cap, also when no clip reports its end, such
  /// as a ring with its sound blocked.
  Timer? _capTimer;

  /// The writes to the log and the weights, one after the other.
  Future<void> _writes = Future.value();

  @override
  Ringing? build() {
    final scheduler = ref.watch(alarmSchedulerProvider);
    ref.listen(alarmsProvider, (_, next) {
      if (next.value case final alarms?) {
        scheduler.watch(alarms);
        _endSnoozesWithoutAlarm(alarms);
      }
    }, fireImmediately: true);
    final due = scheduler.dueRings.listen(_onDue);
    ref.onDispose(() {
      _playback++;
      _capTimer?.cancel();
      unawaited(due.cancel());
    });
    unawaited(_restoreSnoozes());
    return null;
  }

  DateTime get _now => ref.read(nowProvider)();

  SnoozedRings get _snoozed => ref.read(snoozedRingsProvider.notifier);

  /// The first round of the clips of the ring that rings, or that went quiet
  /// last: every sound of it once, in play order.
  List<RingClip> get round => firstRound(_clips);

  void _onDue(DueRing due) {
    final snoozed = _takeSnoozed(due);
    if (snoozed == null && due.alarm.repeatDays.isEmpty) {
      unawaited(_switchOff(due.alarm));
    }
    final session =
        snoozed?.session ??
        RingSession(
          id: newId(),
          alarmId: due.alarm.id,
          scheduledFor: due.scheduledFor,
        );
    // One at a time: a ring that comes due while another one starts waits to
    // know whether that one rings. The other may be found after its cap, such
    // as after a laptop slept through it, and then this one must ring.
    final start = _starts.then((_) => _startUnlessRinging(due, session));
    // The next start goes on also after one that failed, which is reported
    // as before.
    _starts = start.then(
      (_) {},
      onError: (Object error, StackTrace stack) =>
          Zone.current.handleUncaughtError(error, stack),
    );
  }

  /// Starts the ring of [due], unless another one rings: then it is missed.
  Future<void> _startUnlessRinging(DueRing due, RingSession session) async {
    if (!ref.mounted) return;
    final ringing = state;
    if (ringing != null && !ringing.over) {
      debugPrint(
        'Missed the alarm set for ${due.scheduledFor}: another one rings',
      );
      _log(session.missedAt(_now));
      return;
    }
    await _start(due, session);
  }

  /// Takes the snoozed ring that came due as [due] out of the list.
  SnoozedRing? _takeSnoozed(DueRing due) {
    for (final snoozed in ref.read(snoozedRingsProvider)) {
      if (snoozed.due == due) {
        _snoozed.remove(snoozed);
        return snoozed;
      }
    }
    return null;
  }

  /// Switches off the one-time [alarm] that came due, unless the user
  /// changed its time or days since.
  Future<void> _switchOff(Alarm alarm) async {
    final alarms = ref.read(alarmRepositoryProvider);
    try {
      final now = await alarms.byId(alarm.id);
      if (now == null || now.time != alarm.time || now.repeatDays.isNotEmpty) {
        return;
      }
      await alarms.save(now.copyWith(enabled: false));
    } on Object catch (error) {
      debugPrint('Could not switch off the one-time alarm: $error');
    }
  }

  Future<void> _start(DueRing due, RingSession session) async {
    final sounds = await _soundsToPlay();
    final weights = await _weights();
    final plan = await _planOf(due);
    if (!ref.mounted) return;
    _assets = {for (final stored in sounds) stored.sound.id: stored.audioPath};
    final pool = sounds.isEmpty
        ? [fallbackTone]
        : [for (final stored in sounds) stored.sound];
    _clips = plan != null && due.snoozedSoundId == null
        ? clipsOfPlan(plan, due.alarm, pool, weights)
        : buildRingSequence(
            due.alarm,
            pool,
            weights,
            newRingSeed(_random),
            snoozedSoundId: due.snoozedSoundId,
            skipped: plan?.notTonight ?? const {},
          );
    final now = _now;
    final elapsed = now.difference(due.startsAt);
    final missed = ringPosition(_clips, elapsed) == null;
    // One line in the log for each ring, which says how late the check
    // found it: a tester can read it in the browser's console.
    debugPrint(
      '${missed ? 'Missed' : 'Ringing'} the alarm set for '
      '${due.scheduledFor}${due.snoozedSoundId == null ? '' : ', snoozed'}, '
      'found ${elapsed.inMilliseconds} ms after '
      '${due.snoozedSoundId == null ? 'it' : 'the snooze'}',
    );
    if (missed) {
      _log(session.missedAt(now));
      return;
    }
    _session = session;
    _log(session);
    _capTimer?.cancel();
    _capTimer = Timer(_clips.last.endsAt - elapsed, () {
      if (state case Ringing(:final due, over: false)) _goQuiet(due);
    });
    state = Ringing(due);
    unawaited(_play(due));
    // The ring has taken over: a question that still shows is gone.
    ref.read(morningCardProvider.notifier).session = null;
  }

  /// The sounds of the device, or of the library. None when neither can be
  /// read: the ring then plays the tone.
  Future<List<StoredSound>> _soundsToPlay() async {
    try {
      return await ref.read(ringSoundsProvider)();
    } on Object catch (error) {
      debugPrint('Could not read any sound, so the tone plays: $error');
      return const [];
    }
  }

  /// The stored plan of [due], which a ring after Snooze keeps too. Null when
  /// it has none, or none that can be read in a moment.
  Future<RingPlan?> _planOf(DueRing due) async {
    try {
      return await ref
          .read(ringPlanRepositoryProvider)
          .forRing(due.alarm.id, due.scheduledFor)
          .timeout(planLimit);
    } on Object catch (error) {
      debugPrint('Could not read the plan of a ring, so it makes one: $error');
      return null;
    }
  }

  Future<SoundWeights> _weights() async {
    try {
      return await ref.read(weightRepositoryProvider).load();
    } on Object catch (error) {
      debugPrint('Could not read the weights: $error');
      return const SoundWeights.start();
    }
  }

  /// Plays the clips of the ring from where the clock says, one after the
  /// other, until Stop, Snooze or the time cap.
  Future<void> _play(DueRing due) async {
    final playback = ++_playback;
    final player = ref.read(soundPlayerProvider);
    unawaited(
      player.preload({for (final clip in _clips) ?_assets[clip.sound.id]}),
    );
    var next = 0;
    while (playback == _playback) {
      final at = ringPosition(_clips, _now.difference(due.startsAt));
      if (at == null) break;
      // Never back to a clip that played, such as one that ended a moment
      // early.
      final index = max(at.index, next);
      if (index >= _clips.length) break;
      final clip = _clips[index];
      final offset = index == at.index ? at.offset : Duration.zero;
      next = index + 1;
      if (!await _playClip(clip, offset, due, playback)) return;
      if (playback != _playback) return;
      _logPlaying(RingAction.timeout);
    }
    if (playback == _playback) _goQuiet(due);
  }

  /// Plays [clip] from [offset], or the tone in its place when it has no file
  /// or its file cannot be read. Returns false if no sound can play.
  Future<bool> _playClip(
    RingClip clip,
    Duration offset,
    DueRing due,
    int playback,
  ) async {
    final player = ref.read(soundPlayerProvider);
    void playing(Sound sound) {
      if (playback != _playback) return;
      _playing = (sound: sound, startedAt: _now);
      state = Ringing(due, sound: sound);
    }

    final asset = _assets[clip.sound.id];
    if (asset != null) {
      playing(clip.sound);
      try {
        await player.play(
          asset,
          from: clip.window.start + offset,
          to: clip.window.end,
          volume: clip.volume,
        );
        return true;
      } on SoundBlockedException {
        _noSound(due, playback);
        return false;
      } on Object catch (error) {
        debugPrint('Could not play ${clip.sound.id}: $error');
      }
    }
    if (playback != _playback) return true;
    playing(fallbackTone);
    try {
      await player.playTone(
        length: clip.window.length - offset,
        volume: clip.volume,
      );
      return true;
    } on Object catch (error) {
      debugPrint('Could not play the tone: $error');
      _noSound(due, playback);
      return false;
    }
  }

  /// The ring goes on without sound, until a tap or its time cap.
  void _noSound(DueRing due, int playback) {
    if (playback != _playback) return;
    _playing = null;
    state = Ringing(due, audible: false);
  }

  /// The sound that plays ended as [action] says: in the log.
  void _logPlaying(RingAction action) {
    final playing = _playing;
    if (playing == null) return;
    _playing = null;
    _session = _session.withEvent(
      RingEvent(
        soundId: playing.sound.id,
        startedAt: playing.startedAt,
        endedAt: _now,
        action: action,
      ),
    );
    _log(_session);
  }

  /// The ring reached its time cap without a tap: it goes quiet, and counts
  /// as missed.
  void _goQuiet(DueRing due) {
    _playback++;
    _capTimer?.cancel();
    final wasPlaying = _playing != null;
    _logPlaying(RingAction.timeout);
    _session = _session.missedAt(_now);
    _log(_session);
    state = Ringing(due, over: true);
    debugPrint('Missed the alarm set for ${due.scheduledFor}: its time is up');
    if (wasPlaying) unawaited(ref.read(soundPlayerProvider).stop());
  }

  /// Unlocks the sound and plays the ring from where the clock says. Call it
  /// from a tap, such as on "Play sound" when the browser blocked it.
  Future<void> playSound() async {
    final ringing = state;
    if (ringing == null || ringing.audible || ringing.over) return;
    if (!await ref.read(soundPlayerProvider).unlock()) return;
    if (!identical(state, ringing)) return;
    state = Ringing(ringing.due);
    unawaited(_play(ringing.due));
  }

  /// Stops the ring: the log gets the Stop, the sound at the tap gets heavier,
  /// and the Morning card opens. After its time cap it only closes the ring.
  Future<void> stop() async {
    final ringing = state;
    if (ringing == null) return;
    if (!ringing.over) {
      _endByTap(
        ringing,
        RingAction.stop,
        learn: (weights, id) => weights.afterStop(id),
      );
      _leaveMorningCard(_session);
    }
    state = null;
    await ref.read(soundPlayerProvider).stop();
  }

  /// Snoozes the ring: the log gets the Snooze, the sound at the tap gets
  /// lighter, and the ring comes back after the snooze.
  Future<void> snooze() async {
    final ringing = state;
    if (ringing == null || ringing.over) return;
    final soundId = _endByTap(
      ringing,
      RingAction.snooze,
      learn: (weights, id) => weights.afterSnooze(id),
    );
    final back = ringAfterSnooze(ringing.due, soundId: soundId, at: _now);
    ref.read(alarmSchedulerProvider).schedule(back);
    _snoozed.add(SnoozedRing(back, _session));
    state = null;
    debugPrint(
      'Snoozed the alarm set for ${ringing.due.scheduledFor} until '
      '${back.startsAt}',
    );
    await ref.read(soundPlayerProvider).stop();
  }

  /// Ends the ring with a tap, and returns the id of the sound at the tap: the
  /// one that plays, which learns from the tap, or else the one the clock
  /// says, which nobody heard.
  String _endByTap(
    Ringing ringing,
    RingAction action, {
    required SoundWeights Function(SoundWeights weights, String soundId) learn,
  }) {
    _playback++;
    _capTimer?.cancel();
    final playing = _playing;
    if (playing != null) {
      _logPlaying(action);
      _learn(playing.sound.id, learn);
      return playing.sound.id;
    }
    final now = _now;
    final at = ringPosition(_clips, now.difference(ringing.due.startsAt));
    final soundId = _clips[at?.index ?? _clips.length - 1].sound.id;
    _session = _session.withEvent(
      RingEvent.silent(soundId: soundId, at: now, action: action),
    );
    _log(_session);
    return soundId;
  }

  /// Ends the snooze of [ring] with a tap, so it does not come back, and the
  /// Morning card opens, as after any Stop.
  void stopSnoozed(SnoozedRing ring) => _leaveMorningCard(_endSnooze(ring));

  /// Ends the snooze of [ring]: a Stop in the log, without length, as no sound
  /// played. Returns its session.
  RingSession _endSnooze(SnoozedRing ring) {
    ref.read(alarmSchedulerProvider).cancel(ring.due);
    _snoozed.remove(ring);
    final session = _stopped(ring.session);
    _log(session);
    return session;
  }

  /// What the Stop of [session] leaves: its Morning card, or none when the
  /// person turned it off.
  void _leaveMorningCard(RingSession session) {
    ref.read(morningCardProvider.notifier).session =
        ref.read(morningCardOnProvider) ? session : null;
  }

  /// The answer to "Which sound woke you?" on the Morning card: the id of the
  /// sound, which gets heavier on top of what its taps taught, or null for "Not
  /// sure", which teaches nothing. It ends the card, so it counts once. Without
  /// a card, such as after a ring took over, it does nothing.
  void answerMorning(String? soundId) {
    final card = ref.read(morningCardProvider.notifier);
    final session = card.session;
    if (session == null) return;
    card.session = null;
    final answer = MorningAnswer(
      sessionId: session.id,
      soundId: soundId,
      answeredAt: _now,
    );
    _write(
      () => ref.read(morningAnswerRepositoryProvider).save(answer),
      failure: 'Could not save the answer of the Morning card',
    );
    if (soundId != null) {
      _learn(soundId, (weights, id) => weights.afterWoke(id));
    }
  }

  RingSession _stopped(RingSession session) => session.withEvent(
    RingEvent.silent(
      soundId: session.events.last.soundId,
      at: _now,
      action: RingAction.stop,
    ),
  );

  /// Ends each snooze whose alarm was deleted, or whose repeating alarm was
  /// switched off. A one-time alarm is off from its first ring on.
  void _endSnoozesWithoutAlarm(List<Alarm> alarms) {
    final byId = {for (final alarm in alarms) alarm.id: alarm};
    for (final snoozed in ref.read(snoozedRingsProvider)) {
      final alarm = byId[snoozed.due.alarm.id];
      if (alarm == null || (alarm.repeatDays.isNotEmpty && !alarm.enabled)) {
        _endSnooze(snoozed);
      }
    }
  }

  /// Brings back the snoozes of the log, when the app starts. One that ended
  /// long ago comes due at the first check, and is missed then.
  Future<void> _restoreSnoozes() async {
    try {
      final sessions = await ref.read(ringSessionRepositoryProvider).all();
      for (final session in sessions) {
        if (session.outcome != RingOutcome.snoozed) continue;
        final alarm = await ref
            .read(alarmRepositoryProvider)
            .byId(session.alarmId);
        if (!ref.mounted) return;
        final back = alarm == null ? null : snoozedRingOf(session, alarm);
        if (back == null) {
          _log(_stopped(session));
          continue;
        }
        ref.read(alarmSchedulerProvider).schedule(back);
        _snoozed.add(SnoozedRing(back, session));
      }
    } on Object catch (error) {
      debugPrint('Could not read the snoozes from the log: $error');
    }
  }

  /// Saves [session] in the log, after the writes before it.
  void _log(RingSession session) => _write(
    () => ref.read(ringSessionRepositoryProvider).save(session),
    failure: 'Could not write the ring log',
  );

  /// Saves what the tap on the sound with [soundId] taught, after the writes
  /// before it.
  void _learn(
    String soundId,
    SoundWeights Function(SoundWeights weights, String soundId) learn,
  ) => _write(() async {
    final weights = ref.read(weightRepositoryProvider);
    await weights.save(learn(await weights.load(), soundId), soundId: soundId);
  }, failure: 'Could not save the weight of $soundId');

  void _write(Future<void> Function() write, {required String failure}) {
    _writes = _writes.then((_) async {
      if (!ref.mounted) return;
      try {
        await write();
      } on Object catch (error) {
        debugPrint('$failure: $error');
      }
    });
  }
}
