// Base utilities for model parsing and conversion
// Handles snake_case from Django backend to camelCase in Flutter

/// Safely parses a value to String
String? parseString(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

/// Safely parses a value to String with a default value
String parseStringOrDefault(dynamic value, [String defaultValue = '']) {
  if (value == null) return defaultValue;
  return value.toString();
}

/// Safely parses a value to int
int? parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Safely parses a value to int with a default value
int parseIntOrDefault(dynamic value, [int defaultValue = 0]) {
  return parseInt(value) ?? defaultValue;
}

/// Safely parses a value to double
double? parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Safely parses a value to double with a default value
double parseDoubleOrDefault(dynamic value, [double defaultValue = 0.0]) {
  return parseDouble(value) ?? defaultValue;
}

/// Safely parses a value to bool
bool? parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == '1' || lower == 'yes') return true;
    if (lower == 'false' || lower == '0' || lower == 'no') return false;
  }
  return null;
}

/// Safely parses a value to bool with a default value
bool parseBoolOrDefault(dynamic value, [bool defaultValue = false]) {
  return parseBool(value) ?? defaultValue;
}

/// Safely parses a value to DateTime
/// Handles ISO 8601 strings and Unix timestamps
DateTime? parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    // Try ISO 8601 format first
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  if (value is int) {
    // Assume Unix timestamp in seconds or milliseconds
    if (value > 10000000000) {
      // Milliseconds
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else {
      // Seconds
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
  }
  return null;
}

/// Safely parses a value to DateTime with a default value
DateTime parseDateTimeOrDefault(dynamic value, [DateTime? defaultValue]) {
  return parseDateTime(value) ?? defaultValue ?? DateTime.now();
}

/// Safely parses a list of items using a factory function
List<T> parseList<T>(
  dynamic value,
  T Function(Map<String, dynamic>) factory,
) {
  if (value == null) return <T>[];
  if (value is! List) return <T>[];

  return value
      .whereType<Map<String, dynamic>>()
      .map((item) {
        try {
          return factory(item);
        } catch (e) {
          return null;
        }
      })
      .whereType<T>()
      .toList();
}

/// Safely parses a list of strings
List<String> parseStringList(dynamic value) {
  if (value == null) return <String>[];
  if (value is! List) return <String>[];
  return value.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
}

/// Safely parses a list of integers
List<int> parseIntList(dynamic value) {
  if (value == null) return <int>[];
  if (value is! List) return <int>[];
  return value.map((e) => parseInt(e)).whereType<int>().toList();
}

/// Converts a DateTime to ISO 8601 string for API
String? dateTimeToJson(DateTime? date) {
  return date?.toUtc().toIso8601String();
}

/// Converts a camelCase string to snake_case
String camelToSnake(String input) {
  return input.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  );
}

/// Converts a snake_case string to camelCase
String snakeToCamel(String input) {
  return input.replaceAllMapped(
    RegExp(r'_([a-z])'),
    (match) => match.group(1)!.toUpperCase(),
  );
}

/// Converts all keys in a map from snake_case to camelCase
Map<String, dynamic> convertKeysToCamel(Map<String, dynamic> map) {
  return map.map((key, value) {
    final newKey = snakeToCamel(key);
    if (value is Map<String, dynamic>) {
      return MapEntry(newKey, convertKeysToCamel(value));
    } else if (value is List) {
      return MapEntry(
        newKey,
        value.map((e) {
          if (e is Map<String, dynamic>) {
            return convertKeysToCamel(e);
          }
          return e;
        }).toList(),
      );
    }
    return MapEntry(newKey, value);
  });
}

/// Converts all keys in a map from camelCase to snake_case
Map<String, dynamic> convertKeysToSnake(Map<String, dynamic> map) {
  return map.map((key, value) {
    final newKey = camelToSnake(key);
    if (value is Map<String, dynamic>) {
      return MapEntry(newKey, convertKeysToSnake(value));
    } else if (value is List) {
      return MapEntry(
        newKey,
        value.map((e) {
          if (e is Map<String, dynamic>) {
            return convertKeysToSnake(e);
          }
          return e;
        }).toList(),
      );
    }
    return MapEntry(newKey, value);
  });
}

/// Extension on Map for easier access
extension MapExtension on Map<String, dynamic> {
  /// Gets a value with snake_case key support
  T? get<T>(String key) {
    // Try camelCase first
    if (containsKey(key)) return this[key] as T?;
    // Try snake_case
    final snakeKey = camelToSnake(key);
    if (containsKey(snakeKey)) return this[snakeKey] as T?;
    return null;
  }
}

