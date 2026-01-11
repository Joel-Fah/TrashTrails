import 'package:flutter/foundation.dart';

import 'base/model_utils.dart';
import 'public_user.dart';
import 'report_image.dart';
import 'report_location.dart';
import 'report_severity.dart';
import 'trash_category.dart';

/// Enum representing the status of a report
enum ReportStatus {
  pending('PENDING', 'Pending'),
  verified('VERIFIED', 'Verified'),
  inProgress('IN_PROGRESS', 'In Progress'),
  resolved('RESOLVED', 'Resolved'),
  rejected('REJECTED', 'Rejected'),
  duplicate('DUPLICATE', 'Duplicate');

  final String value;
  final String displayName;

  const ReportStatus(this.value, this.displayName);

  /// Creates a ReportStatus from a string value
  static ReportStatus fromString(String? value) {
    if (value == null) return ReportStatus.pending;
    final normalized = value.toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');
    return ReportStatus.values.firstWhere(
      (e) => e.value == normalized || e.name.toUpperCase() == normalized,
      orElse: () => ReportStatus.pending,
    );
  }

  /// Returns true if this status indicates the report is still active
  bool get isActive {
    return this == ReportStatus.pending ||
        this == ReportStatus.verified ||
        this == ReportStatus.inProgress;
  }

  /// Returns true if this status indicates the report is closed
  bool get isClosed {
    return this == ReportStatus.resolved ||
        this == ReportStatus.rejected ||
        this == ReportStatus.duplicate;
  }

  /// Returns true if this is a positive outcome
  bool get isPositive => this == ReportStatus.resolved;

  /// Returns true if this is a negative outcome
  bool get isNegative => this == ReportStatus.rejected || this == ReportStatus.duplicate;
}

/// Model representing a trash dump report from the backend API
///
/// Example JSON from /api/reports/:
/// ```json
/// {
///   "id": "report-uuid",
///   "title": "Illegal dump behind school",
///   "observation": "Plastic bottles and metal scraps",
///   "status": "PENDING",
///   "severity": {
///     "id": "severity-uuid",
///     "level": 3,
///     "name": "High",
///     "description": "Serious issue"
///   },
///   "category": {
///     "id": "category-uuid",
///     "code": "plastic",
///     "name": "Plastic",
///     "description": "Plastic waste materials"
///   },
///   "location": "location-uuid",
///   "created_at": "2026-01-11T12:34:56Z",
///   "updated_at": "2026-01-11T12:34:56Z"
/// }
/// ```
class ReportModel {
  /// Unique identifier for this report (UUID)
  final String id;

  /// Title/headline of the report
  final String title;

  /// Observation notes about the trash dump
  final String? observation;

  /// Current status of the report
  final ReportStatus status;

  /// Severity level of the report
  final ReportSeverityModel severity;

  /// Category of trash
  final TrashCategoryModel category;

  /// Location object containing coordinates and street name
  final ReportLocationModel? location;

  /// Author/creator of this report (public user info)
  final PublicUserModel? user;

  /// List of images attached to this report
  final List<ReportImageModel> images;

  /// Timestamp when the report was created
  final DateTime createdAt;

  /// Timestamp when the report was last updated
  final DateTime? updatedAt;

  const ReportModel({
    required this.id,
    required this.title,
    this.observation,
    this.status = ReportStatus.pending,
    required this.severity,
    required this.category,
    this.location,
    this.user,
    this.images = const [],
    required this.createdAt,
    this.updatedAt,
  });

  /// Creates an empty report
  factory ReportModel.empty() {
    return ReportModel(
      id: '',
      title: '',
      severity: ReportSeverityModel.empty(),
      category: TrashCategoryModel.empty(),
      createdAt: DateTime.now(),
    );
  }

  /// Creates a ReportModel from JSON (snake_case from Django backend)
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    // Parse severity - can be nested object or just ID
    ReportSeverityModel severity;
    final severityJson = json['severity'];
    if (severityJson is Map<String, dynamic>) {
      severity = ReportSeverityModel.fromJson(severityJson);
    } else {
      // Default severity if not provided
      severity = ReportSeverityModel.empty();
    }

    // Parse category - can be nested object or just ID
    TrashCategoryModel category;
    final categoryJson = json['category'];
    if (categoryJson is Map<String, dynamic>) {
      category = TrashCategoryModel.fromJson(categoryJson);
    } else {
      // Default category if not provided
      category = TrashCategoryModel.empty();
    }

    // Parse images - list of image objects
    final images = ReportImageModel.listFromJson(json['images']);

    // Parse location - can be nested object or null
    final locationJson = json['location'];
    ReportLocationModel? location;
    if (locationJson is Map<String, dynamic>) {
      location = ReportLocationModel.fromJson(locationJson);
    }

    // Parse user - public user info if present
    final user = PublicUserModel.tryFromJson(json['user']);

    return ReportModel(
      id: parseStringOrDefault(json['id'], ''),
      title: parseStringOrDefault(json['title'], ''),
      observation: parseString(json['observation']),
      status: ReportStatus.fromString(parseString(json['status'])),
      severity: severity,
      category: category,
      location: location,
      user: user,
      images: images,
      createdAt: parseDateTimeOrDefault(json['created_at'] ?? json['createdAt']),
      updatedAt: parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  /// Creates a ReportModel from list item JSON (lighter response)
  /// Used when parsing paginated results
  factory ReportModel.fromListJson(Map<String, dynamic> json) {
    // Parse severity - lighter version in list response
    ReportSeverityModel severity;
    final severityJson = json['severity'];
    if (severityJson is Map<String, dynamic>) {
      severity = ReportSeverityModel(
        id: parseStringOrDefault(severityJson['id'], ''),
        level: parseIntOrDefault(severityJson['level'], 2),
        name: parseStringOrDefault(severityJson['name'], 'Unknown'),
        // Description may not be present in list response
      );
    } else {
      severity = ReportSeverityModel.empty();
    }

    // Parse category - lighter version in list response
    TrashCategoryModel category;
    final categoryJson = json['category'];
    if (categoryJson is Map<String, dynamic>) {
      category = TrashCategoryModel(
        id: parseStringOrDefault(categoryJson['id'], ''),
        code: parseStringOrDefault(categoryJson['code'], 'other'),
        name: parseStringOrDefault(categoryJson['name'], 'Unknown'),
        // Description may not be present in list response
      );
    } else {
      category = TrashCategoryModel.empty();
    }

    // Parse location - can be nested object or null
    final locationJson = json['location'];
    ReportLocationModel? location;
    if (locationJson is Map<String, dynamic>) {
      location = ReportLocationModel.fromJson(locationJson);
    }

    // Parse images if present in list response
    final images = ReportImageModel.listFromJson(json['images']);

    // Parse user - public user info if present
    final user = PublicUserModel.tryFromJson(json['user']);

    return ReportModel(
      id: parseStringOrDefault(json['id'], ''),
      title: parseStringOrDefault(json['title'], ''),
      status: ReportStatus.fromString(parseString(json['status'])),
      severity: severity,
      category: category,
      location: location,
      user: user,
      images: images,
      createdAt: parseDateTimeOrDefault(json['created_at'] ?? json['createdAt']),
    );
  }

  /// Safely creates a ReportModel from JSON, returns null if parsing fails
  static ReportModel? tryFromJson(dynamic json) {
    if (json == null) return null;
    if (json is! Map<String, dynamic>) return null;
    try {
      return ReportModel.fromJson(json);
    } catch (e) {
      debugPrint('ReportModel.tryFromJson error: $e');
      return null;
    }
  }

  /// Creates a list of ReportModel from a JSON list (for paginated results)
  static List<ReportModel> listFromJson(dynamic json) {
    if (json == null) return [];
    if (json is! List) return [];
    return json
        .whereType<Map<String, dynamic>>()
        .map((item) {
          try {
            return ReportModel.fromListJson(item);
          } catch (e) {
            debugPrint('ReportModel.listFromJson item error: $e');
            return null;
          }
        })
        .whereType<ReportModel>()
        .toList();
  }

  /// Converts the model to JSON (snake_case for Django backend)
  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'title': title,
      if (observation != null) 'observation': observation,
      'status': status.value,
      'severity': severity.toJson(),
      'category': category.toJson(),
      if (location != null) 'location': location!.toJson(),
      if (images.isNotEmpty) 'images': images.map((img) => img.toJson()).toList(),
      'created_at': dateTimeToJson(createdAt),
      if (updatedAt != null) 'updated_at': dateTimeToJson(updatedAt),
    };
  }

  /// Converts to JSON for creating a new report (minimal fields)
  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      if (observation != null) 'observation': observation,
      'severity': severity.id.isNotEmpty ? severity.id : null,
      'category': category.id.isNotEmpty ? category.id : null,
      if (location != null) 'location': location!.id,
    };
  }

  /// Converts to JSON for updating a report
  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      if (observation != null) 'observation': observation,
      if (severity.id.isNotEmpty) 'severity': severity.id,
      if (category.id.isNotEmpty) 'category': category.id,
    };
  }

  /// Creates a copy of this model with optional new values
  ReportModel copyWith({
    String? id,
    String? title,
    String? observation,
    ReportStatus? status,
    ReportSeverityModel? severity,
    TrashCategoryModel? category,
    ReportLocationModel? location,
    PublicUserModel? user,
    List<ReportImageModel>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      title: title ?? this.title,
      observation: observation ?? this.observation,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      category: category ?? this.category,
      location: location ?? this.location,
      user: user ?? this.user,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Utility Methods ─────────────────────────────────────────────────────

  /// Returns true if this report is valid (has required fields)
  bool get isValid => id.isNotEmpty && title.isNotEmpty;

  /// Returns true if this is a draft (not yet submitted)
  bool get isDraft => id.isEmpty;

  /// Returns true if this report has images
  bool get hasImages => images.isNotEmpty;

  /// Returns the first image URL (for thumbnail)
  String? get thumbnailUrl => images.isNotEmpty ? images.first.displayUrl : null;

  /// Returns the number of images
  int get imageCount => images.length;

  /// Returns how long ago this report was created
  Duration get age => DateTime.now().difference(createdAt);

  /// Returns true if this report was created today
  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }

  /// Returns true if this report was created this week
  bool get isThisWeek {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return createdAt.isAfter(weekAgo);
  }

  /// Returns the display name of severity
  String get severityDisplayName => severity.name;

  /// Returns the severity level
  int get severityLevel => severity.level;

  /// Returns true if this is an urgent report
  bool get isUrgent => severity.isUrgent && status.isActive;

  /// Returns true if this report requires special handling
  bool get requiresSpecialHandling => category.requiresSpecialHandling;

  /// Returns the category display name
  String get categoryDisplayName => category.name;

  /// Returns the category code
  String get categoryCode => category.code;

  /// Returns a short summary of the report
  String get summary {
    final parts = <String>[title];
    if (observation != null && observation!.isNotEmpty) {
      parts.add(observation!);
    }
    return parts.join(' - ');
  }

  /// Returns true if the report has author info
  bool get hasAuthor => user != null && user!.isValid;

  /// Returns the author's display name
  String? get authorDisplayName => user?.displayName;

  /// Returns the author's avatar URL
  String? get authorAvatarUrl => user?.avatar;

  /// Returns the author's initials for avatar placeholder
  String get authorInitials => user?.initials ?? '?';

  /// Updates the status (returns new instance)
  ReportModel updateStatus(ReportStatus newStatus) {
    return copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
  }

  // ─── Equality and Hashing ────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportModel &&
        other.id == id &&
        other.title == title &&
        other.status == status &&
        other.severity == severity &&
        other.category == category &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      status,
      severity,
      category,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'ReportModel('
        'id: $id, '
        'title: $title, '
        'status: ${status.displayName}, '
        'severity: ${severity.name}, '
        'category: ${category.name}, '
        'images: ${images.length})';
  }
}

