import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/fonts.dart';
import 'package:shuffle_alarm/design/theme.dart';
import 'package:shuffle_alarm/design/tokens.dart';
import 'package:shuffle_alarm/router.dart';

/// The app: Wakemix. Its package keeps the working name `shuffle_alarm`
/// (docs/DECISIONS.md, task 2.2a).
class ShuffleAlarmApp extends ConsumerWidget {
  const ShuffleAlarmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    registerFontLicenses();
    return MaterialApp.router(
      title: 'Wakemix',
      debugShowCheckedModeBanner: false,
      color: WakemixColors.dark.background,
      // Dark is the reference design. The theme follows the device's
      // setting: `themeMode` stays at its default, ThemeMode.system.
      theme: WakemixTheme.light,
      darkTheme: WakemixTheme.dark,
      routerConfig: ref.watch(routerProvider),
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
