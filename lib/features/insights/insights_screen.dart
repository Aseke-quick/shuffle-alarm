import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/features/settings/settings_button.dart';

/// The Insights tab. Placeholder until task 2.8 adds the last 14 mornings.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  static const path = '/insights';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: const [SettingsButton()],
      ),
      body: const Center(child: Text('No mornings to show yet.')),
    );
  }
}
