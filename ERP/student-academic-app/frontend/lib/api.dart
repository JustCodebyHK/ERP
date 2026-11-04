import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  final Duration timeout;
  final http.Client client;
  String? _authToken;

  ApiClient({
    this.baseUrl = 'http://localhost:4000/api',
    this.timeout = const Duration(seconds: 30),
    http.Client? client,
  }) : client = client ?? http.Client();

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> _authHeaders({Map<String, String>? extra}) {
    final headers = <String, String>{};
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    headers.addAll(extra ?? {});
    return headers;
  }

  Future<http.Response> get(String path, {Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$path');
    return client.get(uri, headers: _authHeaders(headers: headers)).timeout(timeout);
  }

  Future<http.Response> post(String path,
      {Map<String, String>? headers, dynamic body}) async {
    final uri = Uri.parse('$baseUrl$path');
    return client.post(uri,
            headers: {'Content-Type': 'application/json', ...?(_authHeaders(headers: headers))},
            body: jsonEncode(body))
        .timeout(timeout);
  }

  Future<http.Response> put(String path,
      {Map<String, String>? headers, dynamic body}) async {
    final uri = Uri.parse('$baseUrl$path');
    return client.put(uri,
            headers: {'Content-Type': 'application/json', ...?(_authHeaders(headers: headers))},
            body: jsonEncode(body))
        .timeout(timeout);
  }

  Future<http.Response> delete(String path,
      {Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$path');
    return client.delete(uri, headers: _authHeaders(headers: headers)).timeout(timeout);
  }

  void dispose() {
    client.close();
  }
}

/// Group chat API helpers (top-level functions for direct use)
Future<Map<String, dynamic>> apiGetGroupMessages(String groupId,
    {String? before, int limit = 50}) async {
  final client = http.Client();
  try {
    final uri = Uri.parse('http://localhost:4000/api/groups/$groupId/messages')
        .replace(queryParameters: {
          if (before != null) 'before': before,
          'limit': limit.toString(),
        }..removeWhere((k, v) => v == null));
    final res = await client.get(uri).timeout(const Duration(seconds: 30));
    if (res.statusCode >= 400) {
      throw Exception('GET /groups/$groupId/messages failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> apiSendGroupMessage(String groupId,
    {required String content, String type = 'text'}) async {
  final client = http.Client();
  try {
    final uri = Uri.parse('http://localhost:4000/api/groups/$groupId/messages');
    final res = await client.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': content, 'type': type})).timeout(const Duration(seconds: 30));
    if (res.statusCode >= 400) {
      throw Exception('POST /groups/$groupId/messages failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  } finally {
    client.close();
  }
}
