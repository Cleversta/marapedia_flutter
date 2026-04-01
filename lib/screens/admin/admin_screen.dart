import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marapedia_flutter/models/article_translation_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_event.dart';
import '../../blocs/article/article_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../models/profile_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String _tab = 'articles';
  List<ProfileModel> _users = [];
  bool _loadingUsers = false;

  @override
  void initState() {
    super.initState();
    // ArticleAllLoadRequested is fired by the router's BlocProvider — do NOT fire it here
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    final res = await Supabase.instance.client
        .from('profiles')
        .select('*')
        .order('created_at', ascending: false);
    setState(() {
      _users = (res as List)
          .map((j) => ProfileModel.fromJson(Map<String, dynamic>.from(j)))
          .toList();
      _loadingUsers = false;
    });
  }

  Future<void> _setRole(String userId, String role) async {
    await Supabase.instance.client
        .from('profiles')
        .update({'role': role})
        .eq('id', userId);
    setState(() {
      _users = _users
          .map((u) => u.id == userId ? u.copyWith(role: role) : u)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated || !authState.profile.isAdmin) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Admin access only')),
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
          'Admin Panel',
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
          final articles = state is ArticleAllLoaded ? state.articles : [];
          final drafts = articles.where((a) => a.status == 'draft').length;
          final published = articles
              .where((a) => a.status == 'published')
              .length;

          return Column(
            children: [
              _buildStats(articles.length, published, drafts),
              _buildTabBar(),
              Expanded(
                child: _tab == 'articles'
                    ? _buildArticles(state)
                    : _buildUsers(),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Stats ─────────────────────────────────────────────────────────────────────
  Widget _buildStats(int total, int published, int drafts) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          _statCard(
            value: '$total',
            label: 'Articles',
            valueColor: const Color(0xFF1A1A2E),
            icon: Icons.article_outlined,
            iconColor: const Color(0xFF6366F1),
            iconBg: const Color(0xFFEEF2FF),
          ),
          const SizedBox(width: 10),
          _statCard(
            value: '$published',
            label: 'Published',
            valueColor: const Color(0xFF1A1A2E),
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF16A34A),
            iconBg: const Color(0xFFDCFCE7),
          ),
          const SizedBox(width: 10),
          _statCard(
            value: '$drafts',
            label: 'Drafts',
            valueColor: const Color(0xFF1A1A2E),
            icon: Icons.edit_note_outlined,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
          ),
          const SizedBox(width: 10),
          _statCard(
            value: '${_users.length}',
            label: 'Users',
            valueColor: const Color(0xFF1A1A2E),
            icon: Icons.people_outline,
            iconColor: const Color(0xFF7C3AED),
            iconBg: const Color(0xFFF3E8FF),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String value,
    required String label,
    required Color valueColor,
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: valueColor,
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
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              _tabBtn('articles', 'Articles'),
              _tabBtn('users', 'Users (${_users.length})'),
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

  // ── Articles ──────────────────────────────────────────────────────────────────
  Widget _buildArticles(ArticleState state) {
    if (state is ArticleLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is! ArticleAllLoaded) {
      return const Center(child: Text('No data'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: state.articles.length,
      itemBuilder: (_, i) {
        final article = state.articles[i];
        final isPublished = article.status == 'published';
        final t = article.translations
            .cast<ArticleTranslationModel?>()
            .firstWhere(
              (t) => t?.language == 'english',
              orElse: () => article.translations.isNotEmpty
                  ? article.translations.first
                  : null,
            );
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
                    _statusBadge(isPublished),
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
                    if (!isPublished)
                      _actionChip(
                        label: 'Publish',
                        fg: const Color(0xFF16A34A),
                        bg: const Color(0xFFDCFCE7),
                        border: const Color(0xFFBBF7D0),
                        onTap: () => context.read<ArticleBloc>().add(
                          ArticlePublishRequested(article.id, true),
                        ),
                      ),
                    if (isPublished)
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
                    const Spacer(),
                    _actionChip(
                      label: 'Delete',
                      fg: const Color(0xFFDC2626),
                      bg: const Color(0xFFFEF2F2),
                      border: const Color(0xFFFECACA),
                      onTap: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text(
                              'Delete article?',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            content: const Text(
                              'This action cannot be undone.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Color(0xFF6B7280)),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (ok == true && mounted) {
                          context.read<ArticleBloc>().add(
                            ArticleDeleteRequested(article.id),
                          );
                        }
                      },
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

  // ── Users ─────────────────────────────────────────────────────────────────────
  Widget _buildUsers() {
    if (_loadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }
    final myId = (context.read<AuthBloc>().state as AuthAuthenticated).userId;

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _users.length,
      itemBuilder: (_, i) {
        final user = _users[i];

        final roleColor = user.isAdmin
            ? const Color(0xFF7C3AED)
            : user.isEditor
            ? const Color(0xFF1D4ED8)
            : const Color(0xFF6B7280);
        final roleBg = user.isAdmin
            ? const Color(0xFFF3E8FF)
            : user.isEditor
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFF3F4F6);
        final roleBorder = user.isAdmin
            ? const Color(0xFFDDD6FE)
            : user.isEditor
            ? const Color(0xFFBFDBFE)
            : const Color(0xFFE5E7EB);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: roleBg,
                child: Text(
                  user.username[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: roleColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    if ((user.fullName ?? '').isNotEmpty)
                      Text(
                        user.fullName!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: roleBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: roleBorder),
                ),
                child: Text(
                  user.role,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: roleColor,
                  ),
                ),
              ),
              if (user.id != myId) ...[
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE8E8EC)),
                  ),
                  icon: const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Color(0xFF9CA3AF),
                  ),
                  onSelected: (role) => _setRole(user.id, role),
                  itemBuilder: (_) => [
                    if (user.role != 'member')
                      const PopupMenuItem(
                        value: 'member',
                        child: Text(
                          'Set as Member',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    if (user.role != 'editor')
                      const PopupMenuItem(
                        value: 'editor',
                        child: Text(
                          'Set as Editor',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    if (user.role != 'admin')
                      const PopupMenuItem(
                        value: 'admin',
                        child: Text(
                          'Set as Admin',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
