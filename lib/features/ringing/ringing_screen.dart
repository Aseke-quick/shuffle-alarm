import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/ring_sequence.dart';
import 'package:shuffle_alarm/core/snooze.dart';
import 'package:shuffle_alarm/design/components/glass_card.dart';
import 'package:shuffle_alarm/design/components/layout.dart';
import 'package:shuffle_alarm/design/components/mix_bars.dart';
import 'package:shuffle_alarm/design/components/time_text.dart';
import 'package:shuffle_alarm/design/components/wide_button.dart';
import 'package:shuffle_alarm/design/tokens.dart';
import 'package:shuffle_alarm/features/alarms/alarms_screen.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/alarms/tonight_mix.dart';
import 'package:shuffle_alarm/features/ringing/morning_card.dart';
import 'package:shuffle_alarm/features/ringing/morning_card_screen.dart';
import 'package:shuffle_alarm/features/ringing/ringing_controller.dart';

/// The ringing screen (task 2.5): the page at its warmest, above everything
/// else, with a very big clock, the mix as bars with the sound that plays
/// lit, and Snooze and Stop as two wide buttons, Stop the bigger (ADR-005).
/// The app opens it when a ring starts.
class RingingScreen extends ConsumerStatefulWidget {
  const RingingScreen({super.key});

  static const path = '/ringing';

  @override
  ConsumerState<RingingScreen> createState() => _RingingScreenState();
}

class _RingingScreenState extends ConsumerState<RingingScreen> {
  /// The ring it shows: the last one, so nothing jumps while the page closes.
  Ringing? _shown;

  /// Runs a tap on Stop, Snooze or Close, then leaves the page: for the Morning
  /// card that a Stop left, or else for the page below.
  Future<void> _thenLeave(Future<void> Function() tap) async {
    await tap();
    if (!mounted) return;
    final card = ref.read(morningCardProvider) != null;
    if (context.canPop()) {
      if (card) {
        context.pushReplacement(MorningCardScreen.path);
      } else {
        context.pop();
      }
    } else {
      context.go(card ? MorningCardScreen.path : AlarmsScreen.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ringing = ref.watch(ringingProvider);
    // A new frame at each minute, for the clock.
    ref.watch(clockProvider);
    final now = ref.read(nowProvider)();
    final shown = _shown = ringing ?? _shown;
    final controller = ref.read(ringingProvider.notifier);
    final over = shown?.over ?? false;
    return PopScope(
      // Only Stop or Snooze ends a ring: Back would leave it ringing out of
      // sight.
      canPop: ringing == null,
      child: PageScaffold(
        warmth: 1,
        body: SafeArea(
          bottom: false,
          child: ContentWidth(
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Layout.gutter,
                      vertical: Space.s16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (shown != null) _Alarm(shown),
                        const SizedBox(height: Space.s16),
                        _Clock(TimeOfDay.fromDateTime(now)),
                        const SizedBox(height: Space.s16),
                        _Mix(
                          round: controller.round,
                          playing: shown != null && shown.audible && !over
                              ? shown.sound?.id
                              : null,
                        ),
                        const SizedBox(height: Space.s16),
                        if (shown != null)
                          _Sound(
                            ringing: shown,
                            onPlaySound: () =>
                                unawaited(controller.playSound()),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomAction(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!over) ...[
                WideButton.secondary(
                  label: 'Snooze ${defaultSnooze.inMinutes} min',
                  icon: Icons.snooze,
                  onPressed: ringing == null
                      ? null
                      : () => unawaited(_thenLeave(controller.snooze)),
                ),
                const SizedBox(height: Space.s12),
              ],
              WideButton(
                label: over ? 'Close' : 'Stop',
                tall: true,
                onPressed: ringing == null
                    ? null
                    : () => unawaited(_thenLeave(controller.stop)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Above the clock: the alarm that rings, its time and its label.
class _Alarm extends StatelessWidget {
  const _Alarm(this.ringing);

  final Ringing ringing;

  @override
  Widget build(BuildContext context) {
    final alarm = ringing.due.alarm;
    final time = TimeOfDay(
      hour: alarm.time.hour,
      minute: alarm.time.minute,
    ).format(context);
    return Column(
      children: [
        _Pill('Alarm $time'),
        if (alarm.label.isNotEmpty) ...[
          const SizedBox(height: Space.s12),
          Text(
            alarm.label,
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// A small caption in a pill of glass.
class _Pill extends StatelessWidget {
  const _Pill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.glass,
        border: Border.all(color: c.glassLine),
        borderRadius: const BorderRadius.all(Radius.circular(Corners.round)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.s12,
          vertical: Space.s8,
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// The sounds of the ring as bars, in play order, with the one that plays
/// lit. Nothing before the ring has its sounds.
class _Mix extends StatelessWidget {
  const _Mix({required this.round, required this.playing});

  final List<RingClip> round;

  /// The id of the sound that plays, or null while none does.
  final String? playing;

  @override
  Widget build(BuildContext context) {
    if (round.isEmpty) return const SizedBox(height: 56);
    final index = round.indexWhere((clip) => clip.sound.id == playing);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: MixBars(
        segments: mixSegmentsOf(round),
        active: index < 0 ? null : index,
        height: 56,
      ),
    );
  }
}

/// The time now, large, with the AM or PM under it. Screen readers hear it
/// whole.
class _Clock extends StatelessWidget {
  const _Clock(this.time);

  final TimeOfDay time;

  @override
  Widget build(BuildContext context) {
    final (clock, period) = timeParts(context, time);
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: time.format(context),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              clock,
              style: theme.textTheme.displayLarge!.copyWith(
                fontSize: Layout.isWide(context)
                    ? TypeScale.heroWide
                    : TypeScale.ringClock,
                letterSpacing: -0.05 * TypeScale.ringClock,
              ),
            ),
          ),
          if (period != null) Text(period, style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}

/// Below the clock: the sound that plays, or why none does.
class _Sound extends StatelessWidget {
  const _Sound({required this.ringing, required this.onPlaySound});

  final Ringing ringing;
  final VoidCallback onPlaySound;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = WakemixColors.of(context);
    final sound = ringing.sound;
    if (ringing.over) {
      return Text(
        'It rang for ${defaultRingCap.inMinutes} min, and nobody stopped it.',
        style: theme.textTheme.bodyLarge,
        textAlign: TextAlign.center,
      );
    }
    if (!ringing.audible) {
      return Column(
        children: [
          Text(
            'The sound did not play.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.s12),
          WideButton.secondary(
            label: 'Play sound',
            icon: Icons.volume_up_outlined,
            onPressed: onPlaySound,
          ),
        ],
      );
    }
    if (sound == null) return const SizedBox.shrink();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Now playing',
            style: theme.textTheme.labelMedium!.copyWith(color: c.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.s4),
          AnimatedSwitcher(
            duration: Motion.of(context, Motion.medium),
            child: Text(
              sound.title,
              key: ValueKey(sound.id),
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
