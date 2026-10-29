import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/theme.dart';
import 'package:shuffle_alarm/design/tokens.dart';

/// A caption above a group, such as "ALL ALARMS", with an optional
/// [trailing] text at the end, such as a count.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {this.trailing, super.key});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final style = WakemixType.of(context).caption;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Layout.gutter,
        Space.s24,
        Layout.gutter,
        Space.s8,
      ),
      // Read in sentence case, such as "All alarms, 3": screen readers may
      // spell out words in capitals.
      child: Semantics(
        header: true,
        label: trailing == null ? text : '$text, $trailing',
        excludeSemantics: true,
        child: Row(
          children: [
            Expanded(child: Text(text.toUpperCase(), style: style)),
            if (trailing != null) Text(trailing!, style: style),
          ],
        ),
      ),
    );
  }
}
