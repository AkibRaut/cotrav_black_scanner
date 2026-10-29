part of 'login_bloc.dart';

sealed class LoginEvent {
  const LoginEvent();
}

final class LoginModeChanged extends LoginEvent {
  const LoginModeChanged(this.mode);

  final LoginMode mode;
}

final class LoginPasswordSubmitted extends LoginEvent {
  const LoginPasswordSubmitted({required this.loginId, required this.password});

  final String loginId;
  final String password;
}

/// Sends (or re-sends) a login OTP.
final class LoginOtpRequested extends LoginEvent {
  const LoginOtpRequested(this.loginId);

  final String loginId;
}

final class LoginOtpSubmitted extends LoginEvent {
  const LoginOtpSubmitted(this.otp);

  final String otp;
}

/// Goes back to entering the email / contact number.
final class LoginOtpEditRequested extends LoginEvent {
  const LoginOtpEditRequested();
}
