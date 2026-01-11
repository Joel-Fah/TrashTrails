import 'package:flutter/foundation.dart';

import 'base/model_utils.dart';

/// Model representing a trash category from the backend API
///
/// Example JSON from /api/trash-categories/:
/// ```json
/// {
///   "id": "uuid",
///   "code": "plastic",
///   "name": "Plastic",
///   "description": "Plastic waste materials"
/// }
/// ```
class TrashCategoryModel {
  /// Unique identifier (UUID)
  final String id;

  /// Category code (e.g., "plastic", "hazardous")
  final String code;

  /// Display name of the category
  final String name;

  /// Optional description
  final String? description;

  const TrashCategoryModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
  });

  /// Creates an empty/default category
  factory TrashCategoryModel.empty() {
    return const TrashCategoryModel(
      id: '',
      code: 'other',
      name: 'Other',
    );
  }

  /// Creates a TrashCategoryModel from JSON (snake_case from Django backend)
  factory TrashCategoryModel.fromJson(Map<String, dynamic> json) {
    return TrashCategoryModel(
      id: parseStringOrDefault(json['id'], ''),
      code: parseStringOrDefault(json['code'], 'other'),
      name: parseStringOrDefault(json['name'], 'Unknown'),
      description: parseString(json['description']),
    );
  }

  /// Safely creates a TrashCategoryModel from JSON, returns null if parsing fails
  static TrashCategoryModel? tryFromJson(dynamic json) {
    if (json == null) return null;
    if (json is! Map<String, dynamic>) return null;
    try {
      return TrashCategoryModel.fromJson(json);
    } catch (e) {
      debugPrint('TrashCategoryModel.tryFromJson error: $e');
      return null;
    }
  }

  /// Creates a list of TrashCategoryModel from a JSON list
  static List<TrashCategoryModel> listFromJson(dynamic json) {
    if (json == null) return [];
    if (json is! List) return [];
    return json
        .whereType<Map<String, dynamic>>()
        .map((item) {
          try {
            return TrashCategoryModel.fromJson(item);
          } catch (e) {
            debugPrint('TrashCategoryModel.listFromJson item error: $e');
            return null;
          }
        })
        .whereType<TrashCategoryModel>()
        .toList();
  }

  /// Converts the model to JSON (snake_case for Django backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      if (description != null) 'description': description,
    };
  }

  /// Creates a copy of this model with optional new values
  TrashCategoryModel copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
  }) {
    return TrashCategoryModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  // ─── Utility Methods ─────────────────────────────────────────────────────

  /// Returns true if this category is valid
  bool get isValid => id.isNotEmpty && code.isNotEmpty;

  /// Returns true if this is the default/empty category
  bool get isEmpty => id.isEmpty;

  /// Returns true if this category requires special handling
  bool get requiresSpecialHandling {
    return code == 'hazardous' || code == 'electronic' || code == 'construction';
  }

  /// Returns true if this category is recyclable
  bool get isRecyclable {
    return code == 'plastic' || code == 'metal' || code == 'glass';
  }

  /// Returns the display name with code for debugging
  String get debugName => '$name ($code)';

  // ─── Equality and Hashing ────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrashCategoryModel &&
        other.id == id &&
        other.code == code &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, code, name);

  @override
  String toString() {
    return 'TrashCategoryModel(id: $id, code: $code, name: $name)';
  }
}

