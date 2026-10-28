import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/next_ring.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/features/alarms/alarm_editor_screen.dart';
import 'package:shuffle_alarm/features/alarms/alarm_texts.dart';
import 'package:shuffle_alarm/features/alarms/alarm_writes.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/alarms/database_error_view.dart';
import 'package:shuffle_alarm/features/settings/settings_button.dart';

/// The Alarms tab: every alarm by time of day, with its switch and when it
/// rings next. The + button adds an alarm; tapping one changes it.
class AlarmsScreen extends ConsumerWidget {
  const AlarmsScreen({super.key});

  static const path = '/alarms';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarms = ref.watch(alarmsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarms'),
        actions: const [SettingsButton()],
      ),
      body: switch (alarms) {
        // Also while Riverpod tries again, so the error stays in sight.
        AsyncValue(:final error?) => DatabaseErrorView(error: error),
        AsyncValue(value: final alarms?) when alarms.isEmpty =>
          const _NoAlarms(),
        AsyncValue(value: final alarms?) => _AlarmList(alarms: alarms),
        _ => const Center(child: CircularProgressIndicator()),
      },
      // Only once the alarms are there: without the database, a new alarm
      // could not be saved.
      floatingActionButton: alarms.hasValue && !alarms.hasError
          ? FloatingActionButton(
              tooltip: 'Add alarm',
              onPressed: () => context.push(AlarmEditorScreen.newPath),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _NoAlarms extends StatelessWidget {
  const _NoAlarms();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('No alarms yet.'),
          SizedBox(height: 8),
          Text('Tap + to add one.'),
        ],
      ),
    );
  }
}

class _AlarmList extends StatelessWidget {
  const _AlarmList({required this.alarms});

  final List<Alarm> alarms;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      // Room for the + button below the last alarm.
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: alarms.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) => AlarmTile(alarm: alarms[index]),
    );
  }
}

/// One alarm in the list: its time, label, repeat days, when it rings next
/// and its switch.
class AlarmTile extends ConsumerWidget {
  const AlarmTile({required this.alarm, super.key});

  final Alarm alarm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider);
    final ring = nextRing(alarm, now);
    final theme = Theme.of(context);
    final time = TimeOfDay(hour: alarm.time.hour, minute: alarm.time.minute);
    final about = [
      if (alarm.label.isNotEmpty) alarm.label,
      repeatText(alarm.repeatDays),
    ].join(' · ');
    return ListTile(
      isThreeLine: true,
      onTap: () => context.push(AlarmEditorScreen.pathFor(alarm.id)),
      title: Text(
        time.format(context),
        style: theme.textTheme.headlineMedium?.copyWith(
          color: alarm.enabled ? null : theme.disabledColor,
        ),
      ),
      subtitle: Text(
        '$about\n${ring == null ? 'Off' : ringsIn(ring.difference(now))}',
      ),
      trailing: Semantics(
        label: '${time.format(context)} alarm',
        child: Switch(
          value: alarm.enabled,
          onChanged: (enabled) =>
              saveAlarm(context, ref, alarm.copyWith(enabled: enabled)),
        ),
      ),
    );
  }
}
