import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/features/settings/settings_screen.dart';
import 'package:shuffle_alarm/l10n/texts.dart';

/// The gear in each tab's app bar. Opens the Settings page.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: tr.settings,
      // `push` keeps the tabs below, so Back returns to the same tab.
      onPressed: () => context.push(SettingsScreen.path),
    );
  }
}
