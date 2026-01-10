import 'package:flutter/foundation.dart';

import 'base/model_utils.dart';

/// Enum representing the type of waste material detected
enum WasteMaterialType {
  plastic('plastic', 'Plastic'),
  paper('paper', 'Paper'),
  cardboard('cardboard', 'Cardboard'),
  glass('glass', 'Glass'),
  metal('metal', 'Metal'),
  aluminum('aluminum', 'Aluminum'),
  organic('organic', 'Organic'),
  electronic('electronic', 'Electronic'),
  textile('textile', 'Textile'),
  rubber('rubber', 'Rubber'),
  wood('wood', 'Wood'),
  hazardous('hazardous', 'Hazardous'),
  medical('medical', 'Medical'),
  battery('battery', 'Battery'),
  other('other', 'Other');

  final String value;
  final String displayName;

  const WasteMaterialType(this.value, this.displayName);

  /// Creates a WasteMaterialType from a string value
  static WasteMaterialType fromString(String? value) {
    if (value == null) return WasteMaterialType.other;
    return WasteMaterialType.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => WasteMaterialType.other,
    );
  }

  /// Returns true if this material is recyclable
  bool get isRecyclable {
    return [
      WasteMaterialType.plastic,
      WasteMaterialType.paper,
      WasteMaterialType.cardboard,
      WasteMaterialType.glass,
      WasteMaterialType.metal,
      WasteMaterialType.aluminum,
    ].contains(this);
  }

  /// Returns true if this material requires special handling
  bool get requiresSpecialHandling {
    return [
      WasteMaterialType.hazardous,
      WasteMaterialType.medical,
      WasteMaterialType.battery,
      WasteMaterialType.electronic,
    ].contains(this);
  }
}

/// Model representing a detected material with its confidence score
class DetectedMaterial {
  /// Type of material detected
  final WasteMaterialType type;

  /// Raw material name from API
  final String name;

  /// Confidence score for this detection (0.0 to 1.0)
  final double confidence;

  /// Bounding box coordinates [x, y, width, height] (normalized 0-1)
  final List<double>? boundingBox;

  const DetectedMaterial({
    required this.type,
    required this.name,
    required this.confidence,
    this.boundingBox,
  });

  /// Creates a DetectedMaterial from JSON
  factory DetectedMaterial.fromJson(Map<String, dynamic> json) {
    final name = parseStringOrDefault(json['name'] ?? json['material'], '');
    return DetectedMaterial(
      type: WasteMaterialType.fromString(name),
      name: name,
      confidence: parseDoubleOrDefault(
        json['confidence'] ?? json['score'],
        0.0,
      ).clamp(0.0, 1.0),
      boundingBox: _parseBoundingBox(json['bounding_box'] ?? json['boundingBox']),
    );
  }

  static List<double>? _parseBoundingBox(dynamic value) {
    if (value == null) return null;
    if (value is! List) return null;
    final list = value.map((e) => parseDouble(e)).whereType<double>().toList();
    if (list.length != 4) return null;
    return list;
  }

  /// Safely creates a DetectedMaterial from JSON
  static DetectedMaterial? tryFromJson(dynamic json) {
    if (json == null) return null;
    if (json is! Map<String, dynamic>) return null;
    try {
      return DetectedMaterial.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'confidence': confidence,
      if (boundingBox != null) 'bounding_box': boundingBox,
    };
  }

  /// Returns the confidence as a percentage string
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  /// Returns true if this detection has high confidence (>= 0.8)
  bool get isHighConfidence => confidence >= 0.8;

  /// Returns true if this detection has medium confidence (>= 0.5 and < 0.8)
  bool get isMediumConfidence => confidence >= 0.5 && confidence < 0.8;

  /// Returns true if this detection has low confidence (< 0.5)
  bool get isLowConfidence => confidence < 0.5;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetectedMaterial &&
        other.type == type &&
        other.name == name &&
        other.confidence == confidence &&
        listEquals(other.boundingBox, boundingBox);
  }

  @override
  int get hashCode => Object.hash(type, name, confidence, boundingBox);

  @override
  String toString() => 'DetectedMaterial($name: $confidencePercent)';
}

/// Model representing ML analysis results for an image
class MLResultModel {
  /// Unique identifier for this result
  final String? id;

  /// ID of the image that was analyzed
  final String? imageId;

  /// Whether any recyclable materials were detected
  final bool recyclableDetected;

  /// List of detected materials with confidence scores
  final List<DetectedMaterial> detectedMaterials;

  /// Legacy: List of material names (for backward compatibility)
  final List<String> materials;

  /// Overall confidence score for the analysis (0.0 to 1.0)
  final double confidenceScore;

  /// Timestamp when the analysis was performed
  final DateTime analyzedAt;

  /// Processing time in milliseconds
  final int? processingTimeMs;

  /// ML model version used for analysis
  final String? modelVersion;

  /// Any error message from the analysis
  final String? errorMessage;

  const MLResultModel({
    this.id,
    this.imageId,
    required this.recyclableDetected,
    this.detectedMaterials = const [],
    this.materials = const [],
    required this.confidenceScore,
    required this.analyzedAt,
    this.processingTimeMs,
    this.modelVersion,
    this.errorMessage,
  });

  /// Creates an empty/failed result
  factory MLResultModel.empty() {
    return MLResultModel(
      recyclableDetected: false,
      confidenceScore: 0.0,
      analyzedAt: DateTime.now(),
    );
  }

  /// Creates a failed result with an error message
  factory MLResultModel.failed(String error) {
    return MLResultModel(
      recyclableDetected: false,
      confidenceScore: 0.0,
      analyzedAt: DateTime.now(),
      errorMessage: error,
    );
  }

  /// Creates an MLResultModel from JSON (snake_case from Django backend)
  ///
  /// Example JSON:
  /// ```json
  /// {
  ///   "id": "ml_123",
  ///   "image_id": "img_456",
  ///   "recyclable_detected": true,
  ///   "detected_materials": [
  ///     {"name": "plastic", "confidence": 0.95},
  ///     {"name": "paper", "confidence": 0.72}
  ///   ],
  ///   "materials": ["plastic", "paper"],
  ///   "confidence_score": 0.85,
  ///   "analyzed_at": "2024-01-09T12:00:00Z",
  ///   "processing_time_ms": 1500,
  ///   "model_version": "v2.1.0"
  /// }
  /// ```
  factory MLResultModel.fromJson(Map<String, dynamic> json) {
    // Parse detected materials
    List<DetectedMaterial> detectedMaterials = [];
    final materialsJson = json['detected_materials'] ?? json['detectedMaterials'];
    if (materialsJson is List) {
      detectedMaterials = materialsJson
          .map((e) => DetectedMaterial.tryFromJson(e))
          .whereType<DetectedMaterial>()
          .toList();
    }

    // Parse legacy materials list
    List<String> materials = parseStringList(json['materials']);

    // If no detected materials but we have legacy materials, create from them
    if (detectedMaterials.isEmpty && materials.isNotEmpty) {
      detectedMaterials = materials
          .map((m) => DetectedMaterial(
                type: WasteMaterialType.fromString(m),
                name: m,
                confidence: 1.0,
              ))
          .toList();
    }

    return MLResultModel(
      id: parseString(json['id']),
      imageId: parseString(json['image_id'] ?? json['imageId']),
      recyclableDetected: parseBoolOrDefault(
        json['recyclable_detected'] ?? json['recyclableDetected'],
        false,
      ),
      detectedMaterials: detectedMaterials,
      materials: materials.isEmpty
          ? detectedMaterials.map((m) => m.name).toList()
          : materials,
      confidenceScore: parseDoubleOrDefault(
        json['confidence_score'] ?? json['confidenceScore'] ?? json['confidence'],
        0.0,
      ).clamp(0.0, 1.0),
      analyzedAt: parseDateTimeOrDefault(
        json['analyzed_at'] ?? json['analyzedAt'],
      ),
      processingTimeMs: parseInt(json['processing_time_ms'] ?? json['processingTimeMs']),
      modelVersion: parseString(json['model_version'] ?? json['modelVersion']),
      errorMessage: parseString(json['error_message'] ?? json['errorMessage'] ?? json['error']),
    );
  }

  /// Safely creates an MLResultModel from JSON, returns null if parsing fails
  static MLResultModel? tryFromJson(dynamic json) {
    if (json == null) return null;
    if (json is! Map<String, dynamic>) return null;
    try {
      return MLResultModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Converts the model to JSON (snake_case for Django backend)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (imageId != null) 'image_id': imageId,
      'recyclable_detected': recyclableDetected,
      'detected_materials': detectedMaterials.map((m) => m.toJson()).toList(),
      'materials': materials,
      'confidence_score': confidenceScore,
      'analyzed_at': dateTimeToJson(analyzedAt),
      if (processingTimeMs != null) 'processing_time_ms': processingTimeMs,
      if (modelVersion != null) 'model_version': modelVersion,
      if (errorMessage != null) 'error_message': errorMessage,
    };
  }

  /// Creates a copy of this model with optional new values
  MLResultModel copyWith({
    String? id,
    String? imageId,
    bool? recyclableDetected,
    List<DetectedMaterial>? detectedMaterials,
    List<String>? materials,
    double? confidenceScore,
    DateTime? analyzedAt,
    int? processingTimeMs,
    String? modelVersion,
    String? errorMessage,
  }) {
    return MLResultModel(
      id: id ?? this.id,
      imageId: imageId ?? this.imageId,
      recyclableDetected: recyclableDetected ?? this.recyclableDetected,
      detectedMaterials: detectedMaterials ?? this.detectedMaterials,
      materials: materials ?? this.materials,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      modelVersion: modelVersion ?? this.modelVersion,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // ─── Utility Methods ─────────────────────────────────────────────────────

  /// Returns true if this result has any detected materials
  bool get hasMaterials => detectedMaterials.isNotEmpty || materials.isNotEmpty;

  /// Returns true if the analysis was successful (no error)
  bool get isSuccess => errorMessage == null || errorMessage!.isEmpty;

  /// Returns true if the analysis failed
  bool get isFailed => !isSuccess;

  /// Returns the number of detected materials
  int get materialCount => detectedMaterials.isNotEmpty
      ? detectedMaterials.length
      : materials.length;

  /// Returns the confidence score as a percentage string
  String get confidencePercent => '${(confidenceScore * 100).toStringAsFixed(1)}%';

  /// Returns only recyclable materials
  List<DetectedMaterial> get recyclableMaterials {
    return detectedMaterials.where((m) => m.type.isRecyclable).toList();
  }

  /// Returns only non-recyclable materials
  List<DetectedMaterial> get nonRecyclableMaterials {
    return detectedMaterials.where((m) => !m.type.isRecyclable).toList();
  }

  /// Returns materials that require special handling
  List<DetectedMaterial> get specialHandlingMaterials {
    return detectedMaterials.where((m) => m.type.requiresSpecialHandling).toList();
  }

  /// Returns high confidence detections only
  List<DetectedMaterial> get highConfidenceDetections {
    return detectedMaterials.where((m) => m.isHighConfidence).toList();
  }

  /// Returns the material with highest confidence
  DetectedMaterial? get topMaterial {
    if (detectedMaterials.isEmpty) return null;
    return detectedMaterials.reduce((a, b) =>
        a.confidence > b.confidence ? a : b);
  }

  /// Returns the processing time as a formatted string
  String? get formattedProcessingTime {
    if (processingTimeMs == null) return null;
    if (processingTimeMs! < 1000) return '${processingTimeMs}ms';
    return '${(processingTimeMs! / 1000).toStringAsFixed(2)}s';
  }

  /// Returns a summary of detected materials
  String get materialsSummary {
    if (detectedMaterials.isEmpty) return materials.join(', ');
    return detectedMaterials.map((m) => '${m.name} (${m.confidencePercent})').join(', ');
  }

  // ─── Equality and Hashing ────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MLResultModel &&
        other.id == id &&
        other.imageId == imageId &&
        other.recyclableDetected == recyclableDetected &&
        listEquals(other.detectedMaterials, detectedMaterials) &&
        listEquals(other.materials, materials) &&
        other.confidenceScore == confidenceScore &&
        other.analyzedAt == analyzedAt &&
        other.processingTimeMs == processingTimeMs &&
        other.modelVersion == modelVersion &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      imageId,
      recyclableDetected,
      Object.hashAll(detectedMaterials),
      Object.hashAll(materials),
      confidenceScore,
      analyzedAt,
      processingTimeMs,
      modelVersion,
      errorMessage,
    );
  }

  @override
  String toString() {
    return 'MLResultModel('
        'id: $id, '
        'recyclableDetected: $recyclableDetected, '
        'materials: [$materialsSummary], '
        'confidence: $confidencePercent, '
        'analyzedAt: $analyzedAt)';
  }
}
