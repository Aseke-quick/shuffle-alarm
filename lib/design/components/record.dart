import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/time_text.dart';
import 'package:shuffle_alarm/design/theme.dart';
import 'package:shuffle_alarm/design/tokens.dart';

/// A record, drawn flat: a ring of [segments] on its edge, grooves, and a
/// label in the middle that holds [child].
///
/// [RecordArt.outline] draws only its lines, in one color, for the empty
/// and error states.
class RecordArt extends StatelessWidget {
  const RecordArt({this.segments = 0, this.child, super.key})
    : lineColor = null;

  const RecordArt.outline({required Color this.lineColor, super.key})
    : segments = 0,
      child = null;

  /// How many segments the ring on the edge has: one per sound. 0 for none.
  final int segments;

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
        segmentColor: c.textDisabled,
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

/// Draws the ring of [count] segments on the edge of a record of [radius],
/// [width] wide, from 12 o'clock on.
void drawRecordSegments(
  Canvas canvas, {
  required Offset center,
  required double radius,
  required double width,
  required int count,
  required Color color,
}) {
  if (count <= 0) return;
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = color;
  final slice = 2 * math.pi / count;
  final space = math.min(slice * 0.2, 0.08);
  final rect = Rect.fromCircle(center: center, radius: radius - width / 2);
  for (var i = 0; i < count; i++) {
    canvas.drawArc(
      rect,
      -math.pi / 2 + i * slice + space / 2,
      slice - space,
      false,
      paint,
    );
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

  final int segments;
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
      count: segments,
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
      old.segments != segments ||
      old.segmentColor != segmentColor ||
      old.lineColor != lineColor ||
      old.labelColor != labelColor ||
      old.strokeWidth != strokeWidth;
}

/// The next alarm as a record: its [time] and [countdown] on the label,
/// and below the record a [title], the alarm's [details] and a [note], such
/// as the bedtime. Without a [time], an empty record.
///
/// Until task 2.5a the ring on the edge shows 10 grey segments as
/// decoration; then it shows the sounds of the next ring.
class RecordHero extends StatelessWidget {
  const RecordHero({
    this.time,
    this.countdown,
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

  /// Under the record, such as "No alarm set".
  final String? title;

  /// Under the record, such as the alarm's label and days.
  final String? details;

  /// The last line, such as "Bed by 11:00 PM for 8 h of sleep".
  final String? note;

  /// What screen readers say for the record, such as "Next alarm 7:00 AM,
  /// in 7 h 20 min".
  final String? semanticsLabel;

  /// The decorative ring until task 2.5a.
  static const segments = 10;

  /// The largest the record gets.
  static const maxDiameter = 280.0;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    final type = WakemixType.of(context);
    final time = this.time;
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
              child: Semantics(
                container: true,
                label: semanticsLabel,
                image: true,
                excludeSemantics: true,
                child: RecordArt(
                  segments: time == null ? 0 : segments,
                  child: time == null
                      ? null
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TimeText(
                              time,
                              style: theme.textTheme.displayMedium!,
                            ),
                            if (countdown != null) ...[
                              const SizedBox(height: Space.s8),
                              Text(
                                countdown!,
                                style: type.meta.copyWith(color: c.accentText),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.s16),
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
