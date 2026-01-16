import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/models.dart';
import 'api_service.dart';

/// Service for handling leaderboard and user stats API calls
class LeaderboardService extends GetxService {
  // ─── Dependencies ────────────────────────────────────────────────────────
  ApiService get _apiService => Get.find<ApiService>();

  // ─── Constants ─────────────────────────────────────────────────────────
  static const String _leaderboardEndpoint = '/api/leaderboard/';
  static const String _myStatsEndpoint = '/api/leaderboard/me/stats/';
  static const String _myTransactionsEndpoint =
      '/api/leaderboard/me/transactions/';
  static const String _myRankEndpoint = '/api/leaderboard/me/rank/';

  // ─── Leaderboard ──────────────────────────────────────────────────────────

  /// Fetch leaderboard data
  /// GET /api/leaderboard/?period=all&limit=10
  Future<LeaderboardModel?> fetchLeaderboard({
    LeaderboardPeriod period = LeaderboardPeriod.all,
    int limit = 10,
  }) async {
    try {
      // Ensure minimum limit of 10
      final adjustedLimit = limit < 10 ? 10 : limit;

      final queryParams = <String, dynamic>{
        'period': period.value,
        'limit': adjustedLimit,
      };

      final result = await _apiService.get<LeaderboardModel>(
        _leaderboardEndpoint,
        queryParameters: queryParams,
        parser: (data) {
          if (data is Map<String, dynamic>) {
            return LeaderboardModel.fromJson(data);
          }
          return LeaderboardModel.empty();
        },
      );

      if (result.isSuccess && result.data != null) {
        debugPrint(
          'LeaderboardService: Fetched ${result.data!.leaderboard.length} leaderboard entries for ${period.value}',
        );
        return result.data;
      } else {
        debugPrint(
          'LeaderboardService: Failed to fetch leaderboard - ${result.error}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('LeaderboardService: Error fetching leaderboard - $e');
      return null;
    }
  }

  // ─── User Stats ──────────────────────────────────────────────────────────

  /// Fetch current user's statistics
  /// GET /api/leaderboard/me/stats/
  Future<UserStatsModel?> fetchMyStats() async {
    try {
      final result = await _apiService.get<UserStatsModel>(
        _myStatsEndpoint,
        parser: (data) {
          if (data is Map<String, dynamic>) {
            return UserStatsModel.fromJson(data);
          }
          return UserStatsModel.empty();
        },
      );

      if (result.isSuccess && result.data != null) {
        debugPrint(
          'LeaderboardService: Fetched user stats - ${result.data!.totalPoints} total points',
        );
        return result.data;
      } else {
        debugPrint(
          'LeaderboardService: Failed to fetch user stats - ${result.error}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('LeaderboardService: Error fetching user stats - $e');
      return null;
    }
  }

  /// Fetch current user's rank information
  /// GET /api/leaderboard/me/rank/
  Future<UserRankModel?> fetchMyRank() async {
    try {
      final result = await _apiService.get<UserRankModel>(
        _myRankEndpoint,
        parser: (data) {
          if (data is Map<String, dynamic>) {
            return UserRankModel.fromJson(data);
          }
          return UserRankModel.empty();
        },
      );

      if (result.isSuccess && result.data != null) {
        debugPrint(
          'LeaderboardService: Fetched user rank - Rank ${result.data!.overallRank} of ${result.data!.totalUsers}',
        );
        return result.data;
      } else {
        debugPrint(
          'LeaderboardService: Failed to fetch user rank - ${result.error}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('LeaderboardService: Error fetching user rank - $e');
      return null;
    }
  }

  /// Fetch current user's points transactions
  /// GET /api/leaderboard/me/transactions/
  Future<TransactionsModel?> fetchMyTransactions({
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      };

      final result = await _apiService.get<TransactionsModel>(
        _myTransactionsEndpoint,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        parser: (data) {
          if (data is Map<String, dynamic>) {
            return TransactionsModel.fromJson(data);
          }
          return TransactionsModel.empty();
        },
      );

      if (result.isSuccess && result.data != null) {
        debugPrint(
          'LeaderboardService: Fetched ${result.data!.transactions.length} transactions',
        );
        return result.data;
      } else {
        debugPrint(
          'LeaderboardService: Failed to fetch transactions - ${result.error}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('LeaderboardService: Error fetching transactions - $e');
      return null;
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
      return 'You don\'t have permission to access this data.';
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
