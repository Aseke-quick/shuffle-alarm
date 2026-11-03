import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/record.dart';
import 'package:shuffle_alarm/design/tokens.dart';

/// The record of the ringing screen, the only one that turns (spec section
/// 1): a disc in the color on the accent, its segments and grooves in the
/// accent, and a large label in the accent that holds [child], which stays
/// still.
///
/// It stands still when the platform asks for less motion
/// ([Motion.reduceMotion]). It goes on an `AccentPage`.
class SpinningRecord extends StatefulWidget {
  const SpinningRecord({
    required this.child,
    this.segments = const [],
    this.turning = true,
    super.key,
  });

  /// What the label shows, such as the clock. It stays upright.
  final Widget child;

  /// The sounds of the ring, in play order.
  final List<RecordSegment> segments;

  /// Whether it turns: while its sound plays.
  final bool turning;

  /// How long one turn takes. A linear, steady motion, not one of the short
  /// moves of [Motion].
  static const turn = Duration(seconds: 6);

  /// How much of the record's radius the label takes.
  static const labelShare = 0.72;

  @override
  State<SpinningRecord> createState() => _SpinningRecordState();
}

class _SpinningRecordState extends State<SpinningRecord>
    with SingleTickerProviderStateMixin {
  late final _turns = AnimationController(
    vsync: this,
    duration: SpinningRecord.turn,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _turnOrStop();
  }

  @override
  void didUpdateWidget(SpinningRecord oldWidget) {
    super.didUpdateWidget(oldWidget);
    _turnOrStop();
  }

  void _turnOrStop() {
    if (!widget.turning || Motion.reduceMotion(context)) {
      _turns.stop();
    } else if (!_turns.isAnimating) {
      _turns.repeat();
    }
  }

  @override
  void dispose() {
    _turns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Its own layer, so each frame only turns what was drawn once.
        RepaintBoundary(
          child: RotationTransition(
            turns: _turns,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _DiscPainter(
                  disc: c.onAccent,
                  lines: c.accent,
                  segments: widget.segments,
                ),
              ),
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            // The diameter of the label.
            final label =
                constraints.biggest.shortestSide * SpinningRecord.labelShare;
            return Center(
              child: SizedBox(
                // A box with its corners on the round label, 4 by 3: the
                // clock is wide and not tall.
                width: label * 0.8,
                height: label * 0.6,
                child: Center(
                  child: FittedBox(fit: BoxFit.scaleDown, child: widget.child),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DiscPainter extends CustomPainter {
  const _DiscPainter({
    required this.disc,
    required this.lines,
    required this.segments,
  });

  final Color disc;
  final Color lines;
  final List<RecordSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    canvas.drawCircle(center, radius, Paint()..color = disc);

    final ring = math.max(3, radius * 0.03).toDouble();
    final rim = radius - ring * 1.5;
    drawRecordSegments(
      canvas,
      center: center,
      radius: rim,
      width: ring,
      segments: segments,
      color: lines,
    );

    final label = radius * SpinningRecord.labelShare;
    final grooves = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = lines;
    final band = rim - ring - label;
    for (final share in const [0.3, 0.6]) {
      canvas.drawCircle(center, label + band * share, grooves);
    }
    canvas.drawCircle(center, label, Paint()..color = lines);
  }

  @override
  bool shouldRepaint(_DiscPainter old) =>
      old.disc != disc ||
      old.lines != lines ||
      !listEquals(old.segments, segments);
}
