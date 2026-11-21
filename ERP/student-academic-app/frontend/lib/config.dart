import 'package:flutter/foundation.dart';

// API_BASE_URL is the server root (without /api), for example:
// flutter run --dart-define=API_BASE_URL=https://your-app.onrender.com
const String _configuredApiRoot = String.fromEnvironment('API_BASE_URL');

final String apiBaseUrlNoPrefix = () {
  if (_configuredApiRoot.isEmpty) {
    throw StateError('API_BASE_URL not configured. Pass --dart-define=API_BASE_URL=https://your-app.onrender.com');
  }
  return _configuredApiRoot.replaceFirst(RegExp(r'/$'), '');
}();

final String apiBaseUrl = '$apiBaseUrlNoPrefix/api';