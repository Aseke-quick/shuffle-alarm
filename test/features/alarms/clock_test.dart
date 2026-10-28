import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/features/alarms/clock.dart';

void main() {
  group('minuteTicks', () {
    // The fake clock of a widget test starts at 2015-01-01 00:00 UTC and
    // moves only when the test pumps. The tests do not await `cancel()`: its
    // future completes outside the fake time, and the test would never end.
    testWidgets('tells the time right away, then at the start of each minute', (
      tester,
    ) async {
      await tester.pump(const Duration(seconds: 20));
      final times = <DateTime>[];
      final ticks = minuteTicks(now: tester.binding.clock.now)
          .listen(times.add);

      await tester.pump();
      expect(times, [_utc(0, 20)]);

      await tester.pump(const Duration(seconds: 39));
      expect(times, [_utc(0, 20)]);

      await tester.pump(const Duration(seconds: 1));
      expect(times, [_utc(0, 20), _utc(1, 0)]);

      await tester.pump(const Duration(minutes: 1));
      expect(times, [_utc(0, 20), _utc(1, 0), _utc(2, 0)]);

      unawaited(ticks.cancel());
    });

    testWidgets('keeps to the clock when a tick comes late', (tester) async {
      // How far the clock is ahead of the timers.
      var frozen = Duration.zero;
      final times = <DateTime>[];
      final ticks = minuteTicks(
        now: () => tester.binding.clock.now().add(frozen),
      ).listen(times.add);
      await tester.pump();

      // The timers stood still for 50 s, as in a background tab of a
      // browser, so the next tick comes at 00:01:50.
      frozen = const Duration(seconds: 50);
      await tester.pump(const Duration(minutes: 1));
      // The one after it waits only for the rest of that minute.
      await tester.pump(const Duration(seconds: 10));

      expect(times, [_utc(0, 0), _utc(1, 50), _utc(2, 0)]);
      unawaited(ticks.cancel());
    });

    testWidgets('stops when nobody listens', (tester) async {
      final ticks = minuteTicks(now: tester.binding.clock.now).listen((_) {});
      await tester.pump();

      unawaited(ticks.cancel());
      // A widget test fails if a timer is still waiting at its end.
    });
  });
}

/// 2015-01-01 00:[minute]:[second] UTC.
DateTime _utc(int minute, int second) =>
    DateTime.utc(2015, 1, 1, 0, minute, second);
