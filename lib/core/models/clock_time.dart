import 'package:meta/meta.dart';

/// A time on the clock, such as 07:30, without a date or a time zone.
@immutable
class ClockTime {
  /// Throws a [RangeError] if [hour] is not 0–23 or [minute] is not 0–59.
  ClockTime({required this.hour, required this.minute}) {
    RangeError.checkValueInInterval(hour, 0, 23, 'hour');
    RangeError.checkValueInInterval(minute, 0, 59, 'minute');
  }

  final int hour;
  final int minute;

  @override
  bool operator ==(Object other) =>
      other is ClockTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  /// The 24-hour form with two digits each, such as `07:05`.
  @override
  String toString() => '${_twoDigits(hour)}:${_twoDigits(minute)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
