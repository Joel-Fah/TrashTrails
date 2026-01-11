import 'package:flutter/foundation.dart';

import 'base/model_utils.dart';

/// Model representing an image attached to a report
///
/// Example JSON from backend:
/// ```json
/// {
///   "id": "image-uuid",
///   "image": "https://example.com/media/reports/img1.jpg",
///   "uploaded_at": "2026-01-11T12:00:00Z"
/// }
/// ```
class ReportImageModel {
  /// Unique identifier for the image (UUID)
  final String id;

  /// URL of the image
  final String image;

  /// Timestamp when the image was uploaded
  final DateTime uploadedAt;

  const ReportImageModel({
    required this.id,
    required this.image,
    required this.uploadedAt,
  });

  /// Creates an empty/placeholder image model
  factory ReportImageModel.empty() {
    return ReportImageModel(
      id: '',
      image: '',
      uploadedAt: DateTime.now(),
    );
  }

  /// Creates a ReportImageModel from JSON (snake_case from Django backend)
  factory ReportImageModel.fromJson(Map<String, dynamic> json) {
    return ReportImageModel(
      id: parseStringOrDefault(json['id'], ''),
      image: parseStringOrDefault(
        json['image'] ?? json['image_url'] ?? json['imageUrl'] ?? json['url'],
        '',
      ),
      uploadedAt: parseDateTimeOrDefault(
        json['uploaded_at'] ?? json['uploadedAt'],
      ),
    );
  }

  /// Safely creates a ReportImageModel from JSON, returns null if parsing fails
  static ReportImageModel? tryFromJson(dynamic json) {
    if (json == null) return null;
    if (json is! Map<String, dynamic>) return null;
    try {
      return ReportImageModel.fromJson(json);
    } catch (e) {
      debugPrint('ReportImageModel.tryFromJson error: $e');
      return null;
    }
  }

  /// Creates a list of ReportImageModel from a JSON list
  static List<ReportImageModel> listFromJson(dynamic json) {
    if (json == null) return [];
    if (json is! List) return [];
    return json
        .whereType<Map<String, dynamic>>()
        .map((item) {
          try {
            return ReportImageModel.fromJson(item);
          } catch (e) {
            debugPrint('ReportImageModel.listFromJson item error: $e');
            return null;
          }
        })
        .whereType<ReportImageModel>()
        .toList();
  }

  /// Converts the model to JSON (snake_case for Django backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'uploaded_at': dateTimeToJson(uploadedAt),
    };
  }

  /// Creates a copy of this model with optional new values
  ReportImageModel copyWith({
    String? id,
    String? image,
    DateTime? uploadedAt,
  }) {
    return ReportImageModel(
      id: id ?? this.id,
      image: image ?? this.image,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  // ─── Utility Methods ─────────────────────────────────────────────────────

  /// Returns true if this image has a valid URL
  bool get isValid => id.isNotEmpty && image.isNotEmpty;

  /// Returns true if this is empty/placeholder
  bool get isEmpty => id.isEmpty || image.isEmpty;

  /// Returns the image URL for display
  String get displayUrl => image;

  /// Returns true if this is a local file (not yet uploaded)
  bool get isLocal {
    return !image.startsWith('http://') && !image.startsWith('https://');
  }

  /// Returns true if this is a remote/uploaded image
  bool get isRemote => !isLocal;

  // ─── Equality and Hashing ────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportImageModel &&
        other.id == id &&
        other.image == image &&
        other.uploadedAt == uploadedAt;
  }

  @override
  int get hashCode => Object.hash(id, image, uploadedAt);

  @override
  String toString() {
    return 'ReportImageModel(id: $id, image: $image, uploadedAt: $uploadedAt)';
  }
}
