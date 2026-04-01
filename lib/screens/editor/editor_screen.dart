import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_event.dart';
import '../../blocs/article/article_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../models/article_translation_model.dart';
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
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated || !authState.profile.isEditor) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Access denied')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 16,
            color: Color(0xFF1A1A2E),
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Editor Panel',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8E8EC)),
        ),
      ),
      body: BlocBuilder<ArticleBloc, ArticleState>(
        builder: (context, state) {
          if (state is ArticleLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is! ArticleAllLoaded) {
            return const Center(child: Text('Error'));
          }

          final drafts = state.articles
              .where((a) => a.status == 'draft')
              .toList();
          final published = state.articles
              .where((a) => a.status == 'published')
              .toList();
          final featured = state.articles.where((a) => a.featured).toList();

          return Column(
            children: [
              _buildStats(drafts.length, published.length, featured.length),
              _buildTabBar(drafts.length, published.length),
              Expanded(
                child: _buildArticleList(
                  _tab == 'drafts' ? drafts : published,
                  isDraft: _tab == 'drafts',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Stats ─────────────────────────────────────────────────────────────────────
  Widget _buildStats(int drafts, int published, int featured) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          _statCard(
            value: '$drafts',
            label: 'Pending',
            icon: Icons.pending_actions_outlined,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
          ),
          const SizedBox(width: 10),
          _statCard(
            value: '$published',
            label: 'Published',
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF16A34A),
            iconBg: const Color(0xFFDCFCE7),
          ),
          const SizedBox(width: 10),
          _statCard(
            value: '$featured',
            label: 'Featured',
            icon: Icons.star_outline_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String value,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E8EC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
                letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────────────────────
  Widget _buildTabBar(int drafts, int published) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              _tabBtn('drafts', 'Pending ($drafts)'),
              _tabBtn('published', 'Published ($published)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String key, String label) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _tab = key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _tab == key
                  ? AppTheme.greenPrimary
                  : const Color(0xFFE8E8EC),
              width: _tab == key ? 2 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: _tab == key ? FontWeight.w700 : FontWeight.w400,
            color: _tab == key
                ? AppTheme.greenPrimary
                : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    ),
  );

  // ── Article List ──────────────────────────────────────────────────────────────
  Widget _buildArticleList(List articles, {required bool isDraft}) {
    if (articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8E8EC)),
              ),
              child: Icon(
                isDraft
                    ? Icons.pending_actions_outlined
                    : Icons.check_circle_outline,
                size: 26,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isDraft ? 'No pending articles' : 'No published articles',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: articles.length,
      itemBuilder: (_, i) {
        final article = articles[i];
        ArticleTranslationModel? t;
        if (article.translations.isNotEmpty) {
          for (final tr in article.translations) {
            if (tr.language == 'english') {
              t = tr;
              break;
            }
          }
          t ??= article.translations.first;
        }
        final cat = Helpers.getCategoryInfo(article.category);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8E8EC)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon box
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F5F7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE8E8EC)),
                      ),
                      child: Center(
                        child: Text(
                          cat?['icon'] ?? '📄',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title + meta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                context.push('/articles/${article.slug}'),
                            child: Text(
                              t?.title ?? 'Untitled',

                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E),
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${article.profile?.username ?? 'Unknown'}  ·  ${Helpers.timeAgo(article.createdAt)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status badge
                    _statusBadge(!isDraft),
                  ],
                ),
              ),

              // Divider
              Container(height: 1, color: const Color(0xFFF0F0F4)),

              // Action row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    if (isDraft)
                      _actionChip(
                        label: 'Publish',
                        fg: const Color(0xFF16A34A),
                        bg: const Color(0xFFDCFCE7),
                        border: const Color(0xFFBBF7D0),
                        onTap: () => context.read<ArticleBloc>().add(
                          ArticlePublishRequested(article.id, true),
                        ),
                      ),
                    if (!isDraft) ...[
                      _actionChip(
                        label: 'Unpublish',
                        fg: const Color(0xFF6B7280),
                        bg: const Color(0xFFF3F4F6),
                        border: const Color(0xFFE5E7EB),
                        onTap: () => context.read<ArticleBloc>().add(
                          ArticlePublishRequested(article.id, false),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _actionChip(
                        label: article.featured ? '★ Unfeature' : '☆ Feature',
                        fg: const Color(0xFFD97706),
                        bg: const Color(0xFFFEF3C7),
                        border: const Color(0xFFFDE68A),
                        onTap: () => context.read<ArticleBloc>().add(
                          ArticleFeatureToggleRequested(
                            article.id,
                            article.featured,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    _actionChip(
                      label: 'Edit',
                      fg: const Color(0xFF1D4ED8),
                      bg: const Color(0xFFEFF6FF),
                      border: const Color(0xFFBFDBFE),
                      onTap: () =>
                          context.push('/articles/edit/${article.slug}'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusBadge(bool isPublished) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPublished ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPublished
              ? const Color(0xFFBBF7D0)
              : const Color(0xFFFDE68A),
        ),
      ),
      child: Text(
        isPublished ? 'Published' : 'Draft',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isPublished
              ? const Color(0xFF16A34A)
              : const Color(0xFFD97706),
        ),
      ),
    );
  }

  Widget _actionChip({
    required String label,
    required Color fg,
    required Color bg,
    required Color border,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}
