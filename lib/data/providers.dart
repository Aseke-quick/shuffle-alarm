import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';

/// The app's database: opened once, when the app first needs it, and closed
/// with the app. Tests override it with a database in memory.
///
/// Opening it can fail, such as in a browser that blocks the site's storage.
/// The first query then fails, such as the stream of [alarmsProvider].
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.onDevice();
  ref.onDispose(() => unawaited(db.close()));
  return db;
});

final alarmRepositoryProvider = Provider<AlarmRepository>(
  (ref) => AlarmRepository(ref.watch(databaseProvider)),
);

/// Every alarm, by time of day: now, and again after each change.
final alarmsProvider = StreamProvider<List<Alarm>>(
  (ref) => ref.watch(alarmRepositoryProvider).watchAll(),
);

final soundRepositoryProvider = Provider<SoundRepository>(
  (ref) => SoundRepository(ref.watch(databaseProvider)),
);

/// The genres of the built-in sounds, A to Z: the genres an alarm can choose
/// (`buildRingSequence`). Now, and again after each change.
final genresProvider = StreamProvider<List<String>>(
  (ref) => ref
      .watch(soundRepositoryProvider)
      .watchAll()
      .map(
        (sounds) => {
          for (final stored in sounds)
            if (stored.sound.source == SoundSource.builtin) stored.sound.genre,
        }.toList()..sort(),
      ),
);
