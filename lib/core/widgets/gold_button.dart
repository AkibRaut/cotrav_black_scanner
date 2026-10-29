import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Full-width gold gradient button with a press-down scale effect.
///
/// While [loading] it shows a spinner and ignores taps; a null [onPressed]
/// dims it.
class GoldButton extends StatefulWidget {
  const GoldButton({super.key, required this.label, required this.onPressed, this.icon, this.loading = false});

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final onPressed = widget.loading ? null : widget.onPressed;
    final enabled = onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              onPressed();
            }
          : null,
      child: AnimatedOpacity(
        opacity: enabled || widget.loading ? 1 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: _pressed ? 0.15 : 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: widget.loading
                  ? const SizedBox.square(
                      key: ValueKey('loading'),
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.black),
                    )
                  : Row(
                      key: const ValueKey('label'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: AppColors.black, size: 22),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          widget.label.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.black,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
