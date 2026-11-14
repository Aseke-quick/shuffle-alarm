import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/glass_card.dart';
import 'package:shuffle_alarm/design/components/time_text.dart';
import 'package:shuffle_alarm/design/tokens.dart';

/// The alarm that rings next, as the big card of the Alarms tab: "Next
/// alarm", how long until it rings, its [time] in very big numerals and its
/// [details], over soft waves (ADR-005). Without a [time], [title] says that
/// no alarm is set.
class NextAlarmCard extends StatelessWidget {
  const NextAlarmCard({
    this.time,
    this.countdown,
    this.details,
    this.title,
    this.note,
    this.onTap,
    this.semanticsLabel,
    super.key,
  });

  /// When the next alarm rings, or null if no alarm is on.
  final TimeOfDay? time;

  /// How long until it rings, such as "in 7 h 20 min".
  final String? countdown;

  /// Under the time, such as the alarm's label and days.
  final String? details;

  /// In the place of the time, such as "No alarm set".
  final String? title;

  /// Under the [title], such as "Tap New alarm to set one."
  final String? note;

  /// What a tap on the card does, such as opening tonight's mix.
  final VoidCallback? onTap;

  /// What screen readers say for the card, such as "Next alarm 7:00 AM, in
  /// 7 h 20 min".
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    final time = this.time;
    final wide = Layout.isWide(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (time != null) ...[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Space.s8,
            runSpacing: Space.s8,
            children: [
              const _Tag(icon: Icons.alarm, text: 'Next alarm'),
              if (countdown != null) _Tag(text: countdown!, filled: true),
            ],
          ),
          SizedBox(height: wide ? Space.s24 : Space.s16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: TimeText(
              time,
              style: theme.textTheme.displayLarge!.copyWith(
                fontSize: wide ? TypeScale.heroWide : TypeScale.hero,
                letterSpacing:
                    -0.05 * (wide ? TypeScale.heroWide : TypeScale.hero),
              ),
            ),
          ),
          if (details != null) ...[
            const SizedBox(height: Space.s12),
            Text(details!, style: theme.textTheme.titleMedium),
          ],
        ] else ...[
          if (title != null) Text(title!, style: theme.textTheme.headlineLarge),
          if (note != null) ...[
            const SizedBox(height: Space.s8),
            Text(
              note!,
              style: theme.textTheme.bodyLarge!.copyWith(color: c.textMuted),
            ),
          ],
        ],
        // Room for the waves.
        SizedBox(height: wide ? 120 : 72),
      ],
    );
    final card = GlassCard(
      radius: Corners.hero,
      padding: EdgeInsets.zero,
      tint: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          c.fieldOlive,
          c.fieldOlive.withValues(alpha: 0),
          c.fieldBronze,
        ],
      ),
      onTap: onTap,
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(
                painter: _WavesPainter([c.gentle, c.medium, c.strong]),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(wide ? Space.s32 : Space.s24),
            child: SizedBox(width: double.infinity, child: content),
          ),
        ],
      ),
    );
    return Semantics(
      container: true,
      label: semanticsLabel,
      button: onTap != null,
      image: onTap == null && time == null,
      onTap: onTap,
      child: semanticsLabel == null ? card : ExcludeSemantics(child: card),
    );
  }
}

/// A small pill on the card: a caption, or with [filled] the countdown.
class _Tag extends StatelessWidget {
  const _Tag({required this.text, this.icon, this.filled = false});

  final String text;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    final color = filled ? c.onAccent : c.text;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: filled ? c.accent : c.background.withValues(alpha: 0.28),
        borderRadius: const BorderRadius.all(Radius.circular(Corners.round)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.s12,
          vertical: Space.s8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: filled ? color : c.accentText),
              const SizedBox(width: Space.s8),
            ],
            Flexible(
              child: Text(
                text,
                style: Theme.of(context).textTheme.labelLarge!
                    .copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three soft waves along the bottom of the card, in the colors of the three
/// strengths of a sound.
class _WavesPainter extends CustomPainter {
  const _WavesPainter(this.colors);

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final height = math.min(size.height * 0.42, 190);
    for (final (index, color) in colors.indexed) {
      final amplitude = height * (0.22 - 0.045 * index);
      final base = size.height - height * (0.62 - 0.17 * index);
      final frequency = (0.0105 + 0.003 * index) * 660 / size.width;
      final phase = 1.55 * index;
      final path = Path()..moveTo(0, size.height);
      for (var x = 0.0; x <= size.width; x += 6) {
        final y =
            base +
            amplitude * math.sin(x * frequency + phase) +
            amplitude * 0.35 * math.sin(x * frequency * 2.3 + phase);
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.26));
    }
  }

  @override
  bool shouldRepaint(_WavesPainter oldDelegate) => oldDelegate.colors != colors;
}
