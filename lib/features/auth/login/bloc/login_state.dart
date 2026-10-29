part of 'login_bloc.dart';

enum LoginMode { password, otp }

enum LoginStatus { idle, submitting, otpSent, success, failure }

class LoginState extends Equatable {
  const LoginState({
    this.mode = LoginMode.password,
    this.status = LoginStatus.idle,
    this.otpLoginId,
    this.resendAt,
    this.error,
    this.message,
  });

  final LoginMode mode;
  final LoginStatus status;

  /// Set once an OTP has been sent; the OTP is verified against this ID.
  final String? otpLoginId;
  final DateTime? resendAt;
  final String? error;
  final String? message;

  bool get isSubmitting => status == LoginStatus.submitting;
  bool get otpSent => otpLoginId != null;

  LoginState copyWith({
    required LoginStatus status,
    String? otpLoginId,
    DateTime? resendAt,
    String? error,
    String? message,
  }) {
    return LoginState(
      mode: mode,
      status: status,
      otpLoginId: otpLoginId ?? this.otpLoginId,
      resendAt: resendAt ?? this.resendAt,
      error: error,
      message: message,
    );
  }

  @override
  List<Object?> get props => [mode, status, otpLoginId, resendAt, error, message];
}
