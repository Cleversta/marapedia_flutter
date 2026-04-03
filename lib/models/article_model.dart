import 'profile_model.dart';
import 'article_translation_model.dart';

class ArticleImage {
  final String url;
  final String? caption;
  const ArticleImage({required this.url, this.caption});
  factory ArticleImage.fromJson(Map<String, dynamic> j) =>
    ArticleImage(url: j['url'] ?? '', caption: j['caption']);
}

class ArticleModel {
  final String id;
  final String slug;
  final String category;
  final String? articleType;
  final String status;
  final bool featured;
  final int viewCount;
  final String? thumbnailUrl;
  final String? excerpt;
  final String? sourceUrl;
  final String createdAt;
  final String? updatedAt;
  final String? authorId;
  final List<ArticleTranslationModel> translations;
  final ProfileModel? profile;
  final List<ArticleImage> images;

  const ArticleModel({
    required this.id,
    required this.slug,
    required this.category,
    this.articleType,
    required this.status,
    required this.featured,
    required this.viewCount,
    this.thumbnailUrl,
    this.excerpt,
    this.sourceUrl,
    required this.createdAt,
    this.updatedAt,
    this.authorId,
    required this.translations,
    this.profile,
    required this.images,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    final rawTranslations = json['article_translations'];
    final List<ArticleTranslationModel> translations = rawTranslations is List
      ? rawTranslations.map((t) => ArticleTranslationModel.fromJson(Map<String, dynamic>.from(t))).toList()
      : [];

    ProfileModel? profile;
    if (json['profiles'] != null && json['profiles'] is Map) {
      profile = ProfileModel.fromJson(Map<String, dynamic>.from(json['profiles']));
    }

    final rawImages = json['images'];
    final List<ArticleImage> images = rawImages is List
      ? rawImages.map((i) => ArticleImage.fromJson(Map<String, dynamic>.from(i))).toList()
      : [];

    return ArticleModel(
      id: json['id'] ?? '',
      slug: json['slug'] ?? '',
      category: json['category'] ?? 'other',
      articleType: json['article_type'],
      status: json['status'] ?? 'draft',
      featured: json['featured'] == true,
      viewCount: json['view_count'] ?? 0,
      thumbnailUrl: json['thumbnail_url'],
      excerpt: json['excerpt'],
      sourceUrl: json['source_url'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'],
      authorId: json['author_id'],
      translations: translations,
      profile: profile,
      images: images,
    );
  }
}

extension ArticleModelX on ArticleModel {
  Map<String, dynamic> toSimpleMap() => {
    'id': id, 'slug': slug, 'category': category, 'article_type': articleType,
    'status': status, 'featured': featured, 'view_count': viewCount,
    'thumbnail_url': thumbnailUrl, 'excerpt': excerpt,
    'source_url': sourceUrl,
    'created_at': createdAt, 'updated_at': updatedAt, 'author_id': authorId,
    'profiles': profile?.toJson(),
    'article_translations': translations.map((t) => {
      'id': t.id, 'article_id': t.articleId, 'language': t.language,
      'title': t.title, 'content': t.content, 'excerpt': t.excerpt,
    }).toList(),
    'images': images.map((i) => {'url': i.url, 'caption': i.caption}).toList(),
  };
}