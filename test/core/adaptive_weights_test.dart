import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/adaptive_weights.dart';

void main() {
  group('SoundWeights', () {
    test('gives every sound the start weight 1.0', () {
      expect(SoundWeights.startWeight, 1.0);

      for (final weights in [SoundWeights(), const SoundWeights.start()]) {
        expect(weights.weightOf('sound-1'), 1.0);
        expect(weights.weightOf('a sound it never heard of'), 1.0);
      }
    });

    test('keeps the weights it gets, by sound id', () {
      final weights = SoundWeights(const {'sound-1': 2.5, 'sound-2': 0.4});

      expect(weights.weightOf('sound-1'), 2.5);
      expect(weights.weightOf('sound-2'), 0.4);
      expect(weights.weightOf('sound-3'), 1.0);
    });

    test('multiplies the weight of the sound at Snooze by 0.8', () {
      final weights = SoundWeights(const {'sound-2': 2});

      expect(weights.afterSnooze('sound-1').weightOf('sound-1'), 0.8);
      expect(
        weights.afterSnooze('sound-2').weightOf('sound-2'),
        closeTo(1.6, 1e-9),
      );
    });

    test('multiplies the weight of the sound at Stop by 1.1', () {
      final weights = SoundWeights(const {'sound-2': 2});

      expect(weights.afterStop('sound-1').weightOf('sound-1'), 1.1);
      expect(
        weights.afterStop('sound-2').weightOf('sound-2'),
        closeTo(2.2, 1e-9),
      );
    });

    test('multiplies the weight of the sound that woke the user by 1.2', () {
      final weights = SoundWeights(const {'sound-2': 2});

      expect(SoundWeights.wokeFactor, 1.2);
      expect(weights.afterWoke('sound-1').weightOf('sound-1'), 1.2);
      expect(
        weights.afterWoke('sound-2').weightOf('sound-2'),
        closeTo(2.4, 1e-9),
      );
    });

    test('the answer adds to what Stop taught the same sound', () {
      final weights = SoundWeights().afterStop('sound-1').afterWoke('sound-1');

      expect(weights.weightOf('sound-1'), closeTo(1.32, 1e-9));
    });

    test('the answer leaves what Stop taught another sound', () {
      final weights = SoundWeights().afterStop('sound-1').afterWoke('sound-2');

      expect(weights.weightOf('sound-1'), 1.1);
      expect(weights.weightOf('sound-2'), 1.2);
    });

    test('the answer adds to what Snooze taught the same sound', () {
      final weights = SoundWeights()
          .afterSnooze('sound-1')
          .afterWoke('sound-1');

      expect(weights.weightOf('sound-1'), closeTo(0.96, 1e-9));
    });

    test('the answer changes no other sound, in a new value', () {
      final before = SoundWeights(const {'sound-1': 2, 'sound-2': 0.5});
      final after = before.afterWoke('sound-1');

      expect(before, SoundWeights(const {'sound-1': 2, 'sound-2': 0.5}));
      expect(after.weightOf('sound-2'), 0.5);
      expect(after.weightOf('sound-3'), 1.0);
    });

    test('never goes above 3.0, however often a sound wakes the user', () {
      final steps = _taps(100, (weights) => weights.afterWoke('sound-1'));

      // 1.2 to the 6th is 2.99, and to the 7th 3.58: the 7th answer in a row
      // takes a sound from 1.0 to the limit.
      expect(steps[5], closeTo(2.985984, 1e-6));
      expect(steps.skip(6), everyElement(3.0));
    });

    test('leaves the lower limit after an answer', () {
      final weights = SoundWeights(const {'sound-1': 0.2});

      expect(
        weights.afterWoke('sound-1').weightOf('sound-1'),
        closeTo(0.24, 1e-9),
      );
    });

    test('changes only the weight of that sound, in a new value', () {
      final before = SoundWeights(const {'sound-1': 2, 'sound-2': 0.5});
      final snoozed = before.afterSnooze('sound-1');
      final stopped = before.afterStop('sound-2');

      expect(before, SoundWeights(const {'sound-1': 2, 'sound-2': 0.5}));
      expect(snoozed.weightOf('sound-2'), 0.5);
      expect(snoozed.weightOf('sound-3'), 1.0);
      expect(stopped.weightOf('sound-1'), 2.0);
      expect(stopped.weightOf('sound-3'), 1.0);
    });

    test('never goes below 0.2, however often the user snoozes', () {
      final steps = _taps(100, (weights) => weights.afterSnooze('sound-1'));

      // 0.8 to the 7th is 0.21, and to the 8th 0.17: the 8th Snooze in a row
      // takes a sound from 1.0 to the limit.
      expect(steps[6], closeTo(0.2097152, 1e-9));
      expect(steps.skip(7), everyElement(0.2));
    });

    test('never goes above 3.0, however often the user stops', () {
      final steps = _taps(100, (weights) => weights.afterStop('sound-1'));

      // 1.1 to the 11th is 2.85, and to the 12th 3.14: the 12th Stop in a
      // row takes a sound from 1.0 to the limit.
      expect(steps[10], closeTo(2.8531167, 1e-6));
      expect(steps.skip(11), everyElement(3.0));
    });

    test('leaves a limit after a tap the other way', () {
      final weights = SoundWeights(const {'sound-1': 0.2, 'sound-2': 3});

      expect(
        weights.afterStop('sound-1').weightOf('sound-1'),
        closeTo(0.22, 1e-9),
      );
      expect(
        weights.afterSnooze('sound-2').weightOf('sound-2'),
        closeTo(2.4, 1e-9),
      );
    });

    test('stays between 0.2 and 3.0, whatever the user taps', () {
      final random = Random(1);
      var weights = SoundWeights();
      final seen = <double>[];
      for (var tap = 0; tap < 10000; tap++) {
        final id = 'sound-${random.nextInt(3) + 1}';
        // With 3 Snoozes in 10 taps the weights neither climb nor fall on
        // average, so they reach both limits again and again.
        weights = random.nextDouble() < 0.3
            ? weights.afterSnooze(id)
            : weights.afterStop(id);
        seen.add(weights.weightOf(id));
      }

      expect(seen.reduce(min), 0.2);
      expect(seen.reduce(max), 3.0);
    });

    test('moves a stored weight outside the limits to the nearest limit', () {
      final weights = SoundWeights(const {
        'too-light': 0.05,
        'negative': -1,
        'endlessly-light': double.negativeInfinity,
        'too-heavy': 7.5,
        'endlessly-heavy': double.infinity,
      });

      expect(weights.weightOf('too-light'), 0.2);
      expect(weights.weightOf('negative'), 0.2);
      expect(weights.weightOf('endlessly-light'), 0.2);
      expect(weights.weightOf('too-heavy'), 3.0);
      expect(weights.weightOf('endlessly-heavy'), 3.0);
    });

    test('gives a stored weight that is not a number the start weight', () {
      final weights = SoundWeights(const {'sound-1': double.nan});

      expect(weights.weightOf('sound-1'), 1.0);
    });

    test('does not change when the map it got changes', () {
      final map = {'sound-1': 2.5};
      final weights = SoundWeights(map);

      map['sound-1'] = 0.5;

      expect(weights.weightOf('sound-1'), 2.5);
    });

    test('equals weights that give every sound the same weight', () {
      final pairs = [
        (
          SoundWeights(const {'sound-1': 2.5}),
          SoundWeights(const {'sound-1': 2.5}),
        ),
        // A stored start weight is the same as no stored weight.
        (SoundWeights(const {'sound-1': 1}), SoundWeights()),
        (SoundWeights(), const SoundWeights.start()),
        // A stored weight over the limit is the limit.
        (
          SoundWeights(const {'sound-1': 9}),
          SoundWeights(const {'sound-1': 3}),
        ),
        (
          SoundWeights().afterSnooze('sound-1'),
          SoundWeights(const {'sound-1': 0.8}),
        ),
      ];

      for (final (weights, same) in pairs) {
        expect(weights, same);
        expect(weights.hashCode, same.hashCode);
      }
    });

    test('differs from weights with one other weight', () {
      final weights = SoundWeights(const {'sound-1': 2.5, 'sound-2': 0.5});

      for (final other in [
        SoundWeights(const {'sound-1': 2.5}),
        SoundWeights(const {'sound-1': 2.5, 'sound-2': 0.6}),
        SoundWeights(const {'sound-1': 2.5, 'sound-3': 0.5}),
        SoundWeights(const {'sound-1': 2.5, 'sound-2': 0.5, 'sound-3': 0.5}),
      ]) {
        expect(other, isNot(weights));
      }
    });
  });
}

/// The weight of `sound-1` after each of [count] taps in a row, each one made
/// by [tap], from the start weight on.
List<double> _taps(int count, SoundWeights Function(SoundWeights) tap) {
  var weights = SoundWeights();
  final steps = <double>[];
  for (var i = 0; i < count; i++) {
    weights = tap(weights);
    steps.add(weights.weightOf('sound-1'));
  }
  return steps;
}
