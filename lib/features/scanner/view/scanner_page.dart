import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gold_button.dart';
import '../../../core/widgets/gold_text.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../guest/view/widgets/guest_avatar.dart';
import '../../guest/view/guest_details_page.dart';
import '../bloc/scanner_bloc.dart';
import '../data/guest_pass_repository.dart';
import '../models/guest_pass.dart';
import 'widgets/scanner_frame.dart';
import 'widgets/scanner_mask.dart';

class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScannerBloc(repository: GuestPassRepository()),
      child: const ScannerView(),
    );
  }
}

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  // QR only + 720p keeps ML Kit / Vision work per frame small, which is what
  // makes detection feel instant on mid-range devices.
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    cameraResolution: const Size(1280, 720),
    detectionTimeoutMs: 200,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) {
        context.read<ScannerBloc>().add(ScannerCodeDetected(raw));
        return;
      }
    }
  }

  Future<void> _openPass(GuestPass pass) async {
    HapticFeedback.mediumImpact();
    // Pause frame analysis while the details are open; saves CPU and battery.
    unawaited(_controller.pause());
    // Let the success badge land before the page transition starts.
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;

    await Navigator.of(context).push(GuestDetailsPage.route(pass));
    if (!mounted) return;

    context.read<ScannerBloc>().add(const ScannerResumed());
    unawaited(_controller.start());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScannerBloc, ScannerState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        switch (state.status) {
          case ScannerStatus.success:
            _openPass(state.pass!);
          case ScannerStatus.failure:
            HapticFeedback.heavyImpact();
          case ScannerStatus.loading:
            // Instant feedback that the code was read while the pass loads.
            HapticFeedback.selectionClick();
          case ScannerStatus.scanning:
            break;
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppColors.black,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              final side = math.min(size.width * 0.72, 300.0);
              final window = Rect.fromCenter(
                center: Offset(size.width / 2, size.height * 0.46),
                width: side,
                height: side,
              );

              return Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                    scanWindow: window,
                    placeholderBuilder: (_) => const ColoredBox(color: AppColors.black),
                    errorBuilder: (context, error) => _CameraError(error: error, onRetry: _controller.start),
                  ),
                  ScannerMask(window: window),
                  Positioned.fromRect(
                    rect: window,
                    child: BlocSelector<ScannerBloc, ScannerState, ScannerStatus>(
                      selector: (state) => state.status,
                      builder: (context, status) => ScannerFrame(status: status),
                    ),
                  ),
                  Positioned(top: 0, left: 0, right: 0, child: _TopBar(controller: _controller)),
                  Positioned(top: window.bottom + 36, left: 24, right: 24, child: const _StatusMessage()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GoldText('COTRAV', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 6)),
                  SizedBox(height: 2),
                  Text(
                    'BLACK PASS',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 3,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, state, _) {
                if (state.torchState == TorchState.unavailable) {
                  return const SizedBox.shrink();
                }
                final on = state.torchState == TorchState.on;
                return _RoundIconButton(
                  icon: on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  active: on,
                  onTap: controller.toggleTorch,
                );
              },
            ),
            const SizedBox(width: 10),
            _RoundIconButton(icon: Icons.cameraswitch_rounded, onTap: controller.switchCamera),
            const SizedBox(width: 10),
            _RoundIconButton(icon: Icons.person_outline_rounded, onTap: () => _AccountSheet.show(context)),
          ],
        ),
      ),
    );
  }
}

/// Who is logged in, with a logout button.
class _AccountSheet extends StatelessWidget {
  const _AccountSheet();

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => BlocProvider.value(value: context.read<AuthBloc>(), child: const _AccountSheet()),
  );

  @override
  Widget build(BuildContext context) {
    final session = context.select((AuthBloc bloc) => bloc.state.session);
    final name = session?.displayName ?? '';
    final loginId = session?.loginId ?? '';
    final initials = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2).map((w) => w[0]);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GuestAvatar(initials: initials.join().toUpperCase(), size: 64),
            const SizedBox(height: 14),
            GoldText(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            if (loginId.isNotEmpty && loginId != name) ...[
              const SizedBox(height: 4),
              Text(loginId, style: const TextStyle(color: AppColors.textMuted)),
            ],
            const SizedBox(height: 28),
            GoldButton(
              label: 'Log out',
              icon: Icons.logout_rounded,
              onPressed: () {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap, this.active = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: active ? AppColors.goldGradient : null,
          color: active ? null : AppColors.surface.withValues(alpha: 0.8),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Icon(icon, color: active ? AppColors.black : AppColors.gold, size: 22),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScannerBloc, ScannerState>(
      buildWhen: (prev, curr) => prev.status != curr.status || prev.error != curr.error,
      builder: (context, state) {
        final (icon, text, color) = switch (state.status) {
          ScannerStatus.scanning => (
            Icons.qr_code_scanner_rounded,
            'Align the guest QR code inside the frame',
            AppColors.goldLight,
          ),
          ScannerStatus.loading => (Icons.cloud_download_rounded, 'Loading guest pass…', AppColors.goldLight),
          ScannerStatus.success => (Icons.verified_rounded, 'Guest pass verified', AppColors.gold),
          ScannerStatus.failure => (Icons.error_outline_rounded, state.error ?? 'Invalid QR code', AppColors.error),
        };

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(anim),
              child: child,
            ),
          ),
          child: Center(
            key: ValueKey(text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: color, fontSize: 13.5, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error, required this.onRetry});

  final MobileScannerException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: AppColors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(denied ? Icons.no_photography_rounded : Icons.videocam_off_rounded, color: AppColors.gold, size: 56),
              const SizedBox(height: 20),
              Text(
                denied ? 'Camera permission needed' : 'Camera unavailable',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                denied
                    ? 'Allow camera access in Settings to scan guest passes.'
                    : error.errorDetails?.message ?? 'Something went wrong starting the camera.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  side: const BorderSide(color: AppColors.gold),
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
