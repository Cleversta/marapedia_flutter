import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/article_model.dart';

const _fields = '''
  id, slug, category, article_type, status, featured, thumbnail_url,
  view_count, created_at, updated_at, author_id,
  profiles(id, username, avatar_url, role, created_at),
  article_translations(id, article_id, language, title, excerpt, content)
''';

class ArticleRepository {
  final _db = Supabase.instance.client;

  Future<List<ArticleModel>> getRecentArticles({int limit = 10}) async {
    final res = await _db
        .from('articles')
        .select(_fields)
        .eq('status', 'published')
        .order('updated_at', ascending: false)
        .limit(limit);
    return (res as List)
        .map((j) => ArticleModel.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<List<ArticleModel>> getMostViewed({int limit = 10}) async {
    final res = await _db
        .from('articles')
        .select(_fields)
        .eq('status', 'published')
        .order('view_count', ascending: false)
        .limit(limit);
    return (res as List)
        .map((j) => ArticleModel.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<ArticleModel?> getFeatured() async {
    final res = await _db
        .from('articles')
        .select(_fields)
        .eq('status', 'published')
        .eq('featured', true)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (res == null) return null;
    return ArticleModel.fromJson(Map<String, dynamic>.from(res));
  }

  Future<List<ArticleModel>> getByCategory(
    String category, {
    int limit = 30,
  }) async {
    final res = await _db
        .from('articles')
        .select(_fields)
        .eq('status', 'published')
        .eq('category', category)
        .order('updated_at', ascending: false)
        .limit(limit);
    return (res as List)
        .map((j) => ArticleModel.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<ArticleModel?> getBySlug(String slug) async {
    final res = await _db
        .from('articles')
        .select('$_fields, images(url, caption)')
        .eq('slug', slug)
        .maybeSingle();
    if (res == null) return null;
    return ArticleModel.fromJson(Map<String, dynamic>.from(res));
  }

  Future<List<ArticleModel>> search(String query) async {
    final transRes = await _db
        .from('article_translations')
        .select('article_id')
        .or('title.ilike.%$query%,content.ilike.%$query%');
    if ((transRes as List).isEmpty) return [];

    final ids = (transRes as List)
        .map((t) => t['article_id'] as String)
        .toSet()
        .toList();
    final res = await _db
        .from('articles')
        .select(_fields)
        .inFilter('id', ids)
        .eq('status', 'published');
    return (res as List)
        .map((j) => ArticleModel.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

Future<List<ArticleModel>> getMyArticles(String userId) async {
  final res = await _db
      .from('articles')
      .select(_fields)   // ← change '$_fields, article_translations(*)' to just _fields
      .eq('author_id', userId)
      .order('created_at', ascending: false);
  return (res as List)
      .map((j) => ArticleModel.fromJson(Map<String, dynamic>.from(j)))
      .toList();
}
  Future<List<ArticleModel>> getAllArticles() async {
    final res = await _db
        .from('articles')
        .select(_fields)
        .order('created_at', ascending: false);
    return (res as List)
        .map((j) => ArticleModel.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<Map<String, int>> getStats() async {
    final articles = await _db
        .from('articles')
        .select('*')
        .eq('status', 'published')
        .count();
    final users = await _db.from('profiles').select('*').count();
    return {'articles': articles.count, 'users': users.count};
  }

  Future<void> incrementViewCount(String id, int current) async {
    await _db.from('articles').update({'view_count': current + 1}).eq('id', id);
  }

  Future<ArticleModel> createArticle({
    required String slug,
    required String category,
    required String status,
    required String authorId,
    String? thumbnailUrl,
    String? articleType,
  }) async {
    final res = await _db
        .from('articles')
        .insert({
          'slug': slug,
          'category': category,
          'status': status,
          'author_id': authorId,
          'thumbnail_url': thumbnailUrl,
          'article_type': articleType,
        })
        .select()
        .single();
    return ArticleModel.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> upsertTranslation({
    required String articleId,
    required String language,
    required String title,
    required String content,
    required String excerpt,
    required String updatedBy,
  }) async {
    await _db.from('article_translations').upsert({
      'article_id': articleId,
      'language': language,
      'title': title,
      'content': content,
      'excerpt': excerpt,
      'updated_by': updatedBy,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'article_id,language');
  }

  Future<void> updateArticle(String id, Map<String, dynamic> data) async {
    await _db.from('articles').update(data).eq('id', id);
  }

  Future<void> deleteArticle(String id) async {
    await _db.from('articles').delete().eq('id', id);
  }

  Future<void> insertImages(
    String articleId,
    List<Map<String, dynamic>> images,
    String userId,
  ) async {
    if (images.isEmpty) return;
    await _db.from('images').delete().eq('article_id', articleId);
    await _db
        .from('images')
        .insert(
          images
              .map(
                (img) => {
                  'article_id': articleId,
                  'url': img['url'],
                  'caption': img['caption'],
                  'uploaded_by': userId,
                },
              )
              .toList(),
        );
  }
}
