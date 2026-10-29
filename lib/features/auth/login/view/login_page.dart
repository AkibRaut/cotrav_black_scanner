import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/widgets/gold_text_field.dart';
import '../../data/auth_repository.dart';
import '../../data/auth_validators.dart';
import '../../forgot_password/view/forgot_password_page.dart';
import '../../view/widgets/auth_mode_switch.dart';
import '../../view/widgets/auth_scaffold.dart';
import '../../view/widgets/auth_snackbar.dart';
import '../../view/widgets/resend_otp_button.dart';
import '../bloc/login_bloc.dart';

/// Password or OTP login. On success the app-level AuthBloc moves on to the
/// scanner, so this page never navigates forward itself.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(repository: context.read<AuthRepository>()),
      child: const LoginView(),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _loginId = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();

  @override
  void dispose() {
    _loginId.dispose();
    _password.dispose();
    _otp.dispose();
    super.dispose();
  }

  bool _validate() {
    FocusScope.of(context).unfocus();
    return _formKey.currentState?.validate() ?? false;
  }

  void _loginWithPassword() {
    if (!_validate()) return;
    context.read<LoginBloc>().add(LoginPasswordSubmitted(loginId: _loginId.text, password: _password.text));
  }

  void _sendOtp() {
    if (!_validate()) return;
    context.read<LoginBloc>().add(LoginOtpRequested(_loginId.text));
  }

  void _resendOtp() {
    _otp.clear();
    context.read<LoginBloc>().add(LoginOtpRequested(_loginId.text));
  }

  void _verifyOtp() {
    if (!_validate()) return;
    context.read<LoginBloc>().add(LoginOtpSubmitted(_otp.text));
  }

  Future<void> _openForgotPassword() async {
    final loginId = await Navigator.of(context).push<String>(ForgotPasswordPage.route(initialLoginId: _loginId.text));
    if (loginId == null || !mounted) return;
    _loginId.text = loginId;
    _password.clear();
    context.read<LoginBloc>().add(const LoginModeChanged(LoginMode.password));
    showAuthMessage(context, 'Password updated. Log in with your new password.');
  }

  void _onStateChanged(BuildContext context, LoginState state) {
    switch (state.status) {
      case LoginStatus.failure:
        showAuthMessage(context, state.error ?? 'Something went wrong.', error: true);
      case LoginStatus.otpSent:
        HapticFeedback.lightImpact();
        showAuthMessage(context, state.message ?? 'OTP sent.');
      case LoginStatus.success:
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      case LoginStatus.idle || LoginStatus.submitting:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Log in to start verifying guest passes.',
      child: BlocConsumer<LoginBloc, LoginState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: _onStateChanged,
        builder: (context, state) {
          final busy = state.isSubmitting || state.status == LoginStatus.success;
          final otpLocked = state.mode == LoginMode.otp && state.otpSent;

          return Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthModeSwitch(
                    labels: const ['Password', 'OTP'],
                    selected: state.mode.index,
                    onChanged: busy
                        ? (_) {}
                        : (i) {
                            _otp.clear();
                            context.read<LoginBloc>().add(LoginModeChanged(LoginMode.values[i]));
                          },
                  ),
                  const SizedBox(height: 24),
                  GoldTextField(
                    controller: _loginId,
                    label: 'Email ID / Contact No',
                    icon: Icons.person_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username, AutofillHints.email],
                    validator: AuthValidators.loginId,
                    enabled: !busy && !otpLocked,
                    textInputAction: state.mode == LoginMode.password ? TextInputAction.next : TextInputAction.done,
                    onSubmitted: state.mode == LoginMode.otp && !otpLocked ? (_) => _sendOtp() : null,
                  ),
                  const SizedBox(height: 16),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: animation.drive(Tween(begin: const Offset(0, 0.06), end: Offset.zero)),
                          child: child,
                        ),
                      ),
                      layoutBuilder: (current, previous) =>
                          Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
                      child: switch ((state.mode, state.otpSent)) {
                        (LoginMode.password, _) => _PasswordSection(
                          key: const ValueKey('password'),
                          controller: _password,
                          busy: busy,
                          onSubmit: _loginWithPassword,
                          onForgotPassword: _openForgotPassword,
                        ),
                        (LoginMode.otp, false) => _SendOtpSection(
                          key: const ValueKey('send-otp'),
                          busy: busy,
                          onSubmit: _sendOtp,
                        ),
                        (LoginMode.otp, true) => _VerifyOtpSection(
                          key: const ValueKey('verify-otp'),
                          controller: _otp,
                          state: state,
                          busy: busy,
                          onSubmit: _verifyOtp,
                          onResend: _resendOtp,
                          onChangeId: () {
                            _otp.clear();
                            context.read<LoginBloc>().add(const LoginOtpEditRequested());
                          },
                        ),
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PasswordSection extends StatelessWidget {
  const _PasswordSection({
    super.key,
    required this.controller,
    required this.busy,
    required this.onSubmit,
    required this.onForgotPassword,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GoldTextField(
          controller: controller,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          obscure: true,
          enabled: !busy,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          validator: AuthValidators.password,
          onSubmitted: (_) => onSubmit(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: busy ? null : onForgotPassword,
            style: TextButton.styleFrom(foregroundColor: AppColors.gold),
            child: const Text('Forgot password?', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        GoldButton(label: 'Log in', icon: Icons.login_rounded, loading: busy, onPressed: onSubmit),
      ],
    );
  }
}

class _SendOtpSection extends StatelessWidget {
  const _SendOtpSection({super.key, required this.busy, required this.onSubmit});

  final bool busy;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Hint('We will send a one-time password to your registered email or contact number.'),
        const SizedBox(height: 24),
        GoldButton(label: 'Send OTP', icon: Icons.sms_outlined, loading: busy, onPressed: onSubmit),
      ],
    );
  }
}

class _VerifyOtpSection extends StatelessWidget {
  const _VerifyOtpSection({
    super.key,
    required this.controller,
    required this.state,
    required this.busy,
    required this.onSubmit,
    required this.onResend,
    required this.onChangeId,
  });

  final TextEditingController controller;
  final LoginState state;
  final bool busy;
  final VoidCallback onSubmit;
  final VoidCallback onResend;
  final VoidCallback onChangeId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OtpField(controller: controller, enabled: !busy, onSubmitted: onSubmit),
        const SizedBox(height: 4),
        Row(
          children: [
            TextButton.icon(
              onPressed: busy ? null : onChangeId,
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Change'),
            ),
            const Spacer(),
            ResendOtpButton(availableAt: state.resendAt, enabled: !busy, onPressed: onResend),
          ],
        ),
        const SizedBox(height: 12),
        GoldButton(label: 'Verify & log in', icon: Icons.verified_user_outlined, loading: busy, onPressed: onSubmit),
      ],
    );
  }
}

/// Numeric one-time-password input, shared with the reset-password screen.
class OtpField extends StatelessWidget {
  const OtpField({super.key, required this.controller, required this.enabled, this.onSubmitted});

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return GoldTextField(
      controller: controller,
      label: 'OTP',
      icon: Icons.pin_outlined,
      keyboardType: TextInputType.number,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 8,
      letterSpacing: 6,
      enabled: enabled,
      validator: AuthValidators.otp,
      textInputAction: onSubmitted == null ? TextInputAction.next : TextInputAction.done,
      onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.goldDark),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.45)),
        ),
      ],
    );
  }
}
