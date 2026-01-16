import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/models.dart';
import '../services/leaderboard_service.dart';
import '../controllers/auth_controller.dart';

/// Controller for managing leaderboard data and state
class LeaderboardController extends GetxController {
  // ─── Dependencies ────────────────────────────────────────────────────────
  LeaderboardService get _leaderboardService => Get.find<LeaderboardService>();
  AuthController get _authController => Get.find<AuthController>();

  // ─── Observable State ────────────────────────────────────────────────────

  /// Current leaderboard data
  final Rx<LeaderboardModel?> leaderboard = Rx<LeaderboardModel?>(null);

  /// Current user's stats
  final Rx<UserStatsModel?> userStats = Rx<UserStatsModel?>(null);

  /// Current user's rank
  final Rx<UserRankModel?> userRank = Rx<UserRankModel?>(null);

  /// Current user's transactions
  final Rx<TransactionsModel?> transactions = Rx<TransactionsModel?>(null);

  /// Selected period filter
  final Rx<LeaderboardPeriod> selectedPeriod = LeaderboardPeriod.all.obs;

  /// Leaderboard limit
  final RxInt limit = 50.obs;

  /// Loading states
  final RxBool isLoadingLeaderboard = false.obs;
  final RxBool isLoadingStats = false.obs;
  final RxBool isLoadingRank = false.obs;
  final RxBool isLoadingTransactions = false.obs;

  /// Error messages
  final RxString leaderboardError = ''.obs;
  final RxString statsError = ''.obs;
  final RxString rankError = ''.obs;
  final RxString transactionsError = ''.obs;

  // ─── Computed Properties ─────────────────────────────────────────────────

  bool get isLoading =>
      isLoadingLeaderboard.value ||
          isLoadingStats.value ||
          isLoadingRank.value;

  bool get hasLeaderboardData =>
      leaderboard.value != null && leaderboard.value!.isNotEmpty;

  bool get hasUserStats => userStats.value != null;

  bool get hasUserRank => userRank.value != null;

  /// Get current user's ID
  int? get currentUserId => _authController.currentUser?.id;

  /// Get top 3 entries
  List<LeaderboardEntryModel> get topThree {
    return leaderboard.value?.topThree ?? [];
  }

  /// Get remaining entries (after top 3)
  List<LeaderboardEntryModel> get remainingEntries {
    return leaderboard.value?.remaining ?? [];
  }

  /// Get all entries
  List<LeaderboardEntryModel> get allEntries {
    return leaderboard.value?.leaderboard ?? [];
  }

  /// Get current user's rank for selected period
  int? get currentUserRank {
    if (userRank.value == null) return null;
    return userRank.value!.getRankForPeriod(selectedPeriod.value);
  }

  /// Get current user's points for selected period
  int? get currentUserPoints {
    if (userStats.value == null) return null;
    return userStats.value!.getPointsForPeriod(selectedPeriod.value);
  }

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      loadLeaderboard(),
      loadUserStats(),
      loadUserRank(),
    ]);
  }

  // ─── Public Methods ──────────────────────────────────────────────────────

  /// Load leaderboard data
  Future<void> loadLeaderboard({
    LeaderboardPeriod? period,
    int? customLimit,
  }) async {
    if (isLoadingLeaderboard.value) return;

    isLoadingLeaderboard.value = true;
    leaderboardError.value = '';

    if (period != null) {
      selectedPeriod.value = period;
    }

    if (customLimit != null) {
      limit.value = customLimit < 10 ? 10 : customLimit;
    }

    try {
      final result = await _leaderboardService.fetchLeaderboard(
        period: selectedPeriod.value,
        limit: limit.value,
      );

      if (result != null) {
        leaderboard.value = result;
        debugPrint(
          'LeaderboardController: Loaded ${result.leaderboard.length} entries for ${selectedPeriod.value.displayName}',
        );
      } else {
        leaderboardError.value = 'Failed to load leaderboard';
        debugPrint('LeaderboardController: Failed to load leaderboard');
      }
    } catch (e) {
      leaderboardError.value = 'Error loading leaderboard';
      debugPrint('LeaderboardController: Error loading leaderboard - $e');
    } finally {
      isLoadingLeaderboard.value = false;
    }
  }

  /// Refresh leaderboard
  Future<void> refreshLeaderboard() async {
    await loadLeaderboard();
  }

  /// Change period filter
  Future<void> changePeriod(LeaderboardPeriod period) async {
    if (period == selectedPeriod.value) return;
    await loadLeaderboard(period: period);
  }

  /// Change limit
  Future<void> changeLimit(int newLimit) async {
    if (newLimit == limit.value) return;
    await loadLeaderboard(customLimit: newLimit);
  }

  /// Load user statistics
  Future<void> loadUserStats() async {
    if (isLoadingStats.value) return;

    isLoadingStats.value = true;
    statsError.value = '';

    try {
      final result = await _leaderboardService.fetchMyStats();

      if (result != null) {
        userStats.value = result;
        debugPrint(
          'LeaderboardController: Loaded user stats - ${result.totalPoints} points',
        );
      } else {
        statsError.value = 'Failed to load statistics';
        debugPrint('LeaderboardController: Failed to load user stats');
      }
    } catch (e) {
      statsError.value = 'Error loading statistics';
      debugPrint('LeaderboardController: Error loading user stats - $e');
    } finally {
      isLoadingStats.value = false;
    }
  }

  /// Load user rank
  Future<void> loadUserRank() async {
    if (isLoadingRank.value) return;

    isLoadingRank.value = true;
    rankError.value = '';

    try {
      final result = await _leaderboardService.fetchMyRank();

      if (result != null) {
        userRank.value = result;
        debugPrint(
          'LeaderboardController: Loaded user rank - Rank ${result.overallRank}',
        );
      } else {
        rankError.value = 'Failed to load rank';
        debugPrint('LeaderboardController: Failed to load user rank');
      }
    } catch (e) {
      rankError.value = 'Error loading rank';
      debugPrint('LeaderboardController: Error loading user rank - $e');
    } finally {
      isLoadingRank.value = false;
    }
  }

  /// Load user transactions
  Future<void> loadUserTransactions({
    int? limit,
    int? offset,
  }) async {
    if (isLoadingTransactions.value) return;

    isLoadingTransactions.value = true;
    transactionsError.value = '';

    try {
      final result = await _leaderboardService.fetchMyTransactions(
        limit: limit,
        offset: offset,
      );

      if (result != null) {
        transactions.value = result;
        debugPrint(
          'LeaderboardController: Loaded ${result.transactions.length} transactions',
        );
      } else {
        transactionsError.value = 'Failed to load transactions';
        debugPrint('LeaderboardController: Failed to load transactions');
      }
    } catch (e) {
      transactionsError.value = 'Error loading transactions';
      debugPrint('LeaderboardController: Error loading transactions - $e');
    } finally {
      isLoadingTransactions.value = false;
    }
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadLeaderboard(),
      loadUserStats(),
      loadUserRank(),
    ]);
  }

  /// Check if a user ID is the current user
  bool isCurrentUser(int userId) {
    return currentUserId != null && currentUserId == userId;
  }

  /// Find user entry in leaderboard
  LeaderboardEntryModel? findUserInLeaderboard(int userId) {
    if (!hasLeaderboardData) return null;
    try {
      return allEntries.firstWhere((entry) => entry.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Get current user's leaderboard entry
  LeaderboardEntryModel? get currentUserEntry {
    if (currentUserId == null) return null;
    return findUserInLeaderboard(currentUserId!);
  }

  /// Clear all data
  void clearData() {
    leaderboard.value = null;
    userStats.value = null;
    userRank.value = null;
    transactions.value = null;
    selectedPeriod.value = LeaderboardPeriod.all;
    limit.value = 50;
    clearErrors();
  }

  /// Clear errors
  void clearErrors() {
    leaderboardError.value = '';
    statsError.value = '';
    rankError.value = '';
    transactionsError.value = '';
  }

  // ─── Helper Methods ──────────────────────────────────────────────────────

  /// Get medal color for rank
  Color getMedalColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }

  /// Get medal icon for rank
  String getMedalEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  /// Format rank display
  String formatRank(int rank) {
    if (rank <= 0) return '-';
    if (rank <= 3) return getMedalEmoji(rank);
    return '#$rank';
  }
}