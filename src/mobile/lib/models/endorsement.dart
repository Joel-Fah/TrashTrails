import 'base/model_utils.dart';

/// Enum representing the type of endorsement
enum EndorsementType {
  upvote('upvote', 'Upvote'),
  confirm('confirm', 'Confirm'),
  flag('flag', 'Flag'),
  report('report', 'Report Issue');

  final String value;
  final String displayName;

  const EndorsementType(this.value, this.displayName);

  /// Creates an EndorsementType from a string value
  static EndorsementType fromString(String? value) {
    if (value == null) return EndorsementType.upvote;
    return EndorsementType.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => EndorsementType.upvote,
    );
  }

  /// Returns true if this is a positive endorsement
  bool get isPositive => this == EndorsementType.upvote || this == EndorsementType.confirm;

  /// Returns true if this is a negative endorsement
  bool get isNegative => this == EndorsementType.flag || this == EndorsementType.report;
}

/// Model representing an endorsement/vote on a report
class EndorsementModel {
  /// Unique identifier for this endorsement
  final String? id;

  /// ID of the report being endorsed
  final String reportId;

  /// ID of the user who made the endorsement
  final String userId;

  /// Username of the user (for display)
  final String? username;

  /// Avatar URL of the user
  final String? userAvatarUrl;

  /// Type of endorsement
  final EndorsementType type;

  /// Optional comment/reason for the endorsement
  final String? comment;

  /// Timestamp when the endorsement was made
  final DateTime endorsedAt;

  /// Whether the endorsement has been moderated/reviewed
  final bool isModerated;

  /// IP address (for moderation, usually not exposed to clients)
  final String? ipAddress;

  const EndorsementModel({
    this.id,
    required this.reportId,
    required this.userId,
    this.username,
    this.userAvatarUrl,
    this.type = EndorsementType.upvote,
    this.comment,
    required this.endorsedAt,
    this.isModerated = false,
    this.ipAddress,
  });

  /// Creates an empty endorsement
  factory EndorsementModel.empty() {
    return EndorsementModel(
      reportId: '',
      userId: '',
      endorsedAt: DateTime.now(),
    );
  }

  /// Creates a quick upvote endorsement
  factory EndorsementModel.upvote({
    required String reportId,
    required String userId,
    String? username,
  }) {
    return EndorsementModel(
      reportId: reportId,
      userId: userId,
      username: username,
      type: EndorsementType.upvote,
      endorsedAt: DateTime.now(),
    );
  }

  /// Creates a confirmation endorsement
  factory EndorsementModel.confirm({
    required String reportId,
    required String userId,
    String? username,
    String? comment,
  }) {
    return EndorsementModel(
      reportId: reportId,
      userId: userId,
      username: username,
      type: EndorsementType.confirm,
      comment: comment,
      endorsedAt: DateTime.now(),
    );
  }

  /// Creates an EndorsementModel from JSON (snake_case from Django backend)
  ///
  /// Example JSON:
  /// ```json
  /// {
  ///   "id": "end_123",
  ///   "report_id": "rep_456",
  ///   "user_id": "usr_789",
  ///   "username": "john_doe",
  ///   "user_avatar_url": "https://example.com/avatar.jpg",
  ///   "type": "upvote",
  ///   "comment": "Confirmed, I saw this too!",
  ///   "endorsed_at": "2024-01-09T12:00:00Z",
  ///   "is_moderated": false
  /// }
  /// ```
  factory EndorsementModel.fromJson(Map<String, dynamic> json) {
    return EndorsementModel(
      id: parseString(json['id']),
      reportId: parseStringOrDefault(
        json['report_id'] ?? json['reportId'] ?? json['report'],
        '',
      ),
      userId: parseStringOrDefault(
        json['user_id'] ?? json['userId'] ?? json['user'],
        '',
      ),
      username: parseString(json['username'] ?? json['user_name']),
      userAvatarUrl: parseString(
        json['user_avatar_url'] ?? json['userAvatarUrl'] ?? json['avatar_url'] ?? json['avatar'],
      ),
      type: EndorsementType.fromString(
        parseString(json['type'] ?? json['endorsement_type']),
      ),
      comment: parseString(json['comment'] ?? json['reason']),
      endorsedAt: parseDateTimeOrDefault(
        json['endorsed_at'] ?? json['endorsedAt'] ?? json['created_at'],
      ),
      isModerated: parseBoolOrDefault(
        json['is_moderated'] ?? json['isModerated'],
        false,
      ),
      ipAddress: parseString(json['ip_address'] ?? json['ipAddress']),
    );
  }

  /// Safely creates an EndorsementModel from JSON, returns null if parsing fails
  static EndorsementModel? tryFromJson(dynamic json) {
    if (json == null) return null;
    if (json is! Map<String, dynamic>) return null;
    try {
      return EndorsementModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Creates a list of EndorsementModel from a JSON list
  static List<EndorsementModel> listFromJson(dynamic json) {
    return parseList(json, EndorsementModel.fromJson);
  }

  /// Converts the model to JSON (snake_case for Django backend)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'report_id': reportId,
      'user_id': userId,
      if (username != null) 'username': username,
      if (userAvatarUrl != null) 'user_avatar_url': userAvatarUrl,
      'type': type.value,
      if (comment != null) 'comment': comment,
      'endorsed_at': dateTimeToJson(endorsedAt),
      'is_moderated': isModerated,
    };
  }

  /// Creates a copy of this model with optional new values
  EndorsementModel copyWith({
    String? id,
    String? reportId,
    String? userId,
    String? username,
    String? userAvatarUrl,
    EndorsementType? type,
    String? comment,
    DateTime? endorsedAt,
    bool? isModerated,
    String? ipAddress,
  }) {
    return EndorsementModel(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      type: type ?? this.type,
      comment: comment ?? this.comment,
      endorsedAt: endorsedAt ?? this.endorsedAt,
      isModerated: isModerated ?? this.isModerated,
      ipAddress: ipAddress ?? this.ipAddress,
    );
  }

  // ─── Utility Methods ─────────────────────────────────────────────────────

  /// Returns true if this endorsement is valid (has required fields)
  bool get isValid => reportId.isNotEmpty && userId.isNotEmpty;

  /// Returns true if this endorsement has a comment
  bool get hasComment => comment != null && comment!.isNotEmpty;

  /// Returns true if this is an upvote
  bool get isUpvote => type == EndorsementType.upvote;

  /// Returns true if this is a confirmation
  bool get isConfirmation => type == EndorsementType.confirm;

  /// Returns true if this is a flag
  bool get isFlag => type == EndorsementType.flag;

  /// Returns the display name for the user
  String get displayName => username ?? 'User $userId';

  /// Returns how long ago this endorsement was made
  Duration get timeAgo => DateTime.now().difference(endorsedAt);

  /// Returns true if this endorsement was made today
  bool get isToday {
    final now = DateTime.now();
    return endorsedAt.year == now.year &&
        endorsedAt.month == now.month &&
        endorsedAt.day == now.day;
  }

  /// Returns true if this endorsement was made by the specified user
  bool isBy(String userId) => this.userId == userId;

  // ─── Equality and Hashing ────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EndorsementModel &&
        other.id == id &&
        other.reportId == reportId &&
        other.userId == userId &&
        other.username == username &&
        other.userAvatarUrl == userAvatarUrl &&
        other.type == type &&
        other.comment == comment &&
        other.endorsedAt == endorsedAt &&
        other.isModerated == isModerated;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      reportId,
      userId,
      username,
      userAvatarUrl,
      type,
      comment,
      endorsedAt,
      isModerated,
    );
  }

  @override
  String toString() {
    return 'EndorsementModel('
        'id: $id, '
        'reportId: $reportId, '
        'userId: $userId, '
        'username: $username, '
        'type: ${type.value}, '
        'endorsedAt: $endorsedAt)';
  }
}
