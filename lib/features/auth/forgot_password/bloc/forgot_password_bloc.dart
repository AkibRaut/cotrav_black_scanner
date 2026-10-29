import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_repository.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc({required this._repository, this.resendDelay = const Duration(seconds: 30)})
    : super(const ForgotPasswordState()) {
    on<ForgotPasswordOtpRequested>(_onOtpRequested);
    on<ForgotPasswordResetSubmitted>(_onResetSubmitted);
    on<ForgotPasswordEditRequested>((_, emit) {
      if (!state.isSubmitting) emit(const ForgotPasswordState());
    });
  }

  final AuthRepository _repository;
  final Duration resendDelay;

  Future<void> _onOtpRequested(ForgotPasswordOtpRequested event, Emitter<ForgotPasswordState> emit) async {
    if (state.isSubmitting) return;
    emit(state.copyWith(status: ForgotPasswordStatus.submitting));
    try {
      final message = await _repository.forgotPassword(event.loginId);
      emit(
        state.copyWith(
          status: ForgotPasswordStatus.otpSent,
          loginId: event.loginId.trim().toLowerCase(),
          resendAt: DateTime.now().add(resendDelay),
          message: message ?? 'OTP sent to ${event.loginId.trim()}',
        ),
      );
    } on AuthException catch (e) {
      emit(state.copyWith(status: ForgotPasswordStatus.failure, error: e.message));
    }
  }

  Future<void> _onResetSubmitted(ForgotPasswordResetSubmitted event, Emitter<ForgotPasswordState> emit) async {
    final loginId = state.loginId;
    if (state.isSubmitting || loginId == null) return;
    emit(state.copyWith(status: ForgotPasswordStatus.submitting));
    try {
      final message = await _repository.resetPassword(loginId: loginId, otp: event.otp, newPassword: event.newPassword);
      emit(
        state.copyWith(
          status: ForgotPasswordStatus.success,
          message: message ?? 'Password updated. Log in with your new password.',
        ),
      );
    } on AuthException catch (e) {
      emit(state.copyWith(status: ForgotPasswordStatus.failure, error: e.message));
    }
  }
}
