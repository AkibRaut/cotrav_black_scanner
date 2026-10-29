import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/widgets/gold_text_field.dart';
import '../../data/auth_repository.dart';
import '../../data/auth_validators.dart';
import '../../login/view/login_page.dart';
import '../../view/widgets/auth_scaffold.dart';
import '../../view/widgets/auth_snackbar.dart';
import '../../view/widgets/resend_otp_button.dart';
import '../bloc/forgot_password_bloc.dart';

/// Two steps: request a reset OTP, then set a new password with it.
/// Pops with the login ID once the password is changed.
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key, this.initialLoginId = ''});

  final String initialLoginId;

  static Route<String> route({String initialLoginId = ''}) => PageRouteBuilder<String>(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, _, _) => ForgotPasswordPage(initialLoginId: initialLoginId),
    transitionsBuilder: (_, animation, _, child) {
      final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: curved.drive(Tween(begin: const Offset(0.08, 0), end: Offset.zero)),
          child: child,
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ForgotPasswordBloc(repository: context.read<AuthRepository>()),
      child: ForgotPasswordView(initialLoginId: initialLoginId),
    );
  }
}

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key, this.initialLoginId = ''});

  final String initialLoginId;

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  late final _loginId = TextEditingController(text: widget.initialLoginId.trim());
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _loginId.dispose();
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool _validate() {
    FocusScope.of(context).unfocus();
    return _formKey.currentState?.validate() ?? false;
  }

  void _sendOtp() {
    if (!_validate()) return;
    context.read<ForgotPasswordBloc>().add(ForgotPasswordOtpRequested(_loginId.text));
  }

  void _resendOtp() {
    _otp.clear();
    context.read<ForgotPasswordBloc>().add(ForgotPasswordOtpRequested(_loginId.text));
  }

  void _reset() {
    if (!_validate()) return;
    context.read<ForgotPasswordBloc>().add(ForgotPasswordResetSubmitted(otp: _otp.text, newPassword: _password.text));
  }

  void _onStateChanged(BuildContext context, ForgotPasswordState state) {
    switch (state.status) {
      case ForgotPasswordStatus.failure:
        showAuthMessage(context, state.error ?? 'Something went wrong.', error: true);
      case ForgotPasswordStatus.otpSent:
        HapticFeedback.lightImpact();
        showAuthMessage(context, state.message ?? 'OTP sent.');
      case ForgotPasswordStatus.success:
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(state.loginId);
      case ForgotPasswordStatus.idle || ForgotPasswordStatus.submitting:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onStateChanged,
      builder: (context, state) {
        final busy = state.isSubmitting || state.status == ForgotPasswordStatus.success;
        return AuthScaffold(
          title: state.otpSent ? 'Set a new password' : 'Forgot password?',
          subtitle: state.otpSent
              ? 'Enter the OTP we sent and choose a new password.'
              : 'Enter your email ID or contact number and we will send you an OTP.',
          onBack: busy ? null : () => Navigator.of(context).maybePop(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StepIndicator(step: state.otpSent ? 1 : 0),
                const SizedBox(height: 24),
                GoldTextField(
                  controller: _loginId,
                  label: 'Email ID / Contact No',
                  icon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username, AutofillHints.email],
                  validator: AuthValidators.loginId,
                  enabled: !busy && !state.otpSent,
                  textInputAction: TextInputAction.done,
                  onSubmitted: state.otpSent ? null : (_) => _sendOtp(),
                ),
                const SizedBox(height: 16),
                AnimatedSize(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                    layoutBuilder: (current, previous) =>
                        Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
                    child: state.otpSent
                        ? Column(
                            key: const ValueKey('reset'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OtpField(controller: _otp, enabled: !busy),
                              const SizedBox(height: 16),
                              AutofillGroup(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    GoldTextField(
                                      controller: _password,
                                      label: 'New password',
                                      icon: Icons.lock_outline_rounded,
                                      obscure: true,
                                      enabled: !busy,
                                      autofillHints: const [AutofillHints.newPassword],
                                      validator: AuthValidators.newPassword,
                                    ),
                                    const SizedBox(height: 16),
                                    GoldTextField(
                                      controller: _confirm,
                                      label: 'Confirm new password',
                                      icon: Icons.lock_reset_rounded,
                                      obscure: true,
                                      enabled: !busy,
                                      textInputAction: TextInputAction.done,
                                      validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                                      onSubmitted: (_) => _reset(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: busy
                                        ? null
                                        : () {
                                            _otp.clear();
                                            context.read<ForgotPasswordBloc>().add(const ForgotPasswordEditRequested());
                                          },
                                    style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    label: const Text('Change'),
                                  ),
                                  const Spacer(),
                                  ResendOtpButton(availableAt: state.resendAt, enabled: !busy, onPressed: _resendOtp),
                                ],
                              ),
                              const SizedBox(height: 12),
                              GoldButton(
                                label: 'Reset password',
                                icon: Icons.lock_reset_rounded,
                                loading: busy,
                                onPressed: _reset,
                              ),
                            ],
                          )
                        : Padding(
                            key: const ValueKey('request'),
                            padding: const EdgeInsets.only(top: 8),
                            child: GoldButton(
                              label: 'Send OTP',
                              icon: Icons.sms_outlined,
                              loading: busy,
                              onPressed: _sendOtp,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// "1 Verify — 2 Reset" progress with an animated gold fill.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    Widget dot(int index, String label) {
      final active = step >= index;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: active ? AppColors.goldGradient : null,
              border: active ? null : Border.all(color: AppColors.hairline),
            ),
            child: step > index
                ? const Icon(Icons.check_rounded, size: 16, color: AppColors.black)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: active ? AppColors.black : AppColors.textMuted,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.goldLight : AppColors.textMuted,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        dot(0, 'VERIFY'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: step >= 1 ? 1 : 0),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeInOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 2,
                  color: AppColors.gold,
                  backgroundColor: AppColors.hairline,
                ),
              ),
            ),
          ),
        ),
        dot(1, 'RESET'),
      ],
    );
  }
}
