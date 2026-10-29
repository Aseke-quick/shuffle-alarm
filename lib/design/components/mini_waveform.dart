import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/tokens.dart';

/// A small waveform, decoration only: its bars come from [seed], such as an
/// alarm's id, so the same alarm always shows the same waveform. Accent
/// when [active], grey when not.
class MiniWaveform extends StatelessWidget {
  const MiniWaveform({required this.seed, required this.active, super.key});

  final String seed;
  final bool active;

  static const size = Size(56, 24);
  static const bars = 14;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    return ExcludeSemantics(
      child: CustomPaint(
        size: size,
        painter: _WaveformPainter(
          heights: waveformHeights(seed, bars),
          color: active ? c.accent : c.textDisabled,
        ),
      ),
    );
  }
}

/// The heights of [count] bars for [seed], from 0.2 to 1 of the full
/// height, lower at the ends.
///
/// The same on every platform and in every run: Dart's `String.hashCode`
/// and `Random` can differ between the web and the Dart VM, so this has a
/// hash and a random number generator of its own. Every product stays
/// below 2^53, so JavaScript computes them exactly too.
List<double> waveformHeights(String seed, int count) {
  const modulus = 2147483647; // 2^31 - 1
  var state = 1;
  for (final unit in seed.codeUnits) {
    state = (state * 31 + unit) % modulus;
  }
  // The minimal standard generator of Park and Miller, which needs a state
  // from 1 to modulus - 1.
  if (state == 0) state = 1;
  double next() {
    state = state * 48271 % modulus;
    return state / modulus;
  }

  final heights = <double>[];
  var previous = next();
  for (var i = 0; i < count; i++) {
    final value = next();
    // Each bar leans on the one before, like a sound that rises and falls.
    final level = 0.6 * value + 0.4 * previous;
    previous = value;
    final envelope = math.sin(math.pi * (i + 0.5) / count);
    heights.add(0.2 + 0.8 * level * (0.45 + 0.55 * envelope));
  }
  return heights;
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({required this.heights, required this.color});

  final List<double> heights;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 2.0;
    final width = (size.width - gap * (heights.length - 1)) / heights.length;
    final paint = Paint()..color = color;
    for (final (i, height) in heights.indexed) {
      final barHeight = size.height * height;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * (width + gap),
            (size.height - barHeight) / 2,
            width,
            barHeight,
          ),
          Radius.circular(width / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.color != color || !listEquals(old.heights, heights);
}
