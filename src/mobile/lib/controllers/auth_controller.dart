import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

/// Controller for managing authentication UI state
/// Uses AuthService for actual authentication logic
class AuthController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // ─── Services ────────────────────────────────────────────────────────────
  final AuthService _authService = Get.find<AuthService>();

  // ─── Google Sign In ──────────────────────────────────────────────────────
  late final GoogleSignIn _googleSignIn;

  // ─── Animation Controller ────────────────────────────────────────────────
  late final AnimationController animationController;

  // ─── UI State ────────────────────────────────────────────────────────────
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;

  // ─── Getters ─────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get hasError => _error.value.isNotEmpty;

  /// Proxy getters from AuthService
  bool get isAuthenticated => _authService.isAuthenticated;
  bool get isAuthSkipped => _authService.isAuthSkipped;
  bool get canAccessApp => _authService.canAccessApp;
  UserModel? get currentUser => _authService.currentUser;

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();

    // Initialize Google Sign-In with Web Client ID from environment
    // Note: For Android, you need:
    // 1. An Android OAuth Client ID configured in Google Cloud Console with your SHA-1 and package name
    // 2. A Web OAuth Client ID (used as serverClientId to get idToken for backend verification)
    final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? dotenv.env['GOOGLE_CLIENT_ID'] ?? '';

    if (webClientId.isEmpty) {
      debugPrint('AuthController: WARNING - GOOGLE_WEB_CLIENT_ID is not set in .env');
    } else {
      debugPrint('AuthController: Google Web Client ID configured');
    }

    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: webClientId.isNotEmpty ? webClientId : null,
    );

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    animationController.value = 1.0;
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }

  // ─── Authentication Methods ──────────────────────────────────────────────

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    if (_isLoading.value) return false;

    _isLoading.value = true;
    _error.value = '';

    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        _isLoading.value = false;
        return false;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final idToken = googleAuth.idToken;

      if (idToken == null) {
        _error.value = 'Failed to get authentication token. Please ensure Web Client ID is configured correctly.';
        _isLoading.value = false;
        debugPrint('AuthController: idToken is null - Check that GOOGLE_WEB_CLIENT_ID is set in .env');
        return false;
      }

      // Call backend with the Google ID token
      final result = await _authService.loginWithGoogle(idToken);

      _isLoading.value = false;

      if (result.isSuccess) {
        return true;
      } else {
        _error.value = result.error ?? 'Login failed. Please try again.';
        return false;
      }
    } catch (e) {
      _isLoading.value = false;

      // Parse specific Google Sign-In errors for user-friendly messages
      final errorString = e.toString();
      if (errorString.contains('ApiException: 10')) {
        _error.value = 'Configuration error. Please contact support.';
        debugPrint('''
AuthController: Google Sign-In ApiException: 10 (DEVELOPER_ERROR)
This usually means:
1. SHA-1 fingerprint in Google Cloud Console doesn't match your app's signing key
2. Package name doesn't match (expected: com.trashtrails.trashtrails)
3. Android OAuth Client ID is not properly configured

To fix:
- Run: cd android && ./gradlew signingReport
- Copy the SHA-1 from the debug variant
- Add it to your Android OAuth Client ID in Google Cloud Console
- Make sure you also have a Web OAuth Client ID and set it as GOOGLE_WEB_CLIENT_ID in .env
''');
      } else if (errorString.contains('ApiException: 12500')) {
        _error.value = 'Sign-in cancelled or Google Play Services issue.';
      } else if (errorString.contains('ApiException: 7')) {
        _error.value = 'Network error. Please check your connection.';
      } else {
        _error.value = 'Sign-in failed. Please try again.';
      }

      debugPrint('AuthController: Google Sign-In error - $e');
      return false;
    }
  }

  /// Skip authentication for now
  Future<void> skipAuth() async {
    await _authService.skipAuth();
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading.value = true;

    try {
      // Sign out from Google
      await _googleSignIn.signOut();

      // Sign out from backend
      await _authService.logout();
    } catch (e) {
      debugPrint('AuthController: Sign out error - $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Clear error message
  void clearError() {
    _error.value = '';
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    final result = await _authService.refreshUserData();
    if (!result.isSuccess) {
      _error.value = result.error ?? 'Failed to refresh user data';
    }
  }
}

