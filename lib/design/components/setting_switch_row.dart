import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/theme.dart';
import 'package:shuffle_alarm/design/tokens.dart';

/// One setting with a switch: its [title], what it does ([description]) and
/// how it stands now ([status]).
class SettingSwitchRow extends StatelessWidget {
  const SettingSwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.description,
    this.status,
    super.key,
  });

  final String title;
  final String? description;
  final String? status;

  /// Whether the switch is on.
  final bool value;

  /// Null while the setting cannot change: the switch is disabled.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Layout.gutter,
        Space.s8,
        Space.s8,
        Space.s8,
      ),
      // One switch for screen readers, with all its texts as its name.
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  if (description != null) ...[
                    const SizedBox(height: Space.s4),
                    Text(
                      description!,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: c.textMuted,
                      ),
                    ),
                  ],
                  if (status != null) ...[
                    const SizedBox(height: Space.s4),
                    Text(status!, style: WakemixType.of(context).meta),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Space.s8),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
