import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/tokens.dart';

/// A card of glass over the page's color fields: a translucent fill, a
/// hairline and a soft shadow (ADR-005). Without a blur behind it: the fields
/// are soft already.
///
/// With [onTap] the whole card is a button, and [semanticsLabel] says what it
/// does.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(Space.s16),
    this.radius = Corners.card,
    this.tint,
    this.onTap,
    this.semanticsLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// A gradient under the glass, such as the tint of the next alarm's card.
  final Gradient? tint;

  final VoidCallback? onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    final shape = BorderRadius.all(Radius.circular(radius));
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: tint),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.glass,
              borderRadius: shape,
              border: Border.all(color: c.glassLine),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: onTap == null
                  ? Padding(padding: padding, child: child)
                  : InkWell(
                      onTap: onTap,
                      child: Padding(padding: padding, child: child),
                    ),
            ),
          ),
        ),
      ),
    );
    if (onTap == null || semanticsLabel == null) return card;
    return Semantics(
      container: true,
      button: true,
      label: semanticsLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: card,
    );
  }
}
