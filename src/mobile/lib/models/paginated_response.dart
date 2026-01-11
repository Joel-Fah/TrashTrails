import 'package:flutter/foundation.dart';

/// Generic model for paginated API responses
///
/// Example JSON:
/// ```json
/// {
///   "count": 12,
///   "next": "/api/reports/?page=2",
///   "previous": null,
///   "results": [...]
/// }
/// ```
class PaginatedResponse<T> {
  /// Total count of items
  final int count;

  /// URL for the next page (null if last page)
  final String? next;

  /// URL for the previous page (null if first page)
  final String? previous;

  /// List of results for current page
  final List<T> results;

  const PaginatedResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  /// Creates an empty paginated response
  factory PaginatedResponse.empty() {
    return PaginatedResponse<T>(
      count: 0,
      results: [],
    );
  }

  /// Creates a PaginatedResponse from JSON with a custom item parser
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    final resultsList = json['results'];
    List<T> parsedResults = [];

    if (resultsList is List) {
      parsedResults = resultsList
          .whereType<Map<String, dynamic>>()
          .map((item) {
            try {
              return itemParser(item);
            } catch (e) {
              debugPrint('PaginatedResponse item parsing error: $e');
              return null;
            }
          })
          .whereType<T>()
          .toList();
    }

    return PaginatedResponse<T>(
      count: (json['count'] as int?) ?? parsedResults.length,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: parsedResults,
    );
  }

  /// Safely creates a PaginatedResponse from JSON, returns empty if parsing fails
  static PaginatedResponse<T> tryFromJson<T>(
    dynamic json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    if (json == null || json is! Map<String, dynamic>) {
      return PaginatedResponse<T>.empty();
    }
    try {
      return PaginatedResponse<T>.fromJson(json, itemParser);
    } catch (e) {
      debugPrint('PaginatedResponse.tryFromJson error: $e');
      return PaginatedResponse<T>.empty();
    }
  }

  // ─── Utility Methods ─────────────────────────────────────────────────────

  /// Returns true if there are more pages after this one
  bool get hasNext => next != null;

  /// Returns true if there are pages before this one
  bool get hasPrevious => previous != null;

  /// Returns true if this is the first page
  bool get isFirstPage => previous == null;

  /// Returns true if this is the last page
  bool get isLastPage => next == null;

  /// Returns true if the response is empty
  bool get isEmpty => results.isEmpty;

  /// Returns true if the response has results
  bool get isNotEmpty => results.isNotEmpty;

  /// Returns the number of results in this page
  int get pageSize => results.length;

  /// Extracts page number from next URL
  int? get nextPage {
    if (next == null) return null;
    final uri = Uri.tryParse(next!);
    if (uri == null) return null;
    final pageParam = uri.queryParameters['page'];
    return pageParam != null ? int.tryParse(pageParam) : null;
  }

  /// Extracts page number from previous URL
  int? get previousPage {
    if (previous == null) return null;
    final uri = Uri.tryParse(previous!);
    if (uri == null) return null;
    final pageParam = uri.queryParameters['page'];
    return pageParam != null ? int.tryParse(pageParam) : null;
  }

  /// Estimates current page number (1-indexed)
  int get currentPage {
    if (previousPage != null) return previousPage! + 1;
    if (nextPage != null) return nextPage! - 1;
    return 1;
  }

  /// Estimates total number of pages
  int get totalPages {
    if (pageSize == 0) return 1;
    return (count / pageSize).ceil();
  }

  /// Creates a new PaginatedResponse with merged results
  PaginatedResponse<T> merge(PaginatedResponse<T> other) {
    return PaginatedResponse<T>(
      count: other.count,
      next: other.next,
      previous: previous,
      results: [...results, ...other.results],
    );
  }

  /// Creates a new PaginatedResponse with transformed results
  PaginatedResponse<R> map<R>(R Function(T) transform) {
    return PaginatedResponse<R>(
      count: count,
      next: next,
      previous: previous,
      results: results.map(transform).toList(),
    );
  }

  /// Creates a new PaginatedResponse with filtered results
  PaginatedResponse<T> where(bool Function(T) test) {
    final filtered = results.where(test).toList();
    return PaginatedResponse<T>(
      count: filtered.length,
      next: next,
      previous: previous,
      results: filtered,
    );
  }

  @override
  String toString() {
    return 'PaginatedResponse(count: $count, pageSize: $pageSize, '
        'hasNext: $hasNext, hasPrevious: $hasPrevious)';
  }
}

