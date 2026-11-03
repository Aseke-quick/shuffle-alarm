import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/time_text.dart';
import 'package:shuffle_alarm/design/theme.dart';
import 'package:shuffle_alarm/design/tokens.dart';

/// One sound on the edge of a record: how long it plays, and how strong it is.
@immutable
class RecordSegment {
  const RecordSegment({required this.length, this.strength = 1});

  /// How long the sound plays: the longer, the longer its segment.
  final Duration length;

  /// How strong the sound is, from 0 (the gentlest) to 1 (the strongest): the
  /// stronger, the wider its segment.
  final double strength;

  @override
  bool operator ==(Object other) =>
      other is RecordSegment &&
      other.length == length &&
      other.strength == strength;

  @override
  int get hashCode => Object.hash(length, strength);

  @override
  String toString() => 'RecordSegment($length, strength: $strength)';
}

/// A record, drawn flat: a ring of [segments] on its edge, grooves, and a
/// label in the middle that holds [child].
///
/// [RecordArt.outline] draws only its lines, in one color, for the empty
/// and error states.
class RecordArt extends StatelessWidget {
  const RecordArt({this.segments = const [], this.child, super.key})
    : lineColor = null;

  const RecordArt.outline({required Color this.lineColor, super.key})
    : segments = const [],
      child = null;

  /// The segments of the ring on the edge: one per sound, in play order.
  final List<RecordSegment> segments;

  /// The color of every line of an outline record, or null for a record
  /// in the theme's colors.
  final Color? lineColor;

  /// What the label shows, such as the time.
  final Widget? child;

  /// How much of the record's radius the label takes.
  static const labelShare = 0.56;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    final line = lineColor;
    return CustomPaint(
      painter: _RecordPainter(
        segments: segments,
        segmentColor: c.textMuted,
        lineColor: line ?? c.outline,
        labelColor: line == null ? c.surface : null,
        strokeWidth: line == null ? 1 : 1.5,
      ),
      child: child == null
          ? null
          : LayoutBuilder(
              builder: (context, constraints) {
                // The largest square inside the round label.
                final side =
                    constraints.biggest.shortestSide * labelShare / math.sqrt2;
                return Center(
                  child: SizedBox.square(
                    dimension: side,
                    child: Center(
                      child: FittedBox(fit: BoxFit.scaleDown, child: child),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Draws the ring of [segments] on the edge of a record of [radius], from 12
/// o'clock on, in play order: each as long as its share of the time, and at
/// most [width] wide, along the same outer edge.
void drawRecordSegments(
  Canvas canvas, {
  required Offset center,
  required double radius,
  required double width,
  required List<RecordSegment> segments,
  required Color color,
}) {
  if (segments.isEmpty) return;
  final total = segments.fold(
    Duration.zero,
    (sum, segment) => sum + segment.length,
  );
  var start = -math.pi / 2;
  for (final segment in segments) {
    final slice =
        2 * math.pi * segment.length.inMicroseconds / total.inMicroseconds;
    final space = math.min(slice * 0.2, 0.08);
    final stroke = width * (0.5 + 0.5 * segment.strength);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - stroke / 2),
      start + space / 2,
      slice - space,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color,
    );
    start += slice;
  }
}

class _RecordPainter extends CustomPainter {
  const _RecordPainter({
    required this.segments,
    required this.segmentColor,
    required this.lineColor,
    required this.labelColor,
    required this.strokeWidth,
  });

  final List<RecordSegment> segments;
  final Color segmentColor;
  final Color lineColor;
  final Color? labelColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final ring = math.max(3, radius * 0.04).toDouble();
    final gap = ring * 1.5;

    drawRecordSegments(
      canvas,
      center: center,
      radius: radius,
      width: ring,
      segments: segments,
      color: segmentColor,
    );

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = lineColor;
    final edge = radius - ring - gap;
    canvas.drawCircle(center, edge, line);

    // Two bands of grooves, like two tracks, between the edge and the label.
    final label = radius * RecordArt.labelShare;
    final inner = label + gap;
    final outer = edge - gap;
    final band = (outer - inner) / 2;
    for (final start in [inner, inner + band]) {
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(center, start + band * (0.15 + i * 0.3), line);
      }
    }

    if (labelColor case final fill?) {
      canvas.drawCircle(center, label, Paint()..color = fill);
    }
    canvas.drawCircle(center, label, line);
  }

  @override
  bool shouldRepaint(_RecordPainter old) =>
      !listEquals(old.segments, segments) ||
      old.segmentColor != segmentColor ||
      old.lineColor != lineColor ||
      old.labelColor != labelColor ||
      old.strokeWidth != strokeWidth;
}

/// The next alarm as a record: its [time] and [countdown] on the label, its
/// mix as the [segments] on the edge, and below the record a [title], the
/// alarm's [details] and a [note], such as the bedtime. Without a [time], an
/// empty record.
///
/// With an [onTap], a tap on the record or on its [mixLabel] opens the mix.
class RecordHero extends StatelessWidget {
  const RecordHero({
    this.time,
    this.countdown,
    this.segments = const [],
    this.mixLabel,
    this.onTap,
    this.title,
    this.details,
    this.note,
    this.semanticsLabel,
    super.key,
  });

  /// The time on the label, or null for an empty record.
  final TimeOfDay? time;

  /// Under the time, such as "in 7 h 20 min".
  final String? countdown;

  /// The sounds of the next ring, in play order.
  final List<RecordSegment> segments;

  /// Under the record, such as "Tonight's mix · 9 sounds".
  final String? mixLabel;

  /// Opens the mix.
  final VoidCallback? onTap;

  /// Under the record, such as "No alarm set".
  final String? title;

  /// Under the record, such as the alarm's label and days.
  final String? details;

  /// The last line, such as "Bed by 11:00 PM for 8 h of sleep".
  final String? note;

  /// What screen readers say for the record, such as "Next alarm 7:00 AM,
  /// in 7 h 20 min".
  final String? semanticsLabel;

  /// The largest the record gets.
  static const maxDiameter = 280.0;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    final type = WakemixType.of(context);
    final time = this.time;
    final record = RecordArt(
      segments: time == null ? const [] : segments,
      child: time == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TimeText(time, style: theme.textTheme.displayMedium!),
                if (countdown != null) ...[
                  const SizedBox(height: Space.s8),
                  Text(
                    countdown!,
                    style: type.meta.copyWith(color: c.accentText),
                  ),
                ],
              ],
            ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Layout.gutter,
        Space.s16,
        Layout.gutter,
        Space.s8,
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SizedBox.square(
              dimension: math.min(
                constraints.maxWidth - 2 * Space.s16,
                maxDiameter,
              ),
              child: onTap == null
                  ? Semantics(
                      container: true,
                      label: semanticsLabel,
                      image: true,
                      excludeSemantics: true,
                      child: record,
                    )
                  : Semantics(
                      container: true,
                      label: semanticsLabel,
                      button: true,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onTap,
                        child: ExcludeSemantics(child: record),
                      ),
                    ),
            ),
          ),
          if (mixLabel != null)
            // The record says it all to a screen reader and a keyboard.
            ExcludeSemantics(
              child: InkWell(
                onTap: onTap,
                canRequestFocus: false,
                borderRadius: const BorderRadius.all(
                  Radius.circular(Corners.card),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: Layout.minTouchTarget,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.s8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            mixLabel!,
                            style: type.meta,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: Space.s16,
                          color: c.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (mixLabel == null) const SizedBox(height: Space.s16),
          if (title != null)
            Text(
              title!,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          if (details != null)
            Text(
              details!,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          if (note != null) ...[
            const SizedBox(height: Space.s4),
            Text(note!, style: type.meta, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
