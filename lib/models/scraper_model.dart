class ScraperModel {
  /// The unique identifier of the scraper.
  final int id;

  /// The date and time when the article was published.
  final DateTime publishedDate;

  /// The source of the article.
  final String source;

  /// A brief summary of the article.
  final String summary;

  /// The title of the article.
  final String title;

  /// The URL of the article.
  final String url;

  /// The tags associated with the article.
  final List<String> tags;

  /// Create a new ScraperModel instance.
  ScraperModel({
    required this.id,
    required this.publishedDate,
    required this.source,
    required this.summary,
    required this.title,
    required this.url,
    required this.tags,
  });

  /// Create a new ScraperModel instance from a JSON object.
  factory ScraperModel.fromJson(Map<String, dynamic> json) {
    return ScraperModel(
      id: json['id'],
      publishedDate: DateTime.parse(json['published_date']),
      source: json['source'],
      summary: json['summary'],
      title: json['title'],
      url: json['url'],
      tags: List<String>.from(json['tags']),
    );
  }
}
