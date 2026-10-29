import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/tokens.dart';

/// Seven toggle keys from Monday to Sunday: the [selected] days, filled
/// with the accent. Days are [DateTime.weekday] numbers.
///
/// Each key is a seventh of the row and at least [Layout.minTouchTarget]
/// tall, so a row of 336 px gives 48 dp keys.
class DayKeys extends StatelessWidget {
  const DayKeys({
    required this.selected,
    required this.onChanged,
    required this.label,
    required this.semanticsLabel,
    super.key,
  });

  final Set<int> selected;
  final void Function(int day, {required bool selected}) onChanged;

  /// The short name on a key, such as "Mon".
  final String Function(int day) label;

  /// The full name screen readers say, such as "Monday".
  final String Function(int day) semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
          Expanded(
            child: _DayKey(
              label: label(day),
              semanticsLabel: semanticsLabel(day),
              selected: selected.contains(day),
              onPressed: () =>
                  onChanged(day, selected: !selected.contains(day)),
            ),
          ),
      ],
    );
  }
}

class _DayKey extends StatelessWidget {
  const _DayKey({
    required this.label,
    required this.semanticsLabel,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final String semanticsLabel;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(Corners.dayKey)),
    );
    return Semantics(
      container: true,
      button: true,
      checked: selected,
      label: semanticsLabel,
      onTap: onPressed,
      excludeSemantics: true,
      // The gap between the keys belongs to their touch targets.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: AnimatedContainer(
            duration: Motion.of(context, Motion.fast),
            curve: Motion.curve,
            constraints: const BoxConstraints(
              minHeight: Layout.minTouchTarget - 4,
            ),
            decoration: ShapeDecoration(
              shape: shape,
              color: selected ? c.accent : c.surfaceHigh,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                customBorder: shape,
                onTap: onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.s4,
                    vertical: Space.s12,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge!
                            .copyWith(color: selected ? c.onAccent : c.text),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
