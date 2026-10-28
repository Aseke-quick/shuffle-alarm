import 'dart:math';

/// A new random id, such as `0f8c2e9b5d1a4c7e8b3f6a2d9e0c1b47`: 32
/// hexadecimal digits from a secure random source, so two ids never turn out
/// the same in practice.
///
/// For the alarms, ring sessions, songs and voice messages the app creates. A
/// built-in sound keeps its id from `manifest.json`.
String newId() => [
  for (var i = 0; i < 16; i++)
    _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
].join();

final _random = Random.secure();
