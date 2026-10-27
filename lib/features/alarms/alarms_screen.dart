import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/features/settings/settings_button.dart';

/// The Alarms tab. Placeholder until task 2.2 adds the alarm list.
class AlarmsScreen extends StatelessWidget {
  const AlarmsScreen({super.key});

  static const path = '/alarms';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarms'),
        actions: const [SettingsButton()],
      ),
      body: const Center(child: Text('No alarms yet.')),
    );
  }
}
