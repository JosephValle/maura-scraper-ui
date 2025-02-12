import 'package:maura_scraper_ui/models/scraper_model.dart';

class ScrapersResponse {
  final List<ScraperModel> scrapers;
  final int page;
  final int pageSize;
  final int total;

  ScrapersResponse({
    required this.scrapers,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  bool get hasMore => (page * pageSize) < total;

  factory ScrapersResponse.fromJson(Map<String, dynamic> json) {
    return ScrapersResponse(
      scrapers: (json['articles'] as List)
          .map((article) => ScraperModel.fromJson(article))
          .toList(),
      page: json['page'],
      pageSize: json['page_size'],
      total: json['total'],
    );
  }
}
