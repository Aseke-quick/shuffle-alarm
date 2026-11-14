import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/bedtime.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/features/alarms/alarm_texts.dart';
import 'package:shuffle_alarm/features/alarms/clock.dart';
import 'package:shuffle_alarm/l10n/texts.dart';
import 'package:shuffle_alarm/platform/providers.dart';
import 'package:shuffle_alarm/platform/system_notifications.dart';

/// Whether the bedtime reminder is on, and what the platform lets it do.
@immutable
class BedtimeReminder {
  const BedtimeReminder({required this.access, this.wanted = false});

  /// What the platform says about notifications.
  final NotificationAccess access;

  /// What the person chose, saved on the device: off until they turn it on.
  final bool wanted;

  /// Whether a notification comes at bedtime.
  bool get on => wanted && access == NotificationAccess.allowed;

  @override
  bool operator ==(Object other) =>
      other is BedtimeReminder &&
      other.access == access &&
      other.wanted == wanted;

  @override
  int get hashCode => Object.hash(access, wanted);

  @override
  String toString() => 'BedtimeReminder(access: $access, wanted: $wanted)';
}

final bedtimeReminderProvider =
    NotifierProvider<BedtimeReminderController, BedtimeReminder>(
      BedtimeReminderController.new,
    );

/// Shows a notification at the bedtime of the next alarm, when the person
/// wants that and the platform allows it (task 2.4a).
///
/// It runs on the clock of the "Rings in" texts ([clockProvider]), not on the
/// `AlarmScheduler`, so a ring never waits for it and a failure here touches
/// no ring. On the web it works only while the tab is open, and a hidden tab
/// may run that clock a minute late; `dueBedtimeRing` finds a late bedtime
/// too.
class BedtimeReminderController extends Notifier<BedtimeReminder> {
  @override
  BedtimeReminder build() {
    ref.listen(clockProvider, _onClock);
    final access = ref.watch(systemNotificationsProvider).access;
    if (access != NotificationAccess.unavailable) unawaited(_load());
    return BedtimeReminder(access: access);
  }

  Future<void> _load() async {
    try {
      final wanted = await ref
          .read(settingsRepositoryProvider)
          .bedtimeReminder();
      if (ref.mounted) {
        state = BedtimeReminder(access: state.access, wanted: wanted);
      }
    } on Object catch (error) {
      debugPrint('Could not read the bedtime reminder setting: $error');
    }
  }

  void _onClock(DateTime? before, DateTime now) {
    // The person can change it at any time, in the browser's settings.
    _readAccess();
    if (before == null || !state.on) return;
    final alarms = ref.read(alarmsProvider).value;
    if (alarms == null) return;
    final ring = dueBedtimeRing(alarms, since: before, now: now);
    if (ring == null) return;
    // One line in the log for each reminder, as for each ring: a tester can
    // read in the browser's console how late it came.
    final lateBy = now.difference(bedtimeFor(ring));
    debugPrint(
      'Bedtime reminder for the ring at $ring, found '
      '${lateBy.inMilliseconds} ms after the bedtime',
    );
    unawaited(_show(bedtimeReminderBody(ring: ring, now: now, clock: _clock)));
  }

  void _readAccess() {
    final access = ref.read(systemNotificationsProvider).access;
    if (access != state.access) {
      state = BedtimeReminder(access: access, wanted: state.wanted);
    }
  }

  /// Shows a notification. A failure stays here, and only goes to the log.
  Future<void> _show(String body) async {
    try {
      await ref
          .read(systemNotificationsProvider)
          .show(title: bedtimeReminderTitle, body: body);
    } on Object catch (error) {
      debugPrint('Could not show a notification: $error');
      if (ref.mounted) _readAccess();
    }
  }

  /// Turns the reminder on, after asking the person if the platform must.
  /// Tells what the platform says then: unless that is
  /// [NotificationAccess.allowed], the reminder is not on.
  ///
  /// Call it in a tap, and only after the explanation of
  /// `BedtimeReminderScreen` if the platform must ask (`CLAUDE.md`).
  Future<NotificationAccess> turnOn() async {
    final notifications = ref.read(systemNotificationsProvider);
    final access = notifications.access == NotificationAccess.allowed
        ? NotificationAccess.allowed
        : await notifications.ask();
    if (!ref.mounted) return access;
    final wanted = switch (access) {
      NotificationAccess.allowed => true,
      NotificationAccess.blocked => false,
      NotificationAccess.notAsked ||
      NotificationAccess.unavailable => state.wanted,
    };
    state = BedtimeReminder(access: access, wanted: wanted);
    await _save(on: wanted);
    return access;
  }

  /// Turns the reminder off.
  Future<void> turnOff() async {
    state = BedtimeReminder(access: state.access);
    await _save(on: false);
  }

  /// Saves the choice. A failure only goes to the log: the choice then holds
  /// until the app closes.
  Future<void> _save({required bool on}) async {
    try {
      await ref.read(settingsRepositoryProvider).saveBedtimeReminder(on: on);
    } on Object catch (error) {
      debugPrint('Could not save the bedtime reminder setting: $error');
    }
  }
}

/// The time of day as the screens write it. Here without a context, as a
/// notification has none: with AM and PM in English unless the device shows
/// 24 hours, and in 24 hours in Russian and Kazakh.
String _clock(DateTime time) => tr.localeName == 'en'
    ? const DefaultMaterialLocalizations().formatTimeOfDay(
        TimeOfDay.fromDateTime(time),
        alwaysUse24HourFormat:
            WidgetsBinding.instance.platformDispatcher.alwaysUse24HourFormat,
      )
    : '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
