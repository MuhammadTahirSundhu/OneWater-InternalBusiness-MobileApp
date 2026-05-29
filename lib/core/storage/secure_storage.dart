import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Keys
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userDataKey = 'user_data';
  static const _appPinKey = 'app_pin';
  static const _lastActiveKey = 'last_active';
  static const _hasSeenOnboardingKey = 'has_seen_onboarding';

  // Access Token
  Future<void> setAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  // Refresh Token
  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // User Data
  Future<void> setUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: _userDataKey, value: jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: _userDataKey);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  // App PIN
  Future<void> setAppPin(String pin) async {
    await _storage.write(key: _appPinKey, value: pin);
  }

  Future<String?> getAppPin() async {
    return await _storage.read(key: _appPinKey);
  }

  // Last Active timestamp
  Future<void> setLastActive() async {
    await _storage.write(
      key: _lastActiveKey,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  Future<DateTime?> getLastActive() async {
    final data = await _storage.read(key: _lastActiveKey);
    if (data != null) {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(data));
    }
    return null;
  }

  // Onboarding
  Future<void> setHasSeenOnboarding(bool value) async {
    await _storage.write(key: _hasSeenOnboardingKey, value: value.toString());
  }

  Future<bool> hasSeenOnboarding() async {
    final value = await _storage.read(key: _hasSeenOnboardingKey);
    return value == 'true';
  }

  // Check if authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // Clear all
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Clear auth only
  Future<void> clearAuth() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userDataKey);
  }
}
