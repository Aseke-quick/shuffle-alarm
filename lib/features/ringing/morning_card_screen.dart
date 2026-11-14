import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/escalation.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/core/morning.dart';
import 'package:shuffle_alarm/design/components/glass_card.dart';
import 'package:shuffle_alarm/design/components/layout.dart';
import 'package:shuffle_alarm/design/components/mix_bars.dart';
import 'package:shuffle_alarm/design/components/mix_track_row.dart';
import 'package:shuffle_alarm/design/components/time_text.dart';
import 'package:shuffle_alarm/design/components/wide_button.dart';
import 'package:shuffle_alarm/design/theme.dart';
import 'package:shuffle_alarm/design/tokens.dart';
import 'package:shuffle_alarm/features/alarms/alarm_texts.dart';
import 'package:shuffle_alarm/features/alarms/alarms_screen.dart';
import 'package:shuffle_alarm/features/alarms/arming.dart';
import 'package:shuffle_alarm/features/alarms/mix_preview.dart';
import 'package:shuffle_alarm/features/ringing/morning_card.dart';
import 'package:shuffle_alarm/features/ringing/ringing_controller.dart';
import 'package:shuffle_alarm/platform/providers.dart';

/// The Morning card (task 2.5b): after Stop, when the user woke, how long after
/// the alarm, the snoozes and the sounds that played, with one question: which
/// sound woke you? One tap answers and closes it. A ring that comes due takes
/// its place.
class MorningCardScreen extends ConsumerStatefulWidget {
  const MorningCardScreen({super.key});

  static const path = '/morning';

  @override
  ConsumerState<MorningCardScreen> createState() => _MorningCardScreenState();
}

class _MorningCardScreenState extends ConsumerState<MorningCardScreen> {
  /// Read when the page opens: it cannot use `ref` while it closes.
  late final MixPreviewController _preview;

  /// The card it shows: the last one, so nothing jumps while the page closes.
  RingSession? _shown;

  @override
  void initState() {
    super.initState();
    _preview = ref.read(mixPreviewProvider.notifier);
  }

  @override
  void dispose() {
    // After the frame: a provider must not change while the tree is built.
    unawaited(Future.microtask(_preview.stop));
    super.dispose();
  }

  /// Goes back to the page below. A ring that has taken over stays: the page it
  /// replaced is no longer in the stack, and the router keeps its address.
  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AlarmsScreen.path);
    }
  }

  /// Keeps the answer: the id of a sound, or null for "Not sure".
  void _answer(String? soundId) {
    final open = ref.read(morningCardProvider) != null;
    unawaited(_preview.stop());
    ref.read(ringingProvider.notifier).answerMorning(soundId);
    if (open && soundId != null) _say('Thanks. Wakemix will remember that.');
    _leave();
  }

  Future<void> _togglePreview(MorningCardSound row) async {
    final outcome = await _preview.toggle(
      row.sound,
      audioPath: row.audioPath!,
      // Gently: to know the sound again, not to wake anyone.
      volume: Escalation.volumes.first,
    );
    final message = previewProblem(outcome);
    if (message != null && mounted) _say(message);
  }

  /// A message at the bottom of the screen, which also outlives the page.
  void _say(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
    snackBarAnimationStyle: Motion.styleOf(context),
  );

  @override
  Widget build(BuildContext context) {
    final session = _shown = ref.watch(morningCardProvider) ?? _shown;
    final morning = session == null ? null : Morning.of(session);
    return PageScaffold(
      // A morning page: the warm end of the color fields.
      warmth: 0.85,
      appBar: const ContentAppBar(title: Text('Morning card')),
      body: session == null || morning == null
          ? const SizedBox.shrink()
          : _Card(
              alarmAt: session.scheduledFor,
              morning: morning,
              onAnswer: _answer,
              onPreview: (row) => unawaited(_togglePreview(row)),
              onDone: _leave,
            ),
    );
  }
}

class _Card extends ConsumerWidget {
  const _Card({
    required this.alarmAt,
    required this.morning,
    required this.onAnswer,
    required this.onPreview,
    required this.onDone,
  });

  /// When the alarm was set to ring.
  final DateTime alarmAt;
  final Morning morning;
  final ValueChanged<String?> onAnswer;
  final ValueChanged<MorningCardSound> onPreview;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = WakemixType.of(context);
    final stored = ref.watch(morningSoundsProvider).value;
    // Null while they load: the question already shows, and can be left.
    final rows = stored == null ? null : morningCardSounds(morning, stored);
    final asks = morning.sounds.isNotEmpty && (rows == null || rows.isNotEmpty);
    return Column(
      children: [
        Expanded(
          child: ContentWidth(
            child: ListView(
              children: [
                _Header(
                  alarmAt: alarmAt,
                  morning: morning,
                  segments: morningMixSegments(rows ?? const []),
                ),
                const SizedBox(height: Space.s24),
                if (morning.sounds.isEmpty) const _NoSound(),
                if (asks) ...[
                  const _Question(),
                  _Sounds(
                    rows: rows ?? const [],
                    onAnswer: onAnswer,
                    onPreview: onPreview,
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Layout.gutter,
                    Space.s16,
                    Layout.gutter,
                    Space.s16,
                  ),
                  child: Text(
                    'You can turn this card off in Settings.',
                    style: type.meta,
                  ),
                ),
              ],
            ),
          ),
        ),
        BottomAction(
          child: asks
              ? WideButton.secondary(
                  label: 'Not sure',
                  onPressed: () => onAnswer(null),
                )
              : WideButton(label: 'Done', onPressed: onDone),
        ),
      ],
    );
  }
}

/// When the user woke, as a glass card: the time big, how long after the
/// alarm, the snoozes and sounds, and the sounds that played as bars.
class _Header extends StatelessWidget {
  const _Header({
    required this.alarmAt,
    required this.morning,
    required this.segments,
  });

  final DateTime alarmAt;
  final Morning morning;
  final List<MixSegment> segments;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    final type = WakemixType.of(context);
    final alarmTime = TimeOfDay.fromDateTime(alarmAt.toLocal()).format(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Layout.gutter,
        Space.s8,
        Layout.gutter,
        0,
      ),
      child: GlassCard(
        radius: Corners.hero,
        padding: const EdgeInsets.all(Space.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You woke at', style: type.caption),
            const SizedBox(height: Space.s4),
            TimeText(
              TimeOfDay.fromDateTime(morning.wokeAt.toLocal()),
              style: theme.textTheme.displaySmall!,
            ),
            const SizedBox(height: Space.s4),
            Text(
              wokeAfterText(morning.afterAlarm, alarmTime: alarmTime),
              style: theme.textTheme.bodyMedium!.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: Space.s4),
            Text(
              morningFacts(
                snoozes: morning.snoozes,
                sounds: morning.sounds.length,
              ),
              style: type.meta,
            ),
            if (segments.isNotEmpty) ...[
              const SizedBox(height: Space.s16),
              ExcludeSemantics(child: MixBars(segments: segments)),
            ],
          ],
        ),
      ),
    );
  }
}

/// The question, and what its answer does.
class _Question extends StatelessWidget {
  const _Question();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Layout.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Which sound woke you?',
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: Space.s4),
          Text(
            'It will tend to come earlier in your next mixes.',
            style: WakemixType.of(context).meta,
          ),
          const SizedBox(height: Space.s8),
        ],
      ),
    );
  }
}

/// The sounds that played, each with a preview and its answer.
class _Sounds extends ConsumerWidget {
  const _Sounds({
    required this.rows,
    required this.onAnswer,
    required this.onPreview,
  });

  final List<MorningCardSound> rows;
  final ValueChanged<String?> onAnswer;
  final ValueChanged<MorningCardSound> onPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(mixPreviewProvider);
    final hasPreview = ref.watch(soundPlayerProvider).playsSounds;
    return Column(
      children: [
        for (final (index, row) in rows.indexed) ...[
          if (index > 0)
            const Divider(indent: Layout.gutter, endIndent: Layout.gutter),
          _row(row, preview, hasPreview: hasPreview),
        ],
      ],
    );
  }

  Widget _row(
    MorningCardSound row,
    MixPreview? preview, {
    required bool hasPreview,
  }) {
    final sound = row.sound;
    final playing = preview?.soundId == sound.id;
    return MixTrackRow(
      key: ValueKey(sound.id),
      title: sound.title,
      details: '${clipStartText(row.played.firstAt)} · ${soundDetails(sound)}',
      preview: !playing
          ? MixRowPreview.idle
          : preview!.loading
          ? MixRowPreview.loading
          : MixRowPreview.playing,
      previewLabel: playing ? 'Stop preview' : 'Preview ${sound.title}',
      onPreview: hasPreview && row.audioPath != null
          ? () => onPreview(row)
          : null,
      actionLabel: 'This one',
      actionSemanticsLabel: 'This one woke me: ${sound.title}',
      onAction: () => onAnswer(sound.id),
      accentAction: true,
    );
  }
}

/// Instead of the question, when no sound played: why, and what helps.
class _NoSound extends ConsumerWidget {
  const _NoSound();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    final arming = ref.watch(armingProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Layout.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('No sound played', style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: Space.s4),
          Text(
            arming.needed && !arming.armed
                ? 'So there is nothing to ask this time. Tap Arm alarms before '
                      'your next alarm, so that you can hear it.'
                : 'So there is nothing to ask this time.',
            style: theme.textTheme.bodySmall!.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
