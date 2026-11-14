import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/tokens.dart';

/// A title above a group, such as "All alarms", with an optional [trailing]
/// text in a small pill, such as a count, and an optional [action] at the
/// end, such as a button.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {this.trailing, this.action, super.key});

  final String text;
  final String? trailing;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Layout.gutter,
        Space.s24,
        Layout.gutter,
        Space.s12,
      ),
      child: Row(
        children: [
          Expanded(
            // One thing to a screen reader, such as "All alarms, 3".
            child: Semantics(
              header: true,
              label: trailing == null ? text : '$text, $trailing',
              excludeSemantics: true,
              child: Row(
                children: [
                  Flexible(
                    child: Text(text, style: theme.textTheme.titleLarge),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: Space.s8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.glass,
                        border: Border.all(color: c.glassLine),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(Corners.round),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.s8,
                          vertical: Space.s4,
                        ),
                        child: Text(
                          trailing!,
                          style: theme.textTheme.labelMedium!.copyWith(
                            color: c.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
