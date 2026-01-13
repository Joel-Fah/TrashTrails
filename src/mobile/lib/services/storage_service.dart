import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../models/user.dart';

/// Service for managing local storage (tokens, user data, preferences)
class StorageService extends GetxService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const String _authSkippedKey = 'auth_skipped';
  static const String _isAuthenticatedKey = 'is_authenticated';
  static const String _sessionExpiredKey = 'session_expired';

  late final GetStorage _box;

  @override
  void onInit() {
    super.onInit();
    _box = GetStorage();
  }

  // ─── Token Management ────────────────────────────────────────────────────

  /// Get the current access token
  String? get accessToken => _box.read<String>(_accessTokenKey);

  /// Get the current refresh token
  String? get refreshToken => _box.read<String>(_refreshTokenKey);

  /// Check if tokens are stored
  bool get hasTokens => accessToken != null && refreshToken != null;

  /// Save JWT tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _box.write(_accessTokenKey, accessToken);
    await _box.write(_refreshTokenKey, refreshToken);
    await _box.write(_isAuthenticatedKey, true);
    debugPrint('StorageService: Tokens saved successfully');
  }

  /// Clear tokens (logout)
  Future<void> clearTokens() async {
    await _box.remove(_accessTokenKey);
    await _box.remove(_refreshTokenKey);
    debugPrint('StorageService: Tokens cleared');
  }

  // ─── User Data Management ────────────────────────────────────────────────

  /// Get the stored user data
  UserModel? get currentUser {
    final userData = _box.read<Map<String, dynamic>>(_userKey);
    if (userData == null) return null;
    try {
      return UserModel.fromJson(userData);
    } catch (e) {
      debugPrint('StorageService: Failed to parse stored user - $e');
      return null;
    }
  }

  /// Save user data
  Future<void> saveUser(UserModel user) async {
    await _box.write(_userKey, user.toJson());
    debugPrint('StorageService: User saved - ${user.displayName}');
  }

  /// Clear user data
  Future<void> clearUser() async {
    await _box.remove(_userKey);
    debugPrint('StorageService: User data cleared');
  }

  // ─── Auth State Management ───────────────────────────────────────────────

  /// Check if authentication was skipped
  bool get isAuthSkipped => _box.read<bool>(_authSkippedKey) ?? false;

  /// Check if user is marked as authenticated
  bool get isAuthenticated => _box.read<bool>(_isAuthenticatedKey) ?? false;

  /// Check if user can access the app (authenticated or skipped)
  bool get canAccessApp => isAuthenticated || isAuthSkipped;

  /// Mark authentication as skipped
  Future<void> setAuthSkipped(bool skipped) async {
    await _box.write(_authSkippedKey, skipped);
  }

  /// Mark user as authenticated
  Future<void> setAuthenticated(bool authenticated) async {
    await _box.write(_isAuthenticatedKey, authenticated);
  }

  // ─── Clear All Auth Data ─────────────────────────────────────────────────

  /// Clear all authentication related data
  Future<void> clearAuth() async {
    await clearTokens();
    await clearUser();
    await _box.write(_isAuthenticatedKey, false);
    await _box.write(_authSkippedKey, false);
    debugPrint('StorageService: All auth data cleared');
  }

  // ─── Session Expired ─────────────────────────────────────────────────────

  /// Check if the session has expired (token refresh failed)
  bool get isSessionExpired => _box.read<bool>(_sessionExpiredKey) ?? false;

  /// Set the session expired flag
  Future<void> setSessionExpired(bool expired) async {
    await _box.write(_sessionExpiredKey, expired);
    debugPrint('StorageService: Session expired flag set to $expired');
  }

  /// Clear the session expired flag
  Future<void> clearSessionExpired() async {
    await _box.remove(_sessionExpiredKey);
  }

  // ─── Utility Methods ─────────────────────────────────────────────────────

  /// Read a value from storage
  T? read<T>(String key) => _box.read<T>(key);

  /// Write a value to storage
  Future<void> write(String key, dynamic value) => _box.write(key, value);

  /// Remove a value from storage
  Future<void> remove(String key) => _box.remove(key);

  /// Check if a key exists
  bool hasKey(String key) => _box.hasData(key);

  /// Clear all storage (use with caution)
  Future<void> clearAll() async {
    await _box.erase();
    debugPrint('StorageService: All storage cleared');
  }
}

