import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/article_model.dart';

const _base = 'https://marapedia.vercel.app/api';

class ArticleRepository {
  final _db = Supabase.instance.client;

  // ── READS ────────────────────────────────────────────────────────────────────

  Future<List<ArticleModel>> getRecentArticles({int limit = 10}) async {
    final res = await http.get(Uri.parse('$_base/articles?type=recent&limit=$limit'));
    return _parseList(res.body);
  }

  Future<List<ArticleModel>> getMostViewed({int limit = 10}) async {
    final res = await http.get(Uri.parse('$_base/articles?type=viewed&limit=$limit'));
    return _parseList(res.body);
  }

  Future<ArticleModel?> getFeatured() async {
    final res = await http.get(Uri.parse('$_base/articles?type=featured'));
    final list = _parseList(res.body);
    return list.isEmpty ? null : list.first;
  }

  Future<ArticleModel?> getBySlug(String slug) async {
    final res = await http.get(Uri.parse('$_base/articles/$slug'));
    if (res.statusCode == 404) return null;
    return ArticleModel.fromJson(jsonDecode(res.body));
  }

  Future<List<ArticleModel>> getByCategory(String category, {int limit = 30}) async {
    final res = await http.get(Uri.parse('$_base/articles?category=$category&limit=$limit'));
    return _parseList(res.body);
  }

  Future<List<ArticleModel>> search(String query) async {
    final res = await http.get(
        Uri.parse('$_base/articles/search?q=${Uri.encodeComponent(query)}'));
    return _parseList(res.body);
  }

  Future<Map<String, int>> getStats() async {
    final res = await http.get(Uri.parse('$_base/stats'));
    final json = jsonDecode(res.body);
    return {'articles': json['articles'], 'users': json['users']};
  }

  // ── WRITES ───────────────────────────────────────────────────────────────────

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
    String? singer,      // ← NEW
    String? songwriter,  // ← NEW
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

    // Delete first — check error to prevent silent-fail duplication
    final deleteRes =
        await _db.from('images').delete().eq('article_id', articleId);
    // Proceed with insert regardless (delete returns empty on success)
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

  // ── Helpers ──────────────────────────────────────────────────────────────────

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