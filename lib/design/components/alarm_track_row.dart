import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/glass_card.dart';
import 'package:shuffle_alarm/design/components/mini_waveform.dart';
import 'package:shuffle_alarm/design/components/time_text.dart';
import 'package:shuffle_alarm/design/tokens.dart';

/// One alarm in the list, as a glass row: a tile with a small waveform, its
/// [time], [details] such as its label and days, its [status] such as "Rings
/// in 7 h 20 min" or "Off", and its switch. A tap on the row opens it.
class AlarmTrackRow extends StatelessWidget {
  const AlarmTrackRow({
    required this.time,
    required this.details,
    required this.status,
    required this.enabled,
    required this.waveformSeed,
    required this.switchLabel,
    required this.onTap,
    required this.onEnabledChanged,
    super.key,
  });

  final TimeOfDay time;
  final String details;
  final String status;

  /// Whether the alarm is on. An alarm that is off shows its time in grey,
  /// and its [status] says "Off".
  final bool enabled;

  /// The seed of the waveform, such as the alarm's id.
  final String waveformSeed;

  /// What screen readers call the switch, such as "7:00 AM alarm".
  final String switchLabel;
  final VoidCallback onTap;
  final ValueChanged<bool> onEnabledChanged;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Layout.gutter,
        0,
        Layout.gutter,
        Space.s12,
      ),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The tile is decoration: it gives way when the text needs the
            // room, such as with large text on a small phone.
            final roomForTile = 300 + (textScale - 1) * 240;
            return Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onTap,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 80),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Space.s12,
                          Space.s12,
                          Space.s8,
                          Space.s12,
                        ),
                        child: Row(
                          children: [
                            if (constraints.maxWidth >= roomForTile) ...[
                              WaveformTile(seed: waveformSeed, active: enabled),
                              const SizedBox(width: Space.s16),
                            ] else
                              const SizedBox(width: Space.s4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TimeText(
                                    time,
                                    style: theme.textTheme.headlineSmall!,
                                    color: enabled ? c.text : c.textDisabled,
                                  ),
                                  const SizedBox(height: Space.s4),
                                  Text(
                                    details,
                                    style: theme.textTheme.bodySmall!.copyWith(
                                      color: c.textMuted,
                                    ),
                                  ),
                                  Text(
                                    status,
                                    style: theme.textTheme.labelMedium!
                                        .copyWith(
                                          color: enabled
                                              ? c.accentText
                                              : c.textMuted,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: Space.s12),
                  child: Semantics(
                    label: switchLabel,
                    child: Switch(value: enabled, onChanged: onEnabledChanged),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
