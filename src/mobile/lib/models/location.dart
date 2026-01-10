import 'dart:math' as math;

import 'base/model_utils.dart';

/// Model representing a geographic location with coordinates and optional address
class LocationModel {
  /// Latitude coordinate (-90 to 90)
  final double latitude;

  /// Longitude coordinate (-180 to 180)
  final double longitude;

  /// Optional human-readable address
  final String? address;

  /// Optional city name
  final String? city;

  /// Optional country name
  final String? country;

  /// Optional postal/zip code
  final String? postalCode;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.country,
    this.postalCode,
  });

  /// Creates an empty/default location (0, 0)
  factory LocationModel.empty() {
    return const LocationModel(latitude: 0.0, longitude: 0.0);
  }

  /// Creates a LocationModel from JSON (snake_case from Django backend)
  ///
  /// Example JSON:
  /// ```json
  /// {
  ///   "latitude": 48.8566,
  ///   "longitude": 2.3522,
  ///   "address": "Paris, France",
  ///   "city": "Paris",
  ///   "country": "France",
  ///   "postal_code": "75001"
  /// }
  /// ```
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: parseDoubleOrDefault(json['latitude'] ?? json['lat'], 0.0),
      longitude: parseDoubleOrDefault(json['longitude'] ?? json['lng'] ?? json['lon'], 0.0),
      address: parseString(json['address']),
      city: parseString(json['city']),
      country: parseString(json['country']),
      postalCode: parseString(json['postal_code'] ?? json['postalCode']),
    );
  }

  /// Safely creates a LocationModel from JSON, returns null if parsing fails
  static LocationModel? tryFromJson(dynamic json) {
    if (json == null) return null;
    if (json is! Map<String, dynamic>) return null;
    try {
      return LocationModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Converts the model to JSON (snake_case for Django backend)
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      if (postalCode != null) 'postal_code': postalCode,
    };
  }

  /// Creates a copy of this model with optional new values
  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? country,
    String? postalCode,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
    );
  }

  // ─── Utility Methods ─────────────────────────────────────────────────────

  /// Returns true if this location has valid coordinates
  bool get isValid {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0.0 && longitude == 0.0);
  }

  /// Returns true if this location is empty (0, 0)
  bool get isEmpty => latitude == 0.0 && longitude == 0.0;

  /// Returns true if this location has a valid address
  bool get hasAddress => address != null && address!.isNotEmpty;

  /// Returns the formatted coordinates as a string
  String get formattedCoordinates {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  /// Returns a short display string (address if available, otherwise coordinates)
  String get displayString {
    if (hasAddress) return address!;
    return formattedCoordinates;
  }

  /// Returns the full address string combining all address components
  String get fullAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.join(', ');
  }

  /// Calculates the distance in kilometers to another location using Haversine formula
  double distanceTo(LocationModel other) {
    const double earthRadius = 6371.0; // km

    final double lat1Rad = latitude * math.pi / 180;
    final double lat2Rad = other.latitude * math.pi / 180;
    final double deltaLatRad = (other.latitude - latitude) * math.pi / 180;
    final double deltaLonRad = (other.longitude - longitude) * math.pi / 180;

    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLonRad / 2) *
            math.sin(deltaLonRad / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Returns a formatted distance string (e.g., "1.5 km" or "500 m")
  String formattedDistanceTo(LocationModel other) {
    final distance = distanceTo(other);
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }

  /// Returns true if this location is within the specified radius (in km) of another location
  bool isWithinRadius(LocationModel center, double radiusKm) {
    return distanceTo(center) <= radiusKm;
  }

  // ─── Equality and Hashing ────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.address == address &&
        other.city == city &&
        other.country == country &&
        other.postalCode == postalCode;
  }

  @override
  int get hashCode {
    return Object.hash(
      latitude,
      longitude,
      address,
      city,
      country,
      postalCode,
    );
  }

  @override
  String toString() {
    return 'LocationModel('
        'latitude: $latitude, '
        'longitude: $longitude, '
        'address: $address, '
        'city: $city, '
        'country: $country, '
        'postalCode: $postalCode)';
  }
}
