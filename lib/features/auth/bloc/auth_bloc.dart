import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import '../models/auth_session.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// App-wide login state. Screens react to it; they never navigate on login
/// or logout themselves.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required this._repository}) : super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthLogoutRequested>((_, _) => _repository.logout());
  }

  final AuthRepository _repository;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final session = await _repository.restoreSession();
    emit(AuthState.from(session));
    await emit.forEach(_repository.sessionChanges, onData: AuthState.from);
  }
}
