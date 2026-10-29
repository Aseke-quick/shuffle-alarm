import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/time_text.dart';
import 'package:shuffle_alarm/design/theme.dart';
import 'package:shuffle_alarm/design/tokens.dart';

/// The rotary time dial: a knob that runs around a ring of minute marks,
/// with the [time] in the middle.
///
/// - Dragging on the ring puts the knob, and the minute, where the finger
///   points. One turn is 60 minutes, and passing 12 o'clock moves the
///   hour: clockwise to the next one, counter-clockwise to the one before.
/// - A tap on the time opens keyboard entry: the time picker in input mode.
/// - The arrow keys change the time by 1 minute, Page Up and Page Down by
///   1 hour.
/// - Screen readers get an adjustable value, such as "6:45 AM", with
///   increase and decrease.
/// - On phones, a light haptic tick marks every 5 minutes of a drag.
class RotaryTimeDial extends StatefulWidget {
  const RotaryTimeDial({
    required this.time,
    required this.onChanged,
    this.label = 'Alarm time',
    super.key,
  });

  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  /// What screen readers call the dial.
  final String label;

  /// The largest the dial gets.
  static const maxDiameter = 320.0;

  /// How far in from the edge the knob runs.
  static const trackInset = 30.0;

  /// How thick the ring is that the knob runs on.
  static const trackWidth = 28.0;

  @override
  State<RotaryTimeDial> createState() => _RotaryTimeDialState();
}

class _RotaryTimeDialState extends State<RotaryTimeDial> {
  /// The radius of the dial at the last layout.
  var _radius = 0.0;

  /// While dragging: the time last given to [RotaryTimeDial.onChanged], in
  /// minutes after midnight. Null before the first move of a drag.
  int? _dragMinutes;

  var _showFocus = false;

  int get _minutes =>
      widget.time.hour * TimeOfDay.minutesPerHour + widget.time.minute;

  /// Changes the time to [minutes] after midnight, any number of days
  /// before or after.
  void _moveTo(int minutes) {
    final time = minutes % Duration.minutesPerDay;
    if (time == _minutes) return;
    widget.onChanged(
      TimeOfDay(
        hour: time ~/ TimeOfDay.minutesPerHour,
        minute: time % TimeOfDay.minutesPerHour,
      ),
    );
  }

  void _step(int minutes) => _moveTo(_minutes + minutes);

  String _format(int minutes) {
    final time = minutes % Duration.minutesPerDay;
    return TimeOfDay(
      hour: time ~/ TimeOfDay.minutesPerHour,
      minute: time % TimeOfDay.minutesPerHour,
    ).format(context);
  }

  /// Whether [position] is on the ring, where a drag turns the dial. The
  /// middle belongs to the time, which opens keyboard entry.
  bool _onRing(Offset position) {
    final distance = (position - Offset(_radius, _radius)).distance;
    final inner =
        _radius - RotaryTimeDial.trackInset - RotaryTimeDial.trackWidth;
    return distance >= inner && distance <= _radius;
  }

  void _dragStart() => _dragMinutes = null;

  void _dragUpdate(Offset position) {
    final offset = position - Offset(_radius, _radius);
    // Near the middle a small move turns the angle a lot.
    if (offset.distance < _radius * 0.25) return;
    // Clockwise from 12 o'clock.
    final angle = math.atan2(offset.dx, -offset.dy);
    final minute =
        (angle / (2 * math.pi) * TimeOfDay.minutesPerHour).round() %
        TimeOfDay.minutesPerHour;
    final before = _dragMinutes;
    final int after;
    if (before == null) {
      // The first move puts the knob under the finger, in the same hour.
      after = widget.time.hour * TimeOfDay.minutesPerHour + minute;
    } else {
      // The shorter way round from the last minute, so a move across
      // 12 o'clock passes into the next or the last hour.
      final step =
          (minute - before % TimeOfDay.minutesPerHour + 30) %
              TimeOfDay.minutesPerHour -
          30;
      after = before + step;
      if ((before / 5).floor() != (after / 5).floor()) _tick();
    }
    _dragMinutes = after % Duration.minutesPerDay;
    _moveTo(after);
  }

  void _dragEnd() => _dragMinutes = null;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter = math.min(
          constraints.maxWidth,
          RotaryTimeDial.maxDiameter,
        );
        _radius = diameter / 2;
        final middle =
            diameter -
            2 *
                (RotaryTimeDial.trackInset +
                    RotaryTimeDial.trackWidth +
                    Space.s8);
        return Center(
          child: SizedBox.square(
            dimension: diameter,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Semantics(
                    container: true,
                    label: widget.label,
                    value: _format(_minutes),
                    increasedValue: _format(_minutes + 1),
                    decreasedValue: _format(_minutes - 1),
                    onIncrease: () => _step(1),
                    onDecrease: () => _step(-1),
                    child: FocusableActionDetector(
                      onShowFocusHighlight: (show) =>
                          setState(() => _showFocus = show),
                      shortcuts: const {
                        SingleActivator(LogicalKeyboardKey.arrowUp):
                            _StepIntent(1),
                        SingleActivator(LogicalKeyboardKey.arrowRight):
                            _StepIntent(1),
                        SingleActivator(LogicalKeyboardKey.arrowDown):
                            _StepIntent(-1),
                        SingleActivator(LogicalKeyboardKey.arrowLeft):
                            _StepIntent(-1),
                        SingleActivator(LogicalKeyboardKey.pageUp): _StepIntent(
                          TimeOfDay.minutesPerHour,
                        ),
                        SingleActivator(LogicalKeyboardKey.pageDown):
                            _StepIntent(-TimeOfDay.minutesPerHour),
                      },
                      actions: {
                        _StepIntent: CallbackAction<_StepIntent>(
                          onInvoke: (intent) => _step(intent.minutes),
                        ),
                      },
                      mouseCursor: SystemMouseCursors.grab,
                      child: RawGestureDetector(
                        gestures: {
                          _RingDragRecognizer:
                              GestureRecognizerFactoryWithHandlers<
                                _RingDragRecognizer
                              >(
                                () => _RingDragRecognizer(debugOwner: this),
                                (recognizer) => recognizer
                                  ..isOnRing = _onRing
                                  ..onStart = _dragStart
                                  ..onUpdate = _dragUpdate
                                  ..onEnd = _dragEnd,
                              ),
                        },
                        child: CustomPaint(
                          painter: _DialPainter(
                            minute: widget.time.minute,
                            focused: _showFocus,
                            colors: c,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox.square(
                  dimension: middle,
                  // One button for screen readers: the tooltip and the time
                  // inside it would say it all again.
                  child: Semantics(
                    container: true,
                    button: true,
                    label: 'Type the time',
                    onTap: _type,
                    excludeSemantics: true,
                    child: Tooltip(
                      message: 'Type the time',
                      child: Material(
                        type: MaterialType.transparency,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _type,
                          child: Padding(
                            padding: const EdgeInsets.all(Space.s16),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TimeText(
                                    widget.time,
                                    style: theme.textTheme.displayLarge!,
                                  ),
                                  const SizedBox(height: Space.s8),
                                  Text(
                                    'TAP TO TYPE',
                                    style: WakemixType.of(context).caption,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StepIntent extends Intent {
  const _StepIntent(this.minutes);

  final int minutes;
}

/// Takes a drag that starts on the dial's ring as soon as it moves, before
/// a list around the dial can take it for a scroll. A drag elsewhere, or a
/// tap, is left to others.
class _RingDragRecognizer extends OneSequenceGestureRecognizer {
  _RingDragRecognizer({super.debugOwner});

  bool Function(Offset position) isOnRing = _never;
  VoidCallback? onStart;
  ValueChanged<Offset>? onUpdate;
  VoidCallback? onEnd;

  /// How far a pointer moves before it counts as a drag: less than a
  /// scroll needs.
  static const slop = 2.0;

  Offset? _down;
  var _accepted = false;

  static bool _never(Offset position) => false;

  @override
  bool isPointerAllowed(PointerDownEvent event) =>
      _down == null &&
      super.isPointerAllowed(event) &&
      isOnRing(event.localPosition);

  @override
  void addAllowedPointer(PointerDownEvent event) {
    // Starts tracking the pointer, in the dial's own coordinates.
    super.addAllowedPointer(event);
    _down = event.localPosition;
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      if (!_accepted && (event.localPosition - _down!).distance > slop) {
        resolve(GestureDisposition.accepted);
      }
      if (_accepted) {
        invokeCallback<void>(
          'onUpdate',
          () => onUpdate?.call(event.localPosition),
        );
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (_accepted) invokeCallback<void>('onEnd', () => onEnd?.call());
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void acceptGesture(int pointer) {
    _accepted = true;
    invokeCallback<void>('onStart', () => onStart?.call());
  }

  @override
  void rejectGesture(int pointer) => stopTrackingPointer(pointer);

  @override
  void didStopTrackingLastPointer(int pointer) {
    _down = null;
    _accepted = false;
  }

  @override
  String get debugDescription => 'rotary dial drag';
}

class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.minute,
    required this.focused,
    required this.colors,
  });

  final int minute;
  final bool focused;
  final WakemixColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    // A mark for each minute, longer for each 5 minutes.
    for (var i = 0; i < TimeOfDay.minutesPerHour; i++) {
      final major = i % 5 == 0;
      final angle = i / TimeOfDay.minutesPerHour * 2 * math.pi;
      final direction = Offset(math.sin(angle), -math.cos(angle));
      canvas.drawLine(
        center + direction * (radius - 4),
        center + direction * (radius - (major ? 16 : 10)),
        Paint()
          ..strokeWidth = major ? 2 : 1
          ..strokeCap = StrokeCap.round
          ..color = major ? colors.textMuted : colors.textDisabled,
      );
    }

    // The ring the knob runs on.
    final track =
        radius - RotaryTimeDial.trackInset - RotaryTimeDial.trackWidth / 2;
    canvas.drawCircle(
      center,
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = RotaryTimeDial.trackWidth
        ..color = colors.surfaceHigh,
    );

    // The knob, at the minute.
    final angle = minute / TimeOfDay.minutesPerHour * 2 * math.pi;
    final knob = center + Offset(math.sin(angle), -math.cos(angle)) * track;
    canvas
      ..drawCircle(
        knob,
        RotaryTimeDial.trackWidth / 2,
        Paint()..color = colors.accent,
      )
      ..drawCircle(knob, 3, Paint()..color = colors.onAccent);

    if (focused) {
      canvas.drawCircle(
        center,
        radius - 1,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = colors.accent,
      );
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.minute != minute || old.focused != focused || old.colors != colors;
}
