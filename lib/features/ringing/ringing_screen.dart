import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/ring_sequence.dart';
import 'package:shuffle_alarm/core/snooze.dart';
import 'package:shuffle_alarm/design/components/accent_page.dart';
import 'package:shuffle_alarm/design/components/layout.dart';
import 'package:shuffle_alarm/design/components/spinning_record.dart';
import 'package:shuffle_alarm/design/components/time_text.dart';
import 'package:shuffle_alarm/design/components/wide_button.dart';
import 'package:shuffle_alarm/design/theme.dart';
import 'package:shuffle_alarm/design/tokens.dart';
import 'package:shuffle_alarm/features/alarms/alarms_screen.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/ringing/ringing_controller.dart';

/// The ringing screen (task 2.5): filled with the accent, above everything
/// else, with a big clock on a spinning record, the sound that plays, Snooze
/// and Stop. The app opens it when a ring starts.
class RingingScreen extends ConsumerStatefulWidget {
  const RingingScreen({super.key});

  static const path = '/ringing';

  @override
  ConsumerState<RingingScreen> createState() => _RingingScreenState();
}

class _RingingScreenState extends ConsumerState<RingingScreen> {
  /// The ring it shows: the last one, so nothing jumps while the page closes.
  Ringing? _shown;

  /// Runs a tap on Stop, Snooze or Close, then leaves the page.
  Future<void> _thenLeave(Future<void> Function() tap) async {
    await tap();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AlarmsScreen.path);
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
      child: AccentPage(
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
                        _Record(
                          now: now,
                          box: box,
                          turning: shown != null && shown.audible && !over,
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
        bottomAction: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!over) ...[
              WideButton.secondary(
                label: 'Snooze ${defaultSnooze.inMinutes} min',
                onPressed: ringing == null
                    ? null
                    : () => unawaited(_thenLeave(controller.snooze)),
              ),
              const SizedBox(height: Space.s12),
            ],
            WideButton(
              label: over ? 'Close' : 'Stop',
              onPressed: ringing == null
                  ? null
                  : () => unawaited(_thenLeave(controller.stop)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Above the record: the alarm that rings, its time and its label.
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
        // Read in sentence case: screen readers may spell out capitals.
        Text(
          'ALARM ${time.toUpperCase()}',
          style: WakemixType.of(context).caption,
          textAlign: TextAlign.center,
          semanticsLabel: 'Alarm $time',
        ),
        if (alarm.label.isNotEmpty) ...[
          const SizedBox(height: Space.s4),
          Text(
            alarm.label,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// The spinning record with the clock on its label, as large as the space in
/// [box] allows.
class _Record extends StatelessWidget {
  const _Record({required this.now, required this.box, required this.turning});

  final DateTime now;
  final BoxConstraints box;

  /// Whether it turns: not when no sound plays.
  final bool turning;

  /// The smallest the record gets, on a low screen where the page scrolls.
  static const minDiameter = 200.0;

  /// The largest the record gets.
  static const maxDiameter = 420.0;

  /// How much of the height of the page it takes at most, to leave room for
  /// the alarm and the sound.
  static const maxHeightShare = 0.6;

  @override
  Widget build(BuildContext context) {
    final diameter = math
        .min(box.maxWidth - 2 * Layout.gutter, box.maxHeight * maxHeightShare)
        .clamp(minDiameter, maxDiameter);
    return SizedBox.square(
      dimension: diameter,
      child: SpinningRecord(
        turning: turning,
        child: _Clock(TimeOfDay.fromDateTime(now)),
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
          Text(
            clock,
            style: theme.textTheme.displayLarge!.copyWith(
              fontSize: TypeScale.ringClock,
            ),
          ),
          if (period != null) Text(period, style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}

/// Below the record: the sound that plays, or why none does.
class _Sound extends StatelessWidget {
  const _Sound({required this.ringing, required this.onPlaySound});

  final Ringing ringing;
  final VoidCallback onPlaySound;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = WakemixType.of(context);
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
    return Column(
      children: [
        Text('NOW PLAYING', style: type.caption, semanticsLabel: 'Now playing'),
        const SizedBox(height: Space.s4),
        AnimatedSwitcher(
          duration: Motion.of(context, Motion.medium),
          child: Text(
            sound.title,
            key: ValueKey(sound.id),
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
