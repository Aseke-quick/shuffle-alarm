import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/ring_sequence.dart';
import 'package:shuffle_alarm/design/components/layout.dart';
import 'package:shuffle_alarm/design/components/time_text.dart';
import 'package:shuffle_alarm/design/components/wide_button.dart';
import 'package:shuffle_alarm/design/theme.dart';
import 'package:shuffle_alarm/design/tokens.dart';
import 'package:shuffle_alarm/features/ringing/ringing_controller.dart';

/// The page of an alarm that rings: its time, its label and Stop, above
/// everything else. The app opens it when a ring starts (task 2.4); task
/// 2.5 turns it into the ringing screen, with the clock, the sound that
/// plays and Snooze.
class RingingScreen extends ConsumerWidget {
  const RingingScreen({super.key});

  static const path = '/ringing';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ringing = ref.watch(ringingProvider);
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    final type = WakemixType.of(context);
    final alarm = ringing?.due.alarm;
    final minutes = defaultRingCap.inMinutes;
    return PopScope(
      // Only Stop ends a ring: Back would leave it ringing out of sight.
      canPop: ringing == null,
      child: Scaffold(
        body: SafeArea(
          child: ContentWidth(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Space.s24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ALARM', style: type.caption),
                    const SizedBox(height: Space.s8),
                    if (alarm != null)
                      TimeText(
                        TimeOfDay(
                          hour: alarm.time.hour,
                          minute: alarm.time.minute,
                        ),
                        style: theme.textTheme.displayLarge!,
                      ),
                    if (alarm != null && alarm.label.isNotEmpty) ...[
                      const SizedBox(height: Space.s8),
                      Text(
                        alarm.label,
                        style: theme.textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (ringing != null && ringing.over) ...[
                      const SizedBox(height: Space.s24),
                      Text(
                        'It rang for $minutes min, and nobody stopped it.',
                        style: type.meta,
                        textAlign: TextAlign.center,
                      ),
                    ] else if (ringing != null && !ringing.audible) ...[
                      const SizedBox(height: Space.s24),
                      Text(
                        'The sound did not play.',
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: c.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Space.s16),
                      WideButton.secondary(
                        label: 'Play sound',
                        icon: Icons.volume_up_outlined,
                        onPressed: () => unawaited(
                          ref.read(ringingProvider.notifier).playSound(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomAction(
          child: WideButton(
            label: ringing != null && ringing.over ? 'Close' : 'Stop',
            onPressed: () async {
              await ref.read(ringingProvider.notifier).stop();
              if (context.mounted && context.canPop()) context.pop();
            },
          ),
        ),
      ),
    );
  }
}
