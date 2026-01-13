import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:go_router/go_router.dart';
import 'package:trashtrails/ui/pages/auth/auth.dart';
import 'package:trashtrails/utils/utils.dart';

import 'storage_service.dart';

/// Result wrapper for API calls
class ApiResult<T> {
  final T? data;
  final String? error;
  final int? statusCode;
  final bool isSuccess;

  const ApiResult._({
    this.data,
    this.error,
    this.statusCode,
    required this.isSuccess,
  });

  factory ApiResult.success(T data, {int? statusCode}) {
    return ApiResult._(data: data, statusCode: statusCode, isSuccess: true);
  }

  factory ApiResult.failure(String error, {int? statusCode}) {
    return ApiResult._(error: error, statusCode: statusCode, isSuccess: false);
  }
}

/// API Service for handling all HTTP requests
/// Uses Dio for HTTP client with interceptors for auth, logging, and error handling
class ApiService extends GetxService {
  late final Dio _dio;
  late final String _baseUrl;

  StorageService get _storageService => Get.find<StorageService>();

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _initializeDio();
  }

  void _initializeDio() {
    _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://0.0.0.0:8000';

    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.addAll([
      _AuthInterceptor(this),
      if (kDebugMode) _LoggingInterceptor(),
    ]);
  }

  // ─── Public API Methods ──────────────────────────────────────────────────

  /// GET request
  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
    bool requiresAuth = true,
  }) async {
    return _request<T>(
      () => _dio.get(path, queryParameters: queryParameters),
      parser: parser,
      requiresAuth: requiresAuth,
    );
  }

  /// POST request
  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
    bool requiresAuth = true,
    bool isMultipart = false,
  }) async {
    return _request<T>(
      () => _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: isMultipart
            ? Options(contentType: 'multipart/form-data')
            : null,
      ),
      parser: parser,
      requiresAuth: requiresAuth,
    );
  }

  /// PUT request
  Future<ApiResult<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
    bool requiresAuth = true,
  }) async {
    return _request<T>(
      () => _dio.put(path, data: data, queryParameters: queryParameters),
      parser: parser,
      requiresAuth: requiresAuth,
    );
  }

  /// PATCH request
  Future<ApiResult<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
    bool requiresAuth = true,
  }) async {
    return _request<T>(
      () => _dio.patch(path, data: data, queryParameters: queryParameters),
      parser: parser,
      requiresAuth: requiresAuth,
    );
  }

  /// DELETE request
  Future<ApiResult<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
    bool requiresAuth = true,
  }) async {
    return _request<T>(
      () => _dio.delete(path, data: data, queryParameters: queryParameters),
      parser: parser,
      requiresAuth: requiresAuth,
    );
  }

  /// Upload file(s) with multipart form data
  Future<ApiResult<T>> uploadFile<T>(
    String path, {
    required File file,
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    T Function(dynamic)? parser,
    void Function(int, int)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        ...?additionalData,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onProgress,
      );

      return _handleResponse<T>(response, parser);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // ─── Internal Methods ────────────────────────────────────────────────────

  Future<ApiResult<T>> _request<T>(
    Future<Response> Function() request, {
    T Function(dynamic)? parser,
    bool requiresAuth = true,
  }) async {
    try {
      final response = await request();
      return _handleResponse<T>(response, parser);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  ApiResult<T> _handleResponse<T>(
    Response response,
    T Function(dynamic)? parser,
  ) {
    final data = response.data;

    if (parser != null) {
      try {
        final parsed = parser(data);
        return ApiResult.success(parsed, statusCode: response.statusCode);
      } catch (e) {
        debugPrint('ApiService: Parser error - $e');
        return ApiResult.failure(
          'Failed to parse response',
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResult.success(data as T, statusCode: response.statusCode);
  }

  ApiResult<T> _handleError<T>(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      String message;

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message =
              'Connection timeout. Please check your internet connection.';
          break;
        case DioExceptionType.connectionError:
          message =
              'Unable to connect to server. Please check your internet connection.';
          break;
        case DioExceptionType.badResponse:
          message = _extractErrorMessage(error.response);
          break;
        case DioExceptionType.cancel:
          message = 'Request was cancelled.';
          break;
        default:
          message = 'An unexpected error occurred.';
      }

      debugPrint('ApiService: DioException - $message (Status: $statusCode)');
      return ApiResult.failure(message, statusCode: statusCode);
    }

    debugPrint('ApiService: Unknown error - $error');
    return ApiResult.failure('An unexpected error occurred.');
  }

  String _extractErrorMessage(Response? response) {
    if (response == null) return 'Server error occurred.';

    final data = response.data;
    if (data is Map<String, dynamic>) {
      // Try common error message fields
      if (data.containsKey('message')) return data['message'].toString();
      if (data.containsKey('error')) return data['error'].toString();
      if (data.containsKey('detail')) return data['detail'].toString();
      if (data.containsKey('non_field_errors')) {
        final errors = data['non_field_errors'];
        if (errors is List && errors.isNotEmpty) return errors.first.toString();
      }

      // Try to get first field error
      for (final value in data.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
      }
    }

    // Default messages based on status code
    switch (response.statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Authentication required. Please log in again.';
      case 403:
        return 'Access denied. You don\'t have permission.';
      case 404:
        return 'Resource not found.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'An error occurred (${response.statusCode}).';
    }
  }

  // ─── Token Management (for interceptor) ──────────────────────────────────

  String? get accessToken => _storageService.accessToken;

  String? get refreshToken => _storageService.refreshToken;

  Future<bool> refreshAccessToken() async {
    final refresh = refreshToken;
    if (refresh == null) return false;

    try {
      // Use a new Dio instance to avoid interceptor loop
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final response = await refreshDio.post(
        '/api/auth/refresh/',
        data: {'refresh': refresh},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'];
        await _storageService.saveTokens(
          accessToken: newAccessToken,
          refreshToken: refresh,
        );
        return true;
      }
    } catch (e) {
      debugPrint('ApiService: Token refresh failed - $e');
    }

    return false;
  }

  void clearAuth() {
    _storageService.clearAuth();
  }

  /// Handle authentication failure - clear tokens and redirect to login
  void _handleAuthFailure() {
    // Set session expired flag before clearing auth
    _storageService.setSessionExpired(true);
    clearAuth();

    debugPrint('ApiService: Authentication failed, redirecting to login');

    // Navigate to auth page using go_router
    // We need to use a small delay to ensure the storage is cleared first
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        // Get the router context and navigate to auth
        final context = Get.context;
        if (context != null && context.mounted) {
          GoRouter.of(context).goNamed(removeLeadingSlash(AuthPage.routeName));
        }
      } catch (e) {
        debugPrint('ApiService: Could not navigate to auth page - $e');
      }
    });
  }
}

/// Interceptor to add auth token to requests and handle token refresh
/// Uses QueuedInterceptor to properly handle concurrent requests during token refresh
class _AuthInterceptor extends QueuedInterceptor {
  final ApiService apiService;
  bool _isRefreshing = false;

  _AuthInterceptor(this.apiService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = apiService.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only handle 401 Unauthorized errors
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Skip if we're already refreshing or if this is the refresh endpoint itself
    final requestPath = err.requestOptions.path;
    if (_isRefreshing ||
        requestPath.contains('/auth/refresh') ||
        requestPath.contains('/auth/google')) {
      return handler.next(err);
    }

    _isRefreshing = true;

    try {
      final success = await apiService.refreshAccessToken();

      if (success) {
        debugPrint(
          'ApiService: Token refreshed successfully, retrying request',
        );

        // Retry the original request with new token
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer ${apiService.accessToken}';

        // Use apiService's internal dio to retry (maintains base URL and other config)
        final response = await apiService._dio.fetch(options);
        _isRefreshing = false;
        return handler.resolve(response);
      } else {
        debugPrint('ApiService: Token refresh failed, redirecting to login');
        _isRefreshing = false;

        // Clear auth and notify app to redirect to login
        apiService._handleAuthFailure();
        return handler.next(err);
      }
    } catch (e) {
      debugPrint('ApiService: Error during token refresh - $e');
      _isRefreshing = false;

      // Clear auth and notify app to redirect to login
      apiService._handleAuthFailure();
      return handler.next(err);
    }
  }
}

/// Interceptor for logging requests and responses in debug mode
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('┌──────────────────────────────────────────────────────────');
    debugPrint('│ 🌐 ${options.method} ${options.uri}');

    if (options.data != null) {
      if (options.data is FormData) {
        final formData = options.data as FormData;
        debugPrint('│ 📦 Body (FormData):');

        // Log form fields
        if (formData.fields.isNotEmpty) {
          debugPrint('│   Fields:');
          for (final field in formData.fields) {
            debugPrint('│     - ${field.key}: ${field.value}');
          }
        }

        // Log files
        if (formData.files.isNotEmpty) {
          debugPrint('│   Files:');
          for (final file in formData.files) {
            final multipartFile = file.value;
            debugPrint(
              '│     - ${file.key}: ${multipartFile.filename} (${_formatBytes(multipartFile.length)})',
            );
          }
        }
      } else {
        // For regular JSON or other data
        debugPrint('│ 📦 Body: ${options.data}');
      }
    }

    debugPrint('└──────────────────────────────────────────────────────────');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('┌──────────────────────────────────────────────────────────');
    debugPrint('│ ✅ ${response.statusCode} ${response.requestOptions.uri}');
    debugPrint('│ 📥 Response: ${response.data}');
    debugPrint('└──────────────────────────────────────────────────────────');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('┌──────────────────────────────────────────────────────────');
    debugPrint(
      '│ ❌ ${err.response?.statusCode ?? 'ERROR'} ${err.requestOptions.uri}',
    );
    debugPrint('│ 📛 Error: ${err.message}');
    if (err.response?.data != null) {
      debugPrint('│ 📥 Response: ${err.response?.data}');
    }
    debugPrint('└──────────────────────────────────────────────────────────');
    handler.next(err);
  }

  /// Format bytes to human readable format
  String _formatBytes(int? bytes) {
    if (bytes == null || bytes == 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    var size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }
}
