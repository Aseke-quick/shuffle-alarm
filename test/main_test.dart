import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shuffle_alarm/main.dart';

void main() {
  testWidgets('App opens with the Shuffle Alarm title and Material 3', (
    tester,
  ) async {
    await tester.pumpWidget(const ShuffleAlarmApp());

    expect(find.text('Shuffle Alarm'), findsOneWidget);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'Shuffle Alarm');
    expect(app.theme!.useMaterial3, isTrue);
  });
}
