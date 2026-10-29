import 'package:flutter/material.dart';

/// Dims everything outside the scan window. Static, so it is painted once.
class ScannerMask extends StatelessWidget {
  const ScannerMask({super.key, required this.window, this.radius = 28});

  final Rect window;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(size: Size.infinite, painter: _MaskPainter(window, radius)),
    );
  }
}

class _MaskPainter extends CustomPainter {
  _MaskPainter(this.window, this.radius);

  final Rect window;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(window, Radius.circular(radius)));
    canvas.drawPath(path, Paint()..color = const Color(0xC7000000));
  }

  @override
  bool shouldRepaint(_MaskPainter old) => old.window != window || old.radius != radius;
}
