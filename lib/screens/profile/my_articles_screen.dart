// screens/profile/my_articles_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_event.dart';
import '../../blocs/article/article_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../models/article_model.dart';
import '../../repositories/article_repository.dart';
import '../../utils/app_theme.dart';

class MyArticlesScreen extends StatelessWidget {
  const MyArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BlocProvider(
      create: (_) => ArticleBloc(ArticleRepository())
        ..add(ArticleMyListLoadRequested(authState.userId)),
      child: const _MyArticlesView(),
    );
  }
}

class _MyArticlesView extends StatelessWidget {
  const _MyArticlesView();

  void _confirmDelete(BuildContext context, String id, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Article',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete "$title"? This cannot be undone.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ArticleBloc>().add(ArticleDeleteRequested(id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => context.pop(),
  ),
  title: const Text(
    'My Articles',
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  ),
  actions: [
    Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton.icon(
        onPressed: () => context.push('/articles/create'),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('New Article'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
        ),
      ),
    ),
  ],
),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header

          // Article list
          Expanded(
            child: BlocBuilder<ArticleBloc, ArticleState>(
              builder: (context, state) {
                if (state is ArticleLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ArticleError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(state.message,
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            final auth = context.read<AuthBloc>().state;
                            if (auth is AuthAuthenticated) {
                              context.read<ArticleBloc>().add(
                                    ArticleMyListLoadRequested(auth.userId),
                                  );
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ArticleMyListLoaded) {
                  final articles = state.articles;

                  if (articles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.article_outlined,
                              size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text(
                            'No articles yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Start contributing to the encyclopedia!',
                            style: TextStyle(color: Color(0xFF9CA3AF)),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => context.push('/articles/create'),
                            child: const Text('Write your first article'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: articles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _ArticleCard(
                      article: articles[i],
                      onDelete: (id, title) =>
                          _confirmDelete(context, id, title),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final ArticleModel article;
  final void Function(String id, String title) onDelete;

  const _ArticleCard({required this.article, required this.onDelete});

  String get _title {
    if (article.translations.isNotEmpty) {
      final t = article.translations.firstWhere(
        (t) => t.language == 'english',
        orElse: () => article.translations.first,
      );
      return t.title;
    }
    return article.slug;
  }

  String? get _excerpt {
    if (article.translations.isNotEmpty) {
      final t = article.translations.firstWhere(
        (t) => t.language == 'english',
        orElse: () => article.translations.first,
      );
      return t.excerpt ?? article.excerpt;
    }
    return article.excerpt;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/articles/${article.slug}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusBadge(status: article.status),
                        const SizedBox(width: 8),
                        Text(
                          article.category,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF111827),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_excerpt != null && _excerpt!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _excerpt!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppTheme.greenPrimary,
                tooltip: 'Edit',
                onPressed: () =>
                    context.push('/articles/edit/${article.slug}'),
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: Colors.red[400],
                tooltip: 'Delete',
                onPressed: () => onDelete(article.id, _title),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'published' => (const Color(0xFFD1FAE5), AppTheme.greenDark),
      'draft'     => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      'pending'   => (const Color(0xFFDBEAFE), const Color(0xFF1E40AF)),
      _           => (const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}