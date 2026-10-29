import 'package:flutter/widgets.dart';

/// Fades and slides [child] in during the [start]–[end] slice of [animation].
/// Lets one controller drive a whole staggered entrance.
class Reveal extends StatelessWidget {
  const Reveal({
    super.key,
    required this.animation,
    required this.start,
    required this.end,
    required this.child,
    this.offset = const Offset(0, 0.12),
  });

  final Animation<double> animation;
  final double start;
  final double end;
  final Offset offset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = animation.drive(CurveTween(curve: Interval(start, end, curve: Curves.easeOutCubic)));
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: curved.drive(Tween(begin: offset, end: Offset.zero)),
        child: child,
      ),
    );
  }
}
