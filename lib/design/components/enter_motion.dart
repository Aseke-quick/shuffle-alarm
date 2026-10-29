import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/design/tokens.dart';

/// Shows [child] by fading it in while it moves up [Motion.enterOffset]
/// pixels, once, when it is first built: how a new list item appears.
///
/// Without motion when [animate] is false, or when the platform asks for
/// less motion.
class EnterMotion extends StatefulWidget {
  const EnterMotion({required this.child, this.animate = true, super.key});

  final Widget child;
  final bool animate;

  @override
  State<EnterMotion> createState() => _EnterMotionState();
}

class _EnterMotionState extends State<EnterMotion>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late final Animation<double> _progress;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decided once, when the item first appears.
    if (_controller != null || !widget.animate) return;
    if (Motion.reduceMotion(context)) return;
    final controller = AnimationController(vsync: this, duration: Motion.slow);
    _controller = controller;
    _progress = CurvedAnimation(parent: controller, curve: Motion.curve);
    controller.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) return widget.child;
    return FadeTransition(
      opacity: _progress,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - _progress.value) * Motion.enterOffset),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
