import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/models.dart';
import 'api_service.dart';

/// Service for handling points-related operations
class PointsService extends GetxService {
  // ─── Dependencies ────────────────────────────────────────────────────────
  ApiService get _apiService => Get.find<ApiService>();

  // ─── Constants ─────────────────────────────────────────────────────────
  static const String _pointsEndpoint = '/api/points/';
  static const String _userPointsEndpoint = '/api/points/me/';

  /// Extract points data from a report creation response
  /// The points data is embedded in the report response under the "points" key
  ReportPointsModel? extractPointsFromReportResponse(Map<String, dynamic> response) {
    try {
      if (response.containsKey('points') && response['points'] != null) {
        final pointsData = response['points'] as Map<String, dynamic>;
        final points = ReportPointsModel.fromJson(pointsData);
        debugPrint('PointsService: Extracted points - ${points.pointsAwarded} points awarded');
        return points;
      }
      debugPrint('PointsService: No points data in response');
      return null;
    } catch (e) {
      debugPrint('PointsService: Error extracting points - $e');
      return null;
    }
  }

  /// Fetch user's total points and rank
  Future<Map<String, dynamic>?> fetchUserPoints() async {
    try {
      final result = await _apiService.get<Map<String, dynamic>>(
        _userPointsEndpoint,
        parser: (data) => data as Map<String, dynamic>,
      );

      if (result.isSuccess && result.data != null) {
        debugPrint('PointsService: Fetched user points successfully');
        return result.data;
      } else {
        debugPrint('PointsService: Failed to fetch user points - ${result.error}');
        return null;
      }
    } catch (e) {
      debugPrint('PointsService: Error fetching user points - $e');
      return null;
    }
  }

  /// Get points history for the current user
  Future<List<ReportPointsModel>?> fetchPointsHistory({int page = 1}) async {
    try {
      final result = await _apiService.get<List<ReportPointsModel>>(
        '$_pointsEndpoint?page=$page',
        parser: (data) {
          if (data is Map<String, dynamic> && data.containsKey('results')) {
            final results = data['results'] as List<dynamic>;
            return results
                .map((item) => ReportPointsModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return [];
        },
      );

      if (result.isSuccess && result.data != null) {
        debugPrint('PointsService: Fetched ${result.data!.length} points entries');
        return result.data;
      } else {
        debugPrint('PointsService: Failed to fetch points history - ${result.error}');
        return null;
      }
    } catch (e) {
      debugPrint('PointsService: Error fetching points history - $e');
      return null;
    }
  }
}
