import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/mini_waveform.dart';
import 'package:shuffle_alarm/design/components/time_text.dart';
import 'package:shuffle_alarm/design/theme.dart';
import 'package:shuffle_alarm/design/tokens.dart';

/// One alarm in the tracklist: its [time], [details] such as its label and
/// days, its [status] such as "Rings in 7 h 20 min" or "Off", a mini
/// waveform and its switch. A tap on the row opens it.
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
    final type = WakemixType.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        // The waveform is decoration: it gives way when the text needs the
        // room, such as with large text on a small phone.
        final roomForWaveform = 300 + (textScale - 1) * 240;
        return Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 72),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Layout.gutter,
                      Space.s12,
                      Space.s8,
                      Space.s12,
                    ),
                    child: Row(
                      children: [
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
                              Text(status, style: type.meta),
                            ],
                          ),
                        ),
                        if (constraints.maxWidth >= roomForWaveform) ...[
                          const SizedBox(width: Space.s12),
                          MiniWaveform(seed: waveformSeed, active: enabled),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: Space.s8),
              child: Semantics(
                label: switchLabel,
                child: Switch(value: enabled, onChanged: onEnabledChanged),
              ),
            ),
          ],
        );
      },
    );
  }
}
