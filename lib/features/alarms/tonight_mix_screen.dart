import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/core/ring_sequence.dart';
import 'package:shuffle_alarm/design/components/layout.dart';
import 'package:shuffle_alarm/design/components/mix_track_row.dart';
import 'package:shuffle_alarm/design/components/record.dart';
import 'package:shuffle_alarm/design/components/section_label.dart';
import 'package:shuffle_alarm/design/components/status_view.dart';
import 'package:shuffle_alarm/design/components/time_text.dart';
import 'package:shuffle_alarm/design/components/wide_button.dart';
import 'package:shuffle_alarm/design/theme.dart';
import 'package:shuffle_alarm/design/tokens.dart';
import 'package:shuffle_alarm/features/alarms/alarm_texts.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/features/alarms/mix_preview.dart';
import 'package:shuffle_alarm/features/alarms/tonight_mix.dart';
import 'package:shuffle_alarm/platform/providers.dart';

/// Tonight's mix (task 2.5a): the sounds of the next ring in play order, each
/// with a preview and Not tonight, and Reshuffle at the bottom. The ring plays
/// what this page shows.
class TonightMixScreen extends ConsumerStatefulWidget {
  const TonightMixScreen({super.key});

  static const path = '/alarms/tonight';

  @override
  ConsumerState<TonightMixScreen> createState() => _TonightMixScreenState();
}

class _TonightMixScreenState extends ConsumerState<TonightMixScreen> {
  /// Read when the page opens: it cannot use `ref` while it closes.
  late final MixPreviewController _preview;

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

  /// Runs a change of the mix, without the preview that plays. If it cannot be
  /// saved, a message at the bottom of the screen says so.
  Future<void> _change(Future<void> Function() change) async {
    final messenger = ScaffoldMessenger.of(context);
    await _preview.stop();
    try {
      await change();
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not save the mix: $error')),
      );
    }
  }

  Future<void> _reshuffle() => _change(() async {
    final messenger = ScaffoldMessenger.of(context);
    final changed = await ref.read(tonightMixProvider.notifier).reshuffle();
    if (changed) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('These sounds have one order only: gentle to strong.'),
      ),
    );
  });

  Future<void> _togglePreview(
    Sound sound,
    TonightMix mix,
    double volume,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await _preview.toggle(
      sound,
      audioPath: mix.audioPathOf(sound.id),
      volume: volume,
    );
    final message = previewProblem(outcome);
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mix = ref.watch(tonightMixProvider);
    return Scaffold(
      appBar: const ContentAppBar(title: Text("Tonight's mix")),
      body: switch (mix) {
        AsyncValue(value: final mix?) => _Mix(
          mix: mix,
          onPreview: (sound, volume) =>
              unawaited(_togglePreview(sound, mix, volume)),
          onSkip: (sound) => unawaited(
            _change(() => ref.read(tonightMixProvider.notifier).skip(sound.id)),
          ),
          onBringBack: (sound) => unawaited(
            _change(
              () => ref.read(tonightMixProvider.notifier).bringBack(sound.id),
            ),
          ),
          onReshuffle: () => unawaited(_reshuffle()),
        ),
        AsyncValue(isLoading: true) => Center(
          child: CircularProgressIndicator(
            // A still arc when the platform asks for less motion.
            value: Motion.reduceMotion(context) ? 0.25 : null,
          ),
        ),
        _ => const StatusView(
          title: 'No alarm set',
          message: 'Turn an alarm on to see its mix.',
        ),
      },
    );
  }
}

class _Mix extends ConsumerWidget {
  const _Mix({
    required this.mix,
    required this.onPreview,
    required this.onSkip,
    required this.onBringBack,
    required this.onReshuffle,
  });

  final TonightMix mix;
  final void Function(Sound sound, double volume) onPreview;
  final ValueChanged<Sound> onSkip;
  final ValueChanged<Sound> onBringBack;
  final VoidCallback onReshuffle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = WakemixType.of(context);
    final preview = ref.watch(mixPreviewProvider);
    final hasPreview = ref.watch(soundPlayerProvider).playsSounds;
    final round = mix.round;

    Widget row(RingClip clip) {
      final sound = clip.sound;
      final playing = preview?.soundId == sound.id;
      return MixTrackRow(
        key: ValueKey(sound.id),
        title: sound.title,
        details: '${clipStartText(clip.startsAt)} · ${soundDetails(sound)}',
        preview: !playing
            ? MixRowPreview.idle
            : preview!.loading
            ? MixRowPreview.loading
            : MixRowPreview.playing,
        previewLabel: playing ? 'Stop preview' : 'Preview ${sound.title}',
        onPreview: hasPreview ? () => onPreview(sound, clip.volume) : null,
        actionLabel: 'Not tonight',
        actionSemanticsLabel: 'Not tonight: ${sound.title}',
        onAction: mix.canSkip ? () => onSkip(sound) : null,
      );
    }

    return Column(
      children: [
        Expanded(
          child: ContentWidth(
            child: ListView(
              children: [
                _Header(mix: mix),
                SectionLabel(
                  'In play order',
                  trailing: soundCount(round.length),
                ),
                AnimatedSwitcher(
                  duration: Motion.of(context, Motion.medium),
                  child: Column(
                    // A new order fades in; a sound that left does not.
                    key: ValueKey(mix.plan.seed),
                    children: [
                      for (final (index, clip) in round.indexed) ...[
                        if (index > 0)
                          const Divider(
                            indent: Layout.gutter,
                            endIndent: Layout.gutter,
                          ),
                        row(clip),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Layout.gutter,
                    Space.s8,
                    Layout.gutter,
                    0,
                  ),
                  child: Text(
                    mix.clips.length > round.length
                        ? 'Then again in a new order, for '
                              '${defaultRingCap.inMinutes} min at most.'
                        : 'It rings for ${defaultRingCap.inMinutes} min at '
                              'most.',
                    style: type.meta,
                  ),
                ),
                if (!mix.canSkip)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Layout.gutter,
                      Space.s4,
                      Layout.gutter,
                      0,
                    ),
                    child: Text(
                      'One sound stays, so the alarm has something to play.',
                      style: type.meta,
                    ),
                  ),
                if (mix.notTonight.isNotEmpty) ...[
                  SectionLabel(
                    'Not tonight',
                    trailing: '${mix.notTonight.length}',
                  ),
                  for (final sound in mix.notTonight)
                    MixTrackRow(
                      key: ValueKey('out ${sound.id}'),
                      title: sound.title,
                      details: soundDetails(sound),
                      actionLabel: 'Bring back',
                      actionSemanticsLabel: 'Bring back: ${sound.title}',
                      onAction: () => onBringBack(sound),
                    ),
                ],
                const SizedBox(height: Space.s16),
              ],
            ),
          ),
        ),
        BottomAction(
          child: WideButton(
            label: 'Reshuffle',
            icon: Icons.shuffle,
            onPressed: round.length > 1 ? onReshuffle : null,
          ),
        ),
      ],
    );
  }
}

/// A small record of the mix, and the alarm it is for.
class _Header extends ConsumerWidget {
  const _Header({required this.mix});

  final TonightMix mix;

  /// The size of the record.
  static const _record = 96.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    final type = WakemixType.of(context);
    final now = ref.watch(clockProvider);
    final time = mix.alarm.time;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Layout.gutter,
        Space.s8,
        Layout.gutter,
        0,
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: _record,
            child: ExcludeSemantics(
              child: RecordArt(segments: recordSegmentsOf(mix.round)),
            ),
          ),
          const SizedBox(width: Space.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TimeText(
                  TimeOfDay(hour: time.hour, minute: time.minute),
                  style: theme.textTheme.headlineSmall!,
                ),
                Text(
                  alarmDetails(mix.alarm),
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: c.textMuted,
                  ),
                ),
                Text(
                  countdownText(mix.ringAt.difference(now)),
                  style: type.meta.copyWith(color: c.accentText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
