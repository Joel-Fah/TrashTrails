// filepath: c:\Users\ROG STRIX\Documents\GitHub\TrashTrails\src\mobile\lib\models\report_location.dart
import 'package:flutter/foundation.dart';

import 'base/model_utils.dart';
import 'location.dart';

/// Model representing a report's location from the backend API
///
/// Example JSON from /api/reports/:
/// ```json
/// {
///   "id": 1,
///   "latitude": 3.87...,
///   "longitude": 11.52...,
///   "street_name": "Rue de la République"
/// }
/// ```
class ReportLocationModel {
  /// Unique identifier for this location
  final int id;

  /// Latitude coordinate
  final double latitude;

  /// Longitude coordinate
  final double longitude;

  /// Optional street name / address
  final String? streetName;

  const ReportLocationModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.streetName,
  });

  /// Creates an empty/default location
  factory ReportLocationModel.empty() {
    return const ReportLocationModel(
      id: 0,
      latitude: 0.0,
      longitude: 0.0,
    );
  }

  /// Creates a ReportLocationModel from JSON (snake_case from Django backend)
  factory ReportLocationModel.fromJson(Map<String, dynamic> json) {
    return ReportLocationModel(
      id: parseIntOrDefault(json['id'], 0),
      latitude: parseDoubleOrDefault(json['latitude'] ?? json['lat'], 0.0),
      longitude: parseDoubleOrDefault(json['longitude'] ?? json['lng'] ?? json['lon'], 0.0),
      streetName: parseString(json['street_name'] ?? json['streetName'] ?? json['address']),
    );
  }

  /// Safely creates a ReportLocationModel from JSON, returns null if parsing fails
  static ReportLocationModel? tryFromJson(dynamic json) {
    if (json == null) return null;
    if (json is! Map<String, dynamic>) return null;
    try {
      return ReportLocationModel.fromJson(json);
    } catch (e) {
      debugPrint('ReportLocationModel.tryFromJson error: $e');
      return null;
    }
  }

  /// Converts the model to JSON (snake_case for Django backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      if (streetName != null) 'street_name': streetName,
    };
  }

  /// Creates a copy of this model with optional new values
  ReportLocationModel copyWith({
    int? id,
    double? latitude,
    double? longitude,
    String? streetName,
  }) {
    return ReportLocationModel(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      streetName: streetName ?? this.streetName,
    );
  }

  /// Returns true if this location has valid coordinates
  bool get isValid => latitude != 0.0 || longitude != 0.0;

  /// Returns true if this location is empty/invalid
  bool get isEmpty => id == 0 && latitude == 0.0 && longitude == 0.0;

  /// Returns true if this location has a street name
  bool get hasStreetName => streetName != null && streetName!.isNotEmpty;

  /// Converts to a generic LocationModel
  LocationModel toLocationModel() {
    return LocationModel(
      latitude: latitude,
      longitude: longitude,
      address: streetName,
    );
  }

  @override
  String toString() {
    return 'ReportLocationModel(id: $id, lat: $latitude, lng: $longitude, street: $streetName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportLocationModel &&
        other.id == id &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.streetName == streetName;
  }

  @override
  int get hashCode {
    return Object.hash(id, latitude, longitude, streetName);
  }
}

