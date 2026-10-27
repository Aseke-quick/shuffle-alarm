import 'package:flutter/material.dart';

void main() {
  runApp(const ShuffleAlarmApp());
}

class ShuffleAlarmApp extends StatelessWidget {
  const ShuffleAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shuffle Alarm',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const HomePage(),
    );
  }

  static ThemeData _theme(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepOrange,
        brightness: brightness,
      ),
    );
  }
}

/// Placeholder home screen. Replaced by the app shell in task 0.3.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shuffle Alarm')),
      body: const Center(child: Text('No alarms yet.')),
    );
  }
}
