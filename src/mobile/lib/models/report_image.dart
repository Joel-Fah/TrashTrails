import 'base/model_utils.dart';

/// Model representing an image attached to a report
class ReportImageModel {
  /// Unique identifier for the image
  final String? id;

  /// URL of the image (can be remote URL or local path)
  final String imageUrl;

  /// Thumbnail URL for optimized loading
  final String? thumbnailUrl;

  /// Original filename of the image
  final String? fileName;

  /// MIME type of the image (e.g., "image/jpeg")
  final String? mimeType;

  /// File size in bytes
  final int? fileSize;

  /// Width of the image in pixels
  final int? width;

  /// Height of the image in pixels
  final int? height;

  /// Timestamp when the image was uploaded
  final DateTime uploadedAt;

  /// Whether the image has been processed by ML
  final bool isProcessed;

  const ReportImageModel({
    this.id,
    required this.imageUrl,
    this.thumbnailUrl,
    this.fileName,
    this.mimeType,
    this.fileSize,
    this.width,
    this.height,
    required this.uploadedAt,
    this.isProcessed = false,
  });

  /// Creates an empty/placeholder image model
  factory ReportImageModel.empty() {
    return ReportImageModel(
      imageUrl: '',
      uploadedAt: DateTime.now(),
    );
  }

  /// Creates a ReportImageModel for a local file (before upload)
  factory ReportImageModel.local({
    required String localPath,
    String? fileName,
    int? fileSize,
  }) {
    return ReportImageModel(
      imageUrl: localPath,
      fileName: fileName,
      fileSize: fileSize,
      uploadedAt: DateTime.now(),
      isProcessed: false,
    );
  }

  /// Creates a ReportImageModel from JSON (snake_case from Django backend)
  ///
  /// Example JSON:
  /// ```json
  /// {
  ///   "id": "img_123",
  ///   "image_url": "https://example.com/image.jpg",
  ///   "thumbnail_url": "https://example.com/thumb.jpg",
  ///   "file_name": "trash_photo.jpg",
  ///   "mime_type": "image/jpeg",
  ///   "file_size": 1024000,
  ///   "width": 1920,
  ///   "height": 1080,
  ///   "uploaded_at": "2024-01-09T12:00:00Z",
  ///   "is_processed": true
  /// }
  /// ```
  factory ReportImageModel.fromJson(Map<String, dynamic> json) {
    return ReportImageModel(
      id: parseString(json['id']),
      imageUrl: parseStringOrDefault(
        json['image_url'] ?? json['imageUrl'] ?? json['url'],
        '',
      ),
      thumbnailUrl: parseString(json['thumbnail_url'] ?? json['thumbnailUrl']),
      fileName: parseString(json['file_name'] ?? json['fileName']),
      mimeType: parseString(json['mime_type'] ?? json['mimeType']),
      fileSize: parseInt(json['file_size'] ?? json['fileSize']),
      width: parseInt(json['width']),
      height: parseInt(json['height']),
      uploadedAt: parseDateTimeOrDefault(
        json['uploaded_at'] ?? json['uploadedAt'] ?? json['created_at'],
      ),
      isProcessed: parseBoolOrDefault(
        json['is_processed'] ?? json['isProcessed'],
        false,
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
      return null;
    }
  }

  /// Creates a list of ReportImageModel from a JSON list
  static List<ReportImageModel> listFromJson(dynamic json) {
    return parseList(json, ReportImageModel.fromJson);
  }

  /// Converts the model to JSON (snake_case for Django backend)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'image_url': imageUrl,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (fileName != null) 'file_name': fileName,
      if (mimeType != null) 'mime_type': mimeType,
      if (fileSize != null) 'file_size': fileSize,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      'uploaded_at': dateTimeToJson(uploadedAt),
      'is_processed': isProcessed,
    };
  }

  /// Creates a copy of this model with optional new values
  ReportImageModel copyWith({
    String? id,
    String? imageUrl,
    String? thumbnailUrl,
    String? fileName,
    String? mimeType,
    int? fileSize,
    int? width,
    int? height,
    DateTime? uploadedAt,
    bool? isProcessed,
  }) {
    return ReportImageModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      width: width ?? this.width,
      height: height ?? this.height,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      isProcessed: isProcessed ?? this.isProcessed,
    );
  }

  // ─── Utility Methods ─────────────────────────────────────────────────────

  /// Returns true if this image has a valid URL
  bool get isValid => imageUrl.isNotEmpty;

  /// Returns true if this is a local file (not yet uploaded)
  bool get isLocal {
    return !imageUrl.startsWith('http://') && !imageUrl.startsWith('https://');
  }

  /// Returns true if this is a remote/uploaded image
  bool get isRemote => !isLocal;

  /// Returns the best URL for display (thumbnail if available, otherwise full)
  String get displayUrl => thumbnailUrl ?? imageUrl;

  /// Returns the file extension from the URL or filename
  String? get extension {
    final name = fileName ?? imageUrl;
    final lastDot = name.lastIndexOf('.');
    if (lastDot == -1 || lastDot == name.length - 1) return null;
    return name.substring(lastDot + 1).toLowerCase();
  }

  /// Returns true if this is a JPEG image
  bool get isJpeg {
    final ext = extension;
    return ext == 'jpg' || ext == 'jpeg' || mimeType == 'image/jpeg';
  }

  /// Returns true if this is a PNG image
  bool get isPng {
    final ext = extension;
    return ext == 'png' || mimeType == 'image/png';
  }

  /// Returns the formatted file size (e.g., "1.5 MB")
  String? get formattedFileSize {
    if (fileSize == null) return null;
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Returns the aspect ratio of the image (width / height)
  double? get aspectRatio {
    if (width == null || height == null || height == 0) return null;
    return width! / height!;
  }

  /// Returns the dimensions as a formatted string (e.g., "1920x1080")
  String? get dimensions {
    if (width == null || height == null) return null;
    return '${width}x$height';
  }

  // ─── Equality and Hashing ────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportImageModel &&
        other.id == id &&
        other.imageUrl == imageUrl &&
        other.thumbnailUrl == thumbnailUrl &&
        other.fileName == fileName &&
        other.mimeType == mimeType &&
        other.fileSize == fileSize &&
        other.width == width &&
        other.height == height &&
        other.uploadedAt == uploadedAt &&
        other.isProcessed == isProcessed;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      imageUrl,
      thumbnailUrl,
      fileName,
      mimeType,
      fileSize,
      width,
      height,
      uploadedAt,
      isProcessed,
    );
  }

  @override
  String toString() {
    return 'ReportImageModel('
        'id: $id, '
        'imageUrl: $imageUrl, '
        'fileName: $fileName, '
        'fileSize: $formattedFileSize, '
        'dimensions: $dimensions, '
        'uploadedAt: $uploadedAt, '
        'isProcessed: $isProcessed)';
  }
}
