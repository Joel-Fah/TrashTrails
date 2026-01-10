import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/location.dart';
import '../models/report.dart';
import '../models/report_image.dart';

/// Service for handling reports data and API calls
class ReportService extends GetxService {
  // ─── State ───────────────────────────────────────────────────────────────
  final RxList<ReportModel> _nearbyReports = <ReportModel>[].obs;
  final RxList<ReportModel> _userReports = <ReportModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;

  // ─── Getters ─────────────────────────────────────────────────────────────
  List<ReportModel> get nearbyReports => _nearbyReports;
  List<ReportModel> get userReports => _userReports;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get hasNearbyReports => _nearbyReports.isNotEmpty;

  // ─── Public Methods ──────────────────────────────────────────────────────

  /// Load reports near a location
  Future<List<ReportModel>> loadNearbyReports(
    LocationModel location, {
    double radiusKm = 5.0,
  }) async {
    if (!location.isValid) {
      _error.value = 'Invalid location';
      return [];
    }

    _isLoading.value = true;
    _error.value = '';

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      final reports = _getMockReports(location);
      _nearbyReports.value = reports;

      return reports;
    } catch (e) {
      _error.value = 'Failed to load nearby reports';
      debugPrint('ReportService loadNearbyReports error: $e');
      return [];
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load reports by user ID
  Future<List<ReportModel>> loadUserReports(String userId) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      final reports = <ReportModel>[]; // Mock empty for now
      _userReports.value = reports;

      return reports;
    } catch (e) {
      _error.value = 'Failed to load user reports';
      debugPrint('ReportService loadUserReports error: $e');
      return [];
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get a single report by ID
  Future<ReportModel?> getReportById(String id) async {
    try {
      // Check cache first
      final cached = _nearbyReports.firstWhereOrNull((r) => r.id == id);
      if (cached != null) return cached;

      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 300));

      return null;
    } catch (e) {
      debugPrint('ReportService getReportById error: $e');
      return null;
    }
  }

  /// Create a new report
  Future<ReportModel?> createReport(ReportModel report) async {
    _isLoading.value = true;

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 1000));

      // Simulate created report with ID
      final created = report.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
      );

      _nearbyReports.insert(0, created);
      return created;
    } catch (e) {
      _error.value = 'Failed to create report';
      debugPrint('ReportService createReport error: $e');
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Endorse a report
  Future<bool> endorseReport(String reportId) async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 300));

      // Update local cache
      final index = _nearbyReports.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        _nearbyReports[index] = _nearbyReports[index].markAsEndorsed();
      }

      return true;
    } catch (e) {
      debugPrint('ReportService endorseReport error: $e');
      return false;
    }
  }

  /// Remove endorsement from a report
  Future<bool> removeEndorsement(String reportId) async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 300));

      // Update local cache
      final index = _nearbyReports.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        _nearbyReports[index] = _nearbyReports[index].markAsNotEndorsed();
      }

      return true;
    } catch (e) {
      debugPrint('ReportService removeEndorsement error: $e');
      return false;
    }
  }

  /// Refresh nearby reports
  Future<void> refreshNearbyReports(LocationModel location) async {
    await loadNearbyReports(location);
  }

  /// Clear all cached data
  void clearCache() {
    _nearbyReports.clear();
    _userReports.clear();
    _error.value = '';
  }

  // ─── Mock Data ───────────────────────────────────────────────────────────

  List<ReportModel> _getMockReports(LocationModel userLocation) {
    final userLat = userLocation.latitude;
    final userLng = userLocation.longitude;

    return [
      ReportModel(
        id: '1',
        title: 'Large trash dump near park',
        description: 'Illegal dumping site with mixed waste including plastic bags, cardboard boxes, and household items. Located near the children\'s playground.',
        streetName: 'Rue de la Paix',
        status: ReportStatus.verified,
        severity: ReportSeverity.high,
        category: TrashCategory.mixed,
        location: LocationModel(
          latitude: userLat + 0.002,
          longitude: userLng + 0.001,
          address: 'Rue de la Paix, Paris',
          city: 'Paris',
        ),
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        endorsementCount: 15,
        viewCount: 48,
        images: [
          ReportImageModel(
            id: 'img_1_1',
            imageUrl: 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=400',
            thumbnailUrl: 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=200',
            uploadedAt: DateTime.now().subtract(const Duration(hours: 2)),
            isProcessed: true,
          ),
          ReportImageModel(
            id: 'img_1_2',
            imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
            thumbnailUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=200',
            uploadedAt: DateTime.now().subtract(const Duration(hours: 2)),
            isProcessed: true,
          ),
        ],
        tags: ['urgent', 'near-playground'],
        username: 'eco_warrior',
        userId: 'user_123',
      ),
      ReportModel(
        id: '2',
        title: 'Construction debris on sidewalk',
        description: 'Construction waste blocking the sidewalk. Includes concrete pieces, metal bars, and broken tiles.',
        streetName: 'Avenue des Champs',
        status: ReportStatus.pending,
        severity: ReportSeverity.medium,
        category: TrashCategory.construction,
        location: LocationModel(
          latitude: userLat - 0.001,
          longitude: userLng + 0.003,
          address: 'Avenue des Champs, Paris',
          city: 'Paris',
        ),
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        endorsementCount: 8,
        viewCount: 23,
        images: [
          ReportImageModel(
            id: 'img_2_1',
            imageUrl: 'https://images.unsplash.com/photo-1604187351574-c75ca79f5807?w=400',
            thumbnailUrl: 'https://images.unsplash.com/photo-1604187351574-c75ca79f5807?w=200',
            uploadedAt: DateTime.now().subtract(const Duration(hours: 5)),
            isProcessed: true,
          ),
        ],
        tags: ['sidewalk', 'construction'],
        username: 'green_citizen',
        userId: 'user_456',
      ),
      ReportModel(
        id: '3',
        title: 'Illegal e-waste dumping',
        description: 'Electronic waste including old monitors, keyboards, and cables dumped behind the building. Hazardous materials present.',
        streetName: 'Boulevard Victor Hugo',
        status: ReportStatus.inProgress,
        severity: ReportSeverity.critical,
        category: TrashCategory.electronic,
        location: LocationModel(
          latitude: userLat + 0.001,
          longitude: userLng - 0.002,
          address: 'Boulevard Victor Hugo, Paris',
          city: 'Paris',
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        endorsementCount: 23,
        viewCount: 87,
        images: [
          ReportImageModel(
            id: 'img_3_1',
            imageUrl: 'https://images.unsplash.com/photo-1550009158-9ebf69173e03?w=400',
            thumbnailUrl: 'https://images.unsplash.com/photo-1550009158-9ebf69173e03?w=200',
            uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
            isProcessed: true,
          ),
          ReportImageModel(
            id: 'img_3_2',
            imageUrl: 'https://images.unsplash.com/photo-1526951521990-620dc14c214b?w=400',
            thumbnailUrl: 'https://images.unsplash.com/photo-1526951521990-620dc14c214b?w=200',
            uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
            isProcessed: true,
          ),
          ReportImageModel(
            id: 'img_3_3',
            imageUrl: 'https://images.unsplash.com/photo-1495556650867-99590cea3657?w=400',
            thumbnailUrl: 'https://images.unsplash.com/photo-1495556650867-99590cea3657?w=200',
            uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
            isProcessed: true,
          ),
        ],
        tags: ['hazardous', 'e-waste', 'urgent'],
        username: 'trash_hunter',
        userId: 'user_789',
      ),
      ReportModel(
        id: '4',
        title: 'Plastic bottles near river bank',
        description: 'Large amount of plastic bottles and packaging near the river. Risk of water pollution.',
        streetName: 'Quai de Seine',
        status: ReportStatus.verified,
        severity: ReportSeverity.high,
        category: TrashCategory.plastic,
        location: LocationModel(
          latitude: userLat - 0.003,
          longitude: userLng - 0.001,
          address: 'Quai de Seine, Paris',
          city: 'Paris',
        ),
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        endorsementCount: 31,
        viewCount: 102,
        images: [
          ReportImageModel(
            id: 'img_4_1',
            imageUrl: 'https://images.unsplash.com/photo-1621451537084-482c73073a0f?w=400',
            thumbnailUrl: 'https://images.unsplash.com/photo-1621451537084-482c73073a0f?w=200',
            uploadedAt: DateTime.now().subtract(const Duration(hours: 8)),
            isProcessed: true,
          ),
        ],
        tags: ['river', 'plastic', 'pollution'],
        username: 'river_guardian',
        userId: 'user_101',
      ),
    ];
  }
}

