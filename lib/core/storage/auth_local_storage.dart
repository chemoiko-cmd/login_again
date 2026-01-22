import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalStorage {
  static const _kSessionId = 'auth.session_id';
  static const _kUserJson = 'auth.user_json';

  Future<void> saveSession({required String sessionId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSessionId, sessionId);
  }

  Future<String?> getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSessionId);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionId);
  }

  Future<void> saveUserJson(Map<String, dynamic> userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserJson, jsonEncode(userJson));
  }

  Future<Map<String, dynamic>?> getUserJson() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUserJson);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? decoded.cast<String, dynamic>() : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserJson);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionId);
    await prefs.remove(_kUserJson);
  }
}
