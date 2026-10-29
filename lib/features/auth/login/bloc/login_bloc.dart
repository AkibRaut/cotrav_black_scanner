import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required this._repository, this.resendDelay = const Duration(seconds: 30)}) : super(const LoginState()) {
    on<LoginModeChanged>(_onModeChanged);
    on<LoginPasswordSubmitted>(_onPasswordSubmitted);
    on<LoginOtpRequested>(_onOtpRequested);
    on<LoginOtpSubmitted>(_onOtpSubmitted);
    on<LoginOtpEditRequested>(_onOtpEditRequested);
  }

  final AuthRepository _repository;

  /// How long before the operator may ask for another OTP.
  final Duration resendDelay;

  void _onModeChanged(LoginModeChanged event, Emitter<LoginState> emit) {
    if (state.isSubmitting || event.mode == state.mode) return;
    emit(LoginState(mode: event.mode));
  }

  Future<void> _onPasswordSubmitted(LoginPasswordSubmitted event, Emitter<LoginState> emit) async {
    if (state.isSubmitting) return;
    emit(state.copyWith(status: LoginStatus.submitting));
    try {
      await _repository.loginWithPassword(loginId: event.loginId, password: event.password);
      emit(state.copyWith(status: LoginStatus.success));
    } on AuthException catch (e) {
      emit(state.copyWith(status: LoginStatus.failure, error: e.message));
    }
  }

  Future<void> _onOtpRequested(LoginOtpRequested event, Emitter<LoginState> emit) async {
    if (state.isSubmitting) return;
    emit(state.copyWith(status: LoginStatus.submitting));
    try {
      final message = await _repository.sendLoginOtp(event.loginId);
      emit(
        state.copyWith(
          status: LoginStatus.otpSent,
          otpLoginId: event.loginId.trim().toLowerCase(),
          resendAt: DateTime.now().add(resendDelay),
          message: message ?? 'OTP sent to ${event.loginId.trim()}',
        ),
      );
    } on AuthException catch (e) {
      emit(state.copyWith(status: LoginStatus.failure, error: e.message));
    }
  }

  Future<void> _onOtpSubmitted(LoginOtpSubmitted event, Emitter<LoginState> emit) async {
    final loginId = state.otpLoginId;
    if (state.isSubmitting || loginId == null) return;
    emit(state.copyWith(status: LoginStatus.submitting));
    try {
      await _repository.verifyLoginOtp(loginId: loginId, otp: event.otp);
      emit(state.copyWith(status: LoginStatus.success));
    } on AuthException catch (e) {
      emit(state.copyWith(status: LoginStatus.failure, error: e.message));
    }
  }

  void _onOtpEditRequested(LoginOtpEditRequested event, Emitter<LoginState> emit) {
    if (state.isSubmitting) return;
    emit(const LoginState(mode: LoginMode.otp));
  }
}
