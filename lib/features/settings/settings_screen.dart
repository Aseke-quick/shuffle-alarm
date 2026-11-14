import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/core/bedtime.dart';
import 'package:shuffle_alarm/core/next_ring.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/design/components/glass_card.dart';
import 'package:shuffle_alarm/design/components/layout.dart';
import 'package:shuffle_alarm/design/components/section_label.dart';
import 'package:shuffle_alarm/design/components/setting_switch_row.dart';
import 'package:shuffle_alarm/design/tokens.dart';
import 'package:shuffle_alarm/features/alarms/alarm_texts.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/ringing/morning_card.dart';
import 'package:shuffle_alarm/features/settings/bedtime_reminder.dart';
import 'package:shuffle_alarm/features/settings/bedtime_reminder_screen.dart';
import 'package:shuffle_alarm/features/settings/language.dart';
import 'package:shuffle_alarm/l10n/texts.dart';
import 'package:shuffle_alarm/platform/system_notifications.dart';

/// The Settings page. It opens above the tabs, so its app bar has a back
/// button.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const path = '/settings';

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      appBar: ContentAppBar(title: Text(tr.settings)),
      body: ContentWidth(
        child: ListView(
          children: [
            SectionLabel(tr.sleep),
            const _BedtimeReminderRow(),
            const _MorningCardRow(),
            SectionLabel(tr.language),
            const _LanguageRow(),
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
      title: tr.morningCard,
      description: tr.morningCardDescription,
      status: on ? tr.on : tr.off,
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
      title: tr.bedtimeReminder,
      description: tr.bedtimeReminderDescription,
      status: switch (access) {
        NotificationAccess.unavailable => tr.notAvailableOnDevice,
        NotificationAccess.blocked => tr.browserBlocksNotifications,
        _ when reminder.on => _nextReminder(context, ref),
        _ => tr.off,
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
    final next = soonestRing(ref.watch(alarmsProvider).value ?? [], now);
    if (next == null) return tr.noAlarmIsOn;
    return nextReminderText(
      sleepAdvice(ring: next.ring, now: now),
      now: now,
      clock: (time) => TimeOfDay.fromDateTime(time).format(context),
    );
  }
}

/// The language of the app: the chosen one, and a tap opens the list.
class _LanguageRow extends ConsumerWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    final chosen = ref.watch(languageProvider)?.languageCode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Layout.gutter,
        0,
        Layout.gutter,
        Space.s12,
      ),
      child: GlassCard(
        onTap: () => unawaited(_choose(context, ref, chosen)),
        child: Row(
          children: [
            ExcludeSemantics(child: Icon(Icons.language, color: c.textMuted)),
            const SizedBox(width: Space.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languageNames[chosen] ?? tr.languageOfDevice,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: Space.s4),
                  Text(
                    tr.languageDescription,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            ExcludeSemantics(
              child: Icon(Icons.chevron_right, color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the list of languages, and takes the one that is tapped.
  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    String? chosen,
  ) async {
    final setting = ref.read(languageProvider.notifier);
    // An empty code stands for the device's language: null means no choice.
    final code = await showDialog<String>(
      context: context,
      animationStyle: Motion.styleOf(context),
      builder: (context) => SimpleDialog(
        title: Text(tr.language),
        children: [
          for (final (code, name) in [
            ('', tr.languageOfDevice),
            for (final language in languageNames.entries)
              (language.key, language.value),
          ])
            ListTile(
              title: Text(name),
              selected: code == (chosen ?? ''),
              trailing: code == (chosen ?? '') ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop(code),
            ),
        ],
      ),
    );
    if (code == null) return;
    await setting.choose(code.isEmpty ? null : code);
  }
}
