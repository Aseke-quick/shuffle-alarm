import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/glass_card.dart';
import 'package:shuffle_alarm/design/tokens.dart';

/// A card with something to do or to keep in mind, such as "Keep this tab
/// open": an [icon], a [title], a [message], an optional [detail] line, and
/// an optional [action] below, such as a `WideButton`.
///
/// A glass card with the accent on its icon, or the danger color when
/// [error] says something went wrong.
class NoticeCard extends StatelessWidget {
  const NoticeCard({
    required this.icon,
    required this.title,
    required this.message,
    this.detail,
    this.action,
    this.error = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  /// A last line in small print, such as a status.
  final String? detail;

  final Widget? action;

  /// Whether something went wrong: the icon is drawn in the danger color.
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall!.copyWith(color: c.textMuted);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Layout.gutter,
        Space.s8,
        Layout.gutter,
        Space.s4,
      ),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              container: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Icon(icon, color: error ? c.danger : c.accentText),
                  ),
                  const SizedBox(width: Space.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: Space.s4),
                        Text(message, style: small),
                        if (detail != null) ...[
                          const SizedBox(height: Space.s8),
                          Text(detail!, style: small),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (action != null) ...[const SizedBox(height: Space.s16), action!],
          ],
        ),
      ),
    );
  }
}
