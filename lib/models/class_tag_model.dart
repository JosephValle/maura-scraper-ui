class TagModel {
  final String tag;
  final bool hasArticles;

  TagModel({
    required this.tag,
    required this.hasArticles,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      tag: json['tag'],
      hasArticles: json['has_articles'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'has_articles': hasArticles,
    };
  }
}
