// filepath: c:\Users\ROG STRIX\Documents\GitHub\TrashTrails\src\mobile\lib\models\report_points.dart
import 'base/model_utils.dart';
import 'report.dart';

/// Model representing the points breakdown for a single field
///
/// Example JSON:
/// ```json
/// {
///   "points": 15,
///   "reason": "Proper descriptive title"
/// }
/// ```
class PointsBreakdownItem {
  /// Points awarded for this item
  final int points;

  /// Reason for the points
  final String reason;

  /// Optional: rarity level (for category)
  final String? rarity;

  /// Optional: multiplier applied (for category)
  final double? multiplier;

  /// Optional: character count (for observation)
  final int? characterCount;

  /// Optional: image count (for images)
  final int? imageCount;

  /// Optional: first image points (for images)
  final int? firstImagePoints;

  /// Optional: additional image points (for images)
  final int? additionalImagePoints;

  const PointsBreakdownItem({
    required this.points,
    required this.reason,
    this.rarity,
    this.multiplier,
    this.characterCount,
    this.imageCount,
    this.firstImagePoints,
    this.additionalImagePoints,
  });

  /// Creates a PointsBreakdownItem from JSON
  factory PointsBreakdownItem.fromJson(Map<String, dynamic> json) {
    return PointsBreakdownItem(
      points: parseInt(json['points']) ?? 0,
      reason: parseString(json['reason']) ?? '',
      rarity: parseString(json['rarity']),
      multiplier: parseDouble(json['multiplier']),
      characterCount: parseInt(json['character_count']),
      imageCount: parseInt(json['image_count']),
      firstImagePoints: parseInt(json['first_image_points']),
      additionalImagePoints: parseInt(json['additional_image_points']),
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'points': points,
      'reason': reason,
      if (rarity != null) 'rarity': rarity,
      if (multiplier != null) 'multiplier': multiplier,
      if (characterCount != null) 'character_count': characterCount,
      if (imageCount != null) 'image_count': imageCount,
      if (firstImagePoints != null) 'first_image_points': firstImagePoints,
      if (additionalImagePoints != null)
        'additional_image_points': additionalImagePoints,
    };
  }

  @override
  String toString() => 'PointsBreakdownItem(points: $points, reason: $reason)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PointsBreakdownItem &&
        other.points == points &&
        other.reason == reason;
  }

  @override
  int get hashCode => points.hashCode ^ reason.hashCode;
}

/// Model representing the full points breakdown
///
/// Example JSON:
/// ```json
/// {
///   "title": {"points": 15, "reason": "Proper descriptive title"},
///   "severity": {"points": 30, "reason": "Severity: Severe (Level 3)"},
///   "category": {"points": 15, "reason": "Category: Plastic (Common)", "rarity": "common", "multiplier": 1.0},
///   "observation": {"points": 25, "reason": "Detailed observation (186 characters)", "character_count": 186},
///   "location": {"points": 20, "reason": "Location provided"},
///   "images": {"points": 40, "reason": "2 image(s) attached", "image_count": 2, "first_image_points": 15, "additional_image_points": 25}
/// }
/// ```
class PointsBreakdown {
  /// Points for title
  final PointsBreakdownItem title;

  /// Points for severity
  final PointsBreakdownItem severity;

  /// Points for category
  final PointsBreakdownItem category;

  /// Points for observation
  final PointsBreakdownItem observation;

  /// Points for location
  final PointsBreakdownItem location;

  /// Points for images
  final PointsBreakdownItem images;

  const PointsBreakdown({
    required this.title,
    required this.severity,
    required this.category,
    required this.observation,
    required this.location,
    required this.images,
  });

  /// Creates a PointsBreakdown from JSON
  factory PointsBreakdown.fromJson(Map<String, dynamic> json) {
    return PointsBreakdown(
      title: PointsBreakdownItem.fromJson(json['title'] ?? {}),
      severity: PointsBreakdownItem.fromJson(json['severity'] ?? {}),
      category: PointsBreakdownItem.fromJson(json['category'] ?? {}),
      observation: PointsBreakdownItem.fromJson(json['observation'] ?? {}),
      location: PointsBreakdownItem.fromJson(json['location'] ?? {}),
      images: PointsBreakdownItem.fromJson(json['images'] ?? {}),
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title.toJson(),
      'severity': severity.toJson(),
      'category': category.toJson(),
      'observation': observation.toJson(),
      'location': location.toJson(),
      'images': images.toJson(),
    };
  }

  /// Returns all breakdown items as a list for iteration
  List<MapEntry<String, PointsBreakdownItem>> get entries => [
    MapEntry('Title', title),
    MapEntry('Severity', severity),
    MapEntry('Category', category),
    MapEntry('Observation', observation),
    MapEntry('Location', location),
    MapEntry('Images', images),
  ];

  @override
  String toString() =>
      'PointsBreakdown(title: $title, severity: $severity, category: $category, observation: $observation, location: $location, images: $images)';
}

/// Model representing the complete points response from a report submission
///
/// Example JSON:
/// ```json
/// {
///   "points_awarded": 145,
///   "breakdown": {...},
///   "total_user_points": 145,
///   "user_rank": 15,
///   "transaction_id": 1
/// }
/// ```
class ReportPointsModel {
  /// Points awarded for this report
  final int pointsAwarded;

  /// Detailed breakdown of points
  final PointsBreakdown breakdown;

  /// Total cumulative points for the user
  final int totalUserPoints;

  /// User's current rank
  final int userRank;

  /// Transaction ID for this points award
  final int transactionId;

  const ReportPointsModel({
    required this.pointsAwarded,
    required this.breakdown,
    required this.totalUserPoints,
    required this.userRank,
    required this.transactionId,
  });

  /// Creates a ReportPointsModel from JSON
  factory ReportPointsModel.fromJson(Map<String, dynamic> json) {
    // Ensure breakdown map exists
    final Map<String, dynamic> breakdownJson = (json['breakdown'] is Map<String, dynamic>)
        ? json['breakdown'] as Map<String, dynamic>
        : <String, dynamic>{};

    // Parse breakdown first
    final PointsBreakdown breakdown = PointsBreakdown.fromJson(breakdownJson);

    // Try multiple possible keys for awarded points
    final dynamic rawPoints = json['points_awarded'] ?? json['points'];
    int pointsAwarded = parseInt(rawPoints) ?? 0;

    // If backend didn't provide points_awarded but breakdown has values, use the sum as fallback
    if (pointsAwarded == 0) {
      final int sumBreakdown = breakdown.title.points +
          breakdown.severity.points +
          breakdown.category.points +
          breakdown.observation.points +
          breakdown.location.points +
          breakdown.images.points;
      if (sumBreakdown > 0) {
        pointsAwarded = sumBreakdown;
      }
    }

    return ReportPointsModel(
      pointsAwarded: pointsAwarded,
      breakdown: breakdown,
      totalUserPoints: parseInt(json['total_user_points'] ?? json['total_points'] ?? json['totalUserPoints']) ?? 0,
      userRank: parseInt(json['user_rank'] ?? json['rank'] ?? json['userRank']) ?? 0,
      transactionId: parseInt(json['transaction_id'] ?? json['transactionId']) ?? 0,
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'points_awarded': pointsAwarded,
      'breakdown': breakdown.toJson(),
      'total_user_points': totalUserPoints,
      'user_rank': userRank,
      'transaction_id': transactionId,
    };
  }

  /// Creates an empty/default ReportPointsModel
  factory ReportPointsModel.empty() {
    return ReportPointsModel(
      pointsAwarded: 0,
      breakdown: PointsBreakdown(
        title: const PointsBreakdownItem(points: 0, reason: ''),
        severity: const PointsBreakdownItem(points: 0, reason: ''),
        category: const PointsBreakdownItem(points: 0, reason: ''),
        observation: const PointsBreakdownItem(points: 0, reason: ''),
        location: const PointsBreakdownItem(points: 0, reason: ''),
        images: const PointsBreakdownItem(points: 0, reason: ''),
      ),
      totalUserPoints: 0,
      userRank: 0,
      transactionId: 0,
    );
  }

  @override
  String toString() =>
      'ReportPointsModel(pointsAwarded: $pointsAwarded, totalUserPoints: $totalUserPoints, userRank: $userRank)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportPointsModel &&
        other.pointsAwarded == pointsAwarded &&
        other.transactionId == transactionId;
  }

  @override
  int get hashCode => pointsAwarded.hashCode ^ transactionId.hashCode;
}

/// Result of creating a report, including the report and points data
class ReportCreationResult {
  /// The created report
  final ReportModel report;

  /// Points awarded for this report (may be null if backend doesn't return points)
  final ReportPointsModel? points;

  /// User rank after creating this report
  final int? overallRank;

  /// Raw response data for additional processing
  final Map<String, dynamic>? rawResponse;

  const ReportCreationResult({
    required this.report,
    this.points,
    this.overallRank,
    this.rawResponse,
  });

  /// Creates a ReportCreationResult from API response JSON
  factory ReportCreationResult.fromJson(Map<String, dynamic> json) {
    // Unwrap 'data' if present
    Map<String, dynamic> payload = json;
    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      payload = json['data'] as Map<String, dynamic>;
    }

    // Determine report JSON
    final Map<String, dynamic> reportJson = (payload.containsKey('report') && payload['report'] is Map<String, dynamic>)
        ? payload['report'] as Map<String, dynamic>
        : (json.containsKey('report') && json['report'] is Map<String, dynamic>)
            ? json['report'] as Map<String, dynamic>
            : payload;

    // Try multiple places for points JSON
    Map<String, dynamic>? pointsJson;
    if (payload.containsKey('points') && payload['points'] is Map<String, dynamic>) {
      pointsJson = payload['points'] as Map<String, dynamic>;
    } else if (payload.containsKey('report_points') && payload['report_points'] is Map<String, dynamic>) {
      pointsJson = payload['report_points'] as Map<String, dynamic>;
    } else if (reportJson.containsKey('points') && reportJson['points'] is Map<String, dynamic>) {
      pointsJson = reportJson['points'] as Map<String, dynamic>;
    } else if (json.containsKey('points') && json['points'] is Map<String, dynamic>) {
      pointsJson = json['points'] as Map<String, dynamic>;
    }

    // Try multiple places for overall rank
    int? overallRank;
    if (payload.containsKey('overall_rank') && payload['overall_rank'] is int) {
      overallRank = payload['overall_rank'] as int;
    } else if (payload.containsKey('overallRank') && payload['overallRank'] is int) {
      overallRank = payload['overallRank'] as int;
    }


    // Build result
    return ReportCreationResult(
      report: ReportModel.fromJson(reportJson),
      points: pointsJson != null ? ReportPointsModel.fromJson(pointsJson) : null,
      overallRank: overallRank,
      rawResponse: json,
    );
  }

  /// Whether points data is available
  bool get hasPoints => points != null;

  @override
  String toString() =>
      'ReportCreationResult(report: ${report.id}, hasPoints: $hasPoints)';
}
