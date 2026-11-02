import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/layout.dart';
import 'package:shuffle_alarm/design/theme.dart';
import 'package:shuffle_alarm/design/tokens.dart';

/// A page filled with the accent: quiet at night, loud in the morning (spec
/// section 1). Only the ringing screen uses it.
///
/// Everything on it takes the color on the accent, also from the theme, and
/// its buttons turn around: a filled `WideButton` is that color with the
/// accent as its text, and a secondary one has it as its border and text. The
/// pairs are in `test/design/contrast_test.dart`.
class AccentPage extends StatelessWidget {
  const AccentPage({required this.body, this.bottomAction, super.key});

  final Widget body;

  /// What goes at the bottom, where a thumb reaches it ([BottomAction]).
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = WakemixColors.of(context);
    final type = WakemixType.of(context);
    final action = bottomAction;
    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: c.accent,
        textTheme: theme.textTheme.apply(
          bodyColor: c.onAccent,
          displayColor: c.onAccent,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: c.onAccent,
            foregroundColor: c.accent,
            // A button is disabled only while the page closes.
            disabledBackgroundColor: c.onAccent,
            disabledForegroundColor: c.accent,
          ).merge(theme.filledButtonTheme.style),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: c.onAccent,
            disabledForegroundColor: c.onAccent,
            side: BorderSide(color: c.onAccent),
          ).merge(theme.outlinedButtonTheme.style),
        ),
        extensions: [
          c,
          type.copyWith(
            meta: type.meta.copyWith(color: c.onAccent),
            caption: type.caption.copyWith(color: c.onAccent),
          ),
        ],
      ),
      child: Scaffold(
        body: body,
        bottomNavigationBar: action == null
            ? null
            : BottomAction(child: action),
      ),
    );
  }
}
