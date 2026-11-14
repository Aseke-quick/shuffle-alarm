import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/design/components/notice_card.dart';
import 'package:shuffle_alarm/design/components/wide_button.dart';
import 'package:shuffle_alarm/features/alarms/arming.dart';
import 'package:shuffle_alarm/features/ringing/ringing_controller.dart';
import 'package:shuffle_alarm/l10n/texts.dart';

/// On the Alarms tab of the web version: the "Arm alarms" card while an
/// alarm is on or snoozed and its sound is locked, then the "Keep this tab
/// open" banner (task 2.4). Nothing on a platform that needs no tap.
class ArmCard extends ConsumerWidget {
  const ArmCard({required this.alarms, super.key});

  /// The alarms of the list.
  final List<Alarm> alarms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arming = ref.watch(armingProvider);
    final anyOn =
        alarms.any((alarm) => alarm.enabled) ||
        ref.watch(snoozedRingsProvider).isNotEmpty;
    if (!arming.needed || (!arming.armed && !anyOn)) {
      return const SizedBox.shrink();
    }
    if (!arming.armed) {
      return NoticeCard(
        icon: Icons.volume_up_outlined,
        title: tr.armToHear,
        message: arming.failed ? tr.browserBlockedSound : tr.armExplain,
        error: arming.failed,
        action: WideButton(
          label: tr.armAlarms,
          icon: Icons.alarm_on,
          onPressed: () => unawaited(ref.read(armingProvider.notifier).arm()),
        ),
      );
    }
    return NoticeCard(
      icon: Icons.alarm_on,
      title: tr.keepTabOpen,
      message: tr.keepTabOpenExplain,
      detail: !anyOn
          ? null
          : arming.screenOn
          ? tr.screenStaysOn
          : tr.screenMayTurnOff,
    );
  }
}
