import 'dart:convert';

import 'package:hive/hive.dart';

class AuthLocalStorage {
  static const String boxName = 'authBox';
  static const String _kSessionId = 'session_id';
  static const String _kUserJson = 'user_json';
  static const String _kAvatarPrefix = 'avatar_b64_partner_';

  static String avatarCacheKey(int partnerId) => '$_kAvatarPrefix$partnerId';

  Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  Future<void> saveSession({required String sessionId}) async {
    await _box.put(_kSessionId, sessionId);
  }

  Future<String?> getSessionId() async {
    final v = _box.get(_kSessionId);
    return v is String ? v : null;
  }

  Future<void> clearSession() async {
    await _box.delete(_kSessionId);
  }

  Future<void> saveUserJson(Map<String, dynamic> userJson) async {
    await _box.put(_kUserJson, jsonEncode(userJson));
  }

  Future<Map<String, dynamic>?> getUserJson() async {
    final rawAny = _box.get(_kUserJson);
    final raw = rawAny is String ? rawAny : null;
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? decoded.cast<String, dynamic>() : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUser() async {
    await _box.delete(_kUserJson);
  }

  Future<void> savePartnerAvatarBase64({
    required int partnerId,
    required String base64,
  }) async {
    if (partnerId <= 0 || base64.isEmpty) return;
    await _box.put(avatarCacheKey(partnerId), base64);
  }

  Future<String?> getPartnerAvatarBase64(int partnerId) async {
    if (partnerId <= 0) return null;
    final v = _box.get(avatarCacheKey(partnerId));
    return v is String && v.isNotEmpty ? v : null;
  }

  Future<void> clearPartnerAvatar(int partnerId) async {
    if (partnerId <= 0) return;
    await _box.delete(avatarCacheKey(partnerId));
  }

  Future<void> clearAll() async {
    await _box.delete(_kSessionId);
    await _box.delete(_kUserJson);
  }
}
