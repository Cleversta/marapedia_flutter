import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_event.dart';
import '../../blocs/article/article_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../models/article_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/article_card.dart';
import '../../widgets/category_tabs.dart';
import '../../widgets/shimmer_card.dart';
import '../../widgets/marapedia_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCategory;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload home whenever we return to this screen
    // but skip if already loaded to avoid unnecessary fetches
    final state = context.read<ArticleBloc>().state;
    if (state is! ArticleHomeLoaded) {
      context.read<ArticleBloc>().add(ArticleHomeLoadRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.stone50,
      appBar: const MarapediaAppBar(),
      body: Column(
        children: [
          // Category tabs
          CategoryTabs(
            selected: _selectedCategory,
            onTap: (cat) {
              if (cat == 'photos') {
                context.push('/photos');
                return;
              }
              setState(() => _selectedCategory = cat);
              context.push('/category/$cat');
            },
          ),
          Expanded(
            child: BlocBuilder<ArticleBloc, ArticleState>(
              builder: (context, state) {
                if (state is ArticleLoading) {
                  return const SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: ShimmerList(count: 4),
                  );
                }
                if (state is ArticleHomeLoaded) {
                  return _buildHome(context, state);
                }
                if (state is ArticleError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.message,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<ArticleBloc>().add(
                            ArticleHomeLoadRequested(),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                // Any other state (ArticleDetailLoaded etc) — show loading
                // while didChangeDependencies triggers a reload
                return const SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: ShimmerList(count: 4),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return FloatingActionButton.extended(
              onPressed: () => context.push('/articles/create'),
              backgroundColor: AppTheme.greenPrimary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Contribute',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHome(BuildContext context, ArticleHomeLoaded state) {
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<ArticleBloc>().add(ArticleHomeLoadRequested()),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(context, state),
            const SizedBox(height: 16),

            if (state.featured != null) ...[
              _sectionHeader('Featured Article'),
              _buildFeatured(context, state),
              const SizedBox(height: 20),
            ],

            _sectionHeader('Recent Articles'),
            _buildGrid(context, state.recent),

            if (state.mostViewed.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionHeader('Most Viewed'),
              _buildGrid(context, state.mostViewed),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, ArticleHomeLoaded state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFf0fdf4), Colors.white, Color(0xFFFFFBEB)],
        ),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        children: [
          const Text(
            'The Free Mara Encyclopedia',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.greenPrimary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Preserving Mara\nHistory & Culture',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF052e16),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A community-built encyclopedia for the Mara people.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: ['Mara', 'English', 'Myanmar', 'Mizo']
                .map(
                  (lang) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppTheme.greenLight),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      lang,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.greenDark,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _statItem('${state.articleCount}', 'Articles'),
                Container(width: 1, height: 40, color: const Color(0xFFE5E7EB)),
                _statItem('${state.userCount}', 'Contributors'),
                Container(width: 1, height: 40, color: const Color(0xFFE5E7EB)),
                _statItem('4', 'Languages'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.greenPrimary,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
      ],
    ),
  );

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.greenPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ],
    ),
  );

  Widget _buildFeatured(BuildContext context, ArticleHomeLoaded state) {
    final article = state.featured!;
    final t = Helpers.getPreferredTranslation(
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
    if (t == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push('/articles/${article.slug}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              if (article.thumbnailUrl != null &&
                  article.thumbnailUrl!.isNotEmpty)
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: article.thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey[100]),
                    errorWidget: (_, __, ___) =>
                        Container(color: Colors.grey[100]),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.greenBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '✦ Featured',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.greenDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t['title'] as String? ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t['excerpt'] as String? ??
                          Helpers.makeExcerpt(
                            t['content'] as String? ?? '',
                            length: 200,
                          ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'By ${article.profile?.username ?? 'Anonymous'} · '
                      '${Helpers.timeAgo(article.updatedAt ?? article.createdAt)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<ArticleModel> articles) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: articles
            .map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ArticleCard(article: a),
              ),
            )
            .toList(),
      ),
    );
  }
}
