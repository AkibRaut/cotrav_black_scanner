import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_session.dart';

/// Persists the session so the operator stays logged in across launches.
abstract interface class SessionStore {
  Future<AuthSession?> read();
  Future<void> write(AuthSession session);
  Future<void> clear();
}

/// Keeps the session in the Keychain (iOS) / encrypted storage (Android).
class SecureSessionStore implements SessionStore {
  const SecureSessionStore([this._storage = const FlutterSecureStorage()]);

  static const _key = 'auth_session';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Corrupt or unreadable (e.g. restored backup without the key): log in again.
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthSession session) => _storage.write(key: _key, value: jsonEncode(session.toJson()));

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// Non-persistent store, used in tests.
class MemorySessionStore implements SessionStore {
  MemorySessionStore([this._session]);

  AuthSession? _session;

  @override
  Future<AuthSession?> read() async => _session;

  @override
  Future<void> write(AuthSession session) async => _session = session;

  @override
  Future<void> clear() async => _session = null;
}
