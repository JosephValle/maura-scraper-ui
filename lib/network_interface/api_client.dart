import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:maura_scraper_ui/models/response/scrapers_response.dart';

class ApiClient {
  final String _baseUrl = 'https://maura-scraper.onrender.com';
  final Dio _dio = Dio();

  Future<ScrapersResponse> getScrapers({
    required int page,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/articles',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );
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
}
