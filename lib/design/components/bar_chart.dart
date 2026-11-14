import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/tokens.dart';

/// One bar of a [BarChart].
@immutable
class ChartBar {
  const ChartBar({this.value, this.label = '', this.flagged = false});

  /// How tall the bar is, in any unit: the tallest fills the chart. Null for
  /// no value: a stub on the base line.
  final double? value;

  /// Under the bar, such as "M" or "15". Empty for none.
  final String label;

  /// Whether to mark the bar with a dot in the "strong" color, such as for a
  /// missed morning.
  final bool flagged;
}

/// A row of bars over a base line (ADR-005). Decoration for screen readers,
/// which get [semanticsLabel]: what the chart says, in words.
class BarChart extends StatelessWidget {
  const BarChart({
    required this.bars,
    required this.semanticsLabel,
    this.height = 132,
    super.key,
  });

  final List<ChartBar> bars;
  final String semanticsLabel;

  /// The height of the tallest bar.
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    final top = bars.fold<double>(
      0,
      (top, bar) => math.max(top, bar.value ?? 0),
    );
    final gap = bars.length > 14 ? 2.0 : 6.0;
    return Semantics(
      container: true,
      image: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: height + 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final bar in bars)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: gap / 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (bar.flagged)
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: c.strong,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Container(
                              height: bar.value == null || top == 0
                                  ? 3
                                  : math.max(3, height * bar.value! / top),
                              decoration: BoxDecoration(
                                color: bar.value == null ? c.outline : c.accent,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                  bottom: Radius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Space.s8),
            Row(
              children: [
                for (final bar in bars)
                  Expanded(
                    child: Text(
                      bar.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: theme.textTheme.labelSmall!.copyWith(
                        color: c.textMuted,
                      ),
                      // The bars do not grow with the text, so their labels
                      // cannot either.
                      textScaler: TextScaler.noScaling,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
