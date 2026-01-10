import 'package:flutter/foundation.dart';

import 'base/model_utils.dart';
import 'endorsement.dart';
import 'location.dart';
import 'ml_result.dart';
import 'report_image.dart';

/// Enum representing the status of a report
enum ReportStatus {
  pending('pending', 'Pending'),
  verified('verified', 'Verified'),
  inProgress('in_progress', 'In Progress'),
  resolved('resolved', 'Resolved'),
  rejected('rejected', 'Rejected'),
  duplicate('duplicate', 'Duplicate');

  final String value;
  final String displayName;

  const ReportStatus(this.value, this.displayName);

  /// Creates a ReportStatus from a string value
  static ReportStatus fromString(String? value) {
    if (value == null) return ReportStatus.pending;
    final normalized = value.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    return ReportStatus.values.firstWhere(
      (e) => e.value == normalized,
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

/// Enum representing the severity level of a report
enum ReportSeverity {
  low('low', 'Low', 1),
  medium('medium', 'Medium', 2),
  high('high', 'High', 3),
  critical('critical', 'Critical', 4);

  final String value;
  final String displayName;
  final int level;

  const ReportSeverity(this.value, this.displayName, this.level);

  /// Creates a ReportSeverity from a string value
  static ReportSeverity fromString(String? value) {
    if (value == null) return ReportSeverity.medium;
    return ReportSeverity.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => ReportSeverity.medium,
    );
  }

  /// Creates a ReportSeverity from a numeric level
  static ReportSeverity fromLevel(int? level) {
    if (level == null) return ReportSeverity.medium;
    return ReportSeverity.values.firstWhere(
      (e) => e.level == level,
      orElse: () => ReportSeverity.medium,
    );
  }

  /// Returns true if this severity requires urgent attention
  bool get isUrgent => level >= 3;
}

/// Enum representing the type/category of trash reported
enum TrashCategory {
  household('household', 'Household Waste'),
  construction('construction', 'Construction Debris'),
  electronic('electronic', 'E-Waste'),
  hazardous('hazardous', 'Hazardous Materials'),
  organic('organic', 'Organic Waste'),
  plastic('plastic', 'Plastic'),
  metal('metal', 'Metal'),
  glass('glass', 'Glass'),
  mixed('mixed', 'Mixed Waste'),
  other('other', 'Other');

  final String value;
  final String displayName;

  const TrashCategory(this.value, this.displayName);

  /// Creates a TrashCategory from a string value
  static TrashCategory fromString(String? value) {
    if (value == null) return TrashCategory.other;
    return TrashCategory.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => TrashCategory.other,
    );
  }

  /// Returns true if this category requires special handling
  bool get requiresSpecialHandling {
    return this == TrashCategory.hazardous ||
        this == TrashCategory.electronic ||
        this == TrashCategory.construction;
  }

  /// Returns true if this category is recyclable
  bool get isRecyclable {
    return this == TrashCategory.plastic ||
        this == TrashCategory.metal ||
        this == TrashCategory.glass;
  }
}

/// Model representing a trash dump report
class ReportModel {
  /// Unique identifier for this report
  final String id;

  /// Title/headline of the report
  final String title;

  /// Detailed description of the trash dump
  final String? description;

  /// Street name or address description
  final String streetName;

  /// Current status of the report
  final ReportStatus status;

  /// Severity level of the report
  final ReportSeverity severity;

  /// Category of trash
  final TrashCategory category;

  /// Optional observation notes
  final String? observation;

  /// Geographic location of the dump
  final LocationModel location;

  /// Images attached to this report
  final List<ReportImageModel> images;

  /// ML analysis results for the images
  final MLResultModel? mlResult;

  /// Endorsements/votes on this report
  final List<EndorsementModel> endorsements;

  /// ID of the user who created this report
  final String? userId;

  /// Username of the creator
  final String? username;

  /// Avatar URL of the creator
  final String? userAvatarUrl;

  /// Timestamp when the report was created
  final DateTime createdAt;

  /// Timestamp when the report was last updated
  final DateTime? updatedAt;

  /// Timestamp when the report was resolved (if applicable)
  final DateTime? resolvedAt;

  /// Number of endorsements/upvotes
  final int endorsementCount;

  /// Number of views
  final int viewCount;

  /// Estimated size of the dump in square meters
  final double? estimatedSize;

  /// Whether the current user has endorsed this report
  final bool isEndorsedByCurrentUser;

  /// Whether this report belongs to the current user
  final bool isOwnReport;

  /// Tags associated with this report
  final List<String> tags;

  const ReportModel({
    required this.id,
    required this.title,
    this.description,
    required this.streetName,
    this.status = ReportStatus.pending,
    this.severity = ReportSeverity.medium,
    this.category = TrashCategory.mixed,
    this.observation,
    required this.location,
    this.images = const [],
    this.mlResult,
    this.endorsements = const [],
    this.userId,
    this.username,
    this.userAvatarUrl,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.endorsementCount = 0,
    this.viewCount = 0,
    this.estimatedSize,
    this.isEndorsedByCurrentUser = false,
    this.isOwnReport = false,
    this.tags = const [],
  });

  /// Creates an empty report
  factory ReportModel.empty() {
    return ReportModel(
      id: '',
      title: '',
      streetName: '',
      location: LocationModel.empty(),
      createdAt: DateTime.now(),
    );
  }

  /// Creates a new draft report (not yet submitted)
  factory ReportModel.draft({
    required String title,
    String? description,
    required String streetName,
    required LocationModel location,
    List<ReportImageModel> images = const [],
    ReportSeverity severity = ReportSeverity.medium,
    TrashCategory category = TrashCategory.mixed,
  }) {
    return ReportModel(
      id: '',
      title: title,
      description: description,
      streetName: streetName,
      location: location,
      images: images,
      severity: severity,
      category: category,
      status: ReportStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  /// Creates a ReportModel from JSON (snake_case from Django backend)
  ///
  /// Example JSON:
  /// ```json
  /// {
  ///   "id": "rep_123",
  ///   "title": "Large trash dump near park",
  ///   "description": "Illegal dumping site with construction debris",
  ///   "street_name": "123 Main St",
  ///   "status": "verified",
  ///   "severity": "high",
  ///   "category": "construction",
  ///   "observation": "Located near playground, urgent cleanup needed",
  ///   "location": {
  ///     "latitude": 48.8566,
  ///     "longitude": 2.3522,
  ///     "address": "Paris, France"
  ///   },
  ///   "images": [...],
  ///   "ml_result": {...},
  ///   "endorsements": [...],
  ///   "user_id": "usr_456",
  ///   "username": "eco_warrior",
  ///   "user_avatar_url": "https://example.com/avatar.jpg",
  ///   "created_at": "2024-01-09T12:00:00Z",
  ///   "updated_at": "2024-01-10T08:00:00Z",
  ///   "resolved_at": null,
  ///   "endorsement_count": 25,
  ///   "view_count": 150,
  ///   "estimated_size": 15.5,
  ///   "is_endorsed_by_current_user": true,
  ///   "is_own_report": false,
  ///   "tags": ["urgent", "near-school"]
  /// }
  /// ```
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    // Parse location
    LocationModel location;
    final locationJson = json['location'];
    if (locationJson is Map<String, dynamic>) {
      location = LocationModel.fromJson(locationJson);
    } else {
      // Try to parse from flat structure
      location = LocationModel(
        latitude: parseDoubleOrDefault(json['latitude'] ?? json['lat'], 0.0),
        longitude: parseDoubleOrDefault(json['longitude'] ?? json['lng'], 0.0),
        address: parseString(json['address']),
        city: parseString(json['city']),
        country: parseString(json['country']),
      );
    }

    // Parse images
    final images = ReportImageModel.listFromJson(json['images'] ?? json['photos']);

    // Parse ML result
    MLResultModel? mlResult;
    final mlJson = json['ml_result'] ?? json['mlResult'] ?? json['analysis'];
    if (mlJson is Map<String, dynamic>) {
      mlResult = MLResultModel.tryFromJson(mlJson);
    }

    // Parse endorsements
    final endorsements = EndorsementModel.listFromJson(
      json['endorsements'] ?? json['votes'],
    );

    return ReportModel(
      id: parseStringOrDefault(json['id'] ?? json['report_id'], ''),
      title: parseStringOrDefault(json['title'] ?? json['headline'], ''),
      description: parseString(json['description'] ?? json['details']),
      streetName: parseStringOrDefault(
        json['street_name'] ?? json['streetName'] ?? json['address'] ?? json['street'],
        '',
      ),
      status: ReportStatus.fromString(
        parseString(json['status']),
      ),
      severity: ReportSeverity.fromString(
        parseString(json['severity'] ?? json['priority']),
      ),
      category: TrashCategory.fromString(
        parseString(json['category'] ?? json['type'] ?? json['trash_type']),
      ),
      observation: parseString(json['observation'] ?? json['notes']),
      location: location,
      images: images,
      mlResult: mlResult,
      endorsements: endorsements,
      userId: parseString(json['user_id'] ?? json['userId'] ?? json['reporter_id']),
      username: parseString(json['username'] ?? json['user_name'] ?? json['reporter_name']),
      userAvatarUrl: parseString(
        json['user_avatar_url'] ?? json['userAvatarUrl'] ?? json['avatar_url'],
      ),
      createdAt: parseDateTimeOrDefault(
        json['created_at'] ?? json['createdAt'] ?? json['reported_at'],
      ),
      updatedAt: parseDateTime(json['updated_at'] ?? json['updatedAt']),
      resolvedAt: parseDateTime(json['resolved_at'] ?? json['resolvedAt']),
      endorsementCount: parseIntOrDefault(
        json['endorsement_count'] ?? json['endorsementCount'] ??
        json['upvotes'] ?? json['votes_count'] ?? endorsements.length,
        endorsements.length,
      ),
      viewCount: parseIntOrDefault(
        json['view_count'] ?? json['viewCount'] ?? json['views'],
        0,
      ),
      estimatedSize: parseDouble(json['estimated_size'] ?? json['estimatedSize'] ?? json['size']),
      isEndorsedByCurrentUser: parseBoolOrDefault(
        json['is_endorsed_by_current_user'] ?? json['isEndorsedByCurrentUser'] ??
        json['has_endorsed'] ?? json['user_endorsed'],
        false,
      ),
      isOwnReport: parseBoolOrDefault(
        json['is_own_report'] ?? json['isOwnReport'] ?? json['is_owner'],
        false,
      ),
      tags: parseStringList(json['tags'] ?? json['labels']),
    );
  }

  /// Safely creates a ReportModel from JSON, returns null if parsing fails
  static ReportModel? tryFromJson(dynamic json) {
    if (json == null) return null;
    if (json is! Map<String, dynamic>) return null;
    try {
      return ReportModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Creates a list of ReportModel from a JSON list
  static List<ReportModel> listFromJson(dynamic json) {
    return parseList(json, ReportModel.fromJson);
  }

  /// Converts the model to JSON (snake_case for Django backend)
  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'title': title,
      if (description != null) 'description': description,
      'street_name': streetName,
      'status': status.value,
      'severity': severity.value,
      'category': category.value,
      if (observation != null) 'observation': observation,
      'location': location.toJson(),
      'images': images.map((i) => i.toJson()).toList(),
      if (mlResult != null) 'ml_result': mlResult!.toJson(),
      'endorsements': endorsements.map((e) => e.toJson()).toList(),
      if (userId != null) 'user_id': userId,
      if (username != null) 'username': username,
      if (userAvatarUrl != null) 'user_avatar_url': userAvatarUrl,
      'created_at': dateTimeToJson(createdAt),
      if (updatedAt != null) 'updated_at': dateTimeToJson(updatedAt),
      if (resolvedAt != null) 'resolved_at': dateTimeToJson(resolvedAt),
      'endorsement_count': endorsementCount,
      'view_count': viewCount,
      if (estimatedSize != null) 'estimated_size': estimatedSize,
      'is_endorsed_by_current_user': isEndorsedByCurrentUser,
      'is_own_report': isOwnReport,
      'tags': tags,
    };
  }

  /// Converts to JSON for creating a new report (minimal fields)
  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      if (description != null) 'description': description,
      'street_name': streetName,
      'severity': severity.value,
      'category': category.value,
      if (observation != null) 'observation': observation,
      'location': location.toJson(),
      'tags': tags,
    };
  }

  /// Creates a copy of this model with optional new values
  ReportModel copyWith({
    String? id,
    String? title,
    String? description,
    String? streetName,
    ReportStatus? status,
    ReportSeverity? severity,
    TrashCategory? category,
    String? observation,
    LocationModel? location,
    List<ReportImageModel>? images,
    MLResultModel? mlResult,
    List<EndorsementModel>? endorsements,
    String? userId,
    String? username,
    String? userAvatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    int? endorsementCount,
    int? viewCount,
    double? estimatedSize,
    bool? isEndorsedByCurrentUser,
    bool? isOwnReport,
    List<String>? tags,
  }) {
    return ReportModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      streetName: streetName ?? this.streetName,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      category: category ?? this.category,
      observation: observation ?? this.observation,
      location: location ?? this.location,
      images: images ?? this.images,
      mlResult: mlResult ?? this.mlResult,
      endorsements: endorsements ?? this.endorsements,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      endorsementCount: endorsementCount ?? this.endorsementCount,
      viewCount: viewCount ?? this.viewCount,
      estimatedSize: estimatedSize ?? this.estimatedSize,
      isEndorsedByCurrentUser: isEndorsedByCurrentUser ?? this.isEndorsedByCurrentUser,
      isOwnReport: isOwnReport ?? this.isOwnReport,
      tags: tags ?? this.tags,
    );
  }

  // ─── Utility Methods ─────────────────────────────────────────────────────

  /// Returns true if this report is valid (has required fields)
  bool get isValid => id.isNotEmpty && title.isNotEmpty && location.isValid;

  /// Returns true if this is a draft (not yet submitted)
  bool get isDraft => id.isEmpty;

  /// Returns true if this report has images
  bool get hasImages => images.isNotEmpty;

  /// Returns true if this report has ML results
  bool get hasMLResult => mlResult != null;

  /// Returns true if recyclable materials were detected
  bool get hasRecyclables => mlResult?.recyclableDetected ?? false;

  /// Returns the first image URL (for thumbnail)
  String? get thumbnailUrl {
    if (images.isEmpty) return null;
    return images.first.displayUrl;
  }

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

  /// Returns the time since resolution
  Duration? get timeSinceResolution {
    if (resolvedAt == null) return null;
    return DateTime.now().difference(resolvedAt!);
  }

  /// Returns the time to resolution (from creation to resolution)
  Duration? get timeToResolution {
    if (resolvedAt == null) return null;
    return resolvedAt!.difference(createdAt);
  }

  /// Returns the display name of the creator
  String get creatorDisplayName => username ?? 'Anonymous';

  /// Returns true if this report is urgent (high/critical severity and active)
  bool get isUrgent => severity.isUrgent && status.isActive;

  /// Returns true if this report requires special handling
  bool get requiresSpecialHandling => category.requiresSpecialHandling;

  /// Returns the formatted estimated size
  String? get formattedSize {
    if (estimatedSize == null) return null;
    if (estimatedSize! < 1) return '${(estimatedSize! * 100).round()} cm²';
    return '${estimatedSize!.toStringAsFixed(1)} m²';
  }

  /// Returns a short summary of the report
  String get summary {
    final parts = <String>[title];
    if (streetName.isNotEmpty) parts.add(streetName);
    return parts.join(' - ');
  }

  /// Adds an image to the report (returns new instance)
  ReportModel addImage(ReportImageModel image) {
    return copyWith(images: [...images, image]);
  }

  /// Removes an image from the report (returns new instance)
  ReportModel removeImage(ReportImageModel image) {
    return copyWith(images: images.where((i) => i != image).toList());
  }

  /// Adds a tag to the report (returns new instance)
  ReportModel addTag(String tag) {
    if (tags.contains(tag)) return this;
    return copyWith(tags: [...tags, tag]);
  }

  /// Removes a tag from the report (returns new instance)
  ReportModel removeTag(String tag) {
    return copyWith(tags: tags.where((t) => t != tag).toList());
  }

  /// Updates the status (returns new instance)
  ReportModel updateStatus(ReportStatus newStatus) {
    return copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
      resolvedAt: newStatus == ReportStatus.resolved ? DateTime.now() : resolvedAt,
    );
  }

  /// Marks as endorsed by current user (returns new instance)
  ReportModel markAsEndorsed() {
    if (isEndorsedByCurrentUser) return this;
    return copyWith(
      isEndorsedByCurrentUser: true,
      endorsementCount: endorsementCount + 1,
    );
  }

  /// Marks as not endorsed by current user (returns new instance)
  ReportModel markAsNotEndorsed() {
    if (!isEndorsedByCurrentUser) return this;
    return copyWith(
      isEndorsedByCurrentUser: false,
      endorsementCount: (endorsementCount - 1).clamp(0, endorsementCount),
    );
  }

  // ─── Equality and Hashing ────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportModel &&
        other.id == id &&
        other.title == title &&
        other.streetName == streetName &&
        other.status == status &&
        other.severity == severity &&
        other.category == category &&
        other.location == location &&
        listEquals(other.images, images) &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      streetName,
      status,
      severity,
      category,
      location,
      Object.hashAll(images),
      createdAt,
    );
  }

  @override
  String toString() {
    return 'ReportModel('
        'id: $id, '
        'title: $title, '
        'status: ${status.displayName}, '
        'severity: ${severity.displayName}, '
        'location: ${location.displayString}, '
        'images: ${images.length}, '
        'endorsements: $endorsementCount)';
  }
}
