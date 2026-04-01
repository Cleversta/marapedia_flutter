class ArticleTranslationModel {
  final String id;
  final String articleId;
  final String language;
  final String title;
  final String content;
  final String? excerpt;
  final String? thumbnailUrl;

  const ArticleTranslationModel({
    required this.id,
    required this.articleId,
    required this.language,
    required this.title,
    required this.content,
    this.excerpt,
    this.thumbnailUrl,
  });

  factory ArticleTranslationModel.fromJson(Map<String, dynamic> json) =>
    ArticleTranslationModel(
      id: json['id'] ?? '',
      articleId: json['article_id'] ?? '',
      language: json['language'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      excerpt: json['excerpt'],
      thumbnailUrl: json['thumbnail_url'],
    );
}
