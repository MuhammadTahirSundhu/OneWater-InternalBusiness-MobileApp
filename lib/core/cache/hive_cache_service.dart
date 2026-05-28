import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Generic Hive cache wrapper with TTL support.
class HiveCacheService {
  static const String _boxName = 'cache';

  Box get _box => Hive.box(_boxName);

  /// Writes [data] to [key] with an optional [ttlMinutes] expiry.
  Future<void> put(String key, dynamic data, {int ttlMinutes = 60}) async {
    final entry = {
      'data': jsonEncode(data),
      'expires': DateTime.now()
          .add(Duration(minutes: ttlMinutes))
          .millisecondsSinceEpoch,
    };
    await _box.put(key, entry);
  }

  /// Returns cached data if not expired, otherwise null.
  dynamic get(String key) {
    final entry = _box.get(key) as Map?;
    if (entry == null) return null;

    final expires = entry['expires'] as int;
    if (DateTime.now().millisecondsSinceEpoch > expires) {
      _box.delete(key);
      return null;
    }

    try {
      return jsonDecode(entry['data'] as String);
    } catch (_) {
      return null;
    }
  }

  /// Removes a specific key.
  Future<void> invalidate(String key) async {
    await _box.delete(key);
  }

  /// Removes all cached data.
  Future<void> clearAll() async {
    await _box.clear();
  }

  // ─── Typed helpers ──────────────────────────────────────────────

  /// Returns a list of maps, or null if not cached.
  List<Map<String, dynamic>>? getList(String key) {
    final raw = get(key);
    if (raw == null) return null;
    try {
      return (raw as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  /// Returns a single map, or null if not cached.
  Map<String, dynamic>? getMap(String key) {
    final raw = get(key);
    if (raw == null) return null;
    try {
      return raw as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
