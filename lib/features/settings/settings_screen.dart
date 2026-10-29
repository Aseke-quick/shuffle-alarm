import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/layout.dart';
import 'package:shuffle_alarm/design/components/status_view.dart';

/// The Settings page. It opens above the tabs, so its app bar has a back
/// button. Placeholder until the first settings arrive.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const path = '/settings';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: ContentAppBar(title: Text('Settings')),
      body: StatusView(title: 'No settings yet.'),
    );
  }
}
