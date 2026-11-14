import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/tokens.dart';

/// The page behind everything: its color, and soft color fields over it, olive
/// at the top left, pine at the top right and bronze at the bottom (ADR-005).
///
/// Each field is one radial gradient, so it costs no blur. [warmth] says how
/// strong the bronze field is, from 0 (night) to 1 (morning): the alarm editor
/// warms as the chosen time nears morning, and the ringing page is at 1.
class Backdrop extends StatelessWidget {
  const Backdrop({required this.child, this.warmth = defaultWarmth, super.key});

  /// The [warmth] of a page that says nothing about a time of day.
  static const defaultWarmth = 0.5;

  /// How strong the warm field is, from 0 to 1.
  final double warmth;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    return CustomPaint(
      painter: _FieldsPainter(colors: c, warmth: warmth.clamp(0, 1)),
      child: child,
    );
  }
}

class _FieldsPainter extends CustomPainter {
  const _FieldsPainter({required this.colors, required this.warmth});

  final WakemixColors colors;
  final double warmth;

  @override
  void paint(Canvas canvas, Size size) {
    final page = Offset.zero & size;
    canvas.drawRect(page, Paint()..color = colors.background);
    // As big on a phone as on a laptop, by the shape of the page.
    final reach = (size.width + size.height) / 2;
    void field(Color color, Offset center, double radius) {
      if (color.a == 0 || radius <= 0) return;
      canvas.drawRect(
        page,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color,
              color.withValues(alpha: color.a * 0.55),
              color.withValues(alpha: 0),
            ],
            stops: const [0, 0.45, 1],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    field(
      colors.fieldOlive,
      Offset(size.width * 0.1, size.height * 0.08),
      reach * 0.62,
    );
    field(
      colors.fieldPine,
      Offset(size.width * 0.96, size.height * 0.16),
      reach * 0.56,
    );
    final bronze = colors.fieldBronze;
    field(
      bronze.withValues(alpha: math.min(1, bronze.a * (0.35 + 1.3 * warmth))),
      Offset(size.width * 0.52, size.height * 1.08),
      reach * (0.5 + 0.22 * warmth),
    );
  }

  @override
  bool shouldRepaint(_FieldsPainter oldDelegate) =>
      oldDelegate.colors != colors || oldDelegate.warmth != warmth;
}
