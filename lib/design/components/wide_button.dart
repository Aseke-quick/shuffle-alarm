import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/tokens.dart';

/// A full-width button, [Layout.wideButtonHeight] tall: the accent one for
/// the main action of a screen, or an outlined one ([WideButton.secondary]).
class WideButton extends StatelessWidget {
  const WideButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  }) : secondary = false;

  const WideButton.secondary({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  }) : secondary = true;

  final String label;

  /// Null while the action is not possible, such as during a save.
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    const style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size.fromHeight(Layout.wideButtonHeight),
      ),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: Space.s24, vertical: Space.s12),
      ),
    );
    final text = Text(label, textAlign: TextAlign.center);
    final icon = this.icon == null ? null : Icon(this.icon, size: 20);
    if (secondary) {
      return icon == null
          ? OutlinedButton(onPressed: onPressed, style: style, child: text)
          : OutlinedButton.icon(
              onPressed: onPressed,
              style: style,
              icon: icon,
              label: text,
            );
    }
    return icon == null
        ? FilledButton(onPressed: onPressed, style: style, child: text)
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: icon,
            label: text,
          );
  }
}
