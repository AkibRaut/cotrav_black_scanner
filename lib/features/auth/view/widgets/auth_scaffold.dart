import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gold_text.dart';
import '../../../guest/view/widgets/reveal.dart';

/// Shared frame for the auth screens: drifting gold glow, the wax-seal logo
/// and a scrollable form area. Header and [child] fade in one after another.
class AuthScaffold extends StatefulWidget {
  const AuthScaffold({super.key, required this.title, required this.subtitle, required this.child, this.onBack});

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;

  @override
  State<AuthScaffold> createState() => _AuthScaffoldState();
}

class _AuthScaffoldState extends State<AuthScaffold> with SingleTickerProviderStateMixin {
  late final _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _Brand(animation: _intro),
      const SizedBox(height: 36),
      Text(widget.title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 6),
      Text(widget.subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.4)),
      const SizedBox(height: 28),
      widget.child,
    ];
    final step = 0.5 / items.length;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(child: RepaintBoundary(child: _GlowBackground())),
          SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Reveal(
                            animation: _intro,
                            start: 0.25 + i * step,
                            end: math.min(1, 0.55 + i * step),
                            child: items[i],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.onBack != null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gold, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final scale = animation.drive(
      Tween(begin: 0.7, end: 1.0).chain(CurveTween(curve: const Interval(0, 0.6, curve: Curves.easeOutBack))),
    );
    return Column(
      children: [
        ScaleTransition(
          scale: scale,
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.28), blurRadius: 44, spreadRadius: 2)],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/icon/app_icon.png',
                cacheWidth: 312,
                fit: BoxFit.cover,
                semanticLabel: 'Cotrav Black seal',
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const GoldText('COTRAV', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 9)),
        const SizedBox(height: 4),
        const Text('B L A C K   P A S S', style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 5)),
      ],
    );
  }
}

/// Two soft gold light spots drifting slowly behind the form.
class _GlowBackground extends StatefulWidget {
  const _GlowBackground();

  @override
  State<_GlowBackground> createState() => _GlowBackgroundState();
}

class _GlowBackgroundState extends State<_GlowBackground> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GlowPainter(_controller));
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value * 2 * math.pi;
    void spot(Offset center, double radius, double alpha) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.gold.withValues(alpha: alpha),
            AppColors.gold.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    spot(
      Offset(size.width * (0.2 + 0.12 * math.cos(t)), size.height * (0.12 + 0.05 * math.sin(t))),
      size.width * 0.75,
      0.16,
    );
    spot(
      Offset(size.width * (0.85 + 0.1 * math.sin(t)), size.height * (0.85 + 0.06 * math.cos(t))),
      size.width * 0.7,
      0.10,
    );
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) => false;
}
