import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/core/models/alarm.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/l10n/texts.dart';

/// Saves [alarm], and returns whether that worked.
///
/// If it fails, a message at the bottom of the screen says so: nobody should
/// go to sleep believing an alarm is set when it is not.
Future<bool> saveAlarm(BuildContext context, WidgetRef ref, Alarm alarm) =>
    _write(
      context,
      () => ref.read(alarmRepositoryProvider).save(alarm),
      failure: (error) => tr.couldNotSaveAlarm(error),
    );

/// Deletes the alarm with [id], and returns whether that worked. If it fails,
/// a message at the bottom of the screen says so.
Future<bool> deleteAlarm(BuildContext context, WidgetRef ref, String id) =>
    _write(
      context,
      () => ref.read(alarmRepositoryProvider).delete(id),
      failure: (error) => tr.couldNotDeleteAlarm(error),
    );

Future<bool> _write(
  BuildContext context,
  Future<void> Function() write, {
  required String Function(String error) failure,
}) async {
  // Taken before the wait: the page may be gone by the time it fails.
  final messenger = ScaffoldMessenger.of(context);
  try {
    await write();
    return true;
  } on Object catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(failure('$error'))));
    return false;
  }
}
