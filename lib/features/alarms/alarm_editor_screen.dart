import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/next_ring.dart';
import 'package:shuffle_alarm/data/ids.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/features/alarms/alarm_texts.dart';
import 'package:shuffle_alarm/features/alarms/alarm_writes.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/alarms/database_error_view.dart';

/// The page that adds an alarm or changes one: its time, repeat days, label
/// and genres. Save keeps the alarm and switches it on; the bin deletes it.
class AlarmEditorScreen extends ConsumerStatefulWidget {
  const AlarmEditorScreen({this.alarmId, super.key});

  /// Where a new alarm is made.
  static const newPath = '/alarms/new';

  /// Where the alarm with [id] is changed.
  static String pathFor(String id) => '/alarms/$id';

  /// The id of the alarm to change, or null for a new alarm.
  final String? alarmId;

  @override
  ConsumerState<AlarmEditorScreen> createState() => _AlarmEditorScreenState();
}

class _AlarmEditorScreenState extends ConsumerState<AlarmEditorScreen> {
  /// The alarm to change, as the list first had it. The page keeps it, so it
  /// does not turn into "no longer exists" while it closes after Delete.
  Alarm? _alarm;

  @override
  Widget build(BuildContext context) {
    final id = widget.alarmId;
    if (id == null || _alarm != null) return _AlarmForm(alarm: _alarm);
    switch (ref.watch(alarmsProvider)) {
      case AsyncValue(:final error?):
        return _Message(child: DatabaseErrorView(error: error));
      case AsyncValue(value: final alarms?):
        final alarm = alarms.where((alarm) => alarm.id == id).firstOrNull;
        if (alarm == null) {
          return const _Message(
            child: Center(child: Text('This alarm no longer exists.')),
          );
        }
        _alarm = alarm;
        return _AlarmForm(alarm: alarm);
      default:
        return const _Message(
          child: Center(child: CircularProgressIndicator()),
        );
    }
  }
}

/// The page while the alarm to change cannot be shown.
class _Message extends StatelessWidget {
  const _Message({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit alarm')),
      body: child,
    );
  }
}

class _AlarmForm extends ConsumerStatefulWidget {
  const _AlarmForm({this.alarm});

  /// The alarm to change, or null for a new one.
  final Alarm? alarm;

  @override
  ConsumerState<_AlarmForm> createState() => _AlarmFormState();
}

class _AlarmFormState extends ConsumerState<_AlarmForm> {
  /// The alarm as it was when the page opened, or a new one.
  late final Alarm _original;
  late ClockTime _time;
  late final Set<int> _days;
  late final Set<String> _genres;
  late final TextEditingController _label;

  /// Whether a save or a delete is under way.
  var _busy = false;

  bool get _isNew => widget.alarm == null;

  @override
  void initState() {
    super.initState();
    // A new alarm starts at the time now, as on Android and iOS.
    final now = ref.read(clockProvider);
    _original =
        widget.alarm ??
        Alarm(
          id: newId(),
          time: ClockTime(hour: now.hour, minute: now.minute),
        );
    _time = _original.time;
    _days = {..._original.repeatDays};
    _genres = {..._original.genres};
    _label = TextEditingController(text: _original.label);
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  /// The alarm as this page shows it, switched on.
  Alarm _edited() => _original.copyWith(
    time: _time,
    repeatDays: _days,
    label: _label.text.trim(),
    genres: _genres,
    enabled: true,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = ref.watch(clockProvider);
    final time = TimeOfDay(hour: _time.hour, minute: _time.minute);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New alarm' : 'Edit alarm'),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: 'Delete alarm',
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy ? null : _delete,
            ),
          TextButton(
            onPressed: _busy ? null : _save,
            child: const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Tooltip(
              message: 'Change the time',
              child: TextButton(
                onPressed: _pickTime,
                child: Text(
                  time.format(context),
                  style: theme.textTheme.displayMedium,
                ),
              ),
            ),
          ),
          Text(
            // Switched on, so it has a next ring.
            ringsIn(nextRing(_edited(), now)!.difference(now)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text('Repeat', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var day = DateTime.monday; day <= DateTime.sunday; day++)
                FilterChip(
                  label: Text(dayName(day)),
                  selected: _days.contains(day),
                  onSelected: (selected) => setState(() {
                    selected ? _days.add(day) : _days.remove(day);
                  }),
                ),
            ],
          ),
          if (_days.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'No days chosen, so it rings once.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          TextField(
            controller: _label,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Label',
              hintText: 'For example: Gym',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Text('Genres', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _GenreChoice(
            chosen: _genres,
            onChanged: (genre, {required chosen}) => setState(() {
              chosen ? _genres.add(genre) : _genres.remove(genre);
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _time.hour, minute: _time.minute),
    );
    if (picked == null || !mounted) return;
    setState(() => _time = ClockTime(hour: picked.hour, minute: picked.minute));
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final saved = await saveAlarm(context, ref, _edited());
    if (!mounted) return;
    if (saved) {
      context.pop();
    } else {
      setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this alarm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    setState(() => _busy = true);
    final deleted = await deleteAlarm(context, ref, _original.id);
    if (!mounted) return;
    if (deleted) {
      context.pop();
    } else {
      setState(() => _busy = false);
    }
  }
}

/// The genres of the library, to choose those an alarm plays.
class _GenreChoice extends ConsumerWidget {
  const _GenreChoice({required this.chosen, required this.onChanged});

  final Set<String> chosen;
  final void Function(String genre, {required bool chosen}) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(genresProvider).value ?? const <String>[];
    // Also a chosen genre the library no longer has, so it can be taken off.
    final genres = {...library, ...chosen}.toList()..sort();
    final hint = Theme.of(context).textTheme.bodySmall;
    if (genres.isEmpty) {
      return Text(
        'The library has no genres yet, so this alarm plays every sound.',
        style: hint,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final genre in genres)
              FilterChip(
                label: Text(genreName(genre)),
                selected: chosen.contains(genre),
                onSelected: (selected) => onChanged(genre, chosen: selected),
              ),
          ],
        ),
        if (chosen.isEmpty) ...[
          const SizedBox(height: 8),
          Text('None chosen, so it plays every genre.', style: hint),
        ],
      ],
    );
  }
}
