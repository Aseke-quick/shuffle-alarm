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

/// The bottom navigation bar: one tab per [destinations], each an icon and
/// a label. The open tab has the text color and a 4 px accent dot. A flat
/// bar across the bottom with a hairline above it, not a floating card.
class WakemixNavBar extends StatelessWidget {
  const WakemixNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.outline)),
      ),
      child: SafeArea(
        top: false,
        child: ContentWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s8),
            child: Row(
              children: [
                for (final (index, destination) in destinations.indexed)
                  Expanded(
                    child: _NavItem(
                      destination: destination,
                      selected: index == selectedIndex,
                      onPressed: () => onSelected(index),
                    ),
                  ),
              ],
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
    required this.onPressed,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = WakemixColors.of(context);
    final color = selected ? c.text : c.textMuted;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: destination.label,
      onTap: onPressed,
      excludeSemantics: true,
      child: InkWell(
        onTap: onPressed,
        customBorder: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(Corners.card)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.s8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  color: color,
                ),
                const SizedBox(height: Space.s4),
                Text(
                  destination.label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium!
                      .copyWith(color: color),
                ),
                const SizedBox(height: Space.s4),
                // Room for the dot on every tab, so the labels line up.
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? c.accent : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
