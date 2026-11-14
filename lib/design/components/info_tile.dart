import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/glass_card.dart';
import 'package:shuffle_alarm/design/tokens.dart';

/// A small glass tile with one fact: a [label] and an [icon] at the top, then
/// [child] or a [text]. With [onTap] the whole tile is a button.
class InfoTile extends StatelessWidget {
  const InfoTile({
    required this.label,
    required this.icon,
    this.text,
    this.child,
    this.onTap,
    this.semanticsLabel,
    super.key,
  });

  final String label;
  final IconData icon;

  /// What the tile says, such as "Bed by 10:30 PM for 8 h of sleep".
  final String? text;

  /// Under the label, above the [text], such as the bars of a mix.
  final Widget? child;

  final VoidCallback? onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    return GlassCard(
      onTap: onTap,
      semanticsLabel: semanticsLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium!.copyWith(
                    color: c.textMuted,
                  ),
                ),
              ),
              Icon(icon, size: 20, color: c.accentText),
            ],
          ),
          if (child != null) ...[const SizedBox(height: Space.s12), child!],
          if (text != null) ...[
            const SizedBox(height: Space.s12),
            Text(text!, style: theme.textTheme.titleMedium),
          ],
        ],
      ),
    );
  }
}
