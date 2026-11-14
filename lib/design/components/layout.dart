import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/components/backdrop.dart';
import 'package:shuffle_alarm/design/tokens.dart';

/// A page: a [Scaffold] over the [Backdrop], so the color fields show behind
/// its bars and its content (ADR-005).
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.warmth = Backdrop.defaultWarmth,
    super.key,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;

  /// How warm the page is, from 0 to 1 ([Backdrop.warmth]).
  final double warmth;

  @override
  Widget build(BuildContext context) {
    return Backdrop(
      warmth: warmth,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

/// The page of a tab, inside the app's shell, which paints the backdrop and
/// holds the tabs. On a phone it has an app bar with [title] and [actions];
/// on a wide screen the shell's top bar stands in for it.
class TabPage extends StatelessWidget {
  const TabPage({required this.body, this.title, this.actions, super.key});

  final Widget? title;
  final List<Widget>? actions;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: Layout.isWide(context)
          ? null
          : ContentAppBar(title: title, actions: actions),
      body: body,
    );
  }
}

/// [child] at most [Layout.maxContentWidth] wide, centered: one column, as on
/// a phone. With [wide], at most [Layout.maxWideWidth], for a page that lays
/// out two columns on a laptop.
class ContentWidth extends StatelessWidget {
  const ContentWidth({required this.child, this.wide = false, super.key});

  final Widget child;

  /// Whether the content may take the width of a wide page.
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      // As tall as the child, so it also fits where the height is open,
      // such as in a bottom bar.
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: wide ? Layout.maxWideWidth : Layout.maxContentWidth,
        ),
        child: child,
      ),
    );
  }
}

/// An [AppBar] as wide as the content below it ([ContentWidth]), over the
/// page's color fields.
class ContentAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ContentAppBar({this.title, this.actions, this.wide = false, super.key});

  final Widget? title;
  final List<Widget>? actions;

  /// Whether the page below it is a wide one ([ContentWidth.wide]).
  final bool wide;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ContentWidth(
      wide: wide,
      child: AppBar(
        title: title,
        actions: [
          ...?actions,
          const SizedBox(width: Space.s4),
        ],
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
