
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/article_model.dart';
import '../models/profile_model.dart';


class ContributorInfo {
  final ProfileModel profile;
  final int publishedCount;
  final int totalCount;

  const ContributorInfo({
    required this.profile,
    required this.publishedCount,
    required this.totalCount,
  });
}

class ContributorsRepository {
  final _db = Supabase.instance.client;

  /// Fetch all profiles + their article counts, sorted by published desc.
  Future<List<ContributorInfo>> getContributors() async {
    // Fetch profiles
    final profilesRes = await _db
        .from('profiles')
        .select('id, username, full_name, avatar_url, bio, role, created_at')
        .order('created_at', ascending: true);

    final profiles = (profilesRes as List)
        .map((j) => ProfileModel.fromJson(Map<String, dynamic>.from(j)))
        .toList();

    if (profiles.isEmpty) return [];

    // Fetch article counts per author
    final articlesRes = await _db
        .from('articles')
        .select('author_id, status');

    final countMap = <String, Map<String, int>>{};
    for (final row in (articlesRes as List)) {
      final authorId = row['author_id'] as String?;
      if (authorId == null) continue;
      countMap.putIfAbsent(authorId, () => {'total': 0, 'published': 0});
      countMap[authorId]!['total'] = countMap[authorId]!['total']! + 1;
      if (row['status'] == 'published') {
        countMap[authorId]!['published'] = countMap[authorId]!['published']! + 1;
      }
    }

    final contributors = profiles.map((p) {
      final counts = countMap[p.id];
      return ContributorInfo(
        profile: p,
        publishedCount: counts?['published'] ?? 0,
        totalCount: counts?['total'] ?? 0,
      );
    }).toList();

    // Sort: published desc → total desc → username asc
    contributors.sort((a, b) {
      if (b.publishedCount != a.publishedCount) {
        return b.publishedCount.compareTo(a.publishedCount);
      }
      if (b.totalCount != a.totalCount) {
        return b.totalCount.compareTo(a.totalCount);
      }
      return a.profile.username.compareTo(b.profile.username);
    });

    return contributors;
  }

  /// Fetch published articles by a specific author.
  Future<List<ArticleModel>> getArticlesByAuthor(String authorId) async {
    final res = await _db
        .from('articles')
        .select('''
          id, slug, category, article_type, status, featured, thumbnail_url,
          source_url, view_count, created_at, updated_at, author_id,
          profiles(id, username, avatar_url, role, created_at),
          article_translations(id, article_id, language, title, excerpt, content)
        ''')
        .eq('author_id', authorId)
        .eq('status', 'published')
        .order('updated_at', ascending: false);

    return (res as List)
        .map((j) => ArticleModel.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }
}