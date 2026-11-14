import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/bedtime.dart';
import 'package:shuffle_alarm/core/next_ring.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/design/components/layout.dart';
import 'package:shuffle_alarm/design/components/section_label.dart';
import 'package:shuffle_alarm/design/components/setting_switch_row.dart';
import 'package:shuffle_alarm/features/alarms/alarm_texts.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/ringing/morning_card.dart';
import 'package:shuffle_alarm/features/settings/bedtime_reminder.dart';
import 'package:shuffle_alarm/features/settings/bedtime_reminder_screen.dart';
import 'package:shuffle_alarm/platform/system_notifications.dart';

/// The Settings page. It opens above the tabs, so its app bar has a back
/// button.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const path = '/settings';

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      appBar: const ContentAppBar(title: Text('Settings')),
      body: ContentWidth(
        child: ListView(
          children: const [
            SectionLabel('Sleep'),
            _BedtimeReminderRow(),
            _MorningCardRow(),
          ],
        ),
      ),
    );
  }
}

/// The switch of the Morning card, which is on until the person turns it off.
class _MorningCardRow extends ConsumerWidget {
  const _MorningCardRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(morningCardOnProvider);
    return SettingSwitchRow(
      title: 'Morning card',
      description:
          'After Stop: when you woke, your snoozes, the sounds that played, '
          'and which one woke you.',
      status: on ? 'On' : 'Off',
      value: on,
      onChanged: (on) =>
          unawaited(ref.read(morningCardOnProvider.notifier).turn(on: on)),
    );
  }
}

/// The switch of the bedtime reminder. Turning it on opens the explanation
/// when the browser must ask first.
class _BedtimeReminderRow extends ConsumerWidget {
  const _BedtimeReminderRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminder = ref.watch(bedtimeReminderProvider);
    final controller = ref.read(bedtimeReminderProvider.notifier);
    final access = reminder.access;
    return SettingSwitchRow(
      title: 'Bedtime reminder',
      description:
          'One notification at the bedtime of your next alarm, while this tab '
          'is open.',
      status: switch (access) {
        NotificationAccess.unavailable => 'Not available on this device.',
        NotificationAccess.blocked =>
          'Your browser blocks notifications for this site.',
        _ when reminder.on => _nextReminder(context, ref),
        _ => 'Off',
      },
      value: reminder.on,
      onChanged: access == NotificationAccess.unavailable
          ? null
          : (on) {
              if (!on) {
                unawaited(controller.turnOff());
              } else if (access == NotificationAccess.allowed) {
                unawaited(controller.turnOn());
              } else {
                unawaited(context.push(BedtimeReminderScreen.path));
              }
            },
    );
  }

  /// When the reminder that is on comes next.
  String _nextReminder(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider);
    final next = soonestRing(ref.watch(alarmsProvider).value ?? const [], now);
    if (next == null) return 'No alarm is on';
    return nextReminderText(
      sleepAdvice(ring: next.ring, now: now),
      now: now,
      clock: (time) => TimeOfDay.fromDateTime(time).format(context),
    );
  }
}
