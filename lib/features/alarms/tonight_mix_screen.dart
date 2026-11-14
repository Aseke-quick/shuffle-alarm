import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/core/ring_sequence.dart';
import 'package:shuffle_alarm/design/components/layout.dart';
import 'package:shuffle_alarm/design/components/mix_bars.dart';
import 'package:shuffle_alarm/design/components/mix_track_row.dart';
import 'package:shuffle_alarm/design/components/section_label.dart';
import 'package:shuffle_alarm/design/components/sound_deck.dart';
import 'package:shuffle_alarm/design/components/status_view.dart';
import 'package:shuffle_alarm/design/components/time_text.dart';
import 'package:shuffle_alarm/design/components/wide_button.dart';
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
    return PageScaffold(
      appBar: const ContentAppBar(title: Text("Tonight's mix"), wide: true),
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
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall!.copyWith(
      color: WakemixColors.of(context).textMuted,
    );
    final preview = ref.watch(mixPreviewProvider);
    final hasPreview = ref.watch(soundPlayerProvider).playsSounds;
    final round = mix.round;

    DeckCard card(RingClip clip) {
      final sound = clip.sound;
      final playing = preview?.soundId == sound.id;
      return DeckCard(
        id: sound.id,
        title: sound.title,
        details: '${clipStartText(clip.startsAt)} · ${soundDetails(sound)}',
        intensity: sound.intensity,
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

    const gutter = EdgeInsets.fromLTRB(
      Layout.gutter,
      Space.s8,
      Layout.gutter,
      0,
    );
    return Column(
      children: [
        Expanded(
          child: ContentWidth(
            wide: true,
            child: ListView(
              children: [
                _Header(mix: mix),
                SectionLabel(
                  'In play order',
                  trailing: soundCount(round.length),
                ),
                // The deck: a new order moves each card to its new place.
                SoundDeck(cards: [for (final clip in round) card(clip)]),
                Padding(
                  padding: gutter,
                  child: Text(
                    mix.clips.length > round.length
                        ? 'Then again in a new order, for '
                              '${defaultRingCap.inMinutes} min at most.'
                        : 'It rings for ${defaultRingCap.inMinutes} min at '
                              'most.',
                    style: small,
                  ),
                ),
                if (!mix.canSkip)
                  Padding(
                    padding: gutter,
                    child: Text(
                      'One sound stays, so the alarm has something to play.',
                      style: small,
                    ),
                  ),
                if (mix.notTonight.isNotEmpty) ...[
                  SectionLabel(
                    'Not tonight',
                    trailing: '${mix.notTonight.length}',
                  ),
                  ContentWidth(
                    child: Column(
                      children: [
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
                    ),
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

/// The alarm the mix is for, and the mix as bars.
class _Header extends ConsumerWidget {
  const _Header({required this.mix});

  final TonightMix mix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    final now = ref.watch(clockProvider);
    final time = mix.alarm.time;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Layout.gutter,
        Space.s8,
        Layout.gutter,
        0,
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Space.s24,
        runSpacing: Space.s12,
        children: [
          TimeText(
            TimeOfDay(hour: time.hour, minute: time.minute),
            style: theme.textTheme.displayMedium!,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(alarmDetails(mix.alarm), style: theme.textTheme.titleMedium),
              Text(
                countdownText(mix.ringAt.difference(now)),
                style: theme.textTheme.labelMedium!.copyWith(
                  color: c.accentText,
                ),
              ),
            ],
          ),
          SizedBox(
            width: 220,
            child: MixBars(segments: mixSegmentsOf(mix.round)),
          ),
        ],
      ),
    );
  }
}
