import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/article_model.dart';
import '../services/cache_service.dart';

const _base = 'https://marapedia.vercel.app/api';

class ArticleRepository {
  final _db = Supabase.instance.client;

  // ── Home (combined fetch + cache) ─────────────────────────────────────────

  Future<Map<String, dynamic>> fetchHomeData() async {
    final results = await Future.wait([
      http.get(Uri.parse('$_base/articles?type=recent&limit=10')),
      http.get(Uri.parse('$_base/articles?type=viewed&limit=10')),
      http.get(Uri.parse('$_base/articles?type=featured')),
      http.get(Uri.parse('$_base/stats')),
    ]);

    final recent       = _parseList(results[0].body);
    final mostViewed   = _parseList(results[1].body);
    final featuredList = _parseList(results[2].body);
    final featured     = featuredList.isEmpty ? null : featuredList.first;
    final stats        = jsonDecode(results[3].body);

    final data = <String, dynamic>{
      'featured'    : featured?.toSimpleMap(),
      'recent'      : recent.map((a) => a.toSimpleMap()).toList(),
      'mostViewed'  : mostViewed.map((a) => a.toSimpleMap()).toList(),
      'articleCount': stats['articles'] ?? 0,
      'userCount'   : stats['users'] ?? 0,
    };
    await CacheService.saveHome(data);
    return data;
  }

  Map<String, dynamic>? getCachedHomeData() => CacheService.loadHome();

  // ── Detail ────────────────────────────────────────────────────────────────

  Future<ArticleModel?> getBySlug(String slug) async {
    final res = await http.get(Uri.parse('$_base/articles/$slug'));
    if (res.statusCode == 404) return null;
    final article = ArticleModel.fromJson(jsonDecode(res.body));
    await CacheService.saveDetail(slug, article.toSimpleMap());
    return article;
  }

  ArticleModel? getCachedBySlug(String slug) {
    final data = CacheService.loadDetail(slug);
    if (data == null) return null;
    return ArticleModel.fromJson(data);
  }

  // ── Category ──────────────────────────────────────────────────────────────

  Future<List<ArticleModel>> getByCategory(String category,
      {int limit = 30}) async {
    final res = await http.get(
        Uri.parse('$_base/articles?category=$category&limit=$limit'));
    final articles = _parseList(res.body);
    await CacheService.saveCategory(
        category, articles.map((a) => a.toSimpleMap()).toList());
    return articles;
  }

  List<ArticleModel>? getCachedByCategory(String category) {
    final data = CacheService.loadCategory(category);
    if (data == null) return null;
    return data.map((j) => ArticleModel.fromJson(j)).toList();
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Future<List<ArticleModel>> search(String query) async {
    final res = await http.get(
        Uri.parse('$_base/articles/search?q=${Uri.encodeComponent(query)}'));
    return _parseList(res.body);
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  Future<Map<String, int>> getStats() async {
    final res = await http.get(Uri.parse('$_base/stats'));
    final json = jsonDecode(res.body);
    return {'articles': json['articles'], 'users': json['users']};
  }

  // ── Authenticated / writes ────────────────────────────────────────────────

  Future<List<ArticleModel>> getMyArticles(String userId) async {
    final res = await _db
        .from('articles')
        .select(_fields)
        .eq('author_id', userId)
        .order('created_at', ascending: false);
    return _fromSupabase(res);
  }

  Future<List<ArticleModel>> getAllArticles() async {
    final res = await _db
        .from('articles')
        .select(_fields)
        .order('created_at', ascending: false);
    return _fromSupabase(res);
  }

  Future<void> incrementViewCount(String id) async {
    await http.post(
      Uri.parse('https://marapedia.vercel.app/api/view'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': id}),
    );
  }

  Future<ArticleModel> createArticle({
    required String slug,
    required String category,
    required String status,
    required String authorId,
    String? thumbnailUrl,
    String? articleType,
    String? sourceUrl,
    String? singer,
    String? songwriter,
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
          'source_url': sourceUrl,
          'singer': singer,
          'songwriter': songwriter,
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
    await _db.from('images').insert(
          images
              .map((img) => {
                    'article_id': articleId,
                    'url': img['url'],
                    'caption': img['caption'],
                    'uploaded_by': userId,
                  })
              .toList(),
        );
  }

  // ── Favorites ─────────────────────────────────────────────────────────────

  /// Returns true if the given article is favorited by [userId].
  Future<bool> isFavorited(String articleId, String userId) async {
    final res = await _db
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('article_id', articleId)
        .maybeSingle();
    return res != null;
  }

  /// Fetch all articles favorited by [userId], newest first.
  Future<List<ArticleModel>> getFavorites(String userId) async {
    final res = await _db
        .from('favorites')
        .select('''
          article:articles(
            $_fields
          )
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((row) {
          final articleMap = row['article'];
          if (articleMap == null) return null;
          return ArticleModel.fromJson(
              Map<String, dynamic>.from(articleMap));
        })
        .whereType<ArticleModel>()
        .toList();
  }

  /// Add article to favorites.
  Future<void> addFavorite(String articleId, String userId) async {
    await _db.from('favorites').insert({
      'user_id': userId,
      'article_id': articleId,
    });
  }

  /// Remove article from favorites.
  Future<void> removeFavorite(String articleId, String userId) async {
    await _db
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('article_id', articleId);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<ArticleModel> _parseList(String body) {
    final data = jsonDecode(body);
    if (data is! List) return [];
    return data
        .map((j) => ArticleModel.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  List<ArticleModel> _fromSupabase(List<dynamic> res) {
    return res
        .map((j) => ArticleModel.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }
}

const _fields = '''
  id, slug, category, article_type, status, featured, thumbnail_url,
  source_url, singer, songwriter, view_count, created_at, updated_at, author_id,
  profiles(id, username, avatar_url, role, created_at),
  article_translations(id, article_id, language, title, excerpt, content)
''';