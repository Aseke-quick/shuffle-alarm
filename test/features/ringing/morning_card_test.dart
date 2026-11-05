import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:shuffle_alarm/core/fallback_tone.dart';
import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/core/models/sound.dart';
import 'package:shuffle_alarm/core/morning.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/data/settings_repository.dart';
import 'package:shuffle_alarm/data/sound_repository.dart';
import 'package:shuffle_alarm/design/components/record.dart';
import 'package:shuffle_alarm/features/ringing/morning_card.dart';

void main() {
  group('morningCardSounds', () {
    test('lists the sounds in the order they played, with their files', () {
      final rows = morningCardSounds(_morning(['b', 'a']), [
        _stored('a', title: 'Alpha'),
        _stored('b', title: 'Beta'),
        _stored('c', title: 'Gamma'),
      ]);

      expect(rows.map((row) => row.sound.title), ['Beta', 'Alpha']);
      expect(rows.map((row) => row.audioPath), [
        'sounds/b.wav',
        'sounds/a.wav',
      ]);
      expect(rows.first.played.firstAt, Duration.zero);
      expect(rows.last.played.firstAt, const Duration(seconds: 20));
    });

    test('leaves out a sound deleted since: it has no title any more', () {
      final rows = morningCardSounds(_morning(['gone', 'a']), [_stored('a')]);

      expect(rows.map((row) => row.sound.id), ['a']);
    });

    test('has the tone, which is saved nowhere, without a file', () {
      final rows = morningCardSounds(_morning([fallbackTone.id]), const []);

      expect(rows.single.sound, fallbackTone);
      expect(rows.single.audioPath, isNull);
    });

    test('has nothing when no sound played', () {
      final morning = Morning.of(
        RingSession(
          id: 's',
          alarmId: 'a',
          scheduledFor: _seven,
          events: [
            RingEvent.silent(soundId: 'a', at: _seven, action: RingAction.stop),
          ],
        ),
      )!;

      expect(morningCardSounds(morning, [_stored('a')]), isEmpty);
    });
  });

  group('morningRecordSegments', () {
    test('shows how long each sound played, and how strong it is', () {
      final rows = morningCardSounds(_morning(['a', 'b', 'c']), [
        _stored('a'),
        _stored('b', intensity: 2),
        _stored('c', intensity: 3),
      ]);

      expect(morningRecordSegments(rows), const [
        RecordSegment(length: Duration(seconds: 20), strength: 0),
        RecordSegment(length: Duration(seconds: 20), strength: 0.5),
        RecordSegment(length: Duration(seconds: 20)),
      ]);
    });
  });

  group('The setting of the card', () {
    /// Keeps it alive, as the app does.
    ProviderContainer container({List<Override> overrides = const []}) =>
        ProviderContainer.test(overrides: overrides)
          ..listen(morningCardOnProvider, (_, _) {});

    setUp(
      () => SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty(),
    );

    test('is on until someone turns it off', () async {
      final settings = container();

      expect(settings.read(morningCardOnProvider), isTrue);
      await pumpEventQueue();
      expect(settings.read(morningCardOnProvider), isTrue);
    });

    test('reads what was saved', () async {
      await SettingsRepository(SharedPreferencesAsync())
          .saveMorningCard(on: false);
      final settings = container();

      await pumpEventQueue();

      expect(settings.read(morningCardOnProvider), isFalse);
    });

    test('saves a change, which holds after a restart', () async {
      final first = container();
      await pumpEventQueue();

      await first.read(morningCardOnProvider.notifier).turn(on: false);

      expect(first.read(morningCardOnProvider), isFalse);
      final second = container();
      await pumpEventQueue();
      expect(second.read(morningCardOnProvider), isFalse);

      await second.read(morningCardOnProvider.notifier).turn(on: true);
      expect(second.read(morningCardOnProvider), isTrue);
      expect(
        await SettingsRepository(SharedPreferencesAsync()).morningCard(),
        isTrue,
      );
    });

    test('stays on when it cannot be read', () async {
      final settings = container(
        overrides: [
          settingsRepositoryProvider.overrideWith(
            (ref) => _BrokenSettings(SharedPreferencesAsync()),
          ),
        ],
      );

      await pumpEventQueue();

      expect(settings.read(morningCardOnProvider), isTrue);
    });

    test('holds a change that cannot be saved, until the app closes', () async {
      final settings = container(
        overrides: [
          settingsRepositoryProvider.overrideWith(
            (ref) => _BrokenSettings(SharedPreferencesAsync()),
          ),
        ],
      );
      await pumpEventQueue();

      await settings.read(morningCardOnProvider.notifier).turn(on: false);

      expect(settings.read(morningCardOnProvider), isFalse);
    });
  });
}

final _seven = DateTime(2026, 11, 3, 7);

/// A morning where these sounds played one after the other, 20 s each.
Morning _morning(List<String> soundIds) {
  final events = [
    for (final (index, id) in soundIds.indexed)
      RingEvent(
        soundId: id,
        startedAt: _seven.add(Duration(seconds: 20 * index)),
        endedAt: _seven.add(Duration(seconds: 20 * (index + 1))),
        action: index == soundIds.length - 1
            ? RingAction.stop
            : RingAction.timeout,
      ),
  ];
  return Morning.of(
    RingSession(id: 's', alarmId: 'a', scheduledFor: _seven, events: events),
  )!;
}

StoredSound _stored(String id, {String? title, int intensity = 1}) =>
    StoredSound(
      Sound(
        id: id,
        title: title ?? id,
        source: SoundSource.builtin,
        genre: 'calm',
        intensity: intensity,
        duration: const Duration(seconds: 20),
      ),
      audioPath: 'sounds/$id.wav',
    );

/// Settings whose store always fails.
class _BrokenSettings extends SettingsRepository {
  _BrokenSettings(super._store);

  @override
  Future<bool> morningCard() async => throw StateError('Broken');

  @override
  Future<void> saveMorningCard({required bool on}) async =>
      throw StateError('Broken');
}
