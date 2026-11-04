import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode: $message)';
}

// ============================================================================
// Group chat API helpers (top-level functions)
// ============================================================================
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
      throw ApiException(res.statusCode, res.body);
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
      throw ApiException(res.statusCode, res.body);
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  } finally {
    client.close();
  }
}

// ============================================================================
// Generic API helpers
// ============================================================================
Future<Map<String, dynamic>> apiGet(String path) async {
  final client = http.Client();
  try {
    final uri = Uri.parse('http://localhost:4000$path');
    final res = await client.get(uri).timeout(const Duration(seconds: 30));
    if (res.statusCode >= 400) throw ApiException(res.statusCode, res.body);
    return jsonDecode(res.body) as Map<String, dynamic>;
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> apiDelete(String path) async {
  final client = http.Client();
  try {
    final uri = Uri.parse('http://localhost:4000$path');
    final res = await client.delete(uri).timeout(const Duration(seconds: 30));
    if (res.statusCode >= 400) throw ApiException(res.statusCode, res.body);
    return jsonDecode(res.body) as Map<String, dynamic>;
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> apiPost(String path, {required Map<String, dynamic> body}) async {
  final client = http.Client();
  try {
    final uri = Uri.parse('http://localhost:4000$path');
    final res = await client.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body)).timeout(const Duration(seconds: 30));
    if (res.statusCode >= 400) throw ApiException(res.statusCode, res.body);
    return jsonDecode(res.body) as Map<String, dynamic>;
  } finally {
    client.close();
  }
}

// ============================================================================
// File upload/download helpers
// ============================================================================
Future<void> apiUploadFile(String path, String fieldName, File file,
    {Map<String, String>? fields}) async {
  final client = http.Client();
  try {
    final uri = Uri.parse('http://localhost:4000$path');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath(fieldName, file.path))
      ..fields.addAll(fields ?? {});
    final res = await request.send().timeout(const Duration(seconds: 60));
    if (res.statusCode >= 400) {
      final body = await res.stream.bytesToString();
      throw ApiException(res.statusCode, body);
    }
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> apiUploadBytes(String path, String fieldName,
    List<int> bytes, String fileName,
    {Map<String, String>? fields}) async {
  final client = http.Client();
  try {
    final uri = Uri.parse('http://localhost:4000$path');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes(fieldName, bytes, filename: fileName))
      ..fields.addAll(fields ?? {});
    final res = await request.send().timeout(const Duration(seconds: 60));
    if (res.statusCode >= 400) {
      final body = await res.stream.bytesToString();
      throw ApiException(res.statusCode, body);
    }
    return jsonDecode(await res.stream.bytesToString()) as Map<String, dynamic>;
  } finally {
    client.close();
  }
}

Future<bool> ensureStoragePermission(BuildContext context) async {
  final status = await Permission.storage.status;
  if (!status.isGranted) {
    final result = await Permission.storage.request();
    return result.isGranted;
  }
  return true;
}

Future<String> resolveDownloadDirectory(String folderName) async {
  final dir = await getExternalStorageDirectory();
  final path = '${dir?.path}/$folderName';
  await Directory(path).create(recursive: true);
  return path;
}

Future<void> apiDownloadFile(String url, String destPath) async {
  final client = http.Client();
  try {
    final uri = Uri.parse(url.startsWith('http') ? url : 'http://localhost:4000$url');
    final res = await client.get(uri).timeout(const Duration(seconds: 120));
    if (res.statusCode >= 400) throw ApiException(res.statusCode, res.body);
    await File(destPath).writeAsBytes(res.bodyBytes);
  } finally {
    client.close();
  }
}

// ============================================================================
// Assignments API
// ============================================================================
Future<Map<String, dynamic>> apiListAssignments(int batchId, int subjectId) async {
  return apiGet('/api/assignments?batch_id=$batchId&subject_id=$subjectId');
}

Future<Map<String, dynamic>> apiCreateAssignment(Map<String, dynamic> body) async {
  return apiPost('/api/assignments', body: body);
}

Future<Map<String, dynamic>> apiAssignmentSubmissions(int assignmentId) async {
  return apiGet('/api/assignments/$assignmentId/submissions');
}

Future<Map<String, dynamic>> apiGradeSubmission(int assignmentId, int studentId, int score) async {
  return apiPost('/api/assignments/$assignmentId/submissions/$studentId/grade',
      body: {'score': score});
}

// ============================================================================
// Timetable API
// ============================================================================
Future<Map<String, dynamic>> apiListTimetable(int batchId, int subjectId) async {
  return apiGet('/api/timetable?batch_id=$batchId&subject_id=$subjectId');
}

Future<Map<String, dynamic>> apiCreateTimetableEntry(Map<String, dynamic> body) async {
  return apiPost('/api/timetable', body: body);
}

Future<Map<String, dynamic>> apiUpdateTimetableEntry(int id, Map<String, dynamic> body) async {
  return apiPost('/api/timetable/$id', body: body);
}

Future<Map<String, dynamic>> apiDeleteTimetableEntry(int id) async {
  return apiDelete('/api/timetable/$id');
}

// ============================================================================
// Announcements API
// ============================================================================
Future<Map<String, dynamic>> apiListAnnouncements({int? batchId}) async {
  final query = batchId != null ? '?batch_id=$batchId' : '';
  return apiGet('/api/announcements$query');
}

Future<Map<String, dynamic>> apiCreateAnnouncement(Map<String, dynamic> body) async {
  return apiPost('/api/announcements', body: body);
}

Future<Map<String, dynamic>> apiDeleteAnnouncement(int id) async {
  return apiDelete('/api/announcements/$id');
}

// ============================================================================
// Submission Kit API
// ============================================================================
Future<Map<String, dynamic>> apiListTemplates() async {
  return apiGet('/api/submission-kit');
}

Future<Map<String, dynamic>> apiUploadTemplate(Map<String, dynamic> body,
    File file, String fileName) async {
  return apiUploadBytes('/api/submission-kit', 'file',
      await file.readAsBytes(), fileName, fields: body);
}

Future<Map<String, dynamic>> apiUploadTemplateBytes(String path,
    String fieldName, List<int> bytes, String fileName,
    {Map<String, String>? fields}) async {
  return apiUploadBytes(path, fieldName, bytes, fileName, fields: fields);
}

Future<Map<String, dynamic>> apiSetTemplateCurrent(int id) async {
  return apiPost('/api/submission-kit/$id/set-current', body: {});
}

// ============================================================================
// Groups API
// ============================================================================
Future<Map<String, dynamic>> apiGetGroups() async {
  return apiGet('/api/groups');
}

Future<Map<String, dynamic>> apiCreateGroup(Map<String, dynamic> body) async {
  return apiPost('/api/groups', body: body);
}

Future<Map<String, dynamic>> apiGetGroupMembers(int groupId) async {
  return apiGet('/api/groups/$groupId/members');
}

Future<Map<String, dynamic>> apiGetGroup(int groupId) async {
  return apiGet('/api/groups/$groupId');
}

Future<Map<String, dynamic>> apiAddGroupMember(int groupId,
    {required int userId, String role = 'member'}) async {
  return apiPost('/api/groups/$groupId/members', body: {'user_id': userId, 'role': role});
}

Future<Map<String, dynamic>> apiRemoveGroupMember(int groupId, int userId) async {
  return apiDelete('/api/groups/$groupId/members/$userId');
}

Future<Map<String, dynamic>> apiUpdateGroupMemberRole(int groupId, int userId, String role) async {
  return apiPost('/api/groups/$groupId/members/$userId', body: {'role': role});
}

// ============================================================================
// Parent API
// ============================================================================
Future<Map<String, dynamic>> apiGetChildren() async {
  return apiGet('/api/parent/children');
}

Future<Map<String, dynamic>> apiLinkChild(String email, String relation) async {
  return apiPost('/api/parent/link-child', body: {'email': email, 'relation': relation});
}

Future<Map<String, dynamic>> apiChildOverview(int childId) async {
  return apiGet('/api/parent/children/$childId/overview');
}

Future<Map<String, dynamic>> apiChildAttendance(int childId) async {
  return apiGet('/api/parent/children/$childId/attendance');
}

Future<Map<String, dynamic>> apiChildMarks(int childId) async {
  return apiGet('/api/parent/children/$childId/marks');
}

Future<Map<String, dynamic>> apiChildAssignments(int childId) async {
  return apiGet('/api/parent/children/$childId/assignments');
}

Future<Map<String, dynamic>> apiChildAnnouncements(int childId) async {
  return apiGet('/api/parent/children/$childId/announcements');
}

// ============================================================================
// Planner API
// ============================================================================
Future<Map<String, dynamic>> apiCompletePlannerTask(int taskId) async {
  return apiPost('/api/planner/tasks/$taskId/complete', body: {});
}

Future<Map<String, dynamic>> apiCarryForwardPlannerTask(int taskId) async {
  return apiPost('/api/planner/tasks/$taskId/carry-forward', body: {});
}

Future<Map<String, dynamic>> apiDeletePlannerTask(int taskId) async {
  return apiDelete('/api/planner/tasks/$taskId');
}
