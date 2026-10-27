import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/features/settings/settings_button.dart';

/// The Library tab. Placeholder until task 3.7 adds the sound library.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  static const path = '/library';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: const [SettingsButton()],
      ),
      body: const Center(child: Text('No sounds yet.')),
    );
  }
}
