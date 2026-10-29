import 'package:material_ui/material_ui.dart';

/// The name of the app as a wordmark: `wakemix`, lowercase, in Unbounded.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'wakemix',
      semanticsLabel: 'Wakemix',
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}
