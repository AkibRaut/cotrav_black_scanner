import 'package:flutter/widgets.dart';

/// Plain cross-fade, used when swapping between top-level screens.
Route<T> fadeRoute<T>(Widget page, {Duration duration = const Duration(milliseconds: 400)}) {
  return PageRouteBuilder<T>(
    transitionDuration: duration,
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
  );
}
