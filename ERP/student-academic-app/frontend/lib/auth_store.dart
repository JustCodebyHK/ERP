import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
      );

  final String id;
  final String name;
  final String email;
  final String role;
}

/// In-memory session + encrypted on-disk persistence.
///
/// The JWT and user profile are stored in Flutter Secure Storage
/// (Android Keystore / iOS Keychain), NOT in plaintext shared_preferences.
/// This mitigates token extraction from rooted devices, ADB backups, or
/// malicious apps with storage access (F-002).
class AuthStore {
  static const _secureStorage = FlutterSecureStorage();

  static const _kToken = 'token';
  static const _kUserId = 'user_id';
  static const _kUserName = 'user_name';
  static const _kUserEmail = 'user_email';
  static const _kUserRole = 'user_role';

  static String? token;
  static AppUser? user;

  static bool get isLoggedIn => token != null && user != null;

  static Future<void> load() async {
    final savedToken = await _secureStorage.read(key: _kToken);
    final id = await _secureStorage.read(key: _kUserId);
    final name = await _secureStorage.read(key: _kUserName);
    final email = await _secureStorage.read(key: _kUserEmail);
    final role = await _secureStorage.read(key: _kUserRole);
    if (savedToken != null &&
        id != null &&
        name != null &&
        email != null &&
        role != null) {
      token = savedToken;
      user = AppUser(id: id, name: name, email: email, role: role);
    }
  }

  static Future<void> saveSession(
      String newToken, Map<String, dynamic> userJson) async {
    token = newToken;
    user = AppUser.fromJson(userJson);
    await _secureStorage.write(key: _kToken, value: newToken);
    await _secureStorage.write(key: _kUserId, value: user!.id);
    await _secureStorage.write(key: _kUserName, value: user!.name);
    await _secureStorage.write(key: _kUserEmail, value: user!.email);
    await _secureStorage.write(key: _kUserRole, value: user!.role);
  }

  static Future<void> clear() async {
    token = null;
    user = null;
    await _secureStorage.delete(key: _kToken);
    await _secureStorage.delete(key: _kUserId);
    await _secureStorage.delete(key: _kUserName);
    await _secureStorage.delete(key: _kUserEmail);
    await _secureStorage.delete(key: _kUserRole);
  }
}
