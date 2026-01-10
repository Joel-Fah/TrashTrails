import 'package:trashtrails/models/base/model_utils.dart';

/// User model representing an authenticated user
class UserModel {
  final int id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? avatar;
  final String? phone;
  final String? address;
  final int points;
  final int rank;
  final DateTime? dateJoined;
  final DateTime? lastLogin;
  final bool isActive;
  final bool isVerified;

  const UserModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.avatar,
    this.phone,
    this.address,
    this.points = 0,
    this.rank = 0,
    this.dateJoined,
    this.lastLogin,
    this.isActive = true,
    this.isVerified = false,
  });

  /// Creates an empty UserModel (guest user)
  factory UserModel.empty() => const UserModel(
        id: 0,
        email: '',
      );

  /// Creates a UserModel from JSON (snake_case from backend)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: parseIntOrDefault(json['id']),
      email: parseStringOrDefault(json['email']),
      firstName: parseString(json['first_name']),
      lastName: parseString(json['last_name']),
      avatar: parseString(json['avatar']),
      phone: parseString(json['phone']),
      address: parseString(json['address']),
      points: parseIntOrDefault(json['points']),
      rank: parseIntOrDefault(json['rank']),
      dateJoined: parseDateTime(json['date_joined']),
      lastLogin: parseDateTime(json['last_login']),
      isActive: parseBoolOrDefault(json['is_active'], true),
      isVerified: parseBoolOrDefault(json['is_verified']),
    );
  }

  /// Converts the model to JSON (snake_case for backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'avatar': avatar,
      'phone': phone,
      'address': address,
      'points': points,
      'rank': rank,
      'date_joined': dateJoined?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'is_active': isActive,
      'is_verified': isVerified,
    };
  }

  /// Gets the avatar URL (alias for avatar)
  String? get avatarUrl => avatar;

  /// Gets the full name of the user
  String get fullName {
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) parts.add(firstName!);
    if (lastName != null && lastName!.isNotEmpty) parts.add(lastName!);
    return parts.isNotEmpty ? parts.join(' ') : email;
  }

  /// Gets the display name (full name or email)
  String get displayName {
    if (fullName.isNotEmpty && fullName != email) return fullName;
    return email.split('@').first;
  }

  /// Gets initials for avatar placeholder
  String get initials {
    final name = fullName;
    if (name.isEmpty || name == email) {
      return email.isNotEmpty ? email[0].toUpperCase() : '?';
    }

    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  /// Checks if the user is valid (not empty)
  bool get isValid => id > 0 && email.isNotEmpty;

  /// Checks if the user is a guest
  bool get isGuest => !isValid;

  /// Creates a copy with updated fields
  UserModel copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? avatar,
    String? phone,
    String? address,
    int? points,
    int? rank,
    DateTime? dateJoined,
    DateTime? lastLogin,
    bool? isActive,
    bool? isVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatar: avatar ?? this.avatar,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      points: points ?? this.points,
      rank: rank ?? this.rank,
      dateJoined: dateJoined ?? this.dateJoined,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName, points: $points, rank: $rank)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id && other.email == email;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}

