import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/tokens.dart';

/// One sound of a mix, as a bar: how long it plays, and how strong it is.
@immutable
class MixSegment {
  const MixSegment({required this.length, this.strength = 1});

  /// How long the sound plays: the longer, the wider its bar.
  final Duration length;

  /// How strong the sound is, from 0 (the gentlest) to 1 (the strongest): the
  /// stronger, the taller and warmer its bar.
  final double strength;

  /// The intensity it stands for, from 1 to 3.
  int get intensity => 1 + (strength.clamp(0, 1) * 2).round();

  @override
  bool operator ==(Object other) =>
      other is MixSegment &&
      other.length == length &&
      other.strength == strength;

  @override
  int get hashCode => Object.hash(length, strength);

  @override
  String toString() => 'MixSegment($length, strength: $strength)';
}

/// A mix as a row of bars, one per sound in play order: as wide as its clip
/// is long, taller and warmer for a stronger sound. Decoration: the page says
/// in words what the mix is.
///
/// With [active], the bar of that sound is lit and the others are faint, as
/// on the ringing page.
class MixBars extends StatelessWidget {
  const MixBars({
    required this.segments,
    this.active,
    this.height = 30,
    super.key,
  });

  final List<MixSegment> segments;

  /// The index of the sound that plays now, or null.
  final int? active;

  /// The height of the tallest bar.
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (index, segment) in segments.indexed) ...[
              if (index > 0) const SizedBox(width: 4),
              Expanded(
                flex: segment.length.inMilliseconds.clamp(1, 1 << 30),
                child: Container(
                  height: height * (0.4 + 0.3 * (segment.intensity - 1)),
                  decoration: BoxDecoration(
                    color: c
                        .strength(segment.intensity)
                        .withValues(
                          alpha: active == null || active == index ? 1 : 0.38,
                        ),
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
