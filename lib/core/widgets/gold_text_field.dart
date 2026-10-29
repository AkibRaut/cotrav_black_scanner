import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Dark filled input with a gold focus ring. Password fields get a
/// show/hide toggle.
class GoldTextField extends StatefulWidget {
  const GoldTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.obscure = false,
    this.enabled = true,
    this.inputFormatters,
    this.maxLength,
    this.letterSpacing,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscure;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final double? letterSpacing;
  final ValueChanged<String>? onSubmitted;

  @override
  State<GoldTextField> createState() => _GoldTextFieldState();
}

class _GoldTextFieldState extends State<GoldTextField> {
  late bool _hidden = widget.obscure;

  static OutlineInputBorder _border(Color color, [double width = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color, width: width),
  );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      obscureText: _hidden,
      enabled: widget.enabled,
      inputFormatters: widget.inputFormatters,
      maxLength: widget.maxLength,
      onFieldSubmitted: widget.onSubmitted,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      cursorColor: AppColors.gold,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: widget.letterSpacing,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        counterText: '',
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        labelStyle: const TextStyle(color: AppColors.textMuted, letterSpacing: 0.3),
        floatingLabelStyle: const TextStyle(color: AppColors.gold, letterSpacing: 0.6),
        prefixIcon: Icon(widget.icon, size: 20),
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused) ? AppColors.gold : AppColors.textMuted,
        ),
        suffixIcon: widget.obscure
            ? IconButton(
                tooltip: _hidden ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    _hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    key: ValueKey(_hidden),
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
              )
            : null,
        border: _border(AppColors.hairline),
        enabledBorder: _border(AppColors.hairline),
        disabledBorder: _border(AppColors.hairline.withValues(alpha: 0.1)),
        focusedBorder: _border(AppColors.gold, 1.4),
        errorBorder: _border(AppColors.error.withValues(alpha: 0.7)),
        focusedErrorBorder: _border(AppColors.error, 1.4),
        errorStyle: const TextStyle(color: AppColors.error),
      ),
    );
  }
}
