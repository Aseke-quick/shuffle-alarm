import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shuffle_alarm/app.dart';
import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/features/settings/language.dart';

Future<void> main() async {
  // The library sync below reads the assets and opens the database before
  // the first frame, which needs the binding.
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  startLibrarySync(container);
  // So the first page is already in the language chosen in Settings. Not for
  // long: a store that does not answer must not hold the alarms up.
  await container
      .read(languageProvider.notifier)
      .loaded
      .timeout(const Duration(seconds: 1), onTimeout: () {});
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ShuffleAlarmApp(),
    ),
  );
}
