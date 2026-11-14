import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/tokens.dart';

/// A month of the calendar, Monday first, with a mark on some of its days
/// (ADR-005).
///
/// A marked day is a disc in the color of its mark: [marks] gives each day of
/// the month a strength from 1 to 3, as `WakemixColors.strengthFill` takes
/// it. The [selected] day has a ring, [today] is bold. Every day is a button
/// that screen readers call by [dayLabel].
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    required this.month,
    required this.marks,
    required this.dayLabel,
    required this.onDaySelected,
    required this.onPrevious,
    required this.onNext,
    this.selected,
    this.today,
    this.previousLabel = 'Previous month',
    this.nextLabel = 'Next month',
    super.key,
  });

  /// Any time in the month to show.
  final DateTime month;

  /// The mark of a day of the month, from 1 to 3. A day without one is plain.
  final Map<int, int> marks;

  /// What screen readers call a day, such as "Saturday, November 14, snoozed".
  final String Function(int day) dayLabel;
  final ValueChanged<int> onDaySelected;

  /// Goes to the month before. Null when there is none to go to.
  final VoidCallback? onPrevious;

  /// Goes to the month after. Null when there is none to go to.
  final VoidCallback? onNext;

  /// What the two arrows are called.
  final String previousLabel;
  final String nextLabel;

  /// The chosen day of the month, if it is in this month.
  final int? selected;

  /// Today's day of the month, if today is in this month.
  final int? today;

  /// The least height of a day: a touch target.
  static const dayHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final first = DateTime(month.year, month.month);
    final days = DateTime(month.year, month.month + 1, 0).day;
    // Empty places before the first day: Monday is the first column.
    final lead = first.weekday - DateTime.monday;
    final rows = ((lead + days) / DateTime.daysPerWeek).ceil();
    // "S", "M", …, from Sunday.
    final names = localizations.narrowWeekdays;

    Widget day(int number) {
      final mark = marks[number];
      final isSelected = number == selected;
      final fill = mark == null ? null : WakemixColors.strengthFill(mark);
      return Semantics(
        button: true,
        selected: isSelected,
        label: dayLabel(number),
        onTap: () => onDaySelected(number),
        excludeSemantics: true,
        child: InkResponse(
          onTap: () => onDaySelected(number),
          radius: dayHeight / 2,
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: isSelected ? Border.all(color: c.text, width: 2) : null,
              ),
              child: Text(
                '$number',
                style: theme.textTheme.labelLarge!.copyWith(
                  color: fill != null
                      ? WakemixColors.onStrength
                      : number == today
                      ? c.text
                      : c.textMuted,
                  fontWeight: number == today || isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
                // A disc has no room for bigger text.
                textScaler: TextScaler.noScaling,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const SizedBox(width: Space.s8),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  localizations.formatMonthYear(first),
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            IconButton(
              onPressed: onPrevious,
              tooltip: previousLabel,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              onPressed: onNext,
              tooltip: nextLabel,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: Space.s4),
        ExcludeSemantics(
          child: Row(
            children: [
              for (var column = 0; column < DateTime.daysPerWeek; column++)
                Expanded(
                  child: Center(
                    child: Text(
                      names[(column + 1) % DateTime.daysPerWeek],
                      style: theme.textTheme.labelMedium!.copyWith(
                        color: c.textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Space.s4),
        for (var row = 0; row < rows; row++)
          SizedBox(
            height: dayHeight,
            child: Row(
              children: [
                for (var column = 0; column < DateTime.daysPerWeek; column++)
                  Expanded(
                    child: switch (row * DateTime.daysPerWeek +
                        column -
                        lead +
                        1) {
                      final number when number >= 1 && number <= days => day(
                        number,
                      ),
                      _ => const SizedBox.shrink(),
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
