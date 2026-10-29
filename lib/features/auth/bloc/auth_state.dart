part of 'auth_bloc.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.unknown, this.session});

  factory AuthState.from(AuthSession? session) => session == null
      ? const AuthState(status: AuthStatus.unauthenticated)
      : AuthState(status: AuthStatus.authenticated, session: session);

  final AuthStatus status;
  final AuthSession? session;

  @override
  List<Object?> get props => [status, session];
}
