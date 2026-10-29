import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/layout.dart';
import 'package:shuffle_alarm/design/components/status_view.dart';
import 'package:shuffle_alarm/features/settings/settings_button.dart';

/// The Library tab. Placeholder until task 3.7 adds the sound library.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  static const path = '/library';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: ContentAppBar(
        title: Text('Library'),
        actions: [SettingsButton()],
      ),
      body: StatusView(
        title: 'No sounds yet.',
        message: 'The sounds your alarms play will show here.',
      ),
    );
  }
}
