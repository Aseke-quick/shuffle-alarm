import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/design/components/notice_card.dart';
import 'package:shuffle_alarm/design/components/wide_button.dart';
import 'package:shuffle_alarm/features/alarms/arming.dart';

/// On the Alarms tab of the web version: the "Arm alarms" card while an
/// alarm is on and its sound is locked, then the "Keep this tab open"
/// banner (task 2.4). Nothing on a platform that needs no tap.
class ArmCard extends ConsumerWidget {
  const ArmCard({required this.alarms, super.key});

  /// The alarms of the list.
  final List<Alarm> alarms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arming = ref.watch(armingProvider);
    final anyOn = alarms.any((alarm) => alarm.enabled);
    if (!arming.needed || (!arming.armed && !anyOn)) {
      return const SizedBox.shrink();
    }
    if (!arming.armed) {
      return NoticeCard(
        icon: Icons.volume_up_outlined,
        title: 'Arm alarms to hear them',
        message: arming.failed
            ? 'The browser did not let the sound play. Try again.'
            : 'Your browser plays sound only after a tap. Arm alarms, then '
                  'keep this tab open.',
        error: arming.failed,
        action: WideButton(
          label: 'Arm alarms',
          icon: Icons.alarm_on,
          onPressed: () => unawaited(ref.read(armingProvider.notifier).arm()),
        ),
      );
    }
    return NoticeCard(
      icon: Icons.alarm_on,
      title: 'Keep this tab open',
      message:
          'Alarms ring only while this tab is open. Keep the sound on and '
          'the device plugged in.',
      detail: !anyOn
          ? null
          : arming.screenOn
          ? 'The screen stays on.'
          : 'The screen may turn off. Keep this tab in front.',
    );
  }
}
