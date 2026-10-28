import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The time now, again at the start of each minute, so that texts such as
/// "Rings in 7 h 20 min" keep up with the clock. Tests override it with a
/// clock of their own.
final clockProvider = NotifierProvider<Clock, DateTime>(Clock.new);

/// The time now, from the device's clock.
class Clock extends Notifier<DateTime> {
  @override
  DateTime build() {
    final ticks = minuteTicks().listen((time) => state = time);
    ref.onDispose(() => unawaited(ticks.cancel()));
    return DateTime.now();
  }
}

/// The time from [now] right away, then again each time a minute starts.
///
/// Alarm times are whole minutes, so a text that counts the minutes until an
/// alarm changes only when a minute starts. Each wait is worked out again
/// from [now], so a tick that comes late, such as in a background tab of a
/// browser or after the device slept, puts the next one back on the minute.
Stream<DateTime> minuteTicks({DateTime Function() now = DateTime.now}) {
  Timer? timer;
  late final StreamController<DateTime> ticks;
  void tick() {
    final time = now();
    ticks.add(time);
    final intoMinute =
        time.microsecondsSinceEpoch % Duration.microsecondsPerMinute;
    timer = Timer(
      Duration(microseconds: Duration.microsecondsPerMinute - intoMinute),
      tick,
    );
  }

  ticks = StreamController<DateTime>(
    onListen: tick,
    onCancel: () => timer?.cancel(),
  );
  return ticks.stream;
}
