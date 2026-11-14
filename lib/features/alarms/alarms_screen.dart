import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/bedtime.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/next_ring.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/design/components/alarm_track_row.dart';
import 'package:shuffle_alarm/design/components/enter_motion.dart';
import 'package:shuffle_alarm/design/components/info_tile.dart';
import 'package:shuffle_alarm/design/components/layout.dart';
import 'package:shuffle_alarm/design/components/mix_bars.dart';
import 'package:shuffle_alarm/design/components/next_alarm_card.dart';
import 'package:shuffle_alarm/design/components/section_label.dart';
import 'package:shuffle_alarm/design/components/wide_button.dart';
import 'package:shuffle_alarm/design/components/wordmark.dart';
import 'package:shuffle_alarm/design/tokens.dart';
import 'package:shuffle_alarm/features/alarms/alarm_editor_screen.dart';
import 'package:shuffle_alarm/features/alarms/alarm_texts.dart';
import 'package:shuffle_alarm/features/alarms/alarm_writes.dart';
import 'package:shuffle_alarm/features/alarms/arm_card.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/alarms/database_error_view.dart';
import 'package:shuffle_alarm/features/alarms/tonight_mix.dart';
import 'package:shuffle_alarm/features/alarms/tonight_mix_screen.dart';
import 'package:shuffle_alarm/features/ringing/snooze_cards.dart';
import 'package:shuffle_alarm/features/settings/settings_button.dart';
import 'package:shuffle_alarm/l10n/texts.dart';

/// The Alarms tab: the next alarm as a big card with its mix and bedtime,
/// every alarm by time of day, and the New alarm button. Tapping an alarm
/// changes it. Two columns on a wide screen (ADR-005).
class AlarmsScreen extends ConsumerWidget {
  const AlarmsScreen({super.key});

  static const path = '/alarms';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarms = ref.watch(alarmsProvider);
    return TabPage(
      title: const Wordmark(),
      actions: const [SettingsButton()],
      body: switch (alarms) {
        // Also while Riverpod tries again, so the error stays in sight.
        AsyncValue(:final error?) => DatabaseErrorView(error: error),
        AsyncValue(value: final alarms?) => _Alarms(alarms: alarms),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Alarms extends StatelessWidget {
  const _Alarms({required this.alarms});

  final List<Alarm> alarms;

  @override
  Widget build(BuildContext context) {
    // Only once the alarms are there: without the database, a new alarm
    // could not be saved.
    void newAlarm() => unawaited(context.push(AlarmEditorScreen.newPath));
    if (Layout.isWide(context)) {
      return ContentWidth(
        wide: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: Space.s8),
                children: [_NextAlarm(alarms: alarms)],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _Tracklist(
                    alarms: alarms,
                    action: FilledButton.icon(
                      onPressed: newAlarm,
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(tr.newAlarm),
                    ),
                    notices: [
                      const SnoozeCards(),
                      ArmCard(alarms: alarms),
                    ],
                  ),
                  const SizedBox(height: Space.s16),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ContentWidth(
            child: ListView(
              children: [
                const SnoozeCards(),
                ArmCard(alarms: alarms),
                _NextAlarm(alarms: alarms),
                _Tracklist(alarms: alarms),
                const SizedBox(height: Space.s16),
              ],
            ),
          ),
        ),
        BottomAction(
          child: WideButton(
            label: tr.newAlarm,
            icon: Icons.add,
            onPressed: newAlarm,
          ),
        ),
      ],
    );
  }
}

/// The card of the alarm that rings next, with its mix and when to go to bed
/// for it; a card that says so when no alarm is on.
class _NextAlarm extends ConsumerWidget {
  const _NextAlarm({required this.alarms});

  final List<Alarm> alarms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const gutter = EdgeInsets.fromLTRB(
      Layout.gutter,
      Space.s8,
      Layout.gutter,
      0,
    );
    final now = ref.watch(clockProvider);
    final next = soonestRing(alarms, now);
    if (next == null) {
      return Padding(
        padding: gutter,
        child: NextAlarmCard(
          tagLabel: tr.nextAlarm,
          title: tr.noAlarmSet,
          note: alarms.isEmpty ? tr.tapNewAlarm : null,
          semanticsLabel: alarms.isEmpty
              ? '${tr.noAlarmSet}\n${tr.tapNewAlarm}'
              : tr.noAlarmSet,
        ),
      );
    }
    final (:alarm, :ring) = next;
    final time = TimeOfDay(hour: alarm.time.hour, minute: alarm.time.minute);
    final countdown = countdownText(ring.difference(now));
    // Only the mix of this ring: another one may still show for a moment.
    final mix = ref
        .watch(tonightMixProvider)
        .value
        ?.takeIf(alarm: alarm, ring: ring);
    final sounds = mix?.round.length;
    void openMix() => unawaited(context.push(TonightMixScreen.path));
    final bedtime = InfoTile(
      label: tr.bedtime,
      icon: Icons.bedtime_outlined,
      text: sleepText(
        sleepAdvice(ring: ring, now: now),
        now: now,
        clock: (time) => TimeOfDay.fromDateTime(time).format(context),
      ),
    );
    return Padding(
      padding: gutter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NextAlarmCard(
            tagLabel: tr.nextAlarm,
            time: time,
            countdown: countdown,
            details: alarmDetails(alarm),
            onTap: mix == null ? null : openMix,
            semanticsLabel: [
              tr.nextAlarmAt(time.format(context), countdown),
              if (sounds != null) tr.tonightsMixWith(soundCount(sounds)),
            ].join('. '),
          ),
          const SizedBox(height: Space.s12),
          if (mix == null || sounds == null)
            bedtime
          else
            // The card above says it all to a screen reader and a keyboard.
            LayoutBuilder(
              builder: (context, constraints) {
                final mixTile = ExcludeSemantics(
                  child: InfoTile(
                    label: mixCaption(sounds),
                    icon: Icons.arrow_outward,
                    onTap: openMix,
                    child: MixBars(segments: mixSegmentsOf(mix.round)),
                  ),
                );
                // Side by side where both fit, also with large text.
                final scale = MediaQuery.textScalerOf(context).scale(1);
                if (constraints.maxWidth < 420 * scale) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      mixTile,
                      const SizedBox(height: Space.s12),
                      bedtime,
                    ],
                  );
                }
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 5, child: mixTile),
                      const SizedBox(width: Space.s12),
                      Expanded(flex: 4, child: bedtime),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// "All alarms" and every alarm, by time of day; nothing without alarms,
/// unless it has an [action] to show. An alarm that comes in while the list
/// is open, such as one just added, moves in.
class _Tracklist extends StatefulWidget {
  const _Tracklist({
    required this.alarms,
    this.action,
    this.notices = const [],
  });

  final List<Alarm> alarms;

  /// At the end of the title, such as the New alarm button of a wide page.
  final Widget? action;

  /// Between the title and the alarms, such as "Arm alarms".
  final List<Widget> notices;

  @override
  State<_Tracklist> createState() => _TracklistState();
}

class _TracklistState extends State<_Tracklist> {
  /// The ids of the alarms shown so far.
  late final Set<String> _shown;

  /// The ids of the alarms that came in after the list first showed.
  final _added = <String>{};

  @override
  void initState() {
    super.initState();
    _shown = {for (final alarm in widget.alarms) alarm.id};
  }

  @override
  void didUpdateWidget(_Tracklist oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final alarm in widget.alarms) {
      if (_shown.add(alarm.id)) _added.add(alarm.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alarms = widget.alarms;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (alarms.isNotEmpty || widget.action != null)
          SectionLabel(
            tr.allAlarms,
            trailing: alarms.isEmpty ? null : '${alarms.length}',
            action: widget.action,
          ),
        ...widget.notices,
        if (widget.notices.isNotEmpty) const SizedBox(height: Space.s8),
        for (final alarm in alarms)
          EnterMotion(
            key: ValueKey(alarm.id),
            animate: _added.contains(alarm.id),
            child: AlarmTile(alarm: alarm),
          ),
      ],
    );
  }
}

/// One alarm in the list: its time, label and repeat days, when it rings
/// next, and its switch.
class AlarmTile extends ConsumerWidget {
  const AlarmTile({required this.alarm, super.key});

  final Alarm alarm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider);
    final ring = nextRing(alarm, now);
    final time = TimeOfDay(hour: alarm.time.hour, minute: alarm.time.minute);
    return AlarmTrackRow(
      time: time,
      details: alarmDetails(alarm),
      status: ring == null ? tr.off : ringsIn(ring.difference(now)),
      enabled: alarm.enabled,
      waveformSeed: alarm.id,
      switchLabel: tr.alarmAt(time.format(context)),
      onTap: () => unawaited(context.push(AlarmEditorScreen.pathFor(alarm.id))),
      onEnabledChanged: (enabled) =>
          saveAlarm(context, ref, alarm.copyWith(enabled: enabled)),
    );
  }
}
