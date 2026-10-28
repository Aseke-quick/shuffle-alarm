import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';

import 'memory_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = memoryDatabase();
    container = ProviderContainer.test(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() => db.close());

  test('the alarm list follows every change', () async {
    final alarms = AlarmRepository(db);
    final lists = <List<Alarm>>[];
    container.listen(alarmsProvider, (_, next) => lists.add(next.requireValue));

    expect(await container.read(alarmsProvider.future), isEmpty);
    final alarm = Alarm(id: 'a', time: ClockTime(hour: 7, minute: 0));
    await alarms.save(alarm);
    await pumpEventQueue();
    await alarms.delete('a');
    await pumpEventQueue();

    expect(lists, [
      isEmpty,
      [alarm],
      isEmpty,
    ]);
  });

  test(
    'the genres are those of the built-in sounds, A to Z, once each',
    () async {
      final sounds = SoundRepository(db);
      for (final (id, source, genre) in [
        ('sunrise', SoundSource.builtin, 'pop'),
        ('ocean', SoundSource.builtin, 'pop'),
        ('blue', SoundSource.builtin, 'jazz'),
        ('my-song', SoundSource.user, 'my-songs'),
        ('mom', SoundSource.voice, 'voice'),
      ]) {
        await sounds.save(
          StoredSound(
            Sound(
              id: id,
              title: id,
              source: source,
              genre: genre,
              intensity: 1,
              duration: const Duration(seconds: 20),
            ),
            audioPath: '$genre/$id.mp3',
          ),
        );
      }

      // Riverpod pauses a provider that nobody listens to.
      final genres = container.listen(genresProvider.future, (_, _) {});
      expect(await genres.read(), ['jazz', 'pop']);
    },
  );
}
