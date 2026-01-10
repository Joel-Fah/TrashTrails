import 'package:flutter/material.dart';

import 'base/model_utils.dart';

/// Enum representing the rank tier of a user
enum RankTier {
  bronze('bronze', 'Bronze', 0, 99),
  silver('silver', 'Silver', 100, 499),
  gold('gold', 'Gold', 500, 999),
  platinum('platinum', 'Platinum', 1000, 2499),
  diamond('diamond', 'Diamond', 2500, 4999),
  master('master', 'Master', 5000, 9999),
  legend('legend', 'Legend', 10000, null);

  final String value;
  final String displayName;
  final int minScore;
  final int? maxScore;

  const RankTier(this.value, this.displayName, this.minScore, this.maxScore);

  /// Creates a RankTier from a score
  static RankTier fromScore(int score) {
    for (final tier in RankTier.values.reversed) {
      if (score >= tier.minScore) return tier;
    }
    return RankTier.bronze;
  }

  /// Creates a RankTier from a string value
  static RankTier fromString(String? value) {
    if (value == null) return RankTier.bronze;
    return RankTier.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => RankTier.bronze,
    );
  }

  /// Returns the color associated with this tier
  Color get color {
    return switch (this) {
      RankTier.bronze => const Color(0xFFCD7F32),
      RankTier.silver => const Color(0xFFC0C0C0),
      RankTier.gold => const Color(0xFFFFD700),
      RankTier.platinum => const Color(0xFFE5E4E2),
      RankTier.diamond => const Color(0xFFB9F2FF),
      RankTier.master => const Color(0xFF9B59B6),
      RankTier.legend => const Color(0xFFFF6B6B),
    };
  }

  /// Returns the icon for this tier
  IconData get icon {
    return switch (this) {
      RankTier.bronze => Icons.shield_outlined,
      RankTier.silver => Icons.shield,
      RankTier.gold => Icons.workspace_premium_outlined,
      RankTier.platinum => Icons.workspace_premium,
      RankTier.diamond => Icons.diamond_outlined,
      RankTier.master => Icons.diamond,
      RankTier.legend => Icons.military_tech,
    };
  }

  /// Returns the progress to next tier (0.0 to 1.0)
  double progressToNext(int score) {
    if (maxScore == null) return 1.0; // Already at max tier
    final range = maxScore! - minScore + 1;
    final progress = score - minScore;
    return (progress / range).clamp(0.0, 1.0);
  }

  /// Returns points needed for next tier
  int? pointsToNextTier(int score) {
    if (maxScore == null) return null; // Already at max tier
    return maxScore! - score + 1;
  }
}

/// Enum representing the time period for leaderboard
enum LeaderboardPeriod {
  daily('daily', 'Today'),
  weekly('weekly', 'This Week'),
  monthly('monthly', 'This Month'),
  allTime('all_time', 'All Time');

  final String value;
  final String displayName;

  const LeaderboardPeriod(this.value, this.displayName);

  /// Creates a LeaderboardPeriod from a string value
  static LeaderboardPeriod fromString(String? value) {
    if (value == null) return LeaderboardPeriod.allTime;
    return LeaderboardPeriod.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase().replaceAll('-', '_'),
      orElse: () => LeaderboardPeriod.allTime,
    );
  }
}

/// Model representing a single entry in the leaderboard
class LeaderboardEntryModel {
  /// Unique identifier for this entry
  final String? id;

  /// User ID
  final String userId;

  /// Username for display
  final String username;

  /// User's full name (optional)
  final String? fullName;

  /// User's avatar URL
  final String? avatarUrl;

  /// User's score/points
  final int score;

  /// User's rank position (1-based)
  final int rank;

  /// Previous rank position (for showing movement)
  final int? previousRank;

  /// Number of reports submitted
  final int? reportCount;

  /// Number of endorsements received
  final int? endorsementCount;

  /// User's rank tier
  final RankTier tier;

  /// The time period this entry is for
  final LeaderboardPeriod? period;

  /// Whether this is the current user's entry
  final bool isCurrentUser;

  /// Last activity timestamp
  final DateTime? lastActiveAt;

  /// User's city/region
  final String? city;

  /// User's country
  final String? country;

  const LeaderboardEntryModel({
    this.id,
    required this.userId,
    required this.username,
    this.fullName,
    this.avatarUrl,
    required this.score,
    required this.rank,
    this.previousRank,
    this.reportCount,
    this.endorsementCount,
    this.tier = RankTier.bronze,
    this.period,
    this.isCurrentUser = false,
    this.lastActiveAt,
    this.city,
    this.country,
  });

  /// Creates an empty leaderboard entry
  factory LeaderboardEntryModel.empty() {
    return const LeaderboardEntryModel(
      userId: '',
      username: '',
      score: 0,
      rank: 0,
    );
  }

  /// Creates a LeaderboardEntryModel from JSON (snake_case from Django backend)
  ///
  /// Example JSON:
  /// ```json
  /// {
  ///   "id": "entry_123",
  ///   "user_id": "usr_456",
  ///   "username": "eco_warrior",
  ///   "full_name": "John Doe",
  ///   "avatar_url": "https://example.com/avatar.jpg",
  ///   "score": 1500,
  ///   "rank": 5,
  ///   "previous_rank": 7,
  ///   "report_count": 25,
  ///   "endorsement_count": 150,
  ///   "tier": "platinum",
  ///   "period": "monthly",
  ///   "is_current_user": false,
  ///   "last_active_at": "2024-01-09T12:00:00Z",
  ///   "city": "Paris",
  ///   "country": "France"
  /// }
  /// ```
  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    final score = parseIntOrDefault(json['score'] ?? json['points'], 0);
    final tierStr = parseString(json['tier'] ?? json['rank_tier']);

    return LeaderboardEntryModel(
      id: parseString(json['id']),
      userId: parseStringOrDefault(
        json['user_id'] ?? json['userId'] ?? json['user'],
        '',
      ),
      username: parseStringOrDefault(
        json['username'] ?? json['user_name'] ?? json['name'],
        '',
      ),
      fullName: parseString(json['full_name'] ?? json['fullName']),
      avatarUrl: parseString(
        json['avatar_url'] ?? json['avatarUrl'] ?? json['avatar'] ?? json['profile_picture'],
      ),
      score: score,
      rank: parseIntOrDefault(json['rank'] ?? json['position'], 0),
      previousRank: parseInt(json['previous_rank'] ?? json['previousRank']),
      reportCount: parseInt(json['report_count'] ?? json['reportCount'] ?? json['reports']),
      endorsementCount: parseInt(
        json['endorsement_count'] ?? json['endorsementCount'] ?? json['endorsements'],
      ),
      tier: tierStr != null
          ? RankTier.fromString(tierStr)
          : RankTier.fromScore(score),
      period: LeaderboardPeriod.fromString(
        parseString(json['period'] ?? json['time_period']),
      ),
      isCurrentUser: parseBoolOrDefault(
        json['is_current_user'] ?? json['isCurrentUser'] ?? json['is_me'],
        false,
      ),
      lastActiveAt: parseDateTime(json['last_active_at'] ?? json['lastActiveAt']),
      city: parseString(json['city']),
      country: parseString(json['country']),
    );
  }

  /// Safely creates a LeaderboardEntryModel from JSON, returns null if parsing fails
  static LeaderboardEntryModel? tryFromJson(dynamic json) {
    if (json == null) return null;
    if (json is! Map<String, dynamic>) return null;
    try {
      return LeaderboardEntryModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Creates a list of LeaderboardEntryModel from a JSON list
  static List<LeaderboardEntryModel> listFromJson(dynamic json) {
    return parseList(json, LeaderboardEntryModel.fromJson);
  }

  /// Converts the model to JSON (snake_case for Django backend)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'username': username,
      if (fullName != null) 'full_name': fullName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'score': score,
      'rank': rank,
      if (previousRank != null) 'previous_rank': previousRank,
      if (reportCount != null) 'report_count': reportCount,
      if (endorsementCount != null) 'endorsement_count': endorsementCount,
      'tier': tier.value,
      if (period != null) 'period': period!.value,
      'is_current_user': isCurrentUser,
      if (lastActiveAt != null) 'last_active_at': dateTimeToJson(lastActiveAt),
      if (city != null) 'city': city,
      if (country != null) 'country': country,
    };
  }

  /// Creates a copy of this model with optional new values
  LeaderboardEntryModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? fullName,
    String? avatarUrl,
    int? score,
    int? rank,
    int? previousRank,
    int? reportCount,
    int? endorsementCount,
    RankTier? tier,
    LeaderboardPeriod? period,
    bool? isCurrentUser,
    DateTime? lastActiveAt,
    String? city,
    String? country,
  }) {
    return LeaderboardEntryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      score: score ?? this.score,
      rank: rank ?? this.rank,
      previousRank: previousRank ?? this.previousRank,
      reportCount: reportCount ?? this.reportCount,
      endorsementCount: endorsementCount ?? this.endorsementCount,
      tier: tier ?? this.tier,
      period: period ?? this.period,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      city: city ?? this.city,
      country: country ?? this.country,
    );
  }

  // ─── Utility Methods ─────────────────────────────────────────────────────

  /// Returns true if this entry is valid
  bool get isValid => userId.isNotEmpty && username.isNotEmpty;

  /// Returns the display name (full name or username)
  String get displayName => fullName ?? username;

  /// Returns the formatted score with thousand separators
  String get formattedScore {
    return score.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// Returns the ordinal rank string (1st, 2nd, 3rd, etc.)
  String get ordinalRank {
    if (rank <= 0) return '-';
    final suffix = switch (rank % 100) {
      11 || 12 || 13 => 'th',
      _ => switch (rank % 10) {
          1 => 'st',
          2 => 'nd',
          3 => 'rd',
          _ => 'th',
        },
    };
    return '$rank$suffix';
  }

  /// Returns true if the user is in top 3
  bool get isTopThree => rank >= 1 && rank <= 3;

  /// Returns true if the user is in top 10
  bool get isTopTen => rank >= 1 && rank <= 10;

  /// Returns the rank movement compared to previous rank
  int? get rankMovement {
    if (previousRank == null) return null;
    return previousRank! - rank; // Positive = moved up, Negative = moved down
  }

  /// Returns true if rank improved
  bool get rankImproved => rankMovement != null && rankMovement! > 0;

  /// Returns true if rank declined
  bool get rankDeclined => rankMovement != null && rankMovement! < 0;

  /// Returns the rank movement as a display string
  String? get rankMovementDisplay {
    if (rankMovement == null) return null;
    if (rankMovement == 0) return '-';
    if (rankMovement! > 0) return '↑$rankMovement';
    return '↓${rankMovement!.abs()}';
  }

  /// Returns the progress to next tier (0.0 to 1.0)
  double get tierProgress => tier.progressToNext(score);

  /// Returns points needed for next tier
  int? get pointsToNextTier => tier.pointsToNextTier(score);

  /// Returns the location display string
  String? get locationDisplay {
    if (city != null && country != null) return '$city, $country';
    return city ?? country;
  }

  // ─── Equality and Hashing ────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardEntryModel &&
        other.id == id &&
        other.userId == userId &&
        other.username == username &&
        other.score == score &&
        other.rank == rank &&
        other.tier == tier &&
        other.period == period &&
        other.isCurrentUser == isCurrentUser;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      username,
      score,
      rank,
      tier,
      period,
      isCurrentUser,
    );
  }

  @override
  String toString() {
    return 'LeaderboardEntryModel('
        'rank: $ordinalRank, '
        'username: $username, '
        'score: $formattedScore, '
        'tier: ${tier.displayName})';
  }
}

/// Model representing a complete leaderboard with multiple entries
class LeaderboardModel {
  /// List of leaderboard entries
  final List<LeaderboardEntryModel> entries;

  /// The time period for this leaderboard
  final LeaderboardPeriod period;

  /// Total number of participants
  final int totalParticipants;

  /// The current user's entry (if available)
  final LeaderboardEntryModel? currentUserEntry;

  /// When the leaderboard was last updated
  final DateTime? lastUpdatedAt;

  const LeaderboardModel({
    required this.entries,
    this.period = LeaderboardPeriod.allTime,
    this.totalParticipants = 0,
    this.currentUserEntry,
    this.lastUpdatedAt,
  });

  /// Creates an empty leaderboard
  factory LeaderboardModel.empty() {
    return const LeaderboardModel(entries: []);
  }

  /// Creates a LeaderboardModel from JSON
  factory LeaderboardModel.fromJson(Map<String, dynamic> json) {
    final entries = LeaderboardEntryModel.listFromJson(
      json['entries'] ?? json['results'] ?? json['leaderboard'],
    );

    return LeaderboardModel(
      entries: entries,
      period: LeaderboardPeriod.fromString(
        parseString(json['period'] ?? json['time_period']),
      ),
      totalParticipants: parseIntOrDefault(
        json['total_participants'] ?? json['totalParticipants'] ?? json['total'] ?? entries.length,
        entries.length,
      ),
      currentUserEntry: LeaderboardEntryModel.tryFromJson(
        json['current_user'] ?? json['currentUser'] ?? json['me'],
      ),
      lastUpdatedAt: parseDateTime(json['last_updated_at'] ?? json['lastUpdatedAt']),
    );
  }

  /// Safely creates a LeaderboardModel from JSON
  static LeaderboardModel? tryFromJson(dynamic json) {
    if (json == null) return null;
    if (json is! Map<String, dynamic>) return null;
    try {
      return LeaderboardModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'entries': entries.map((e) => e.toJson()).toList(),
      'period': period.value,
      'total_participants': totalParticipants,
      if (currentUserEntry != null) 'current_user': currentUserEntry!.toJson(),
      if (lastUpdatedAt != null) 'last_updated_at': dateTimeToJson(lastUpdatedAt),
    };
  }

  /// Returns the top N entries
  List<LeaderboardEntryModel> topN(int n) {
    return entries.take(n).toList();
  }

  /// Returns the top 3 entries
  List<LeaderboardEntryModel> get topThree => topN(3);

  /// Returns the top 10 entries
  List<LeaderboardEntryModel> get topTen => topN(10);

  /// Returns true if empty
  bool get isEmpty => entries.isEmpty;

  /// Returns true if not empty
  bool get isNotEmpty => entries.isNotEmpty;

  /// Returns the number of entries
  int get length => entries.length;

  @override
  String toString() {
    return 'LeaderboardModel('
        'period: ${period.displayName}, '
        'entries: ${entries.length}, '
        'total: $totalParticipants)';
  }
}
