import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/layout.dart';
import 'package:shuffle_alarm/design/components/status_view.dart';
import 'package:shuffle_alarm/features/settings/settings_button.dart';

/// The Insights tab. Placeholder until task 2.8 adds the last 14 mornings.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  static const path = '/insights';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: ContentAppBar(
        title: Text('Insights'),
        actions: [SettingsButton()],
      ),
      body: StatusView(
        title: 'No mornings to show yet.',
        message: 'After your first alarm, your mornings will show here.',
      ),
    );
  }
}
