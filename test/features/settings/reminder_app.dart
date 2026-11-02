import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/core/models/clock_time.dart';
import 'package:shuffle_alarm/data/alarm_repository.dart';
import 'package:shuffle_alarm/data/database.dart';
import 'package:shuffle_alarm/data/settings_repository.dart';
import 'package:shuffle_alarm/platform/providers.dart';
import 'package:shuffle_alarm/platform/system_notifications.dart';

import '../../platform/fake_platform.dart';
import '../alarms/alarms_app.dart';

/// An empty settings store in memory, where the app's Dart VM in tests has
/// none. Call it in `setUp`.
void useMemorySettings() => SharedPreferencesAsyncPlatform.instance =
    InMemorySharedPreferencesAsync.empty();

/// What the settings store says about the bedtime reminder.
Future<bool> savedReminder() =>
    SettingsRepository(SharedPreferencesAsync()).bedtimeReminder();

/// A 07:00 alarm.
Alarm sevenOClock({bool enabled = true}) =>
    Alarm(id: 'seven', time: ClockTime(hour: 7, minute: 0), enabled: enabled);

/// Opens the app on the Alarms tab with [notifications], [alarms], and the
/// bedtime reminder saved as [saved] (null: nothing saved yet). Returns its
/// clock, which moves only when the test moves it.
Future<TestClock> openWithReminder(
  WidgetTester tester, {
  required AppDatabase db,
  required SystemNotifications notifications,
  required DateTime now,
  bool? saved,
  List<Alarm>? alarms,
  List<Override> overrides = const [],
  Size size = const Size(800, 1600),
}) async {
  if (saved != null) {
    await SettingsRepository(SharedPreferencesAsync())
        .saveBedtimeReminder(on: saved);
  }
  for (final alarm in alarms ?? [sevenOClock()]) {
    await AlarmRepository(db).save(alarm);
  }
  return await openAlarms(
    tester,
    db: db,
    now: now,
    size: size,
    overrides: [
      systemNotificationsProvider.overrideWithValue(notifications),
      ...overrides,
    ],
  );
}

/// Opens Settings from the gear of the Alarms tab.
Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
}

/// The notifications of a browser that shows them, where the person has
/// answered yes before.
FakeSystemNotifications allowedNotifications() =>
    FakeSystemNotifications(access: NotificationAccess.allowed);
