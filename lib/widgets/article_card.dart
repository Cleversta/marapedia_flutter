import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../models/article_model.dart';
import '../utils/helpers.dart';
import '../utils/app_theme.dart';

class ArticleCard extends StatelessWidget {
  final ArticleModel article;
  const ArticleCard({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final cat = Helpers.getCategoryInfo(article.category);
    final translation = Helpers.getPreferredTranslation(
      article.translations
          .map(
            (t) => {
              'language': t.language,
              'title': t.title,
              'content': t.content,
              'excerpt': t.excerpt,
            },
          )
          .toList(),
    );
    if (translation == null) return const SizedBox.shrink();

    final title = translation['title'] as String? ?? '';
    final excerpt =
        translation['excerpt'] as String? ??
        Helpers.makeExcerpt(translation['content'] as String? ?? '');

    // Safe URL — treat empty string same as null
    final thumbUrl = article.thumbnailUrl?.isNotEmpty == true
        ? article.thumbnailUrl
        : null;

    return GestureDetector(
      onTap: () => context.push('/articles/${article.slug}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (thumbUrl != null)
              SizedBox(
                height: 160,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: thumbUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: Colors.grey[100]),
                  errorWidget: (_, _, _) => Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: Text(
                        cat?['icon'] ?? '📁',
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 64,
                width: double.infinity,
                color: Colors.grey[50],
                child: Center(
                  child: Text(
                    cat?['icon'] ?? '📁',
                    style: TextStyle(fontSize: 28, color: Colors.grey[400]),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.greenBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.greenLight),
                    ),
                    child: Text(
                      '${cat?['icon'] ?? ''} ${cat?['label'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.greenDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (excerpt.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      excerpt,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Footer
                  Row(
                    children: [
                      _Avatar(
                        avatarUrl: article.profile?.avatarUrl,
                        username: article.profile?.username,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          article.profile?.username ?? 'Anonymous',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (article.viewCount > 0) ...[
                        const Icon(
                          Icons.remove_red_eye_outlined,
                          size: 11,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${article.viewCount}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        Helpers.timeAgo(article.updatedAt ?? article.createdAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Safe avatar widget — handles null, empty string, and network errors
class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String? username;
  const _Avatar({this.avatarUrl, this.username});

  @override
  Widget build(BuildContext context) {
    final safeUrl = avatarUrl != null && avatarUrl!.isNotEmpty
        ? avatarUrl
        : null;

    if (safeUrl != null) {
      return CircleAvatar(
        radius: 8,
        backgroundColor: AppTheme.greenLight,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: safeUrl,
            width: 16,
            height: 16,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => _initial(username),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 8,
      backgroundColor: AppTheme.greenLight,
      child: _initial(username),
    );
  }

  Widget _initial(String? name) => Text(
    (name ?? 'A')[0].toUpperCase(),
    style: const TextStyle(
      fontSize: 8,
      color: AppTheme.greenDark,
      fontWeight: FontWeight.bold,
    ),
  );
}
