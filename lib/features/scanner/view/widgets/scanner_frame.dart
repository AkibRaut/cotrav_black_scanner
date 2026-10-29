import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../bloc/scanner_bloc.dart';

/// Gold corner brackets around the scan window with a sweeping laser line.
/// Shakes red on an invalid code, fills with a gold check on success.
class ScannerFrame extends StatefulWidget {
  const ScannerFrame({super.key, required this.status});

  final ScannerStatus status;

  @override
  State<ScannerFrame> createState() => _ScannerFrameState();
}

class _ScannerFrameState extends State<ScannerFrame> with TickerProviderStateMixin {
  late final AnimationController _laser = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))
    ..repeat(reverse: true);

  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat(reverse: true);

  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));

  @override
  void didUpdateWidget(ScannerFrame old) {
    super.didUpdateWidget(old);
    if (old.status == widget.status) return;

    switch (widget.status) {
      case ScannerStatus.scanning:
        _laser.repeat(reverse: true);
        _pulse.repeat(reverse: true);
      case ScannerStatus.loading:
        _laser.stop();
      case ScannerStatus.success:
        _laser.stop();
        _pulse.stop();
      case ScannerStatus.failure:
        _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _laser.dispose();
    _pulse.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final color = switch (status) {
      ScannerStatus.failure => AppColors.error,
      _ => AppColors.gold,
    };

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _shake,
        builder: (context, child) {
          final t = _shake.value;
          final dx = math.sin(t * math.pi * 6) * 12 * (1 - t);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Soft breathing glow behind the brackets.
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.10 + 0.18 * _pulse.value),
                      blurRadius: 28 + 16 * _pulse.value,
                      spreadRadius: -6,
                    ),
                  ],
                ),
              ),
            ),
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: color),
              duration: const Duration(milliseconds: 250),
              builder: (context, c, _) => CustomPaint(painter: _CornersPainter(c ?? color)),
            ),
            if (status == ScannerStatus.scanning)
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: AnimatedBuilder(
                  animation: _laser,
                  builder: (context, child) => Align(
                    alignment: Alignment(0, Curves.easeInOutSine.transform(_laser.value) * 2 - 1),
                    child: child,
                  ),
                  child: const _LaserLine(),
                ),
              ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutBack,
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: switch (status) {
                ScannerStatus.success => const _SuccessBadge(),
                ScannerStatus.loading => const _LoadingBadge(),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LaserLine extends StatelessWidget {
  const _LaserLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          colors: [AppColors.gold.withValues(alpha: 0), AppColors.goldLight, AppColors.gold.withValues(alpha: 0)],
        ),
        boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.7), blurRadius: 14, spreadRadius: 1)],
      ),
    );
  }
}

class _LoadingBadge extends StatelessWidget {
  const _LoadingBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 92,
        height: 92,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.black.withValues(alpha: 0.75),
          border: Border.all(color: AppColors.hairline),
        ),
        child: const CircularProgressIndicator(strokeWidth: 3, color: AppColors.gold),
      ),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.goldGradient,
          boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.6), blurRadius: 40)],
        ),
        child: const Icon(Icons.check_rounded, size: 54, color: AppColors.black),
      ),
    );
  }
}

class _CornersPainter extends CustomPainter {
  _CornersPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const len = 38.0;
    const r = 28.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final path = Path()
      // top-left
      ..moveTo(0, len + r)
      ..lineTo(0, r)
      ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
      ..lineTo(len + r, 0)
      // top-right
      ..moveTo(w - len - r, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
      ..lineTo(w, len + r)
      // bottom-right
      ..moveTo(w, h - len - r)
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: const Radius.circular(r))
      ..lineTo(w - len - r, h)
      // bottom-left
      ..moveTo(len + r, h)
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: const Radius.circular(r))
      ..lineTo(0, h - len - r);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornersPainter old) => old.color != color;
}
