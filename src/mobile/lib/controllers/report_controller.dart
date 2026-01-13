import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/models.dart';
import '../services/report_service.dart';

/// Controller for managing report data and state
class ReportController extends GetxController {
  // ─── Dependencies ────────────────────────────────────────────────────────
  ReportService get _reportService => Get.find<ReportService>();

  // ─── Observable State ────────────────────────────────────────────────────

  /// List of nearby reports
  final RxList<ReportModel> nearbyReports = <ReportModel>[].obs;

  /// List of user's own reports
  final RxList<ReportModel> userReports = <ReportModel>[].obs;

  /// Currently selected/viewed report
  final Rx<ReportModel?> currentReport = Rx<ReportModel?>(null);

  /// Available trash categories from API
  final RxList<TrashCategoryModel> categories = <TrashCategoryModel>[].obs;

  /// Available severity levels from API
  final RxList<ReportSeverityModel> severities = <ReportSeverityModel>[].obs;

  /// Loading states
  final RxBool isLoadingReports = false.obs;
  final RxBool isLoadingMyReports = false.obs;
  final RxBool isLoadingCategories = false.obs;
  final RxBool isLoadingSeverities = false.obs;
  final RxBool isCreatingReport = false.obs;
  final RxBool isDeletingReport = false.obs;

  /// Error messages
  final RxString reportsError = ''.obs;
  final RxString myReportsError = ''.obs;
  final RxString categoriesError = ''.obs;
  final RxString severitiesError = ''.obs;
  final RxString createError = ''.obs;

  /// Pagination state for all reports
  final RxInt currentPage = 1.obs;
  final RxInt totalCount = 0.obs;
  final RxBool hasMoreReports = true.obs;

  /// Pagination state for user's reports
  final RxInt myReportsPage = 1.obs;
  final RxInt myReportsTotalCount = 0.obs;
  final RxBool hasMoreMyReports = true.obs;

  /// Search and filter state
  final RxString searchQuery = ''.obs;
  final RxString ordering = '-created_at'.obs;

  // ─── Computed Properties ─────────────────────────────────────────────────

  bool get isLoading =>
      isLoadingReports.value ||
      isLoadingMyReports.value ||
      isLoadingCategories.value ||
      isLoadingSeverities.value;

  bool get hasReports => nearbyReports.isNotEmpty;

  bool get hasUserReports => userReports.isNotEmpty;

  bool get hasCategories => categories.isNotEmpty;

  bool get hasSeverities => severities.isNotEmpty;

  String? get error {
    if (reportsError.value.isNotEmpty) return reportsError.value;
    if (myReportsError.value.isNotEmpty) return myReportsError.value;
    if (categoriesError.value.isNotEmpty) return categoriesError.value;
    if (severitiesError.value.isNotEmpty) return severitiesError.value;
    if (createError.value.isNotEmpty) return createError.value;
    return null;
  }

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    // Load categories and severities on init
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      loadCategories(),
      loadSeverities(),
    ]);
  }

  // ─── Public Methods ──────────────────────────────────────────────────────

  /// Load trash categories from API
  Future<void> loadCategories() async {
    if (isLoadingCategories.value) return;

    isLoadingCategories.value = true;
    categoriesError.value = '';

    try {
      final result = await _reportService.fetchCategories();
      if (result != null) {
        categories.value = result;
        debugPrint('ReportController: Loaded ${result.length} categories');
      } else {
        categoriesError.value = 'Failed to load categories';
        debugPrint('ReportController: Failed to load categories');
      }
    } catch (e) {
      categoriesError.value = 'Error loading categories';
      debugPrint('ReportController: Error loading categories - $e');
    } finally {
      isLoadingCategories.value = false;
    }
  }

  /// Load severity levels from API
  Future<void> loadSeverities() async {
    if (isLoadingSeverities.value) return;

    isLoadingSeverities.value = true;
    severitiesError.value = '';

    try {
      final result = await _reportService.fetchSeverities();
      if (result != null) {
        severities.value = result;
        debugPrint('ReportController: Loaded ${result.length} severities');
      } else {
        severitiesError.value = 'Failed to load severities';
        debugPrint('ReportController: Failed to load severities');
      }
    } catch (e) {
      severitiesError.value = 'Error loading severities';
      debugPrint('ReportController: Error loading severities - $e');
    } finally {
      isLoadingSeverities.value = false;
    }
  }

  /// Load reports with pagination
  Future<void> loadReports({
    bool refresh = false,
    String? search,
    String? ordering,
  }) async {
    if (isLoadingReports.value) return;

    if (refresh) {
      currentPage.value = 1;
      hasMoreReports.value = true;
      nearbyReports.clear();
    }

    if (!hasMoreReports.value) return;

    isLoadingReports.value = true;
    reportsError.value = '';

    if (search != null) searchQuery.value = search;
    if (ordering != null) this.ordering.value = ordering;

    try {
      final result = await _reportService.fetchReports(
        page: currentPage.value,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        ordering: this.ordering.value,
      );

      if (result != null) {
        totalCount.value = result.count;
        hasMoreReports.value = result.hasNext;

        if (refresh) {
          nearbyReports.value = result.results;
        } else {
          nearbyReports.addAll(result.results);
        }

        currentPage.value++;
        debugPrint('ReportController: Loaded ${result.results.length} reports, total: ${result.count}');
      } else {
        reportsError.value = 'Failed to load reports';
        debugPrint('ReportController: Failed to load reports');
      }
    } catch (e) {
      reportsError.value = 'Error loading reports';
      debugPrint('ReportController: Error loading reports - $e');
    } finally {
      isLoadingReports.value = false;
    }
  }

  /// Refresh all reports
  Future<void> refreshReports() async {
    await loadReports(refresh: true);
  }

  /// Load more reports (next page)
  Future<void> loadMoreReports() async {
    if (!hasMoreReports.value || isLoadingReports.value) return;
    await loadReports();
  }

  /// Load current user's reports with pagination
  /// Useful for the user's profile page
  Future<void> loadMyReports({
    bool refresh = false,
    String? search,
    String? ordering,
  }) async {
    if (isLoadingMyReports.value) return;

    if (refresh) {
      myReportsPage.value = 1;
      hasMoreMyReports.value = true;
      userReports.clear();
    }

    if (!hasMoreMyReports.value) return;

    isLoadingMyReports.value = true;
    myReportsError.value = '';

    try {
      final result = await _reportService.fetchMyReports(
        page: myReportsPage.value,
        search: search,
        ordering: ordering ?? this.ordering.value,
      );

      if (result != null) {
        myReportsTotalCount.value = result.count;
        hasMoreMyReports.value = result.hasNext;

        if (refresh) {
          userReports.value = result.results;
        } else {
          userReports.addAll(result.results);
        }

        myReportsPage.value++;
        debugPrint('ReportController: Loaded ${result.results.length} user reports, total: ${result.count}');
      } else {
        myReportsError.value = 'Failed to load your reports';
        debugPrint('ReportController: Failed to load user reports');
      }
    } catch (e) {
      myReportsError.value = 'Error loading your reports';
      debugPrint('ReportController: Error loading user reports - $e');
    } finally {
      isLoadingMyReports.value = false;
    }
  }

  /// Refresh current user's reports
  Future<void> refreshMyReports() async {
    await loadMyReports(refresh: true);
  }

  /// Load more user reports (next page)
  Future<void> loadMoreMyReports() async {
    if (!hasMoreMyReports.value || isLoadingMyReports.value) return;
    await loadMyReports();
  }

  /// Get a single report by ID
  Future<ReportModel?> getReport(String reportId) async {
    try {
      // Check cache first
      final cached = nearbyReports.firstWhereOrNull((r) => r.id == reportId);
      if (cached != null) {
        currentReport.value = cached;
        return cached;
      }

      // Fetch from API
      final report = await _reportService.fetchReport(reportId);
      if (report != null) {
        currentReport.value = report;
      }
      return report;
    } catch (e) {
      debugPrint('ReportController: Error getting report - $e');
      return null;
    }
  }

  /// Create a new report
  Future<ReportModel?> createReport({
    required String title,
    String? observation,
    required String severityId,
    required String categoryId,
    LocationModel? location,
    required List<String> imagePaths,
  }) async {
    if (isCreatingReport.value) return null;

    // Ensure at least one image is provided
    if (imagePaths.isEmpty) {
      createError.value = 'Please attach at least one image before submitting.';
      debugPrint('ReportController: Aborting createReport - no images provided');
      return null;
    }

    // Validate that all image files exist
    final validPaths = <String>[];
    for (final path in imagePaths) {
      final file = File(path);
      if (file.existsSync()) {
        validPaths.add(path);
      } else {
        debugPrint('ReportController: Image file not found at $path');
      }
    }

    if (validPaths.isEmpty) {
      createError.value = 'No valid images found. Please try again.';
      debugPrint('ReportController: Aborting createReport - no valid image files');
      return null;
    }

    isCreatingReport.value = true;
    createError.value = '';

    try {
      final result = await _reportService.createReport(
        title: title,
        observation: observation,
        severityId: severityId,
        categoryId: categoryId,
        location: location,
        imagePaths: validPaths,
      );

      if (result != null) {
        // Add to the beginning of the list
        nearbyReports.insert(0, result);
        debugPrint('ReportController: Created report ${result.id}');
        return result;
      } else {
        createError.value = 'Failed to create report';
        debugPrint('ReportController: Failed to create report');
        return null;
      }
    } catch (e) {
      createError.value = 'Error creating report';
      debugPrint('ReportController: Error creating report - $e');
      return null;
    } finally {
      isCreatingReport.value = false;
    }
  }

  /// Create a new report and return both report and points data
  /// This method is used for the new report flow where we need to show points
  Future<ReportCreationResult?> createReportWithPoints({
    required String title,
    String? observation,
    required String severityId,
    required String categoryId,
    LocationModel? location,
    required List<String> imagePaths,
  }) async {
    if (isCreatingReport.value) return null;

    // Ensure at least one image is provided
    if (imagePaths.isEmpty) {
      createError.value = 'Please attach at least one image before submitting.';
      debugPrint('ReportController: Aborting createReport - no images provided');
      return null;
    }

    // Validate that all image files exist
    final validPaths = <String>[];
    for (final path in imagePaths) {
      final file = File(path);
      if (file.existsSync()) {
        validPaths.add(path);
      } else {
        debugPrint('ReportController: Image file not found at $path');
      }
    }

    isCreatingReport.value = true;
    createError.value = '';

    try {
      final result = await _reportService.createReportWithPoints(
        title: title,
        observation: observation,
        severityId: severityId,
        categoryId: categoryId,
        location: location,
        imagePaths: imagePaths,
      );

      if (result != null) {
        // Add to the beginning of the list
        nearbyReports.insert(0, result.report);
        debugPrint('ReportController: Created report ${result.report.id} with points: ${result.hasPoints}');
        return result;
      } else {
        createError.value = 'Failed to create report';
        debugPrint('ReportController: Failed to create report with points');
        return null;
      }
    } catch (e) {
      createError.value = 'Error creating report with points';
      debugPrint('ReportController: Error creating report with points - $e');
      return null;
    } finally {
      isCreatingReport.value = false;
    }
  }

  /// Update an existing report
  Future<ReportModel?> updateReport(
    String reportId, {
    String? title,
    String? observation,
    String? severityId,
    String? categoryId,
  }) async {
    try {
      final result = await _reportService.updateReport(
        reportId,
        title: title,
        observation: observation,
        severityId: severityId,
        categoryId: categoryId,
      );

      if (result != null) {
        // Update in the list
        final index = nearbyReports.indexWhere((r) => r.id == reportId);
        if (index != -1) {
          nearbyReports[index] = result;
        }

        // Update current report if it's the same
        if (currentReport.value?.id == reportId) {
          currentReport.value = result;
        }

        debugPrint('ReportController: Updated report $reportId');
      }
      return result;
    } catch (e) {
      debugPrint('ReportController: Error updating report - $e');
      return null;
    }
  }

  /// Delete a report
  Future<bool> deleteReport(String reportId) async {
    if (isDeletingReport.value) return false;

    isDeletingReport.value = true;

    try {
      final success = await _reportService.deleteReport(reportId);
      if (success) {
        // Remove from list
        nearbyReports.removeWhere((r) => r.id == reportId);

        // Clear current report if it's the same
        if (currentReport.value?.id == reportId) {
          currentReport.value = null;
        }

        debugPrint('ReportController: Deleted report $reportId');
      }
      return success;
    } catch (e) {
      debugPrint('ReportController: Error deleting report - $e');
      return false;
    } finally {
      isDeletingReport.value = false;
    }
  }

  /// Search reports
  Future<void> searchReports(String query) async {
    await loadReports(refresh: true, search: query);
  }

  /// Change ordering
  Future<void> changeOrdering(String newOrdering) async {
    await loadReports(refresh: true, ordering: newOrdering);
  }

  /// Clear all data
  void clearData() {
    nearbyReports.clear();
    userReports.clear();
    currentReport.value = null;
    currentPage.value = 1;
    totalCount.value = 0;
    hasMoreReports.value = true;
    myReportsPage.value = 1;
    myReportsTotalCount.value = 0;
    hasMoreMyReports.value = true;
    searchQuery.value = '';
    reportsError.value = '';
    myReportsError.value = '';
    createError.value = '';
  }

  /// Clear errors
  void clearErrors() {
    reportsError.value = '';
    myReportsError.value = '';
    categoriesError.value = '';
    severitiesError.value = '';
    createError.value = '';
  }

  // ─── Helper Methods ──────────────────────────────────────────────────────

  /// Get category by ID
  TrashCategoryModel? getCategoryById(String id) {
    return categories.firstWhereOrNull((c) => c.id == id);
  }

  /// Get severity by ID
  ReportSeverityModel? getSeverityById(String id) {
    return severities.firstWhereOrNull((s) => s.id == id);
  }

  /// Get category by code
  TrashCategoryModel? getCategoryByCode(String code) {
    return categories.firstWhereOrNull((c) => c.code == code);
  }

  /// Get severity by level
  ReportSeverityModel? getSeverityByLevel(int level) {
    return severities.firstWhereOrNull((s) => s.level == level);
  }
}
