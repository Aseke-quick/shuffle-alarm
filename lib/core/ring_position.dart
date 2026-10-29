import 'package:meta/meta.dart';

import 'package:shuffle_alarm/core/ring_sequence.dart';

/// Where in a ring sequence a ring plays: the clip at [index], [offset] into
/// it, counted from the start of its clip window.
@immutable
class RingPosition {
  const RingPosition(this.index, {this.offset = Duration.zero});

  /// The index of the clip in the ring sequence.
  final int index;

  /// How far into the clip, from the start of its window.
  final Duration offset;

  @override
  bool operator ==(Object other) =>
      other is RingPosition && other.index == index && other.offset == offset;

  @override
  int get hashCode => Object.hash(index, offset);

  @override
  String toString() => 'RingPosition($index, offset: $offset)';
}

/// Where a ring of [clips] plays [elapsed] after it started: in the clip
/// whose time holds it (`RingClip.startsAt` to `RingClip.endsAt`), so a ring
/// that starts late, such as in a throttled background tab, keeps to the
/// clock (docs/DECISIONS.md, 1.6).
///
/// Null once the ring is over, when [elapsed] reaches the end of the last
/// clip, which is the time cap: the ring was missed. A time before the
/// start, such as from a clock set back a moment, counts as the start: a
/// ring never fails for a clock.
RingPosition? ringPosition(List<RingClip> clips, Duration elapsed) {
  final time = elapsed < Duration.zero ? Duration.zero : elapsed;
  for (final (index, clip) in clips.indexed) {
    if (time < clip.endsAt) {
      return RingPosition(index, offset: time - clip.startsAt);
    }
  }
  return null;
}
