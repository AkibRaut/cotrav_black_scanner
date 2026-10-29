import 'package:equatable/equatable.dart';

/// A logged-in operator, as returned by the login / OTP endpoints.
///
/// The whole response is kept in [user] so nothing the server sends is lost;
/// [token] is pulled out when the response carries one.
class AuthSession extends Equatable {
  const AuthSession({required this.loginId, this.token, this.user = const {}});

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    loginId: json['login_id'] as String? ?? '',
    token: json['token'] as String?,
    user: (json['user'] as Map?)?.cast<String, dynamic>() ?? const {},
  );

  final String loginId;
  final String? token;
  final Map<String, dynamic> user;

  /// Best available name for greeting the operator.
  String get displayName {
    for (final key in const ['name', 'full_name', 'fullname', 'user_name', 'username', 'first_name']) {
      final value = _lookup(user, key);
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return loginId;
  }

  Map<String, dynamic> toJson() => {'login_id': loginId, 'token': token, 'user': user};

  @override
  List<Object?> get props => [loginId, token, user];
}

/// Finds [key] at the top level or one level down (e.g. under `data`).
Object? _lookup(Map<String, dynamic> map, String key) {
  if (map.containsKey(key)) return map[key];
  for (final value in map.values) {
    if (value is Map && value.containsKey(key)) return value[key];
  }
  return null;
}
