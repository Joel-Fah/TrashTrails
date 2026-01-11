import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/models.dart';
import 'api_service.dart';

/// Service for handling reports API calls
class ReportService extends GetxService {
  // ─── Dependencies ────────────────────────────────────────────────────────
  ApiService get _apiService => Get.find<ApiService>();

  // ─── Constants ─────────────────────────────────────────────────────────
  static const String _reportsEndpoint = '/api/reports/';
  static const String _myReportsEndpoint = '/api/reports/me/';
  static const String _categoriesEndpoint = '/api/reports/trash-categories/';
  static const String _severitiesEndpoint = '/api/reports/report-severities/';

  // ─── Categories ──────────────────────────────────────────────────────────

  /// Fetch all trash categories
  /// GET /api/trash-categories/
  Future<List<TrashCategoryModel>?> fetchCategories() async {
    try {
      final result = await _apiService.get<List<TrashCategoryModel>>(
        _categoriesEndpoint,
        parser: (data) => TrashCategoryModel.listFromJson(data),
      );

      if (result.isSuccess && result.data != null) {
        debugPrint('ReportService: Fetched ${result.data!.length} categories');
        return result.data;
      } else {
        debugPrint('ReportService: Failed to fetch categories - ${result.error}');
        return null;
      }
    } catch (e) {
      debugPrint('ReportService: Error fetching categories - $e');
      return null;
    }
  }

  // ─── Severities ──────────────────────────────────────────────────────────

  /// Fetch all report severity levels
  /// GET /api/report-severities/
  Future<List<ReportSeverityModel>?> fetchSeverities() async {
    try {
      final result = await _apiService.get<List<ReportSeverityModel>>(
        _severitiesEndpoint,
        parser: (data) => ReportSeverityModel.listFromJson(data),
      );

      if (result.isSuccess && result.data != null) {
        debugPrint('ReportService: Fetched ${result.data!.length} severities');
        return result.data;
      } else {
        debugPrint('ReportService: Failed to fetch severities - ${result.error}');
        return null;
      }
    } catch (e) {
      debugPrint('ReportService: Error fetching severities - $e');
      return null;
    }
  }

  // ─── Reports CRUD ────────────────────────────────────────────────────────

  /// Fetch paginated list of reports
  /// GET /api/reports/?page=1&search=query&ordering=-created_at
  Future<PaginatedResponse<ReportModel>?> fetchReports({
    int page = 1,
    String? search,
    String? ordering,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        if (search != null && search.isNotEmpty) 'search': search,
        if (ordering != null && ordering.isNotEmpty) 'ordering': ordering,
      };

      final result = await _apiService.get<PaginatedResponse<ReportModel>>(
        _reportsEndpoint,
        queryParameters: queryParams,
        parser: (data) {
          if (data is Map<String, dynamic>) {
            return PaginatedResponse.fromJson(data, ReportModel.fromListJson);
          }
          return PaginatedResponse.empty();
        },
      );

      if (result.isSuccess && result.data != null) {
        debugPrint('ReportService: Fetched ${result.data!.results.length} reports (page $page, total: ${result.data!.count})');
        return result.data;
      } else {
        debugPrint('ReportService: Failed to fetch reports - ${result.error}');
        return null;
      }
    } catch (e) {
      debugPrint('ReportService: Error fetching reports - $e');
      return null;
    }
  }

  /// Fetch paginated list of current user's reports
  /// GET /api/reports/me/?page=1&search=query&ordering=-created_at
  Future<PaginatedResponse<ReportModel>?> fetchMyReports({
    int page = 1,
    String? search,
    String? ordering,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        if (search != null && search.isNotEmpty) 'search': search,
        if (ordering != null && ordering.isNotEmpty) 'ordering': ordering,
      };

      final result = await _apiService.get<PaginatedResponse<ReportModel>>(
        _myReportsEndpoint,
        queryParameters: queryParams,
        parser: (data) {
          if (data is Map<String, dynamic>) {
            return PaginatedResponse.fromJson(data, ReportModel.fromListJson);
          }
          return PaginatedResponse.empty();
        },
      );

      if (result.isSuccess && result.data != null) {
        debugPrint('ReportService: Fetched ${result.data!.results.length} user reports (page $page, total: ${result.data!.count})');
        return result.data;
      } else {
        debugPrint('ReportService: Failed to fetch user reports - ${result.error}');
        return null;
      }
    } catch (e) {
      debugPrint('ReportService: Error fetching user reports - $e');
      return null;
    }
  }

  /// Fetch a single report by ID
  /// GET /api/reports/{report_id}/
  Future<ReportModel?> fetchReport(String reportId) async {
    if (reportId.isEmpty) {
      debugPrint('ReportService: Invalid report ID');
      return null;
    }

    try {
      final result = await _apiService.get<ReportModel>(
        '$_reportsEndpoint$reportId/',
        parser: (data) {
          if (data is Map<String, dynamic>) {
            return ReportModel.fromJson(data);
          }
          throw Exception('Invalid response format');
        },
      );

      if (result.isSuccess && result.data != null) {
        debugPrint('ReportService: Fetched report $reportId');
        return result.data;
      } else {
        debugPrint('ReportService: Failed to fetch report $reportId - ${result.error}');
        return null;
      }
    } catch (e) {
      debugPrint('ReportService: Error fetching report $reportId - $e');
      return null;
    }
  }

  /// Create a new report
  /// POST /api/reports/
  Future<ReportModel?> createReport({
    required String title,
    String? observation,
    required String severityId,
    required String categoryId,
    String? locationId,
  }) async {
    try {
      final data = <String, dynamic>{
        'title': title,
        if (observation != null && observation.isNotEmpty) 'observation': observation,
        'severity': severityId,
        'category': categoryId,
        if (locationId != null && locationId.isNotEmpty) 'location': locationId,
      };

      final result = await _apiService.post<ReportModel>(
        _reportsEndpoint,
        data: data,
        parser: (responseData) {
          if (responseData is Map<String, dynamic>) {
            return ReportModel.fromJson(responseData);
          }
          throw Exception('Invalid response format');
        },
      );

      if (result.isSuccess && result.data != null) {
        debugPrint('ReportService: Created report ${result.data!.id}');
        return result.data;
      } else {
        debugPrint('ReportService: Failed to create report - ${result.error}');
        return null;
      }
    } catch (e) {
      debugPrint('ReportService: Error creating report - $e');
      return null;
    }
  }

  /// Update an existing report
  /// PATCH /api/reports/{report_id}/
  Future<ReportModel?> updateReport(
    String reportId, {
    String? title,
    String? observation,
    String? severityId,
    String? categoryId,
  }) async {
    if (reportId.isEmpty) {
      debugPrint('ReportService: Invalid report ID');
      return null;
    }

    try {
      final data = <String, dynamic>{
        if (title != null && title.isNotEmpty) 'title': title,
        if (observation != null) 'observation': observation,
        if (severityId != null && severityId.isNotEmpty) 'severity': severityId,
        if (categoryId != null && categoryId.isNotEmpty) 'category': categoryId,
      };

      if (data.isEmpty) {
        debugPrint('ReportService: No data to update');
        return null;
      }

      final result = await _apiService.patch<ReportModel>(
        '$_reportsEndpoint$reportId/',
        data: data,
        parser: (responseData) {
          if (responseData is Map<String, dynamic>) {
            return ReportModel.fromJson(responseData);
          }
          throw Exception('Invalid response format');
        },
      );

      if (result.isSuccess && result.data != null) {
        debugPrint('ReportService: Updated report $reportId');
        return result.data;
      } else {
        debugPrint('ReportService: Failed to update report $reportId - ${result.error}');
        return null;
      }
    } catch (e) {
      debugPrint('ReportService: Error updating report $reportId - $e');
      return null;
    }
  }

  /// Delete a report
  /// DELETE /api/reports/{report_id}/
  Future<bool> deleteReport(String reportId) async {
    if (reportId.isEmpty) {
      debugPrint('ReportService: Invalid report ID');
      return false;
    }

    try {
      final result = await _apiService.delete<void>(
        '$_reportsEndpoint$reportId/',
      );

      if (result.isSuccess) {
        debugPrint('ReportService: Deleted report $reportId');
        return true;
      } else {
        debugPrint('ReportService: Failed to delete report $reportId - ${result.error}');
        return false;
      }
    } catch (e) {
      debugPrint('ReportService: Error deleting report $reportId - $e');
      return false;
    }
  }

  // ─── Helper Methods ──────────────────────────────────────────────────────

  /// Get a user-friendly error message
  String getErrorMessage(String? error) {
    if (error == null || error.isEmpty) {
      return 'An unexpected error occurred. Please try again.';
    }

    if (error.contains('connection') || error.contains('network')) {
      return 'Unable to connect. Please check your internet connection.';
    }

    if (error.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (error.contains('unauthorized') || error.contains('401')) {
      return 'Your session has expired. Please log in again.';
    }

    if (error.contains('forbidden') || error.contains('403')) {
      return 'You don\'t have permission to perform this action.';
    }

    if (error.contains('not found') || error.contains('404')) {
      return 'The requested resource was not found.';
    }

    if (error.contains('server') || error.contains('500')) {
      return 'Server error. Please try again later.';
    }

    return error;
  }
}

