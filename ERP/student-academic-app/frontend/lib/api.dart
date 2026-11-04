import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  final Duration timeout;
  final http.Client client;

  ApiClient({
    this.baseUrl = 'http://localhost:4000/api',
    this.timeout = const Duration(seconds: 30),
    http.Client? client,
  }) : client = client ?? http.Client();

  Future<http.Response> get(String path, {Map<String, String>? headers}) async {
    final uri = Uri.parse('\\');
    return client.get(uri, headers: headers).timeout(timeout);
  }

  Future<http.Response> post(String path,
      {Map<String, String>? headers, dynamic body}) async {
    final uri = Uri.parse('\\');
    return client.post(uri,
            headers: {'Content-Type': 'application/json', ...?headers},
            body: jsonEncode(body))
        .timeout(timeout);
  }

  Future<http.Response> put(String path,
      {Map<String, String>? headers, dynamic body}) async {
    final uri = Uri.parse('\\');
    return client.put(uri,
            headers: {'Content-Type': 'application/json', ...?headers},
            body: jsonEncode(body))
        .timeout(timeout);
  }

  Future<http.Response> delete(String path,
      {Map<String, String>? headers}) async {
    final uri = Uri.parse('\\');
    return client.delete(uri, headers: headers).timeout(timeout);
  }

  void dispose() {
    client.close();
  }
}
