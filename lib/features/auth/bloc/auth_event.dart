part of 'auth_bloc.dart';

sealed class AuthEvent {
  const AuthEvent();
}

/// Restores the saved session and starts following login / logout.
final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
