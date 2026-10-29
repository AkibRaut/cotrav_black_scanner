import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// "Resend OTP" link that counts down until [availableAt].
class ResendOtpButton extends StatefulWidget {
  const ResendOtpButton({super.key, required this.availableAt, required this.onPressed, this.enabled = true});

  final DateTime? availableAt;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  State<ResendOtpButton> createState() => _ResendOtpButtonState();
}

class _ResendOtpButtonState extends State<ResendOtpButton> {
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(ResendOtpButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availableAt != widget.availableAt) _start();
  }

  void _start() {
    _timer?.cancel();
    _tick();
    if (_secondsLeft > 0) _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final at = widget.availableAt;
    final left = at == null ? 0 : (at.difference(DateTime.now()).inMilliseconds / 1000).ceil();
    if (left <= 0) _timer?.cancel();
    if (mounted) setState(() => _secondsLeft = left < 0 ? 0 : left);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waiting = _secondsLeft > 0;
    return TextButton(
      onPressed: waiting || !widget.enabled ? null : widget.onPressed,
      style: TextButton.styleFrom(foregroundColor: AppColors.gold, disabledForegroundColor: AppColors.textMuted),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          waiting ? 'Resend OTP in 0:${_secondsLeft.toString().padLeft(2, '0')}' : 'Resend OTP',
          key: ValueKey(waiting),
          style: const TextStyle(fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()]),
        ),
      ),
    );
  }
}
