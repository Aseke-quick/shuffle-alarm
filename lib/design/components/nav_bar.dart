import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/layout.dart';
import 'package:shuffle_alarm/design/tokens.dart';

/// One tab of the [WakemixNavBar].
@immutable
class NavDestination {
  const NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// The tabs of the app, one per [destinations], each an icon and a label.
///
/// On a phone it is the bar across the bottom: the open tab has the text
/// color and its icon sits in an accent pill. On a wide screen ([top]) it is
/// the bar across the top: [leading] such as the wordmark, the tabs as one
/// pill in the middle, and [trailing] such as the Settings button (ADR-005).
class WakemixNavBar extends StatelessWidget {
  const WakemixNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.top = false,
    this.leading,
    this.trailing,
    super.key,
  });

  final List<NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Whether it is the top bar of a wide screen.
  final bool top;
  final Widget? leading;
  final Widget? trailing;

  /// The height of the top bar.
  static const topHeight = 84.0;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    final items = [
      for (final (index, destination) in destinations.indexed)
        _NavItem(
          destination: destination,
          selected: index == selectedIndex,
          inPill: top,
          onPressed: () => onSelected(index),
        ),
    ];
    if (top) {
      return SafeArea(
        bottom: false,
        child: ContentWidth(
          wide: true,
          child: SizedBox(
            height: topHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Layout.gutter),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: leading,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.glass,
                      border: Border.all(color: c.glassLine),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(Corners.round),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(Space.s4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: items,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: trailing,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.outline)),
      ),
      child: SafeArea(
        top: false,
        child: ContentWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s8),
            child: Row(
              children: [for (final item in items) Expanded(child: item)],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.inPill,
    required this.onPressed,
  });

  final NavDestination destination;
  final bool selected;

  /// Whether it is one of the tabs of the top bar: icon and label side by
  /// side, the open one filled with the accent.
  final bool inPill;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    final labels = Theme.of(context).textTheme.labelMedium!;
    final icon = selected ? destination.selectedIcon : destination.icon;
    const round = BorderRadius.all(Radius.circular(Corners.round));
    final Widget item;
    if (inPill) {
      final color = selected ? c.onAccent : c.textMuted;
      item = DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? c.accent : null,
          borderRadius: round,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Layout.minTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: Space.s8),
                Text(
                  destination.label,
                  style: Theme.of(context).textTheme.labelLarge!
                      .copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      final color = selected ? c.text : c.textMuted;
      item = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.s8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Room for the pill on every tab, so the labels line up.
              DecoratedBox(
                decoration: BoxDecoration(
                  color: selected ? c.accent : null,
                  borderRadius: round,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.s16,
                    vertical: Space.s4,
                  ),
                  child: Icon(icon, color: selected ? c.onAccent : color),
                ),
              ),
              const SizedBox(height: Space.s4),
              Text(
                destination.label,
                textAlign: TextAlign.center,
                style: labels.copyWith(color: color),
              ),
            ],
          ),
        ),
      );
    }
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: destination.label,
      onTap: onPressed,
      excludeSemantics: true,
      child: InkWell(
        onTap: onPressed,
        customBorder: const RoundedRectangleBorder(borderRadius: round),
        child: item,
      ),
    );
  }
}
