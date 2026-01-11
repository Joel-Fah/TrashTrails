import 'package:flutter/foundation.dart';

import 'base/model_utils.dart';

/// Lightweight user model for public user info in reports and other contexts
///
/// Example JSON from backend:
/// ```json
/// {
///   "id": 5,
///   "username": "joelfah",
///   "first_name": "Joel",
///   "last_name": "Fah",
///   "avatar": "https://..."
/// }
/// ```
class PublicUserModel {
  /// Unique identifier for the user
  final int id;

  /// Username
  final String username;

  /// First name
  final String? firstName;

  /// Last name
  final String? lastName;

  /// Avatar URL
  final String? avatar;

  const PublicUserModel({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.avatar,
  });

  /// Creates an empty/placeholder user model
  factory PublicUserModel.empty() {
    return const PublicUserModel(
      id: 0,
      username: '',
    );
  }

  /// Creates a PublicUserModel from JSON (snake_case from Django backend)
  factory PublicUserModel.fromJson(Map<String, dynamic> json) {
    return PublicUserModel(
      id: parseIntOrDefault(json['id'], 0),
      username: parseStringOrDefault(json['username'], ''),
      firstName: parseString(json['first_name'] ?? json['firstName']),
      lastName: parseString(json['last_name'] ?? json['lastName']),
      avatar: parseString(json['avatar'] ?? json['avatar_url']),
    );
  }

  /// Safely creates a PublicUserModel from JSON, returns null if parsing fails
  static PublicUserModel? tryFromJson(dynamic json) {
    if (json == null) return null;
    if (json is! Map<String, dynamic>) return null;
    try {
      return PublicUserModel.fromJson(json);
    } catch (e) {
      debugPrint('PublicUserModel.tryFromJson error: $e');
      return null;
    }
  }

  /// Converts the model to JSON (snake_case for Django backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (avatar != null) 'avatar': avatar,
    };
  }

  /// Creates a copy of this model with optional new values
  PublicUserModel copyWith({
    int? id,
    String? username,
    String? firstName,
    String? lastName,
    String? avatar,
  }) {
    return PublicUserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatar: avatar ?? this.avatar,
    );
  }

  // ─── Utility Methods ─────────────────────────────────────────────────────

  /// Returns true if this is a valid user
  bool get isValid => id > 0 && username.isNotEmpty;

  /// Returns true if this is empty/placeholder
  bool get isEmpty => id == 0 || username.isEmpty;

  /// Returns true if the user has an avatar
  bool get hasAvatar => avatar != null && avatar!.isNotEmpty;

  /// Gets the full name of the user
  String get fullName {
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) parts.add(firstName!);
    if (lastName != null && lastName!.isNotEmpty) parts.add(lastName!);
    return parts.isNotEmpty ? parts.join(' ') : username;
  }

  /// Gets the display name (full name or username)
  String get displayName {
    final name = fullName;
    return name.isNotEmpty ? name : username;
  }

  /// Gets initials for avatar placeholder
  String get initials {
    if (firstName != null && firstName!.isNotEmpty) {
      if (lastName != null && lastName!.isNotEmpty) {
        return '${firstName![0]}${lastName![0]}'.toUpperCase();
      }
      return firstName![0].toUpperCase();
    }
    return username.isNotEmpty ? username[0].toUpperCase() : '?';
  }

  // ─── Equality and Hashing ────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PublicUserModel &&
        other.id == id &&
        other.username == username;
  }

  @override
  int get hashCode => Object.hash(id, username);

  @override
  String toString() {
    return 'PublicUserModel(id: $id, username: $username, name: $fullName)';
  }
}

