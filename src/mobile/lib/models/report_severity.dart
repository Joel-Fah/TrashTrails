import 'package:flutter/foundation.dart';

import 'base/model_utils.dart';

/// Model representing a report severity level from the backend API
///
/// Example JSON from /api/reports/report-severities/:
/// ```json
/// {
///   "id": "uuid",
///   "level": 1,
///   "name": "Low",
///   "description": "Minor issue"
/// }
/// ```
class ReportSeverityModel {
  /// Unique identifier (UUID)
  final String id;

  /// Numeric level (1-4, where 4 is most severe)
  final int level;

  /// Display name of the severity
  final String name;

  /// Optional description
  final String? description;

  const ReportSeverityModel({
    required this.id,
    required this.level,
    required this.name,
    this.description,
  });

  /// Creates an empty/default severity (medium)
  factory ReportSeverityModel.empty() {
    return const ReportSeverityModel(
      id: '',
      level: 2,
      name: 'Medium',
    );
  }

  /// Creates a ReportSeverityModel from JSON (snake_case from Django backend)
  factory ReportSeverityModel.fromJson(Map<String, dynamic> json) {
    return ReportSeverityModel(
      id: parseStringOrDefault(json['id'], ''),
      level: parseIntOrDefault(json['level'], 2),
      name: parseStringOrDefault(json['name'], 'Unknown'),
      description: parseString(json['description']),
    );
  }

  /// Safely creates a ReportSeverityModel from JSON, returns null if parsing fails
  static ReportSeverityModel? tryFromJson(dynamic json) {
    if (json == null) return null;
    if (json is! Map<String, dynamic>) return null;
    try {
      return ReportSeverityModel.fromJson(json);
    } catch (e) {
      debugPrint('ReportSeverityModel.tryFromJson error: $e');
      return null;
    }
  }

  /// Creates a list of ReportSeverityModel from a JSON list
  static List<ReportSeverityModel> listFromJson(dynamic json) {
    if (json == null) return [];
    if (json is! List) return [];
    return json
        .whereType<Map<String, dynamic>>()
        .map((item) {
          try {
            return ReportSeverityModel.fromJson(item);
          } catch (e) {
            debugPrint('ReportSeverityModel.listFromJson item error: $e');
            return null;
          }
        })
        .whereType<ReportSeverityModel>()
        .toList();
  }

  /// Converts the model to JSON (snake_case for Django backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level,
      'name': name,
      if (description != null) 'description': description,
    };
  }

  /// Creates a copy of this model with optional new values
  ReportSeverityModel copyWith({
    String? id,
    int? level,
    String? name,
    String? description,
  }) {
    return ReportSeverityModel(
      id: id ?? this.id,
      level: level ?? this.level,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  // ─── Utility Methods ─────────────────────────────────────────────────────

  /// Returns true if this severity is valid
  bool get isValid => id.isNotEmpty && level >= 1 && level <= 4;

  /// Returns true if this is the default/empty severity
  bool get isEmpty => id.isEmpty;

  /// Returns true if this severity requires urgent attention
  bool get isUrgent => level >= 3;

  /// Returns true if this is a critical severity
  bool get isCritical => level == 4;

  /// Returns true if this is a low severity
  bool get isLow => level == 1;

  /// Returns the lowercase name for comparison
  String get normalizedName => name.toLowerCase();

  /// Returns the display name with level for debugging
  String get debugName => '$name (Level $level)';

  // ─── Equality and Hashing ────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportSeverityModel &&
        other.id == id &&
        other.level == level &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, level, name);

  @override
  String toString() {
    return 'ReportSeverityModel(id: $id, level: $level, name: $name)';
  }
}

