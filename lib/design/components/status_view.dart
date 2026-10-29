import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/record.dart';
import 'package:shuffle_alarm/design/theme.dart';
import 'package:shuffle_alarm/design/tokens.dart';

/// An empty or an error state: an outline record, a [title], a [message],
/// an optional [action] such as a "Try again" button, and an optional
/// [detail] in small print that can be copied for a bug report.
class StatusView extends StatelessWidget {
  const StatusView({
    required this.title,
    this.message,
    this.action,
    this.detail,
    this.error = false,
    super.key,
  });

  final String title;
  final String? message;
  final Widget? action;
  final String? detail;

  /// Whether something went wrong: the record is drawn in the danger color.
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.s24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Layout.maxContentWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 96,
                child: ExcludeSemantics(
                  child: RecordArt.outline(
                    lineColor: error ? c.danger : c.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: Space.s24),
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: Space.s8),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: c.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: Space.s24),
                action!,
              ],
              if (detail != null) ...[
                const SizedBox(height: Space.s16),
                SelectableText(
                  detail!,
                  style: WakemixType.of(context).caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
