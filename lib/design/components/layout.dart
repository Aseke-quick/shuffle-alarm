import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/tokens.dart';

/// [child] at most [Layout.maxContentWidth] wide, centered: on the web and
/// desktop the content keeps the width of a phone.
class ContentWidth extends StatelessWidget {
  const ContentWidth({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      // As tall as the child, so it also fits where the height is open,
      // such as in a bottom bar.
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Layout.maxContentWidth),
        child: child,
      ),
    );
  }
}

/// An [AppBar] as wide as the content below it ([ContentWidth]).
class ContentAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ContentAppBar({this.title, this.actions, super.key});

  final Widget? title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: WakemixColors.of(context).background,
      child: ContentWidth(
        child: AppBar(
          title: title,
          actions: [
            ...?actions,
            const SizedBox(width: Space.s4),
          ],
        ),
      ),
    );
  }
}

/// The main action of a screen: [child], usually a `WideButton`, at the
/// bottom, where a thumb reaches it.
class BottomAction extends StatelessWidget {
  const BottomAction({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        Layout.gutter,
        Space.s8,
        Layout.gutter,
        Space.s16,
      ),
      child: ContentWidth(child: child),
    );
  }
}
