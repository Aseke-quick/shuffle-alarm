import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/mini_waveform.dart';
import 'package:shuffle_alarm/design/components/mix_track_row.dart';
import 'package:shuffle_alarm/design/tokens.dart';

/// One card of a [SoundDeck]: a sound of a mix.
@immutable
class DeckCard {
  const DeckCard({
    required this.id,
    required this.title,
    required this.details,
    required this.intensity,
    required this.actionLabel,
    required this.actionSemanticsLabel,
    required this.onAction,
    this.preview = MixRowPreview.idle,
    this.previewLabel,
    this.onPreview,
  });

  /// What tells the card apart, such as the `Sound.id`: a card keeps its
  /// place in the tree by it, so it moves when the order changes.
  final String id;
  final String title;

  /// Under the title, such as when it starts and what it is.
  final String details;

  /// How strong the sound is, from 1 to 3: the color of the card.
  final int intensity;

  /// The text of the button, such as "Not tonight".
  final String actionLabel;

  /// What screen readers call the button, such as "Not tonight: Warm Tape".
  final String actionSemanticsLabel;

  /// Null while the action is not possible, such as for the last sound. A
  /// card dragged up and away does it too.
  final VoidCallback? onAction;

  final MixRowPreview preview;

  /// What the preview button says, such as "Preview Warm Tape".
  final String? previewLabel;

  /// Null for no preview button.
  final VoidCallback? onPreview;
}

/// The sounds of a mix as a deck of cards in play order (ADR-005).
///
/// Where there is room, the cards lie as a fan, each a little over the one
/// before; on a narrow screen they are a row that scrolls sideways. When the
/// order changes, such as after Reshuffle, each card moves to its new place,
/// so the deck mixes in front of the user; not when the platform asks for
/// less motion. A card dragged up and away does its action.
class SoundDeck extends StatelessWidget {
  const SoundDeck({required this.cards, super.key});

  final List<DeckCard> cards;

  /// The width of a card.
  static const cardWidth = 176.0;

  /// The width of a card in the row of a narrow screen: two and a part of
  /// the third show on a phone, so the row is seen to scroll.
  static const rowCardWidth = 148.0;

  /// The least of a card that shows in the fan: its title must fit.
  static const minStep = 112.0;

  /// How far each card of the fan turns from the one before, in radians.
  static const turn = 0.07;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 3.0);
    // Room for the place, two lines of title and three of details, which
    // grow with the text, and for the two buttons, which do not.
    final cardHeight = 96 + 156 * scale;
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = cards.length;
        final room = constraints.maxWidth - 2 * Layout.gutter;
        final step = count < 2
            ? 0.0
            : math.min(cardWidth + Space.s12, (room - cardWidth) / (count - 1));
        if (count > 1 && step < minStep * scale) {
          // No room for a fan: a row that scrolls sideways.
          return SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Layout.gutter),
              itemCount: count,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: Space.s12),
              itemBuilder: (context, index) => SizedBox(
                key: ValueKey(cards[index].id),
                width: rowCardWidth * (0.7 + 0.3 * scale),
                child: _SoundCard(
                  card: cards[index],
                  place: index + 1,
                  textWidth: double.infinity,
                ),
              ),
            ),
          );
        }
        final fanWidth = cardWidth + step * (count - 1);
        final left = Layout.gutter + (room - fanWidth) / 2;
        final overlaps = count > 1 && step < cardWidth;
        final middle = (count - 1) / 2;
        final duration = Motion.of(context, const Duration(milliseconds: 520));
        // Room for the cards at the ends, which a fan lowers and turns.
        final drop = overlaps ? 5.0 * middle * middle : 0.0;
        return SizedBox(
          height: cardHeight + drop + 28,
          child: Stack(
            children: [
              for (final (index, card) in cards.indexed)
                AnimatedPositioned(
                  key: ValueKey(card.id),
                  duration: duration,
                  curve: Curves.easeInOutCubic,
                  left: left + step * index,
                  top:
                      8 +
                      (overlaps
                          ? 5.0 * (index - middle) * (index - middle)
                          : 0),
                  width: cardWidth,
                  height: cardHeight,
                  child: AnimatedRotation(
                    duration: duration,
                    curve: Curves.easeInOutCubic,
                    turns: overlaps
                        ? (index - middle) * turn / (2 * math.pi)
                        : 0,
                    alignment: Alignment.bottomCenter,
                    child: _SoundCard(
                      card: card,
                      place: index + 1,
                      textWidth: overlaps ? step - Space.s16 : double.infinity,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SoundCard extends StatelessWidget {
  const _SoundCard({
    required this.card,
    required this.place,
    required this.textWidth,
  });

  final DeckCard card;

  /// Its place in the play order, from 1.
  final int place;

  /// How wide its texts can be: in a fan, the part of the card that shows.
  final double textWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const ink = WakemixColors.onStrength;
    final fill = WakemixColors.strengthFill(card.intensity);
    final c = WakemixColors.of(context);
    final action = card.onAction;
    final onPreview = card.onPreview;
    return GestureDetector(
      // A flick up takes the card out of the deck.
      onVerticalDragEnd: action == null
          ? null
          : (details) {
              if ((details.primaryVelocity ?? 0) < -300) action();
            },
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(fill, c.surface, 0.14)!, fill],
          ),
          borderRadius: const BorderRadius.all(Radius.circular(Corners.card)),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.s16, Space.s12, Space.s8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: textWidth),
                child: MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$place',
                        style: theme.textTheme.labelMedium!.copyWith(
                          color: ink.withValues(alpha: 0.6),
                        ),
                        semanticsLabel: 'Number $place',
                      ),
                      const SizedBox(height: Space.s4),
                      Text(
                        card.title,
                        style: theme.textTheme.titleMedium!.copyWith(
                          color: ink,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Space.s4),
                      Text(
                        card.details,
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: ink.withValues(alpha: 0.72),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (onPreview != null) ...[
                    IconButton.filled(
                      onPressed: onPreview,
                      tooltip: card.previewLabel,
                      style: IconButton.styleFrom(
                        backgroundColor: ink,
                        foregroundColor: fill,
                      ),
                      icon: switch (card.preview) {
                        MixRowPreview.idle => const Icon(Icons.play_arrow),
                        MixRowPreview.playing => const Icon(Icons.stop),
                        MixRowPreview.loading => SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: fill,
                            // A still arc when the platform asks for less
                            // motion.
                            value: Motion.reduceMotion(context) ? 0.25 : null,
                          ),
                        ),
                      },
                    ),
                    const SizedBox(width: Space.s8),
                  ],
                  // A small waveform: taller for a stronger sound.
                  ExcludeSemantics(
                    child: SizedBox(
                      height: 40,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final height in waveformHeights(card.id, 6)) ...[
                            Container(
                              width: 4,
                              height:
                                  8 +
                                  26 * height * (0.55 + 0.15 * card.intensity),
                              decoration: BoxDecoration(
                                color: ink.withValues(alpha: 0.8),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Semantics(
                container: true,
                button: true,
                enabled: action != null,
                label: card.actionSemanticsLabel,
                onTap: action,
                excludeSemantics: true,
                child: TextButton(
                  onPressed: action,
                  style: TextButton.styleFrom(
                    foregroundColor: ink,
                    disabledForegroundColor: ink.withValues(alpha: 0.38),
                    padding: const EdgeInsets.symmetric(horizontal: Space.s8),
                    minimumSize: const Size(0, Layout.minTouchTarget),
                  ),
                  child: Text(card.actionLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
