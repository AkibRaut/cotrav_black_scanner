part of 'forgot_password_bloc.dart';

sealed class ForgotPasswordEvent {
  const ForgotPasswordEvent();
}

/// Sends (or re-sends) the reset OTP.
final class ForgotPasswordOtpRequested extends ForgotPasswordEvent {
  const ForgotPasswordOtpRequested(this.loginId);

  final String loginId;
}

final class ForgotPasswordResetSubmitted extends ForgotPasswordEvent {
  const ForgotPasswordResetSubmitted({required this.otp, required this.newPassword});

  final String otp;
  final String newPassword;
}

final class ForgotPasswordEditRequested extends ForgotPasswordEvent {
  const ForgotPasswordEditRequested();
}
