import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/bedtime.dart';
import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/next_ring.dart';
import 'package:shuffle_alarm/data/ids.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/design/components/day_keys.dart';
import 'package:shuffle_alarm/design/components/glass_card.dart';
import 'package:shuffle_alarm/design/components/layout.dart';
import 'package:shuffle_alarm/design/components/section_label.dart';
import 'package:shuffle_alarm/design/components/status_view.dart';
import 'package:shuffle_alarm/design/components/time_wheels.dart';
import 'package:shuffle_alarm/design/components/wide_button.dart';
import 'package:shuffle_alarm/design/tokens.dart';
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
            child: StatusView(title: 'This alarm no longer exists.'),
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
    return PageScaffold(
      appBar: const ContentAppBar(title: Text('Edit alarm')),
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

  /// How warm the page is for [time]: warmest in the morning, coolest at
  /// night, so the page says what kind of hour the wheels show.
  static double _warmth(ClockTime time) {
    final hours = time.hour + time.minute / TimeOfDay.minutesPerHour;
    final fromMorning = (hours - 7.5).abs();
    final away = fromMorning > 12 ? 24 - fromMorning : fromMorning;
    return (1 - away / 9).clamp(0.1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    final hint = theme.textTheme.bodySmall!.copyWith(color: c.textMuted);
    final now = ref.watch(clockProvider);
    // Switched on, so it has a next ring.
    final ring = nextRing(_edited(), now)!;
    const gutter = EdgeInsets.symmetric(horizontal: Layout.gutter);
    final wide = Layout.isWide(context);
    final save = WideButton(
      label: 'Save alarm',
      onPressed: _busy ? null : _save,
    );
    final time = [
      Padding(
        padding: gutter,
        child: GlassCard(
          radius: Corners.hero,
          padding: const EdgeInsets.symmetric(
            horizontal: Space.s8,
            vertical: Space.s16,
          ),
          child: Column(
            children: [
              TimeWheels(
                time: TimeOfDay(hour: _time.hour, minute: _time.minute),
                onChanged: (time) => setState(
                  () => _time = ClockTime(hour: time.hour, minute: time.minute),
                ),
              ),
              const SizedBox(height: Space.s12),
              Text(
                ringsIn(ring.difference(now)),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium!.copyWith(
                  color: c.accentText,
                ),
              ),
              const SizedBox(height: Space.s4),
              Text(
                sleepText(
                  sleepAdvice(ring: ring, now: now),
                  now: now,
                  clock: (time) => TimeOfDay.fromDateTime(time).format(context),
                ),
                textAlign: TextAlign.center,
                style: hint,
              ),
            ],
          ),
        ),
      ),
    ];
    final form = [
      const SectionLabel('Repeat'),
      // Narrower margins: on a phone 360 px wide, each key keeps
      // a touch target of 48 dp.
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.s12),
        child: DayKeys(
          selected: _days,
          label: dayName,
          semanticsLabel: fullDayName,
          onChanged: (day, {required selected}) => setState(() {
            selected ? _days.add(day) : _days.remove(day);
          }),
        ),
      ),
      if (_days.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Layout.gutter,
            Space.s8,
            Layout.gutter,
            0,
          ),
          child: Text('No days chosen, so it rings once.', style: hint),
        ),
      const SizedBox(height: Space.s24),
      Padding(
        padding: gutter,
        child: TextField(
          controller: _label,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Label',
            hintText: 'For example: Gym',
          ),
        ),
      ),
      const SectionLabel('Genres'),
      Padding(
        padding: gutter,
        child: _GenreChoice(
          chosen: _genres,
          onChanged: (genre, {required chosen}) => setState(() {
            chosen ? _genres.add(genre) : _genres.remove(genre);
          }),
        ),
      ),
      const SizedBox(height: Space.s24),
    ];
    return PageScaffold(
      warmth: _warmth(_time),
      appBar: ContentAppBar(
        wide: wide,
        title: Text(_isNew ? 'New alarm' : 'Edit alarm'),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: 'Delete alarm',
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
      body: wide
          ? ContentWidth(
              wide: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(top: Space.s8),
                      children: time,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        ...form,
                        Padding(padding: gutter, child: save),
                        const SizedBox(height: Space.s24),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ContentWidth(
                    child: ListView(
                      padding: const EdgeInsets.only(top: Space.s8),
                      children: [...time, ...form],
                    ),
                  ),
                ),
                BottomAction(child: save),
              ],
            ),
    );
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
    final danger = WakemixColors.of(context).danger;
    final sure = await showDialog<bool>(
      context: context,
      animationStyle: Motion.styleOf(context),
      builder: (context) => AlertDialog(
        title: const Text('Delete this alarm?'),
        content: const Text('It will not ring again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: danger),
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
    final hint = Theme.of(context).textTheme.bodySmall!
        .copyWith(color: WakemixColors.of(context).textMuted);
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
          spacing: Space.s8,
          runSpacing: Space.s8,
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
          const SizedBox(height: Space.s8),
          Text('None chosen, so it plays every genre.', style: hint),
        ],
      ],
    );
  }
}
