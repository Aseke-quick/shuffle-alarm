import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shuffle_alarm/app.dart';
import 'package:shuffle_alarm/data/providers.dart';

void main() {
  // The library sync below reads the assets and opens the database before
  // the first frame, which needs the binding.
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  startLibrarySync(container);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ShuffleAlarmApp(),
    ),
  );
}
