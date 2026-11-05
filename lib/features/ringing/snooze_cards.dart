import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/notice_card.dart';
import 'package:shuffle_alarm/design/components/wide_button.dart';
import 'package:shuffle_alarm/features/ringing/morning_card.dart';
import 'package:shuffle_alarm/features/ringing/morning_card_screen.dart';
import 'package:shuffle_alarm/features/ringing/ringing_controller.dart';

/// On the Alarms tab: a card for each alarm that was snoozed, which says when
/// it comes back and can end the snooze. Nothing without a snooze.
class SnoozeCards extends ConsumerWidget {
  const SnoozeCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snoozed = ref.watch(snoozedRingsProvider);
    String name(SnoozedRing ring) {
      final label = ring.due.alarm.label;
      return label.isEmpty ? 'The alarm' : label;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final ring in snoozed)
          NoticeCard(
            icon: Icons.snooze,
            title:
                'Snoozed until '
                '${TimeOfDay.fromDateTime(ring.due.startsAt).format(context)}',
            message: '${name(ring)} rings again then, while this tab is open.',
            action: WideButton.secondary(
              label: 'Stop alarm',
              onPressed: () {
                ref.read(ringingProvider.notifier).stopSnoozed(ring);
                if (ref.read(morningCardProvider) != null) {
                  unawaited(context.push(MorningCardScreen.path));
                }
              },
            ),
          ),
      ],
    );
  }
}
