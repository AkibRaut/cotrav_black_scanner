import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/navigation/fade_route.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gold_text.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/login/view/login_page.dart';
import '../scanner/view/scanner_page.dart';

/// Short branded intro (~1.2s) that hands off to the scanner, or to login
/// when there is no saved session.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    _next();
  }

  Future<void> _next() async {
    final auth = context.read<AuthBloc>();
    // The session restore runs alongside the animation, so this rarely waits.
    await _controller.forward().orCancel.catchError((_) {});
    final state = auth.state.status != AuthStatus.unknown
        ? auth.state
        : await auth.stream.firstWhere((s) => s.status != AuthStatus.unknown);
    if (!mounted) return;
    final page = state.status == AuthStatus.authenticated ? const ScannerPage() : const LoginPage();
    Navigator.of(context).pushReplacement(fadeRoute<void>(page));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoScale = _controller.drive(
      Tween(begin: 0.6, end: 1.0).chain(CurveTween(curve: const Interval(0, 0.55, curve: Curves.easeOutBack))),
    );
    final logoFade = _controller.drive(CurveTween(curve: const Interval(0, 0.35)));
    final textFade = _controller.drive(CurveTween(curve: const Interval(0.3, 0.7, curve: Curves.easeOut)));
    final lineWidth = _controller.drive(CurveTween(curve: const Interval(0.45, 0.95, curve: Curves.easeInOutCubic)));

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: logoFade,
              child: ScaleTransition(
                scale: logoScale,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.goldGradient,
                    boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.45), blurRadius: 48)],
                  ),
                  child: const Icon(Icons.qr_code_2_rounded, size: 52, color: AppColors.black),
                ),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: textFade,
              child: const GoldText(
                'COTRAV',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 10),
              ),
            ),
            const SizedBox(height: 10),
            SizeTransition(
              sizeFactor: lineWidth,
              axis: Axis.horizontal,
              child: Container(width: 140, height: 1.5, color: AppColors.gold),
            ),
            const SizedBox(height: 10),
            FadeTransition(
              opacity: textFade,
              child: const Text(
                'B L A C K   P A S S',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12, letterSpacing: 6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
