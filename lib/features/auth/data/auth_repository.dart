import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../models/auth_session.dart';
import 'session_store.dart';

/// A request was rejected; [message] is safe to show to the user.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Talks to the events auth API and owns the stored session.
///
/// The API takes form-encoded bodies and always answers 200 with
/// `{"success": "1" | "0", "error": "...", ...}`, so success is read from the
/// body, not the status code.
class AuthRepository {
  AuthRepository({
    http.Client? client,
    this._store = const SecureSessionStore(),
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final SessionStore _store;
  final Duration timeout;

  final _sessions = StreamController<AuthSession?>.broadcast();

  /// Emits the new session on login and `null` on logout.
  Stream<AuthSession?> get sessionChanges => _sessions.stream;

  Future<AuthSession?> restoreSession() => _store.read();

  Future<AuthSession> loginWithPassword({required String loginId, required String password}) async {
    final id = _normalize(loginId);
    final body = await _post(ApiConfig.passwordLogin, {'login_id': id, 'password': password});
    return _startSession(id, body);
  }

  /// Returns the server's confirmation message, if any.
  Future<String?> sendLoginOtp(String loginId) async {
    final body = await _post(ApiConfig.sendOtp, {'login_id': _normalize(loginId)});
    return _message(body);
  }

  Future<AuthSession> verifyLoginOtp({required String loginId, required String otp}) async {
    final id = _normalize(loginId);
    final body = await _post(ApiConfig.verifyOtp, {'login_id': id, 'otp': otp.trim()});
    return _startSession(id, body);
  }

  Future<String?> forgotPassword(String loginId) async {
    final body = await _post(ApiConfig.forgotPassword, {'login_id': _normalize(loginId)});
    return _message(body);
  }

  Future<String?> resetPassword({required String loginId, required String otp, required String newPassword}) async {
    final body = await _post(ApiConfig.resetPassword, {
      'login_id': _normalize(loginId),
      'otp': otp.trim(),
      'new_password': newPassword,
    });
    return _message(body);
  }

  Future<void> logout() async {
    await _store.clear();
    _sessions.add(null);
  }

  void close() {
    _sessions.close();
    _client.close();
  }

  Future<AuthSession> _startSession(String loginId, Map<String, dynamic> body) async {
    final session = AuthSession(loginId: loginId, token: _findToken(body), user: body);
    await _store.write(session);
    _sessions.add(session);
    return session;
  }

  Future<Map<String, dynamic>> _post(String url, Map<String, String> fields) async {
    final http.Response response;
    try {
      response = await _client.post(Uri.parse(url), body: fields).timeout(timeout);
    } on TimeoutException {
      throw const AuthException('Server took too long. Please try again.');
    } on http.ClientException {
      throw const AuthException('No internet connection.');
    }

    if (response.statusCode >= 500) {
      throw const AuthException('Server is unavailable right now. Please try again.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true));
    } on FormatException {
      throw AuthException('Unexpected server response (${response.statusCode}).');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const AuthException('Unexpected server response.');
    }

    if (!_isSuccess(decoded['success'] ?? decoded['status'])) {
      throw AuthException(_error(decoded) ?? 'Something went wrong. Please try again.');
    }
    return decoded;
  }

  static String _normalize(String loginId) => loginId.trim().toLowerCase();

  static bool _isSuccess(Object? value) => switch (value) {
    true || 1 => true,
    String s => const {'1', 'true', 'success', 'ok'}.contains(s.trim().toLowerCase()),
    _ => false,
  };

  static String? _error(Map<String, dynamic> body) => _firstText(body, const ['error', 'message', 'msg']);

  static String? _message(Map<String, dynamic> body) => _firstText(body, const ['message', 'msg']);

  static String? _firstText(Map<String, dynamic> body, List<String> keys) {
    for (final key in keys) {
      final value = body[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static const _tokenKeys = ['access_token', 'token', 'auth_token', 'api_token', 'accessToken'];

  /// Looks for a token at the top level or one level down (`data`, `user`...).
  static String? _findToken(Map<String, dynamic> body) {
    for (final key in _tokenKeys) {
      final value = body[key];
      if (value is String && value.isNotEmpty) return value;
    }
    for (final nested in body.values.whereType<Map<String, dynamic>>()) {
      final token = _findToken(nested);
      if (token != null) return token;
    }
    return null;
  }
}
