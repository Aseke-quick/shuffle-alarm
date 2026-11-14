import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/core/bedtime.dart';
import 'package:shuffle_alarm/design/components/layout.dart';
import 'package:shuffle_alarm/design/components/notice_card.dart';
import 'package:shuffle_alarm/design/components/wide_button.dart';
import 'package:shuffle_alarm/design/tokens.dart';
import 'package:shuffle_alarm/features/alarms/alarm_texts.dart';
import 'package:shuffle_alarm/features/settings/bedtime_reminder.dart';
import 'package:shuffle_alarm/features/settings/settings_screen.dart';
import 'package:shuffle_alarm/l10n/texts.dart';
import 'package:shuffle_alarm/platform/system_notifications.dart';

/// Explains the bedtime reminder before the browser asks for the permission
/// (`CLAUDE.md`): the question comes only after a tap on "Turn on", and saying
/// no leaves the alarms as they are.
class BedtimeReminderScreen extends ConsumerStatefulWidget {
  const BedtimeReminderScreen({super.key});

  static const path = '/bedtime-reminder';

  @override
  ConsumerState<BedtimeReminderScreen> createState() =>
      _BedtimeReminderScreenState();
}

class _BedtimeReminderScreenState extends ConsumerState<BedtimeReminderScreen> {
  /// Whether the browser's question is open.
  var _asking = false;

  /// Whether the last question got no answer.
  var _noAnswer = false;

  Future<void> _turnOn() async {
    setState(() {
      _asking = true;
      _noAnswer = false;
    });
    // Still in the tap: a browser may ask only then.
    final access = await ref.read(bedtimeReminderProvider.notifier).turnOn();
    if (!mounted) return;
    if (access == NotificationAccess.allowed) return _leave();
    setState(() {
      _asking = false;
      _noAnswer = access == NotificationAccess.notAsked;
    });
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      // Opened by its address, such as after a reload.
      context.go(SettingsScreen.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(
      bedtimeReminderProvider.select((reminder) => reminder.access),
    );
    final theme = Theme.of(context);
    return PageScaffold(
      // A page about the night: the cool end of the color fields.
      warmth: 0.2,
      appBar: ContentAppBar(title: Text(tr.bedtimeReminder)),
      body: ContentWidth(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(Layout.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    container: true,
                    header: true,
                    child: Text(
                      tr.goToBedOnTime,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: Space.s8),
                  Semantics(
                    container: true,
                    child: Text(
                      tr.reminderExplain(sleepGoalText(defaultSleepGoal)),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: Space.s24),
                  if (access == NotificationAccess.notAsked)
                    _Point(
                      icon: Icons.notifications_outlined,
                      text: tr.browserWillAsk,
                    ),
                  _Point(icon: Icons.tab_outlined, text: tr.worksWhileTabOpen),
                ],
              ),
            ),
            if (access == NotificationAccess.unavailable)
              NoticeCard(
                icon: Icons.notifications_off_outlined,
                title: tr.notAvailableTitle,
                message: tr.notAvailableBody,
              )
            else if (access == NotificationAccess.blocked)
              NoticeCard(
                icon: Icons.notifications_off_outlined,
                title: tr.notificationsBlockedTitle,
                message: tr.notificationsBlockedBody,
                error: true,
              )
            else if (_noAnswer)
              NoticeCard(
                icon: Icons.notifications_outlined,
                title: tr.noAnswerTitle,
                message: tr.noAnswerBody,
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAction(
        child: access == NotificationAccess.unavailable
            ? WideButton.secondary(label: tr.back, onPressed: _leave)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WideButton(
                    label: _asking
                        ? tr.waitingForBrowser
                        : _noAnswer || access == NotificationAccess.blocked
                        ? tr.tryAgain
                        : tr.turnOn,
                    onPressed: _asking ? null : () => unawaited(_turnOn()),
                  ),
                  const SizedBox(height: Space.s8),
                  WideButton.secondary(label: tr.notNow, onPressed: _leave),
                ],
              ),
      ),
    );
  }
}

/// One thing to know, with an [icon].
class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Space.s16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: Icon(icon, color: c.textMuted)),
            const SizedBox(width: Space.s12),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
