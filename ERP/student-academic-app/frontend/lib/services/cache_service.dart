import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Simple offline cache for key data. Stores JSON strings.
class CacheService {
  static const String _keyNotes = 'cache_notes';
  static const String _keyAssignments = 'cache_assignments';
  static const String _keyTimetable = 'cache_timetable';
  static const String _keyAnnouncements = 'cache_announcements';
  static const String _keySubmissionKit = 'cache_submission_kit';
  static const String _keyLastSync = 'cache_last_sync';

  static Future<void> saveNotes(List<dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNotes, jsonEncode(data));
  }

  static Future<List<dynamic>> getNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyNotes);
    if (str == null) return [];
    return jsonDecode(str) as List<dynamic>;
  }

  static Future<void> saveAssignments(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAssignments, jsonEncode(data));
  }

  static Future<Map<String, dynamic>> getAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyAssignments);
    if (str == null) return {};
    return jsonDecode(str) as Map<String, dynamic>;
  }

  static Future<void> saveTimetable(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTimetable, jsonEncode(data));
  }

  static Future<Map<String, dynamic>> getTimetable() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyTimetable);
    if (str == null) return {};
    return jsonDecode(str) as Map<String, dynamic>;
  }

  static Future<void> saveAnnouncements(List<dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAnnouncements, jsonEncode(data));
  }

  static Future<List<dynamic>> getAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyAnnouncements);
    if (str == null) return [];
    return jsonDecode(str) as List<dynamic>;
  }

  static Future<void> saveSubmissionKit(List<dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySubmissionKit, jsonEncode(data));
  }

  static Future<List<dynamic>> getSubmissionKit() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keySubmissionKit);
    if (str == null) return [];
    return jsonDecode(str) as List<dynamic>;
  }

  static Future<void> setLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSync, DateTime.now().toIso8601String());
  }

  static Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyLastSync);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyNotes);
    await prefs.remove(_keyAssignments);
    await prefs.remove(_keyTimetable);
    await prefs.remove(_keyAnnouncements);
    await prefs.remove(_keySubmissionKit);
    await prefs.remove(_keyLastSync);
  }
}