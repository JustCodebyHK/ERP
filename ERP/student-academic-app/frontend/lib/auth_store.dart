import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStore {
  static final AuthStore _instance = AuthStore._internal();
  factory AuthStore() => _instance;
  AuthStore._internal();

  final _storage = const FlutterSecureStorage();
  Map<String, dynamic>? _userCache;
  bool? _isLoggedInCache;

  static const _tokenKey = 'auth_token';
  static const _refreshKey = 'refresh_token';
  static const _userKey = 'user';

  static Future<void> load() async {
    final store = _instance;
    await store.getUser();
    await store.getToken();
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    _isLoggedInCache = true;
  }

  Future<String?> getToken() async => _storage.read(key: _tokenKey);

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshKey, value: token);
  }

  Future<String?> getRefreshToken() async => _storage.read(key: _refreshKey);

  Future<void> saveUser(Map<String, dynamic> user) async {
    _userCache = user;
    await _storage.write(key: _userKey, value: jsonEncode(user));
    _isLoggedInCache = true;
  }

  static Future<void> saveSession(Map<String, dynamic> user,
      {String? token, String? refreshToken}) async {
    final store = _instance;
    if (token != null) await store.saveToken(token);
    if (refreshToken != null) await store.saveRefreshToken(refreshToken);
    await store.saveUser(user);
  }

  Future<void> updateUser(Map<String, dynamic> updates) async {
    final current = await getUser();
    if (current == null) return;
    final merged = {...current, ...updates};
    await saveUser(merged);
  }

  Future<Map<String, dynamic>?> getUser() async {
    if (_userCache != null) return _userCache;
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    try {
      _userCache = jsonDecode(raw) as Map<String, dynamic>;
      return _userCache;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? get user => _userCache;

  static bool get isLoggedIn => _instance._isLoggedInCache ?? false;

  Future<bool> get _isLoggedIn async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clear() async {
    final store = _instance;
    store._userCache = null;
    store._isLoggedInCache = false;
    await store._storage.delete(key: _tokenKey);
    await store._storage.delete(key: _refreshKey);
    await store._storage.delete(key: _userKey);
  }

  Future<void> logout() async {
    await clear();
  }

  Future<void> clearAll() async {
    _userCache = null;
    _isLoggedInCache = false;
    await _storage.deleteAll();
  }
}
