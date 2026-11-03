import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'auth_store.dart';
import 'services/cache_service.dart';

/// Backend base URL.
/// - Web / Windows desktop: http://localhost:4000 (default)
/// - Android emulator:  flutter run --dart-define=API_BASE=http://10.0.2.2:4000
/// - Physical phone:    flutter run --dart-define=API_BASE=http://PC-LAN-IP:4000
const String apiBase =
    String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:4000');

class ApiException implements Exception {
  ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

/// Runs an HTTP call and maps network-level failures to friendly messages.
///
/// We intentionally do NOT pre-block requests based on the connectivity
/// plugin: it reports false "offline" states on some devices/emulators.
/// The request itself is the source of truth.
Future<T> _networkGuard<T>(Future<T> Function() send) async {
  try {
    return await send();
  } on SocketException {
    throw ApiException(
        'Unable to connect. Check your internet connection and try again.', 0);
  } on http.ClientException {
    throw ApiException(
        'Unable to connect. Check your internet connection and try again.', 0);
  } on TimeoutException {
    throw ApiException(
        'Server is taking too long to respond. Please try again.', 0);
  }
}

/// Returns a user-friendly error message for display in the UI.
/// Network errors get a connection-focused message; server errors
/// get their original message or a generic fallback.
String friendlyErrorMessage(dynamic error) {
  if (error is ApiException) {
    return error.message;
  }
  // For unexpected errors, return a generic friendly message.
  return 'Unable to connect. Check your internet connection and try again.';
}

Map<String, String> _headers() {
  final headers = {'Content-Type': 'application/json'};
  final token = AuthStore.token;
  if (token != null) {
    headers['Authorization'] = 'Bearer $token';
  }
  return headers;
}

Map<String, dynamic> _decode(http.Response res) {
  Map<String, dynamic> data;
  try {
    data = jsonDecode(res.body) as Map<String, dynamic>;
  } catch (_) {
    data = const {};
  }
  if (res.statusCode >= 200 && res.statusCode < 300) return data;
  throw ApiException(
    data['error']?.toString() ?? 'Request failed (${res.statusCode})',
    res.statusCode,
  );
}

Future<Map<String, dynamic>> apiGet(String path) async {
  final res = await _networkGuard(() => http
      .get(Uri.parse('$apiBase$path'), headers: _headers())
      .timeout(const Duration(seconds: 10)));
  return _decode(res);
}

Future<Map<String, dynamic>> apiPost(
    String path, Map<String, dynamic> body) async {
  final res = await _networkGuard(() => http
      .post(Uri.parse('$apiBase$path'),
          headers: _headers(), body: jsonEncode(body))
      .timeout(const Duration(seconds: 10)));
  return _decode(res);
}

/// PUT request
Future<Map<String, dynamic>> apiPut(
    String path, Map<String, dynamic> body) async {
  final res = await _networkGuard(() => http
      .put(Uri.parse('$apiBase$path'),
          headers: _headers(), body: jsonEncode(body))
      .timeout(const Duration(seconds: 10)));
  return _decode(res);
}

/// DELETE request
Future<Map<String, dynamic>> apiDelete(String path) async {
  final res = await _networkGuard(() => http
      .delete(Uri.parse('$apiBase$path'), headers: _headers())
      .timeout(const Duration(seconds: 10)));
  return _decode(res);
}

/// Uploads a file with multipart/form-data. Returns the parsed JSON response.
Future<Map<String, dynamic>> apiUploadFile(
    String path,
    String fieldName,
    File file,
    String fileName,
    Map<String, String> fields, {
  String mimeType = 'application/octet-stream',
}) async {
  final request = http.MultipartRequest('POST', Uri.parse('$apiBase$path'));
  final token = AuthStore.token;
  if (token != null) {
    request.headers['Authorization'] = 'Bearer $token';
  }
  request.fields.addAll(fields);
  request.files.add(await http.MultipartFile.fromPath(
    fieldName,
    file.path,
    filename: fileName,
    contentType: MediaType.parse(mimeType),
  ));

  final res = await _networkGuard(() async {
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    return http.Response.fromStream(streamed);
  });
  return _decode(res);
}

/// Uploads bytes with multipart/form-data. Returns the parsed JSON response.
Future<Map<String, dynamic>> apiUploadBytes(
    String path,
    String fieldName,
    List<int> bytes,
    String fileName,
    Map<String, String> fields, {
  String mimeType = 'application/octet-stream',
}) async {
  final request = http.MultipartRequest('POST', Uri.parse('$apiBase$path'));
  final token = AuthStore.token;
  if (token != null) {
    request.headers['Authorization'] = 'Bearer $token';
  }
  request.fields.addAll(fields);
  request.files.add(http.MultipartFile.fromBytes(
    fieldName,
    bytes,
    filename: fileName,
    contentType: MediaType.parse(mimeType),
  ));

  final res = await _networkGuard(() async {
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    return http.Response.fromStream(streamed);
  });
  return _decode(res);
}

/// Downloads a file and saves it to [destPath]. Returns the file size.
Future<int> apiDownloadFile(String path, String destPath) async {
  final token = AuthStore.token;
  final headers = {'Authorization': 'Bearer $token'};
  final client = http.Client();
  try {
    final req = http.Request('GET', Uri.parse('$apiBase$path'))..headers.addAll(headers);
    final streamed = await _networkGuard(
        () => client.send(req).timeout(const Duration(seconds: 30)));
    if (streamed.statusCode >= 400) {
      final body = await streamed.stream.bytesToString();
      String errorMsg = 'Download failed (${streamed.statusCode})';
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map && decoded['error'] != null) {
          errorMsg = decoded['error'].toString();
        }
      } catch (_) {
        if (body.trim().isNotEmpty && body.length < 120) {
          errorMsg = body.trim();
        }
      }
      throw ApiException(errorMsg, streamed.statusCode);
    }
    final sink = File(destPath).openWrite();
    await streamed.stream.pipe(sink);
    await sink.flush();
    await sink.close();
    return File(destPath).lengthSync();
  } finally {
    client.close();
  }
}

/// Assignments API

Future<Map<String, dynamic>> apiCreateAssignment(Map<String, dynamic> body) =>
    apiPost('/api/assignments', body);

Future<Map<String, dynamic>> apiListAssignments(String batchId, String subjectId) =>
    apiGet('/api/assignments?batch_id=$batchId&subject_id=$subjectId');

Future<Map<String, dynamic>> apiMyAssignments() =>
    apiGet('/api/assignments/my');

Future<Map<String, dynamic>> apiAssignmentDetail(String id) =>
    apiGet('/api/assignments/$id');

Future<Map<String, dynamic>> apiSubmitAssignment(
    String id, File file, String fileName, {String mimeType = 'application/octet-stream'}) =>
    apiUploadFile('/api/assignments/$id/submit', 'file', file, fileName, {}, mimeType: mimeType);

Future<Map<String, dynamic>> apiSubmitAssignmentBytes(
    String id, List<int> bytes, String fileName, {String mimeType = 'application/octet-stream'}) =>
    apiUploadBytes('/api/assignments/$id/submit', 'file', bytes, fileName, {}, mimeType: mimeType);

Future<Map<String, dynamic>> apiAssignmentSubmissions(String id) =>
    apiGet('/api/assignments/$id/submissions');

Future<Map<String, dynamic>> apiGradeSubmission(
    String id, String studentId, int score) =>
    apiPost('/api/assignments/$id/grade', {
      'student_id': studentId,
      'score': score,
    });

/// Timetable API

Future<Map<String, dynamic>> apiCreateTimetableEntry(Map<String, dynamic> body) =>
    apiPost('/api/timetable', body);

Future<Map<String, dynamic>> apiListTimetable(String batchId, String subjectId) =>
    apiGet('/api/timetable?batch_id=$batchId&subject_id=$subjectId');

Future<Map<String, dynamic>> apiMyTimetable() =>
    apiGet('/api/timetable/my');

Future<Map<String, dynamic>> apiTodayTimetable() =>
    apiGet('/api/timetable/today');

Future<Map<String, dynamic>> apiUpdateTimetableEntry(
    String id, Map<String, dynamic> body) async {
  final res = await _networkGuard(() => http
      .put(Uri.parse('$apiBase/api/timetable/$id'),
          headers: _headers(), body: jsonEncode(body))
      .timeout(const Duration(seconds: 10)));
  return _decode(res);
}

Future<Map<String, dynamic>> apiDeleteTimetableEntry(String id) async {
  final res = await _networkGuard(() => http
      .delete(Uri.parse('$apiBase/api/timetable/$id'), headers: _headers())
      .timeout(const Duration(seconds: 10)));
  return _decode(res);
}

/// Announcements API

Future<Map<String, dynamic>> apiCreateAnnouncement(Map<String, dynamic> body) =>
    apiPost('/api/announcements', body);

Future<Map<String, dynamic>> apiListAnnouncements({String? batchId}) {
  final basePath = batchId != null ? '/api/announcements?batch_id=$batchId' : '/api/announcements';
  final cacheBuster = '_t=${DateTime.now().millisecondsSinceEpoch}';
  final path = '$basePath&$cacheBuster';
  return apiGet(path);
}

Future<Map<String, dynamic>> apiUnreadAnnouncementsCount() =>
    apiGet('/api/announcements/unread-count');

Future<Map<String, dynamic>> apiMarkAnnouncementRead(String id) =>
    apiPost('/api/announcements/$id/read', {});

Future<Map<String, dynamic>> apiDeleteAnnouncement(String id) async {
  final res = await _networkGuard(() => http
      .delete(Uri.parse('$apiBase/api/announcements/$id'), headers: _headers())
      .timeout(const Duration(seconds: 10)));
  return _decode(res);
}

/// Submission Kit API

Future<Map<String, dynamic>> apiUploadTemplate(Map<String, String> body, File file, String fileName, {String mimeType = 'application/octet-stream'}) =>
    apiUploadFile('/api/submission-kit', 'file', file, fileName, body, mimeType: mimeType);

Future<Map<String, dynamic>> apiUploadTemplateBytes(Map<String, String> body, List<int> bytes, String fileName, {String mimeType = 'application/octet-stream'}) =>
    apiUploadBytes('/api/submission-kit', 'file', bytes, fileName, body, mimeType: mimeType);

Future<Map<String, dynamic>> apiListTemplates() =>
    apiGet('/api/submission-kit');

Future<Map<String, dynamic>> apiGetCurrentTemplate(String type) =>
    apiGet('/api/submission-kit/$type/current');

Future<int> apiDownloadTemplate(String id, String destPath) =>
    apiDownloadFile('/api/submission-kit/$id/download', destPath);

Future<Map<String, dynamic>> apiSetTemplateCurrent(String id) async {
  final res = await _networkGuard(() => http
      .put(Uri.parse('$apiBase/api/submission-kit/$id/set-current'), headers: _headers())
      .timeout(const Duration(seconds: 10)));
  return _decode(res);
}

/// Cached GET helpers — try network, fall back to cache, update cache on success.

Future<Map<String, dynamic>> apiGetCached(String path, String cacheKey,
    {Future<void> Function(Map<String, dynamic>)? onSuccess}) async {
  try {
    final data = await apiGet(path);
    if (onSuccess != null) await onSuccess(data);
    await CacheService.setLastSync();
    return data;
  } catch (e) {
    // Try cache
    switch (cacheKey) {
      case 'notes':
        return {'notes': await CacheService.getNotes()};
      case 'assignments':
        return await CacheService.getAssignments();
      case 'timetable':
        return await CacheService.getTimetable();
      case 'announcements':
        return {'announcements': await CacheService.getAnnouncements()};
      case 'submission_kit':
        return {'templates': await CacheService.getSubmissionKit()};
      default:
        rethrow;
    }
  }
}

Future<Map<String, dynamic>> apiMyAssignmentsCached() => apiGetCached(
      '/api/assignments/my',
      'assignments',
      onSuccess: CacheService.saveAssignments,
    );

Future<Map<String, dynamic>> apiMyTimetableCached() => apiGetCached(
      '/api/timetable/my',
      'timetable',
      onSuccess: CacheService.saveTimetable,
    );

Future<Map<String, dynamic>> apiTodayTimetableCached() => apiGetCached(
      '/api/timetable/today',
      'timetable',
      onSuccess: CacheService.saveTimetable,
    );

Future<Map<String, dynamic>> apiListAnnouncementsCached({String? batchId}) {
  final path = batchId != null ? '/api/announcements?batch_id=$batchId' : '/api/announcements';
  return apiGetCached(path, 'announcements', onSuccess: (data) => CacheService.saveAnnouncements(data['announcements'] as List? ?? []));
}

Future<Map<String, dynamic>> apiListTemplatesCached() => apiGetCached(
      '/api/submission-kit',
      'submission_kit',
      onSuccess: (data) => CacheService.saveSubmissionKit(data['templates'] as List? ?? []),
    );

Future<Map<String, dynamic>> apiMySubjectsCached() => apiGetCached(
      '/api/academic/my-subjects',
      'notes',
      onSuccess: (data) => CacheService.saveNotes(data['subjects'] as List? ?? []),
    );

Future<Map<String, dynamic>> apiNotesBySubjectCached(String subjectId) => apiGetCached(
      '/api/notes?subject_id=$subjectId',
      'notes',
      onSuccess: (data) => CacheService.saveNotes(data['notes'] as List? ?? []),
    );

/// Parent API

Future<Map<String, dynamic>> apiLinkChild(String studentEmail, String relationship) =>
    apiPost('/api/parent/link', {
      'student_email': studentEmail,
      'relationship': relationship,
    });

Future<Map<String, dynamic>> apiGetChildren() =>
    apiGet('/api/parent/children');

Future<Map<String, dynamic>> apiChildOverview(String studentId) =>
    apiGet('/api/parent/children/$studentId/overview');

Future<Map<String, dynamic>> apiChildAttendance(String studentId) =>
    apiGet('/api/parent/children/$studentId/attendance');

Future<Map<String, dynamic>> apiChildMarks(String studentId) =>
    apiGet('/api/parent/children/$studentId/marks');

Future<Map<String, dynamic>> apiChildAssignments(String studentId) =>
    apiGet('/api/parent/children/$studentId/assignments');

Future<Map<String, dynamic>> apiChildAnnouncements(String studentId) =>
    apiGet('/api/parent/children/$studentId/announcements');

/// Growth Index API

Future<Map<String, dynamic>> apiMyGrowth() =>
    apiGet('/api/growth/me');

Future<Map<String, dynamic>> apiStudentGrowth(String studentId) =>
    apiGet('/api/growth/student/$studentId');

/// Planner API

Future<Map<String, dynamic>> apiGetPlannerTasks(String date) =>
    apiGet('/api/planner/tasks?date=$date');

Future<Map<String, dynamic>> apiGetPlannerWeek(String start) =>
    apiGet('/api/planner/tasks/week?start=$start');

Future<Map<String, dynamic>> apiCreatePlannerTask(Map<String, dynamic> body) =>
    apiPost('/api/planner/tasks', body);

Future<Map<String, dynamic>> apiUpdatePlannerTask(String id, Map<String, dynamic> body) async {
  final res = await _networkGuard(() => http
      .put(Uri.parse('$apiBase/api/planner/tasks/$id'),
          headers: _headers(), body: jsonEncode(body))
      .timeout(const Duration(seconds: 10)));
  return _decode(res);
}

Future<Map<String, dynamic>> apiCompletePlannerTask(String id) =>
    apiPost('/api/planner/tasks/$id/complete', {});

Future<Map<String, dynamic>> apiCarryForwardPlannerTask(String id) =>
    apiPost('/api/planner/tasks/$id/carry-forward', {});

Future<Map<String, dynamic>> apiDeletePlannerTask(String id) async {
  final res = await _networkGuard(() => http
      .delete(Uri.parse('$apiBase/api/planner/tasks/$id'), headers: _headers())
      .timeout(const Duration(seconds: 10)));
  return _decode(res);
}

Future<Map<String, dynamic>> apiDailyDigest() =>
    apiGet('/api/planner/digest/today');

Future<Map<String, dynamic>> apiWeeklyDigest(String start) =>
    apiGet('/api/planner/digest/week?start=$start');

/// Groups API

Future<Map<String, dynamic>> apiCreateGroup(Map<String, dynamic> body) =>
    apiPost('/api/groups', body);

Future<Map<String, dynamic>> apiGetGroups() =>
    apiGet('/api/groups');

Future<Map<String, dynamic>> apiJoinGroup(String inviteCode) =>
    apiPost('/api/groups/join', {'invite_code': inviteCode});

Future<Map<String, dynamic>> apiGetGroup(String id) =>
    apiGet('/api/groups/$id');

Future<Map<String, dynamic>> apiGetGroupMembers(String id) =>
    apiGet('/api/groups/$id/members');

Future<Map<String, dynamic>> apiAddGroupMember(String id, {String? userId, String? email, String role = 'member'}) =>
    apiPost('/api/groups/$id/members', {'user_id': userId, 'email': email, 'role': role});

Future<Map<String, dynamic>> apiRemoveGroupMember(String id, String userId) =>
    apiDelete('/api/groups/$id/members/$userId');

Future<Map<String, dynamic>> apiUpdateGroupMemberRole(String id, String userId, String role) =>
    apiPut('/api/groups/$id/members/$userId', {'role': role});

Future<Map<String, dynamic>> apiGetGroupMessages(String id, {String? before, int limit = 50}) =>
    apiGet('/api/groups/$id/messages?${before != null ? 'before=$before&' : ''}limit=$limit');

Future<Map<String, dynamic>> apiSendGroupMessage(String id, Map<String, dynamic> body) =>
    apiPost('/api/groups/$id/messages', body);

Future<Map<String, dynamic>> apiGetGroupAnnouncements(String id) =>
    apiGet('/api/groups/$id/announcements');

Future<Map<String, dynamic>> apiCreateGroupAnnouncement(String id, Map<String, dynamic> body) =>
    apiPost('/api/groups/$id/announcements', body);

/// Academic API

Future<Map<String, dynamic>> apiCreateBatch(Map<String, dynamic> body) =>
    apiPost('/api/academic/batches', body);
