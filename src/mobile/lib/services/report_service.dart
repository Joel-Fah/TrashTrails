import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide MultipartFile, FormData;
import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';

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
        parser: (data) {
          // Handle paginated response: {count, next, previous, results}
          if (data is Map<String, dynamic> && data.containsKey('results')) {
            return TrashCategoryModel.listFromJson(data['results']);
          }
          // Handle direct list response
          return TrashCategoryModel.listFromJson(data);
        },
      );

      if (result.isSuccess && result.data != null) {
        debugPrint('ReportService: Fetched ${result.data!.length} categories');
        return result.data;
      } else {
        debugPrint(
          'ReportService: Failed to fetch categories - ${result.error}',
        );
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
        parser: (data) {
          // Handle paginated response: {count, next, previous, results}
          if (data is Map<String, dynamic> && data.containsKey('results')) {
            return ReportSeverityModel.listFromJson(data['results']);
          }
          // Handle direct list response
          return ReportSeverityModel.listFromJson(data);
        },
      );

      if (result.isSuccess && result.data != null) {
        debugPrint('ReportService: Fetched ${result.data!.length} severities');
        return result.data;
      } else {
        debugPrint(
          'ReportService: Failed to fetch severities - ${result.error}',
        );
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
        debugPrint(
          'ReportService: Fetched ${result.data!.results.length} reports (page $page, total: ${result.data!.count})',
        );
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
        debugPrint(
          'ReportService: Fetched ${result.data!.results.length} user reports (page $page, total: ${result.data!.count})',
        );
        return result.data;
      } else {
        debugPrint(
          'ReportService: Failed to fetch user reports - ${result.error}',
        );
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
        debugPrint(
          'ReportService: Failed to fetch report $reportId - ${result.error}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('ReportService: Error fetching report $reportId - $e');
      return null;
    }
  }

  /// Create a new report with file uploads
  /// POST /api/reports/
  Future<ReportModel?> createReport({
    required String title,
    String? observation,
    required String severityId,
    required String categoryId,
    LocationModel? location,
    required List<String> imagePaths,
  }) async {
    if (imagePaths.isEmpty) {
      debugPrint('ReportService: At least one image is required');
      return null;
    }

    try {
      final formData = FormData();

      // Add text fields
      formData.fields.add(MapEntry('title', title));
      formData.fields.add(MapEntry('severity', severityId));
      formData.fields.add(MapEntry('category', categoryId));

      if (observation != null && observation.isNotEmpty) {
        formData.fields.add(MapEntry('observation', observation));
      }

      // Add location as JSON string if provided
      if (location != null && location.isValid) {
        formData.fields.add(
          MapEntry(
            'location',
            jsonEncode({
              'latitude': location.latitude,
              'longitude': location.longitude,
              'street_name': location.address ?? location.city ?? '',
            }),
          ),
        );
      }

      // Add image files
      for (final path in imagePaths) {
        final file = File(path);
        if (file.existsSync()) {
          formData.files.add(
            MapEntry(
              'images',
              await MultipartFile.fromFile(
                file.path,
                filename: file.path.split('/').last,
              ),
            ),
          );
        } else {
          debugPrint('ReportService: Image file not found at $path');
        }
      }

      if (formData.files.isEmpty) {
        debugPrint('ReportService: No valid image files found');
        return null;
      }

      final result = await _apiService.post<ReportModel>(
        _reportsEndpoint,
        data: formData,
        parser: (responseData) {
          if (responseData is Map<String, dynamic>) {
            return ReportModel.fromJson(responseData);
          }
          throw Exception('Invalid response format');
        },
      );

      // Save images to gallery after successful upload
      if (result.isSuccess && result.data != null) {
        debugPrint('ReportService: Created report ${result.data!.id}');
        await _saveImagesToGallery(imagePaths);
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

  /// Create a new report and return both report and points data
  /// POST /api/reports/
  /// Returns ReportCreationResult containing both report and points
  Future<ReportCreationResult?> createReportWithPoints({
    required String title,
    String? observation,
    required String severityId,
    required String categoryId,
    LocationModel? location,
    required List<String> imagePaths,
  }) async {
    if (imagePaths.isEmpty) {
      debugPrint('ReportService: At least one image is required');
      return null;
    }

    try {
      final formData = FormData();

      // Add text fields
      formData.fields.add(MapEntry('title', title));
      formData.fields.add(MapEntry('severity', severityId));
      formData.fields.add(MapEntry('category', categoryId));

      if (observation != null && observation.isNotEmpty) {
        formData.fields.add(MapEntry('observation', observation));
      }

      // Add location as JSON string if provided
      if (location != null && location.isValid) {
        formData.fields.add(
          MapEntry(
            'location',
            jsonEncode({
              'latitude': location.latitude,
              'longitude': location.longitude,
              'street_name': location.address ?? location.city ?? '',
            }),
          ),
        );
      }

      // Add image files
      for (final path in imagePaths) {
        final file = File(path);
        if (file.existsSync()) {
          formData.files.add(
            MapEntry(
              'images',
              await MultipartFile.fromFile(
                file.path,
                filename: file.path.split('/').last,
              ),
            ),
          );
        } else {
          debugPrint('ReportService: Image file not found at $path');
        }
      }

      if (formData.files.isEmpty) {
        debugPrint('ReportService: No valid image files found');
        return null;
      }

      final result = await _apiService.post<ReportCreationResult>(
        _reportsEndpoint,
        data: formData,
        parser: (responseData) {
          if (responseData is Map<String, dynamic>) {
            return ReportCreationResult.fromJson(responseData);
          }
          throw Exception('Invalid response format');
        },
      );

      // Save images to gallery after successful upload
      if (result.isSuccess && result.data != null) {
        debugPrint(
          'ReportService: Created report ${result.data!.report.id} with points: ${result.data!.hasPoints}',
        );
        await _saveImagesToGallery(imagePaths);
        return result.data;
      } else {
        debugPrint('ReportService: Failed to create report - ${result.error}');
        return null;
      }
    } catch (e) {
      debugPrint('ReportService: Error creating report with points - $e');
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
        debugPrint(
          'ReportService: Failed to update report $reportId - ${result.error}',
        );
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
        debugPrint(
          'ReportService: Failed to delete report $reportId - ${result.error}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('ReportService: Error deleting report $reportId - $e');
      return false;
    }
  }

  // ─── Helper Methods ──────────────────────────────────────────────────────

  /// Save images to device gallery
  Future<void> _saveImagesToGallery(List<String> imagePaths) async {
    try {
      for (final path in imagePaths) {
        final file = File(path);
        if (file.existsSync()) {
          await GallerySaver.saveImage(path, albumName: 'Trash Trails');
          debugPrint('ReportService: Saved image to gallery: $path');
        }
      }
    } catch (e) {
      debugPrint('ReportService: Error saving images to gallery - $e');
      // Don't throw - saving to gallery is optional
    }
  }

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
