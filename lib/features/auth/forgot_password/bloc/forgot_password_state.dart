part of 'forgot_password_bloc.dart';

enum ForgotPasswordStatus { idle, submitting, otpSent, success, failure }

class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.idle,
    this.loginId,
    this.resendAt,
    this.error,
    this.message,
  });

  final ForgotPasswordStatus status;

  /// Set once the reset OTP has been sent.
  final String? loginId;
  final DateTime? resendAt;
  final String? error;
  final String? message;

  bool get isSubmitting => status == ForgotPasswordStatus.submitting;
  bool get otpSent => loginId != null;

  ForgotPasswordState copyWith({
    required ForgotPasswordStatus status,
    String? loginId,
    DateTime? resendAt,
    String? error,
    String? message,
  }) {
    return ForgotPasswordState(
      status: status,
      loginId: loginId ?? this.loginId,
      resendAt: resendAt ?? this.resendAt,
      error: error,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, loginId, resendAt, error, message];
}
