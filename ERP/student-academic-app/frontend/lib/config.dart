import 'package:flutter/foundation.dart';

// API_BASE_URL is the server root (without /api), for example:
// flutter run --dart-define=API_BASE_URL=https://your-app.onrender.com
const String _configuredApiRoot = String.fromEnvironment('API_BASE_URL');

String get _defaultApiRoot {
  // Default to production server URL
  return 'https://academic-erp-api-u026.onrender.com';
}

final String apiBaseUrlNoPrefix =
    (_configuredApiRoot.isEmpty ? _defaultApiRoot : _configuredApiRoot)
        .replaceFirst(RegExp(r'/$'), '');

final String apiBaseUrl = '$apiBaseUrlNoPrefix/api';
