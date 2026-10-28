import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/data/ids.dart';

void main() {
  group('newId', () {
    test('is 32 hexadecimal digits', () {
      for (var i = 0; i < 1000; i++) {
        expect(newId(), matches(RegExp(r'^[0-9a-f]{32}$')));
      }
    });

    test('never gives the same id twice', () {
      final ids = {for (var i = 0; i < 10000; i++) newId()};

      expect(ids, hasLength(10000));
    });

    test('can give any digit in any place', () {
      final digitsByPlace = List.generate(32, (_) => <String>{});
      for (var i = 0; i < 1000; i++) {
        final id = newId();
        for (var place = 0; place < 32; place++) {
          digitsByPlace[place].add(id[place]);
        }
      }

      // 1000 random ids miss one of the 16 digits in some place with a
      // chance of about 1 in 10^25.
      expect(digitsByPlace, everyElement(hasLength(16)));
    });
  });
}
