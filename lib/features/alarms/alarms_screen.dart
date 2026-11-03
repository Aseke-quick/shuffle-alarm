import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/bedtime.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/next_ring.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/design/components/alarm_track_row.dart';
import 'package:shuffle_alarm/design/components/enter_motion.dart';
import 'package:shuffle_alarm/design/components/layout.dart';
import 'package:shuffle_alarm/design/components/record.dart';
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

/// The Alarms tab: the next alarm as a record, every alarm by time of day
/// below it, and the New alarm button. Tapping an alarm changes it.
class AlarmsScreen extends ConsumerWidget {
  const AlarmsScreen({super.key});

  static const path = '/alarms';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarms = ref.watch(alarmsProvider);
    return Scaffold(
      appBar: const ContentAppBar(
        title: Wordmark(),
        actions: [SettingsButton()],
      ),
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
        // Only once the alarms are there: without the database, a new alarm
        // could not be saved.
        BottomAction(
          child: WideButton(
            label: 'New alarm',
            icon: Icons.add,
            onPressed: () => context.push(AlarmEditorScreen.newPath),
          ),
        ),
      ],
    );
  }
}

/// The record of the alarm that rings next, with when it rings and when to
/// go to bed for it; an empty record when no alarm is on.
class _NextAlarm extends ConsumerWidget {
  const _NextAlarm({required this.alarms});

  final List<Alarm> alarms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider);
    final next = soonestRing(alarms, now);
    if (next == null) {
      return RecordHero(
        title: 'No alarm set',
        note: alarms.isEmpty ? 'Tap New alarm to set one.' : null,
        semanticsLabel: 'No alarm set',
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
    return RecordHero(
      time: time,
      countdown: countdown,
      segments: mix == null ? const [] : recordSegmentsOf(mix.round),
      mixLabel: sounds == null ? null : mixCaption(sounds),
      onTap: mix == null ? null : () => context.push(TonightMixScreen.path),
      details: alarmDetails(alarm),
      note: sleepText(
        sleepAdvice(ring: ring, now: now),
        now: now,
        clock: (time) => TimeOfDay.fromDateTime(time).format(context),
      ),
      semanticsLabel:
          'Next alarm ${time.format(context)}, $countdown'
          '${sounds == null ? '' : ". Tonight's mix, ${soundCount(sounds)}"}',
    );
  }
}

/// "All alarms" and every alarm, by time of day; nothing without alarms.
/// An alarm that comes in while the list is open, such as one just added,
/// moves in.
class _Tracklist extends StatefulWidget {
  const _Tracklist({required this.alarms});

  final List<Alarm> alarms;

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
      children: [
        if (alarms.isNotEmpty)
          SectionLabel('All alarms', trailing: '${alarms.length}'),
        for (final (index, alarm) in alarms.indexed) ...[
          if (index > 0)
            const Divider(indent: Layout.gutter, endIndent: Layout.gutter),
          EnterMotion(
            key: ValueKey(alarm.id),
            animate: _added.contains(alarm.id),
            child: AlarmTile(alarm: alarm),
          ),
        ],
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
      status: ring == null ? 'Off' : ringsIn(ring.difference(now)),
      enabled: alarm.enabled,
      waveformSeed: alarm.id,
      switchLabel: '${time.format(context)} alarm',
      onTap: () => context.push(AlarmEditorScreen.pathFor(alarm.id)),
      onEnabledChanged: (enabled) =>
          saveAlarm(context, ref, alarm.copyWith(enabled: enabled)),
    );
  }
}
