import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/fonts.dart';
import 'package:shuffle_alarm/design/theme.dart';
import 'package:shuffle_alarm/design/tokens.dart';
import 'package:shuffle_alarm/features/ringing/morning_card.dart';
import 'package:shuffle_alarm/features/ringing/ringing_controller.dart';
import 'package:shuffle_alarm/features/settings/bedtime_reminder.dart';
import 'package:shuffle_alarm/router.dart';

/// The app: Wakemix. Its package keeps the working name `shuffle_alarm`
/// (docs/DECISIONS.md, task 2.2a).
class ShuffleAlarmApp extends ConsumerWidget {
  const ShuffleAlarmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    registerFontLicenses();
    final router = ref.watch(routerProvider);
    // Rings the alarms that come due, while the app runs, and shows the
    // ringing page above everything when one starts.
    ref
      ..listen(ringingProvider, (before, now) {
        if (before == null && now != null) {
          unawaited(openRingingPage(router));
        }
      })
      // Shows the bedtime reminder when it comes due, while the app runs.
      ..listen(bedtimeReminderProvider, (_, _) {})
      // Reads the setting of the Morning card at the start, so that a Stop
      // does not have to wait for it.
      ..listen(morningCardOnProvider, (_, _) {});
    return MaterialApp.router(
      title: 'Wakemix',
      debugShowCheckedModeBanner: false,
      color: WakemixColors.dark.background,
      // Dark is the reference design. The theme follows the device's
      // setting: `themeMode` stays at its default, ThemeMode.system.
      theme: WakemixTheme.light,
      darkTheme: WakemixTheme.dark,
      routerConfig: router,
      builder: (context, child) => _LessMotion(child: child!),
    );
  }
}

/// No ink splashes when the platform asks for less motion. Pages and
/// dialogs come in at once then too (`Motion.reduceMotion`).
class _LessMotion extends StatelessWidget {
  const _LessMotion({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Motion.reduceMotion(context)) return child;
    return Theme(
      data: Theme.of(context).copyWith(splashFactory: NoSplash.splashFactory),
      child: child,
    );
  }
}
