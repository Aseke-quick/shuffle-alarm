import 'package:shared_preferences/shared_preferences.dart';

/// The simple settings of the app, kept on the device: in a browser, in the
/// local storage of the site.
class SettingsRepository {
  SettingsRepository(this._store);

  final SharedPreferencesAsync _store;

  static const _bedtimeReminder = 'bedtime_reminder';
  static const _morningCard = 'morning_card';

  /// Whether the person wants the bedtime reminder. It is off until they turn
  /// it on.
  Future<bool> bedtimeReminder() async =>
      await _store.getBool(_bedtimeReminder) ?? false;

  Future<void> saveBedtimeReminder({required bool on}) =>
      _store.setBool(_bedtimeReminder, on);

  /// Whether the Morning card shows after Stop. It is on until the person
  /// turns it off.
  Future<bool> morningCard() async =>
      await _store.getBool(_morningCard) ?? true;

  Future<void> saveMorningCard({required bool on}) =>
      _store.setBool(_morningCard, on);
}
