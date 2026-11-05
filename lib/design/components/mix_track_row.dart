import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/theme.dart';
import 'package:shuffle_alarm/design/tokens.dart';

/// Where the preview of a sound is.
enum MixRowPreview { idle, loading, playing }

/// One sound in the list of a mix: a preview button, its [title], its
/// [details] such as when it starts, and an action such as "Not tonight".
class MixTrackRow extends StatelessWidget {
  const MixTrackRow({
    required this.title,
    required this.details,
    required this.actionLabel,
    required this.actionSemanticsLabel,
    required this.onAction,
    this.preview = MixRowPreview.idle,
    this.previewLabel,
    this.onPreview,
    this.accentAction = false,
    super.key,
  });

  final String title;
  final String details;

  /// The text of the button, such as "Not tonight".
  final String actionLabel;

  /// What screen readers call the button, such as "Not tonight: Warm Tape":
  /// they may reach it without the row around it.
  final String actionSemanticsLabel;

  /// Null while the action is not possible, such as for the last sound.
  final VoidCallback? onAction;

  final MixRowPreview preview;

  /// What the preview button says, such as "Preview Warm Tape".
  final String? previewLabel;

  /// Null for no preview button.
  final VoidCallback? onPreview;

  /// Whether the action is the point of the row, such as an answer: it gets
  /// the accent. Otherwise it stays quiet.
  final bool accentAction;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    final type = WakemixType.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final text = MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          Text(details, style: type.meta),
        ],
      ),
    );
    final action = Semantics(
      container: true,
      label: actionSemanticsLabel,
      button: true,
      enabled: onAction != null,
      excludeSemantics: true,
      onTap: onAction,
      // Quiet at night: the list keeps the accent for the preview that plays.
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: accentAction ? c.accentText : c.textMuted,
        ),
        onPressed: onAction,
        child: Text(actionLabel),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // The button goes under the text when the text needs the room, such
        // as with large text on a small phone.
        final besideText = constraints.maxWidth >= 300 + (textScale - 1) * 260;
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: EdgeInsets.only(
              left: onPreview == null ? Layout.gutter : Space.s4,
              right: Space.s8,
            ),
            child: Row(
              children: [
                if (onPreview != null) ...[
                  _PreviewButton(
                    preview: preview,
                    label: previewLabel,
                    onPressed: onPreview,
                  ),
                  const SizedBox(width: Space.s4),
                ],
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.s8),
                    child: besideText
                        ? text
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [text, action],
                          ),
                  ),
                ),
                if (besideText) ...[const SizedBox(width: Space.s4), action],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PreviewButton extends StatelessWidget {
  const _PreviewButton({
    required this.preview,
    required this.label,
    required this.onPressed,
  });

  final MixRowPreview preview;
  final String? label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      icon: switch (preview) {
        MixRowPreview.idle => const Icon(Icons.play_arrow),
        MixRowPreview.playing => Icon(
          Icons.stop,
          color: WakemixColors.of(context).accentText,
        ),
        MixRowPreview.loading => SizedBox.square(
          dimension: Space.s24,
          child: Padding(
            padding: const EdgeInsets.all(Space.s4),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              // A still arc when the platform asks for less motion.
              value: Motion.reduceMotion(context) ? 0.25 : null,
            ),
          ),
        ),
      },
    );
  }
}
