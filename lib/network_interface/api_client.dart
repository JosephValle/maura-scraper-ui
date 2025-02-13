import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:maura_scraper_ui/models/response/scrapers_response.dart';

class ApiClient {
  final String _baseUrl = 'https://maura-scraper.onrender.com';
  final Dio _dio = Dio();

  Future<ScrapersResponse> getScrapers({
    required int page,
    int pageSize = 20,
    required List<String> selectedTags,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/articles',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (selectedTags.isNotEmpty)
            'tags': selectedTags.isEmpty ? null : selectedTags,
        },
      );
      print("The example request is: ${response.requestOptions.uri}");
      print("The response is: ${response.data}");
      return ScrapersResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting scrapers: $e');
      rethrow;
    }
  }

  Future<void> runScraper() async {
    try {
      await _dio.post('$_baseUrl/restart');
    } catch (e) {
      debugPrint('Error restarting scraper: $e');
      rethrow;
    }
  }

  Future<List<String>> getTags() async {
    try {
      final response = await _dio.get('$_baseUrl/tags');
      return List<String>.from(response.data);
    } catch (e) {
      debugPrint('Error getting tags: $e');
      return ['Error getting tags'];
    }
  }
}
