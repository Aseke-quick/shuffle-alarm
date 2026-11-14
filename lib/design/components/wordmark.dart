import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/tokens.dart';

/// The name of the app as a wordmark: a small mark of three bars, and
/// `wakemix`, lowercase.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.accent, c.gentle],
              ),
              borderRadius: const BorderRadius.all(Radius.circular(11)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final (index, height) in const [9.0, 17.0, 12.0].indexed)
                  Container(
                    width: 3,
                    height: height,
                    margin: EdgeInsets.only(left: index == 0 ? 0 : 2.5),
                    decoration: BoxDecoration(
                      color: c.onAccent,
                      borderRadius: const BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: Space.s12),
        Text(
          'wakemix',
          semanticsLabel: 'Wakemix',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}
