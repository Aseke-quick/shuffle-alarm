import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/tokens.dart';

/// A time of day as the device shows it, such as "7:00 AM" or "07:00", with
/// the AM or PM at a smaller size. Screen readers hear it whole.
class TimeText extends StatelessWidget {
  const TimeText(
    this.time, {
    required this.style,
    this.color,
    this.textAlign,
    super.key,
  });

  final TimeOfDay time;

  /// The style of the clock part; the AM or PM is smaller.
  final TextStyle style;
  final Color? color;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final (clock, period) = timeParts(context, time);
    final size = style.fontSize ?? TypeScale.body;
    return Text.rich(
      TextSpan(
        text: clock,
        children: [
          if (period != null)
            TextSpan(
              // A plain space: the fonts have no thin one, and at the
              // smaller size it is narrow anyway.
              text: ' $period',
              style: TextStyle(
                fontSize: math.max(TypeScale.caption, size * 0.42),
                letterSpacing: 0,
              ),
            ),
        ],
      ),
      style: style.copyWith(color: color),
      textAlign: textAlign,
      semanticsLabel: time.format(context),
    );
  }
}

/// [time] as the device shows it ([TimeOfDay.format]), split into the clock
/// part and the AM or PM: ("7:00", "AM"), or ("07:00", null) on a device
/// set to 24-hour time.
(String, String?) timeParts(BuildContext context, TimeOfDay time) {
  final formatted = time.format(context);
  final localizations = MaterialLocalizations.of(context);
  final period = time.period == DayPeriod.am
      ? localizations.anteMeridiemAbbreviation
      : localizations.postMeridiemAbbreviation;
  if (!formatted.endsWith(' $period')) return (formatted, null);
  return (formatted.substring(0, formatted.length - period.length - 1), period);
}
