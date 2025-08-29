import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:maura_scraper_ui/models/response/scrapers_response.dart';

import '../models/class_tag_model.dart';

/// Lightweight API error to propagate meaningful messages to UI layers.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Responses for /keywords mutations
class KeywordsAddResponse {
  final List<String> added;
  final List<String> skipped;

  KeywordsAddResponse({required this.added, required this.skipped});

  factory KeywordsAddResponse.fromJson(Map<String, dynamic> json) =>
      KeywordsAddResponse(
        added: (json['added'] as List?)?.cast<String>() ?? const [],
        skipped: (json['skipped'] as List?)?.cast<String>() ?? const [],
      );
}

class KeywordsDeleteResponse {
  final List<String> removed;
  final List<String> notFound;

  KeywordsDeleteResponse({required this.removed, required this.notFound});

  factory KeywordsDeleteResponse.fromJson(Map<String, dynamic> json) =>
      KeywordsDeleteResponse(
        removed: (json['removed'] as List?)?.cast<String>() ?? const [],
        notFound: (json['not_found'] as List?)?.cast<String>() ?? const [],
      );
}

/// Single, testable API client that mirrors the provided Flask server.
/// Endpoints:
/// - GET    /articles
/// - POST   /restart
/// - GET    /tags
/// - PUT    /tags   (or POST)
/// - GET    /keywords
/// - POST   /keywords
/// - DELETE /keywords
/// - DELETE /keywords/{value}
class ApiClient {
  /// Default comes from `--dart-define=API_BASE_URL=...` if provided.
  final String baseUrl;

  /// Exposed for advanced customization/testing, but generally keep private.
  final Dio dio;

  ApiClient({
    String? baseUrl,
    Dio? dio,
    Duration connectTimeout = const Duration(minutes: 2),
    Duration receiveTimeout = const Duration(seconds: 20),
  })  : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'https://maura-scraper.onrender.com',
            ),
        dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: connectTimeout,
                receiveTimeout: receiveTimeout,
                responseType: ResponseType.json,
                // Note: We set the baseUrl here to keep calls concise.
                baseUrl: baseUrl ??
                    const String.fromEnvironment(
                      'API_BASE_URL',
                      defaultValue: 'https://maura-scraper.onrender.com',
                    ),
                headers: const {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    // Minimal logging in debug builds.
    if (kDebugMode) {
      this.dio.interceptors.add(
            LogInterceptor(
              request: true,
              requestBody: true,
              requestHeader: false,
              responseHeader: false,
              responseBody: false,
              error: true,
            ),
          );
    }
  }

  // ----------------------
  // Articles
  // ----------------------

  /// Mirrors GET /articles with support for multiple 'tags' params.
  ///
  /// Server expects repeated `tags` query keys:
  ///   /articles?tags=foo&tags=bar
  ///
  /// We enforce ListFormat.multi to match Flask's `getlist('tags')` parsing.
  Future<ScrapersResponse> getArticles({
    required int page,
    int pageSize = 20,
    List<String> selectedTags = const [],
    CancelToken? cancelToken,
  }) async {
    try {
      // Normalize tags to avoid blanks and stray whitespace
      final List<String> normTags = selectedTags
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(growable: false);

      // Basic guards
      final int safePage = page < 1 ? 1 : page;
      final int safePageSize =
          pageSize.clamp(1, 500); // adjust upper bound as you like

      final resp = await dio.post<Map<String, dynamic>>(
        '/articles/search',
        data: {
          'page': safePage,
          'page_size': safePageSize,
          if (normTags.isNotEmpty) 'tags': normTags,
        },
        cancelToken: cancelToken,
      );

      final data = resp.data;
      if (data == null) {
        throw ApiException(
          'Empty response body from /articles',
          statusCode: resp.statusCode,
        );
      }
      return ScrapersResponse.fromJson(data);
    } on DioException catch (e) {
      throw _asApiException(e, fallback: 'Failed to load articles');
    }
  }

  // ----------------------
  // Maintenance
  // ----------------------

  /// Mirrors POST /restart; returns true if 200.
  Future<bool> restartScraper({CancelToken? cancelToken}) async {
    try {
      final resp = await dio.post<Map<String, dynamic>>(
        '/restart',
        cancelToken: cancelToken,
      );
      return resp.statusCode == 200;
    } on DioException catch (e) {
      throw _asApiException(e, fallback: 'Failed to restart scraper');
    }
  }

  // ----------------------
  // Tags (canonical list)
  // ----------------------

  /// GET /tags?include_has_articles=1 → [{tag, has_articles}, ...]
  Future<List<TagModel>> getTags({CancelToken? cancelToken}) async {
    try {
      final resp = await dio.get<dynamic>(
        '/tags',
        queryParameters: {'include_has_articles': 1},
        cancelToken: cancelToken,
      );

      final body = resp.data;

      // Expected shape: List<Map<String, dynamic>>
      if (body is List) {
        if (body.isEmpty) return <TagModel>[];
        final first = body.first;
        if (first is Map<String, dynamic>) {
          return body
              .cast<Map<String, dynamic>>()
              .map((e) => TagModel.fromJson(e))
              .toList();
        }
      }

      // If server accidentally returned the legacy array of strings,
      // degrade gracefully (hasArticles=false). This protects callers.
      if (body is List && (body.isEmpty || body.first is String)) {
        final tagModels = body
            .cast<String>()
            .map((t) => TagModel(tag: t.toLowerCase(), hasArticles: false));
        final unique = <String, TagModel>{};
        for (final tag in tagModels) {
          unique[tag.tag] = tag;
        }
        return unique.values.toList();
      }

      throw ApiException('Unexpected /tags enriched payload shape', data: body);
    } on DioException catch (e) {
      throw _asApiException(
        e,
        fallback: 'Failed to load tags with article status',
      );
    }
  }

  /// PUT/POST /tags?include_has_articles=1
  /// Returns: [{ "tag": "...", "has_articles": bool }, ...]
  Future<List<TagModel>> setTagsAndGetModels(
    List<String> tags, {
    CancelToken? cancelToken,
    bool usePost = false,
  }) async {
    try {
      final method = usePost ? dio.post<dynamic> : dio.put<dynamic>;

      final resp = await method(
        '/tags',
        queryParameters: {'include_has_articles': 1},
        data: jsonEncode({'tags': tags}),
        cancelToken: cancelToken,
      );

      final body = resp.data;

      // Preferred shape: List<Map<String,dynamic>>
      if (body is List) {
        if (body.isEmpty) return <TagModel>[];
        final first = body.first;
        if (first is Map<String, dynamic>) {
          return body
              .cast<Map<String, dynamic>>()
              .map((e) => TagModel.fromJson(e))
              .toList();
        }
        // If server sent back a list of strings, degrade (hasArticles=false)
        if (first is String) {
          return body
              .cast<String>()
              .map((t) => TagModel(tag: t, hasArticles: false))
              .toList();
        }
      }

      // If server returned the legacy {"tags":[...]} shape, degrade gracefully
      if (body is Map && body['tags'] is List) {
        final tagsList = (body['tags'] as List).cast<String>();
        // Lowercase and create TagModels
        final tagModels = tagsList
            .map((t) => TagModel(tag: t.toLowerCase(), hasArticles: false));
        // Deduplicate by tag
        final unique = <String, TagModel>{};
        for (final tag in tagModels) {
          unique[tag.tag] = tag;
        }
        return unique.values.toList();
      }

      throw ApiException('Unexpected enriched /tags response', data: body);
    } on DioException catch (e) {
      throw _asApiException(e, fallback: 'Failed to set tags (enriched)');
    }
  }

  // ----------------------
  // Keywords CRUD
  // ----------------------

  /// GET /keywords → all keywords (lowercased, canonical DB form)
  Future<List<String>> listKeywords({CancelToken? cancelToken}) async {
    try {
      final resp = await dio.get<dynamic>(
        '/keywords',
        cancelToken: cancelToken,
      );
      final body = resp.data;
      if (body is List) return body.cast<String>();
      throw ApiException('Unexpected /keywords response', data: body);
    } on DioException catch (e) {
      throw _asApiException(e, fallback: 'Failed to list keywords');
    }
  }

  /// POST /keywords with a single keyword.
  Future<KeywordsAddResponse> addKeyword(
    String keyword, {
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await dio.post<Map<String, dynamic>>(
        '/keywords',
        data: jsonEncode({'keyword': keyword}),
        cancelToken: cancelToken,
      );
      final data = resp.data;
      if (data == null) {
        throw ApiException('Empty response from /keywords');
      }
      return KeywordsAddResponse.fromJson(data);
    } on DioException catch (e) {
      throw _asApiException(e, fallback: 'Failed to add keyword');
    }
  }

  /// POST /keywords with multiple keywords.
  Future<KeywordsAddResponse> addKeywords(
    List<String> keywords, {
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await dio.post<Map<String, dynamic>>(
        '/keywords',
        data: jsonEncode({'keywords': keywords}),
        cancelToken: cancelToken,
      );
      final data = resp.data;
      if (data == null) {
        throw ApiException('Empty response from /keywords');
      }
      return KeywordsAddResponse.fromJson(data);
    } on DioException catch (e) {
      throw _asApiException(e, fallback: 'Failed to add keywords');
    }
  }

  /// DELETE /keywords with a JSON body: {"keywords": [...]}
  Future<KeywordsDeleteResponse> deleteKeywordsBulk(
    List<String> keywords, {
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await dio.delete<Map<String, dynamic>>(
        '/keywords',
        data: jsonEncode({'keywords': keywords}),
        cancelToken: cancelToken,
      );
      final data = resp.data;
      if (data == null) {
        throw ApiException('Empty response from DELETE /keywords');
      }
      return KeywordsDeleteResponse.fromJson(data);
    } on DioException catch (e) {
      throw _asApiException(e, fallback: 'Failed to delete keywords');
    }
  }

  /// DELETE /keywords/{value}
  Future<KeywordsDeleteResponse> deleteKeywordSingle(
    String value, {
    CancelToken? cancelToken,
  }) async {
    try {
      final encoded = Uri.encodeComponent(value);
      final resp = await dio.delete<Map<String, dynamic>>(
        '/keywords/$encoded',
        cancelToken: cancelToken,
      );
      final data = resp.data;
      if (data == null) {
        throw ApiException('Empty response from DELETE /keywords/<value>');
      }
      return KeywordsDeleteResponse.fromJson(data);
    } on DioException catch (e) {
      throw _asApiException(e, fallback: 'Failed to delete keyword "$value"');
    }
  }

  // ----------------------
  // Internal helpers
  // ----------------------

  ApiException _asApiException(DioException e, {String? fallback}) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    // Prefer server-provided messages when available.
    String message;
    if (data is Map && data['error'] is String) {
      message = data['error'] as String;
    } else if (data is Map && data['message'] is String) {
      message = data['message'] as String;
    } else if (e.message != null && e.message!.isNotEmpty) {
      message = e.message!;
    } else {
      message = fallback ?? 'Request failed';
    }

    if (kDebugMode) {
      debugPrint('ApiException: $status $message');
      if (data != null) debugPrint('Payload: $data');
    }

    return ApiException(message, statusCode: status, data: data);
  }
}
