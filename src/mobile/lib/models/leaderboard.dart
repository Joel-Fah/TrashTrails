import 'base/model_utils.dart';

/// Enum for leaderboard time periods
enum LeaderboardPeriod {
  all('all', 'All Time'),
  weekly('weekly', 'Weekly'),
  monthly('monthly', 'Monthly'),
  yearly('yearly', 'Yearly');

  final String value;
  final String displayName;

  const LeaderboardPeriod(this.value, this.displayName);

  static LeaderboardPeriod fromString(String? value) {
    if (value == null) return LeaderboardPeriod.all;
    return LeaderboardPeriod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => LeaderboardPeriod.all,
    );
  }
}

/// Model representing a leaderboard entry
class LeaderboardEntryModel {
  final int rank;
  final int userId;
  final String username;
  final String? fullName;
  final String? avatar;
  final int points;
  final int totalReports;

  const LeaderboardEntryModel({
    required this.rank,
    required this.userId,
    required this.username,
    this.fullName,
    this.avatar,
    required this.points,
    required this.totalReports,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      rank: parseIntOrDefault(json['rank'], 0),
      userId: parseIntOrDefault(json['user_id'] ?? json['userId'], 0),
      username: parseStringOrDefault(json['username'], ''),
      fullName: parseString(json['full_name'] ?? json['fullName']),
      avatar: parseString(json['avatar']),
      points: parseIntOrDefault(json['points'], 0),
      totalReports: parseIntOrDefault(
        json['total_reports'] ?? json['totalReports'],
        0,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'user_id': userId,
      'username': username,
      if (fullName != null) 'full_name': fullName,
      if (avatar != null) 'avatar': avatar,
      'points': points,
      'total_reports': totalReports,
    };
  }

  /// Display name (full name or username)
  String get displayName => fullName ?? username;

  /// Returns true if this is a top 3 position
  bool get isTopThree => rank <= 3;

  /// Returns true if this entry has an avatar
  bool get hasAvatar => avatar != null && avatar!.isNotEmpty;

  @override
  String toString() =>
      'LeaderboardEntryModel(rank: $rank, username: $username, points: $points)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardEntryModel &&
        other.rank == rank &&
        other.userId == userId;
  }

  @override
  int get hashCode => rank.hashCode ^ userId.hashCode;
}

/// Model representing the complete leaderboard response
class LeaderboardModel {
  final LeaderboardPeriod period;
  final int count;
  final List<LeaderboardEntryModel> leaderboard;

  const LeaderboardModel({
    required this.period,
    required this.count,
    required this.leaderboard,
  });

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) {
    final leaderboardList = json['leaderboard'] as List<dynamic>? ?? [];

    return LeaderboardModel(
      period: LeaderboardPeriod.fromString(parseString(json['period'])),
      count: parseIntOrDefault(json['count'], 0),
      leaderboard: leaderboardList
          .whereType<Map<String, dynamic>>()
          .map((item) => LeaderboardEntryModel.fromJson(item))
          .toList(),
    );
  }

  factory LeaderboardModel.empty() {
    return const LeaderboardModel(
      period: LeaderboardPeriod.all,
      count: 0,
      leaderboard: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period.value,
      'count': count,
      'leaderboard': leaderboard.map((e) => e.toJson()).toList(),
    };
  }

  /// Get top 3 entries
  List<LeaderboardEntryModel> get topThree {
    return leaderboard.take(3).toList();
  }

  /// Get entries after top 3
  List<LeaderboardEntryModel> get remaining {
    return leaderboard.skip(3).toList();
  }

  /// Check if leaderboard has entries
  bool get isNotEmpty => leaderboard.isNotEmpty;

  bool get isEmpty => leaderboard.isEmpty;

  @override
  String toString() =>
      'LeaderboardModel(period: ${period.value}, count: $count, entries: ${leaderboard.length})';
}

/// Model for user statistics
class UserStatsModel {
  final int totalPoints;
  final int weeklyPoints;
  final int monthlyPoints;
  final int yearlyPoints;
  final int totalReports;
  final int verifiedReports;

  const UserStatsModel({
    required this.totalPoints,
    required this.weeklyPoints,
    required this.monthlyPoints,
    required this.yearlyPoints,
    required this.totalReports,
    required this.verifiedReports,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      totalPoints: parseIntOrDefault(
        json['total_points'] ?? json['totalPoints'],
        0,
      ),
      weeklyPoints: parseIntOrDefault(
        json['weekly_points'] ?? json['weeklyPoints'],
        0,
      ),
      monthlyPoints: parseIntOrDefault(
        json['monthly_points'] ?? json['monthlyPoints'],
        0,
      ),
      yearlyPoints: parseIntOrDefault(
        json['yearly_points'] ?? json['yearlyPoints'],
        0,
      ),
      totalReports: parseIntOrDefault(
        json['total_reports'] ?? json['totalReports'],
        0,
      ),
      verifiedReports: parseIntOrDefault(
        json['verified_reports'] ?? json['verifiedReports'],
        0,
      ),
    );
  }

  factory UserStatsModel.empty() {
    return const UserStatsModel(
      totalPoints: 0,
      weeklyPoints: 0,
      monthlyPoints: 0,
      yearlyPoints: 0,
      totalReports: 0,
      verifiedReports: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_points': totalPoints,
      'weekly_points': weeklyPoints,
      'monthly_points': monthlyPoints,
      'yearly_points': yearlyPoints,
      'total_reports': totalReports,
      'verified_reports': verifiedReports,
    };
  }

  /// Get points for specific period
  int getPointsForPeriod(LeaderboardPeriod period) {
    switch (period) {
      case LeaderboardPeriod.weekly:
        return weeklyPoints;
      case LeaderboardPeriod.monthly:
        return monthlyPoints;
      case LeaderboardPeriod.yearly:
        return yearlyPoints;
      case LeaderboardPeriod.all:
        return totalPoints;
    }
  }

  @override
  String toString() =>
      'UserStatsModel(totalPoints: $totalPoints, totalReports: $totalReports)';
}

/// Model for user rank information
class UserRankModel {
  final int overallRank;
  final int weeklyRank;
  final int monthlyRank;
  final int yearlyRank;
  final int totalUsers;

  const UserRankModel({
    required this.overallRank,
    required this.weeklyRank,
    required this.monthlyRank,
    required this.yearlyRank,
    required this.totalUsers,
  });

  factory UserRankModel.fromJson(Map<String, dynamic> json) {
    return UserRankModel(
      overallRank: parseIntOrDefault(
        json['overall_rank'] ?? json['overallRank'],
        0,
      ),
      weeklyRank: parseIntOrDefault(
        json['weekly_rank'] ?? json['weeklyRank'],
        0,
      ),
      monthlyRank: parseIntOrDefault(
        json['monthly_rank'] ?? json['monthlyRank'],
        0,
      ),
      yearlyRank: parseIntOrDefault(
        json['yearly_rank'] ?? json['yearlyRank'],
        0,
      ),
      totalUsers: parseIntOrDefault(
        json['total_users'] ?? json['totalUsers'],
        0,
      ),
    );
  }

  factory UserRankModel.empty() {
    return const UserRankModel(
      overallRank: 0,
      weeklyRank: 0,
      monthlyRank: 0,
      yearlyRank: 0,
      totalUsers: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overall_rank': overallRank,
      'weekly_rank': weeklyRank,
      'monthly_rank': monthlyRank,
      'yearly_rank': yearlyRank,
      'total_users': totalUsers,
    };
  }

  /// Get rank for specific period
  int getRankForPeriod(LeaderboardPeriod period) {
    switch (period) {
      case LeaderboardPeriod.weekly:
        return weeklyRank;
      case LeaderboardPeriod.monthly:
        return monthlyRank;
      case LeaderboardPeriod.yearly:
        return yearlyRank;
      case LeaderboardPeriod.all:
        return overallRank;
    }
  }

  @override
  String toString() =>
      'UserRankModel(overallRank: $overallRank, totalUsers: $totalUsers)';
}

/// Model for transaction breakdown item
class TransactionBreakdownItem {
  final int points;
  final String reason;
  final String? endorser;

  const TransactionBreakdownItem({
    required this.points,
    required this.reason,
    this.endorser,
  });

  factory TransactionBreakdownItem.fromJson(Map<String, dynamic> json) {
    return TransactionBreakdownItem(
      points: parseIntOrDefault(json['points'], 0),
      reason: parseStringOrDefault(json['reason'], ''),
      endorser: parseString(json['endorser']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points,
      'reason': reason,
      if (endorser != null) 'endorser': endorser,
    };
  }
}

/// Model for points transaction
class PointsTransactionModel {
  final int id;
  final String transactionType;
  final String transactionTypeDisplay;
  final int points;
  final Map<String, dynamic>? breakdown;
  final String description;
  final String? reportTitle;
  final DateTime createdAt;

  const PointsTransactionModel({
    required this.id,
    required this.transactionType,
    required this.transactionTypeDisplay,
    required this.points,
    this.breakdown,
    required this.description,
    this.reportTitle,
    required this.createdAt,
  });

  factory PointsTransactionModel.fromJson(Map<String, dynamic> json) {
    return PointsTransactionModel(
      id: parseIntOrDefault(json['id'], 0),
      transactionType: parseStringOrDefault(
        json['transaction_type'] ?? json['transactionType'],
        '',
      ),
      transactionTypeDisplay: parseStringOrDefault(
        json['transaction_type_display'] ?? json['transactionTypeDisplay'],
        '',
      ),
      points: parseIntOrDefault(json['points'], 0),
      breakdown: json['breakdown'] as Map<String, dynamic>?,
      description: parseStringOrDefault(json['description'], ''),
      reportTitle: parseString(json['report_title'] ?? json['reportTitle']),
      createdAt: parseDateTimeOrDefault(
        json['created_at'] ?? json['createdAt'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_type': transactionType,
      'transaction_type_display': transactionTypeDisplay,
      'points': points,
      if (breakdown != null) 'breakdown': breakdown,
      'description': description,
      if (reportTitle != null) 'report_title': reportTitle,
      'created_at': dateTimeToJson(createdAt),
    };
  }

  /// Returns true if points are positive
  bool get isPositive => points > 0;

  /// Returns true if points are negative
  bool get isNegative => points < 0;

  @override
  String toString() =>
      'PointsTransactionModel(id: $id, type: $transactionType, points: $points)';
}

/// Model for transactions response
class TransactionsModel {
  final int count;
  final List<PointsTransactionModel> transactions;

  const TransactionsModel({required this.count, required this.transactions});

  factory TransactionsModel.fromJson(Map<String, dynamic> json) {
    final transactionsList = json['transactions'] as List<dynamic>? ?? [];

    return TransactionsModel(
      count: parseIntOrDefault(json['count'], 0),
      transactions: transactionsList
          .whereType<Map<String, dynamic>>()
          .map((item) => PointsTransactionModel.fromJson(item))
          .toList(),
    );
  }

  factory TransactionsModel.empty() {
    return const TransactionsModel(count: 0, transactions: []);
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }

  bool get isNotEmpty => transactions.isNotEmpty;

  bool get isEmpty => transactions.isEmpty;

  @override
  String toString() => 'TransactionsModel(count: $count)';
}
