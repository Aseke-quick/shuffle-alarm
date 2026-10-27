import 'package:material_ui/material_ui.dart';

/// The Settings page. It opens above the tabs, so its app bar has a back
/// button. Placeholder until the first settings arrive.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const path = '/settings';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('No settings yet.')),
    );
  }
}
