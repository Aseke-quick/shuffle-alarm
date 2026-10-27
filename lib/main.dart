import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shuffle_alarm/app.dart';

void main() {
  runApp(const ProviderScope(child: ShuffleAlarmApp()));
}
