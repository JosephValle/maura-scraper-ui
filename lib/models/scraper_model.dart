class ScraperModel {
  final int id;
  final DateTime publishedDate;
  final String source;
  final String summary;
  final String title;
  final String url;

  ScraperModel({
    required this.id,
    required this.publishedDate,
    required this.source,
    required this.summary,
    required this.title,
    required this.url,
  });

  factory ScraperModel.fromJson(Map<String, dynamic> json) {
    return ScraperModel(
      id: json['id'],
      publishedDate: DateTime.parse(json['published_date']),
      source: json['source'],
      summary: json['summary'],
      title: json['title'],
      url: json['url'],
    );
  }
}
