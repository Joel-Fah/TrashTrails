import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Response model for authentication
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access'] ?? json['access_token'] ?? '',
      refreshToken: json['refresh'] ?? json['refresh_token'] ?? '',
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }
}

/// Service for handling authentication with the backend
class AuthService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  // ─── Reactive State ──────────────────────────────────────────────────────
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);
  final RxBool _isAuthenticated = false.obs;

  // ─── Getters ─────────────────────────────────────────────────────────────
  UserModel? get currentUser => _currentUser.value;
  bool get isAuthenticated => _isAuthenticated.value;
  bool get isAuthSkipped => _storageService.isAuthSkipped;
  bool get canAccessApp => isAuthenticated || isAuthSkipped;

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _loadStoredUser();
  }

  void _loadStoredUser() {
    final storedUser = _storageService.currentUser;
    if (storedUser != null && _storageService.hasTokens) {
      _currentUser.value = storedUser;
      _isAuthenticated.value = true;
      debugPrint('AuthService: Loaded stored user - ${storedUser.displayName}');
    }
  }

  // ─── Authentication Methods ──────────────────────────────────────────────

  /// Login with Google OAuth token
  /// POST /api/auth/google/ with { "id_token": "..." }
  /// Backend verifies token, creates/retrieves user, returns JWT tokens + user data
  /// Response: { "access": "...", "refresh": "...", "user": {...} }
  Future<ApiResult<AuthResponse>> loginWithGoogle(String googleIdToken) async {
    final result = await _apiService.post<AuthResponse>(
      '/api/auth/google/',
      data: {
        'id_token': googleIdToken,
      },
      parser: (data) => AuthResponse.fromJson(data),
      requiresAuth: false,
    );

    if (result.isSuccess && result.data != null) {
      await _handleAuthSuccess(result.data!);
    }

    return result;
  }

  /// Handle successful authentication
  Future<void> _handleAuthSuccess(AuthResponse authResponse) async {
    // Save tokens
    await _storageService.saveTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
    );

    // Save user
    await _storageService.saveUser(authResponse.user);

    // Update state
    _currentUser.value = authResponse.user;
    _isAuthenticated.value = true;

    debugPrint('AuthService: Login successful - ${authResponse.user.displayName}');
  }

  /// Skip authentication
  Future<void> skipAuth() async {
    await _storageService.setAuthSkipped(true);
    debugPrint('AuthService: Auth skipped');
  }

  /// Logout
  /// Calls backend with refresh token in body and access token in header
  Future<void> logout() async {
    final refreshToken = _storageService.refreshToken;

    // Notify backend to invalidate the refresh token
    if (refreshToken != null) {
      try {
        await _apiService.post(
          '/api/auth/logout/',
          data: {'refresh': refreshToken},
          requiresAuth: true,
        );
      } catch (e) {
        debugPrint('AuthService: Logout API call failed (continuing anyway) - $e');
      }
    }

    // Clear local state regardless of API call result
    await _storageService.clearAuth();
    _currentUser.value = null;
    _isAuthenticated.value = false;

    debugPrint('AuthService: Logged out');
  }

  /// Refresh user data from backend
  Future<ApiResult<UserModel>> refreshUserData() async {
    final result = await _apiService.get<UserModel>(
      '/api/auth/me/',
      parser: (data) => UserModel.fromJson(data),
    );

    if (result.isSuccess && result.data != null) {
      _currentUser.value = result.data;
      await _storageService.saveUser(result.data!);
    }

    return result;
  }

  /// Update user profile
  Future<ApiResult<UserModel>> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
  }) async {
    final result = await _apiService.patch<UserModel>(
      '/api/auth/me/',
      data: {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (username != null) 'username': username,
      },
      parser: (data) => UserModel.fromJson(data),
    );

    if (result.isSuccess && result.data != null) {
      _currentUser.value = result.data;
      await _storageService.saveUser(result.data!);
    }

    return result;
  }

  /// Check if current tokens are valid
  Future<bool> validateTokens() async {
    if (!_storageService.hasTokens) return false;

    final result = await _apiService.get<UserModel>(
      '/api/auth/me/',
      parser: (data) => UserModel.fromJson(data),
    );

    if (result.isSuccess && result.data != null) {
      _currentUser.value = result.data;
      _isAuthenticated.value = true;
      await _storageService.saveUser(result.data!);
      return true;
    }

    return false;
  }
}

