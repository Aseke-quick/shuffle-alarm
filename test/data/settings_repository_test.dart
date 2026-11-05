import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:shuffle_alarm/data/settings_repository.dart';

void main() {
  late SettingsRepository settings;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    settings = SettingsRepository(SharedPreferencesAsync());
  });

  group('The Morning card', () {
    test('is on until someone turns it off', () async {
      expect(await settings.morningCard(), isTrue);
    });

    test('keeps what was saved', () async {
      await settings.saveMorningCard(on: false);
      expect(await settings.morningCard(), isFalse);

      await settings.saveMorningCard(on: true);
      expect(await settings.morningCard(), isTrue);
    });

    test('is saved apart from the bedtime reminder', () async {
      await settings.saveMorningCard(on: false);
      await settings.saveBedtimeReminder(on: true);

      expect(await settings.morningCard(), isFalse);
      expect(await settings.bedtimeReminder(), isTrue);
    });
  });
}
