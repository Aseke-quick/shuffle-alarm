import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/tokens.dart';

/// The time wheels: one wheel for the hours and one for the minutes, with the
/// chosen [time] big in a band in the middle (ADR-005).
///
/// - Dragging or scrolling a wheel turns it, and it settles on a value. Each
///   wheel goes round: after 59 comes 00.
/// - On a device that shows 12-hour time, AM and PM are two keys next to the
///   wheels.
/// - "Type the time" opens keyboard entry: the time picker in input mode.
/// - The arrow keys change the time by 1 minute, Page Up and Page Down by
///   1 hour.
/// - Screen readers get one adjustable value, such as "6:45 AM", with
///   increase and decrease.
/// - On phones, a light haptic tick marks each value that passes.
class TimeWheels extends StatefulWidget {
  const TimeWheels({
    required this.time,
    required this.onChanged,
    this.label = 'Alarm time',
    super.key,
  });

  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  /// What screen readers call the wheels.
  final String label;

  /// The height of one value of a wheel.
  static const itemExtent = 64.0;

  /// How much bigger the chosen value is than the others.
  static const magnification = 1.45;

  /// The height of the wheels: the chosen value and one above and below.
  static const double height = itemExtent * 3.6;

  @override
  State<TimeWheels> createState() => _TimeWheelsState();
}

class _TimeWheelsState extends State<TimeWheels> {
  late FixedExtentScrollController _hours;
  late FixedExtentScrollController _minutes;
  var _showFocus = false;

  /// Whether a change of the wheels comes from the widget moving them to a
  /// new [TimeWheels.time], not from a finger.
  var _syncing = false;

  /// The time it reported last, in minutes after midnight, until the parent
  /// builds it again: two changes in one frame, such as two key presses,
  /// then add up.
  int? _reported;

  int get _minuteOfDay =>
      _reported ??
      widget.time.hour * TimeOfDay.minutesPerHour + widget.time.minute;

  @override
  void initState() {
    super.initState();
    _hours = FixedExtentScrollController(initialItem: widget.time.hour);
    _minutes = FixedExtentScrollController(initialItem: widget.time.minute);
  }

  @override
  void didUpdateWidget(TimeWheels oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reported = null;
    if (oldWidget.time == widget.time) return;
    // After the frame: a wheel cannot move while it is laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncing = true;
      _turnTo(_hours, widget.time.hour, TimeOfDay.hoursPerDay);
      _turnTo(_minutes, widget.time.minute, TimeOfDay.minutesPerHour);
      _syncing = false;
    });
  }

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    super.dispose();
  }

  /// Turns the wheel of [controller] the short way round to [value], one of
  /// [count] values.
  void _turnTo(FixedExtentScrollController controller, int value, int count) {
    if (!controller.hasClients) return;
    final item = controller.selectedItem;
    final step =
        (value - item % count + count + count ~/ 2) % count - count ~/ 2;
    if (step != 0) controller.jumpToItem(item + step);
  }

  /// Changes the time to [minutes] after midnight, any number of days before
  /// or after.
  void _moveTo(int minutes) {
    final time = minutes % Duration.minutesPerDay;
    if (time == _minuteOfDay) return;
    _reported = time;
    widget.onChanged(
      TimeOfDay(
        hour: time ~/ TimeOfDay.minutesPerHour,
        minute: time % TimeOfDay.minutesPerHour,
      ),
    );
  }

  void _step(int minutes) => _moveTo(_minuteOfDay + minutes);

  void _hourTurned(int item) {
    if (_syncing) return;
    _tick();
    _moveTo(
      item % TimeOfDay.hoursPerDay * TimeOfDay.minutesPerHour +
          _minuteOfDay % TimeOfDay.minutesPerHour,
    );
  }

  void _minuteTurned(int item) {
    if (_syncing) return;
    _tick();
    _moveTo(
      _minuteOfDay -
          _minuteOfDay % TimeOfDay.minutesPerHour +
          item % TimeOfDay.minutesPerHour,
    );
  }

  String _format(int minutes) {
    final time = minutes % Duration.minutesPerDay;
    return TimeOfDay(
      hour: time ~/ TimeOfDay.minutesPerHour,
      minute: time % TimeOfDay.minutesPerHour,
    ).format(context);
  }

  /// A light haptic tick, on phones only.
  void _tick() {
    if (defaultTargetPlatform
        case TargetPlatform.android || TargetPlatform.iOS) {
      unawaited(HapticFeedback.selectionClick());
    }
  }

  Future<void> _type() async {
    final typed = await showDialog<TimeOfDay>(
      context: context,
      animationStyle: Motion.styleOf(context),
      builder: (context) => TimePickerDialog(
        initialTime: widget.time,
        initialEntryMode: TimePickerEntryMode.inputOnly,
      ),
    );
    if (typed == null || !mounted) return;
    _moveTo(typed.hour * TimeOfDay.minutesPerHour + typed.minute);
  }

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    // As the device shows a time: with AM and PM, or 24 hours.
    final twelveHour =
        !MediaQuery.alwaysUse24HourFormatOf(context) &&
        MaterialLocalizations.of(context).timeOfDayFormat() ==
            TimeOfDayFormat.h_colon_mm_space_a;
    final localizations = MaterialLocalizations.of(context);
    final digits = theme.textTheme.displayMedium!.copyWith(
      fontSize: 46,
      letterSpacing: -2,
    );
    String hourText(int hour) {
      if (!twelveHour) return hour.toString().padLeft(2, '0');
      final ofPeriod = hour % TimeOfDay.hoursPerPeriod;
      return '${ofPeriod == 0 ? TimeOfDay.hoursPerPeriod : ofPeriod}';
    }

    Widget wheel({
      required FixedExtentScrollController controller,
      required int count,
      required String Function(int value) text,
      required ValueChanged<int> onTurned,
    }) => SizedBox(
      width: 112,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: TimeWheels.itemExtent,
        physics: const FixedExtentScrollPhysics(),
        diameterRatio: 1.7,
        useMagnifier: true,
        magnification: TimeWheels.magnification,
        overAndUnderCenterOpacity: 0.42,
        onSelectedItemChanged: onTurned,
        childDelegate: ListWheelChildLoopingListDelegate(
          children: [
            for (var value = 0; value < count; value++)
              Center(
                child: Text(
                  text(value),
                  style: digits,
                  // Big already: they do not grow with the text scale.
                  textScaler: TextScaler.noScaling,
                ),
              ),
          ],
        ),
      ),
    );

    final wheels = SizedBox(
      height: TimeWheels.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The band of the chosen value.
          Positioned(
            left: 0,
            right: 0,
            child: Container(
              height: TimeWheels.itemExtent * TimeWheels.magnification + 8,
              decoration: BoxDecoration(
                color: c.glass,
                border: Border.all(
                  color: _showFocus
                      ? c.accent
                      : c.accent.withValues(alpha: 0.5),
                  width: _showFocus ? 2 : 1.5,
                ),
                borderRadius: const BorderRadius.all(
                  Radius.circular(Corners.hero),
                ),
              ),
            ),
          ),
          ExcludeSemantics(
            child: ScrollConfiguration(
              // A mouse drags a wheel too, as a finger does.
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: PointerDeviceKind.values.toSet(),
                scrollbars: false,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  wheel(
                    controller: _hours,
                    count: TimeOfDay.hoursPerDay,
                    text: hourText,
                    onTurned: _hourTurned,
                  ),
                  Text(
                    ':',
                    style: digits.copyWith(
                      fontSize: 46 * TimeWheels.magnification,
                    ),
                    textScaler: TextScaler.noScaling,
                  ),
                  wheel(
                    controller: _minutes,
                    count: TimeOfDay.minutesPerHour,
                    text: (minute) => minute.toString().padLeft(2, '0'),
                    onTurned: _minuteTurned,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          container: true,
          label: widget.label,
          value: _format(_minuteOfDay),
          increasedValue: _format(_minuteOfDay + 1),
          decreasedValue: _format(_minuteOfDay - 1),
          onIncrease: () => _step(1),
          onDecrease: () => _step(-1),
          child: FocusableActionDetector(
            onShowFocusHighlight: (show) => setState(() => _showFocus = show),
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.arrowUp): _StepIntent(1),
              SingleActivator(LogicalKeyboardKey.arrowRight): _StepIntent(1),
              SingleActivator(LogicalKeyboardKey.arrowDown): _StepIntent(-1),
              SingleActivator(LogicalKeyboardKey.arrowLeft): _StepIntent(-1),
              SingleActivator(LogicalKeyboardKey.pageUp): _StepIntent(
                TimeOfDay.minutesPerHour,
              ),
              SingleActivator(LogicalKeyboardKey.pageDown): _StepIntent(
                -TimeOfDay.minutesPerHour,
              ),
            },
            actions: {
              _StepIntent: CallbackAction<_StepIntent>(
                onInvoke: (intent) => _step(intent.minutes),
              ),
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: wheels,
            ),
          ),
        ),
        const SizedBox(height: Space.s8),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: Space.s8,
          runSpacing: Space.s8,
          children: [
            if (twelveHour)
              SegmentedButton<DayPeriod>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: DayPeriod.am,
                    label: Text(localizations.anteMeridiemAbbreviation),
                  ),
                  ButtonSegment(
                    value: DayPeriod.pm,
                    label: Text(localizations.postMeridiemAbbreviation),
                  ),
                ],
                selected: {widget.time.period},
                onSelectionChanged: (periods) {
                  if (periods.single == widget.time.period) return;
                  _step(
                    periods.single == DayPeriod.pm
                        ? TimeOfDay.hoursPerPeriod * TimeOfDay.minutesPerHour
                        : -TimeOfDay.hoursPerPeriod * TimeOfDay.minutesPerHour,
                  );
                },
              ),
            TextButton.icon(
              onPressed: _type,
              icon: const Icon(Icons.keyboard_outlined, size: 20),
              label: const Text('Type the time'),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepIntent extends Intent {
  const _StepIntent(this.minutes);

  final int minutes;
}
