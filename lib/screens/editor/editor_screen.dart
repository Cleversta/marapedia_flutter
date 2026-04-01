import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_event.dart';
import '../../blocs/article/article_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  String _tab = 'drafts';

  @override
  void initState() {
    super.initState();
    context.read<ArticleBloc>().add(ArticleAllLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated || !authState.profile.isEditor) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Access denied')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '✏️ Editor Panel',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<ArticleBloc, ArticleState>(
        builder: (context, state) {
          if (state is ArticleLoading)
            return const Center(child: CircularProgressIndicator());
          if (state is! ArticleAllLoaded)
            return const Center(child: Text('Error'));

          final drafts = state.articles
              .where((a) => a.status == 'draft')
              .toList();
          final published = state.articles
              .where((a) => a.status == 'published')
              .toList();

          return Column(
            children: [
              // Stats
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _statCard(
                      '${drafts.length}',
                      'Pending',
                      const Color(0xFFFEF3C7),
                      const Color(0xFF92400E),
                    ),
                    const SizedBox(width: 10),
                    _statCard(
                      '${published.length}',
                      'Published',
                      AppTheme.greenBg,
                      AppTheme.greenDark,
                    ),
                  ],
                ),
              ),

              // Tabs
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    _tabBtn('drafts', 'Pending (${drafts.length})'),
                    _tabBtn('published', 'Published (${published.length})'),
                  ],
                ),
              ),

              // List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _tab == 'drafts'
                      ? drafts.length
                      : published.length,
                  itemBuilder: (_, i) {
                    final article = _tab == 'drafts' ? drafts[i] : published[i];
                    final t = article.translations.firstWhere(
                      (t) => t.language == 'english',
                      orElse: () => article.translations.isNotEmpty
                          ? article.translations.first
                          : article.translations.first,
                    );
                    final cat = Helpers.getCategoryInfo(article.category);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                cat?['icon'] ?? '',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      context.push('/articles/${article.slug}'),
                                  child: Text(
                                    t.title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'By ${article.profile?.username ?? 'Unknown'} · ${Helpers.timeAgo(article.createdAt)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (_tab == 'drafts')
                                _actionBtn(
                                  'Publish',
                                  AppTheme.greenPrimary,
                                  Colors.white,
                                  () {
                                    context.read<ArticleBloc>().add(
                                      ArticlePublishRequested(article.id, true),
                                    );
                                  },
                                ),
                              if (_tab == 'published') ...[
                                _actionBtn(
                                  'Unpublish',
                                  Colors.white,
                                  Colors.grey[700]!,
                                  () {
                                    context.read<ArticleBloc>().add(
                                      ArticlePublishRequested(
                                        article.id,
                                        false,
                                      ),
                                    );
                                  },
                                  border: true,
                                ),
                                const SizedBox(width: 6),
                                _actionBtn(
                                  article.featured
                                      ? '★ Unfeature'
                                      : '☆ Feature',
                                  article.featured
                                      ? const Color(0xFFFFFBEB)
                                      : Colors.white,
                                  article.featured
                                      ? const Color(0xFFD97706)
                                      : Colors.grey[600]!,
                                  () => context.read<ArticleBloc>().add(
                                    ArticleFeatureToggleRequested(
                                      article.id,
                                      article.featured,
                                    ),
                                  ),
                                  border: true,
                                ),
                              ],
                              const Spacer(),
                              _actionBtn(
                                'Edit',
                                Colors.white,
                                Colors.grey[700]!,
                                () => context.push(
                                  '/articles/edit/${article.slug}',
                                ),
                                border: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(String value, String label, Color bg, Color fg) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: fg.withOpacity(0.7)),
          ),
        ],
      ),
    ),
  );

  Widget _tabBtn(String key, String label) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _tab = key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _tab == key ? AppTheme.greenPrimary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _tab == key ? AppTheme.greenPrimary : Colors.grey[400],
          ),
        ),
      ),
    ),
  );

  Widget _actionBtn(
    String label,
    Color bg,
    Color fg,
    VoidCallback onTap, {
    bool border = false,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: border ? Border.all(color: const Color(0xFFE5E7EB)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    ),
  );
}
