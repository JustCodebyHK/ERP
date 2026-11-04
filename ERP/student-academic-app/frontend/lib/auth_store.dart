import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStore {
  static final AuthStore _instance = AuthStore._internal();
  factory AuthStore() => _instance;
  AuthStore._internal();

  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _refreshKey = 'refresh_token';
  static const _userKey = 'user';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async => _storage.read(key: _tokenKey);

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshKey, value: token);
  }

  Future<String?> getRefreshToken() async => _storage.read(key: _refreshKey);

  Future<void> saveUser(Map<String, dynamic> user) async {
    await _storage.write(key: _userKey, value: user.toString());
  }

  Future<void> updateUser(Map<String, dynamic> updates) async {
    final current = await getUser();
    if (current == null) return;
    final merged = {...?current, ...updates};
    await saveUser(merged);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    return {'raw': raw};
  }

  Future<bool> get isAuthenticated async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
