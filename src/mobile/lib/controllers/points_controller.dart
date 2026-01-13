import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/models.dart';
import '../services/services.dart';

/// Controller for managing report points data and state
class PointsController extends GetxController {
  // ─── Services ────────────────────────────────────────────────────────────
  PointsService get _pointsService => Get.find<PointsService>();

  // ─── State ───────────────────────────────────────────────────────────────

  /// Current report points (from last submission)
  final Rx<ReportPointsModel?> currentReportPoints = Rx<ReportPointsModel?>(null);

  /// Whether the points are being loaded
  final RxBool isLoading = false.obs;

  /// Whether to show detailed breakdown
  final RxBool showDetails = false.obs;

  /// Animation progress for points counter (0.0 to 1.0)
  final RxDouble animationProgress = 0.0.obs;

  /// User's total cumulative points
  final RxInt totalUserPoints = 0.obs;

  /// User's current rank
  final RxInt userRank = 0.obs;

  // ─── Getters ─────────────────────────────────────────────────────────────

  /// Check if we have points data to display
  bool get hasPointsData => currentReportPoints.value != null;

  /// Get animated points value based on progress
  int get animatedPoints {
    final points = currentReportPoints.value?.pointsAwarded ?? 0;
    return (points * animationProgress.value).round();
  }

  /// Get the points breakdown
  PointsBreakdown? get breakdown => currentReportPoints.value?.breakdown;

  // ─── Methods ─────────────────────────────────────────────────────────────

  /// Set the current report points from a report submission response
  void setPointsFromResponse(Map<String, dynamic> response) {
    final points = _pointsService.extractPointsFromReportResponse(response);
    if (points != null) {
      currentReportPoints.value = points;
      totalUserPoints.value = points.totalUserPoints;
      userRank.value = points.userRank;
      debugPrint('PointsController: Points set - ${points.pointsAwarded} awarded');
    } else {
      debugPrint('PointsController: No points data in response');
    }
  }

  /// Set points directly from a ReportPointsModel
  void setPoints(ReportPointsModel points) {
    currentReportPoints.value = points;
    totalUserPoints.value = points.totalUserPoints;
    userRank.value = points.userRank;
    debugPrint('PointsController: Points set directly - ${points.pointsAwarded} awarded');
  }

  /// Toggle details visibility
  void toggleDetails() {
    showDetails.value = !showDetails.value;
  }

  /// Reset animation progress
  void resetAnimation() {
    animationProgress.value = 0.0;
  }

  /// Set animation progress (called from animation controller)
  void setAnimationProgress(double progress) {
    animationProgress.value = progress.clamp(0.0, 1.0);
  }

  /// Clear current points data
  void clearPoints() {
    currentReportPoints.value = null;
    showDetails.value = false;
    animationProgress.value = 0.0;
    debugPrint('PointsController: Points cleared');
  }

  /// Fetch user's cumulative points
  Future<void> fetchUserPoints() async {
    isLoading.value = true;
    try {
      final data = await _pointsService.fetchUserPoints();
      if (data != null) {
        totalUserPoints.value = data['total_points'] ?? 0;
        userRank.value = data['rank'] ?? 0;
        debugPrint('PointsController: Fetched user points - $totalUserPoints, rank: $userRank');
      }
    } catch (e) {
      debugPrint('PointsController: Error fetching user points - $e');
    } finally {
      isLoading.value = false;
    }
  }
}
