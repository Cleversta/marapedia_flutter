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
    context.read<ArticleBloc>().add(ArticleAllLoadRequested());
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
      appBar: AppBar(
        title: const Text(
          '⚙️ Admin Panel',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () => context.pop(),
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
              // Stats
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statCard(
                      '${articles.length}',
                      'Articles',
                      const Color(0xFFEFF6FF),
                      const Color(0xFF1D4ED8),
                    ),
                    _statCard(
                      '$published',
                      'Published',
                      AppTheme.greenBg,
                      AppTheme.greenDark,
                    ),
                    _statCard(
                      '$drafts',
                      'Drafts',
                      const Color(0xFFFEF3C7),
                      const Color(0xFF92400E),
                    ),
                    _statCard(
                      '${_users.length}',
                      'Users',
                      const Color(0xFFF5F3FF),
                      const Color(0xFF6D28D9),
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
                    _tabBtn('articles', 'Articles'),
                    _tabBtn('users', 'Users (${_users.length})'),
                  ],
                ),
              ),

              // Content
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

  Widget _buildArticles(ArticleState state) {
    if (state is ArticleLoading)
      return const Center(child: CircularProgressIndicator());
    if (state is! ArticleAllLoaded) return const Center(child: Text('No data'));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: state.articles.length,
      itemBuilder: (_, i) {
        final article = state.articles[i];
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
                      onTap: () => context.push('/articles/${article.slug}'),
                      child: Text(
                        t?.title ?? 'Untitled',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: article.status == 'published'
                          ? AppTheme.greenBg
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      article.status,
                      style: TextStyle(
                        fontSize: 10,
                        color: article.status == 'published'
                            ? AppTheme.greenDark
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${article.profile?.username ?? 'Unknown'} · ${Helpers.timeAgo(article.createdAt)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (article.status != 'published')
                    _actionBtn(
                      'Publish',
                      AppTheme.greenPrimary,
                      Colors.white,
                      () => context.read<ArticleBloc>().add(
                        ArticlePublishRequested(article.id, true),
                      ),
                    ),
                  if (article.status == 'published')
                    _actionBtn(
                      'Unpublish',
                      Colors.white,
                      Colors.grey[700]!,
                      () => context.read<ArticleBloc>().add(
                        ArticlePublishRequested(article.id, false),
                      ),
                      border: true,
                    ),
                  const SizedBox(width: 6),
                  _actionBtn(
                    article.featured ? '★ Unfeature' : '☆ Feature',
                    article.featured ? const Color(0xFFFFFBEB) : Colors.white,
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
                  const Spacer(),
                  _actionBtn(
                    'Delete',
                    Colors.red[50]!,
                    Colors.red[600]!,
                    () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete article?'),
                          content: const Text('This cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsers() {
    if (_loadingUsers) return const Center(child: CircularProgressIndicator());
    final myId = (context.read<AuthBloc>().state as AuthAuthenticated).userId;
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _users.length,
      itemBuilder: (_, i) {
        final user = _users[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.greenLight,
                child: Text(
                  user.username[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.greenDark,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user.fullName ?? '',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: user.isAdmin
                      ? const Color(0xFFF3E8FF)
                      : user.isEditor
                      ? const Color(0xFFEFF6FF)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.role,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: user.isAdmin
                        ? const Color(0xFF7C3AED)
                        : user.isEditor
                        ? const Color(0xFF1D4ED8)
                        : Colors.grey[600],
                  ),
                ),
              ),
              if (user.id != myId) ...[
                const SizedBox(width: 6),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Colors.grey,
                  ),
                  onSelected: (role) => _setRole(user.id, role),
                  itemBuilder: (_) => [
                    if (user.role != 'member')
                      const PopupMenuItem(
                        value: 'member',
                        child: Text('Set as Member'),
                      ),
                    if (user.role != 'editor')
                      const PopupMenuItem(
                        value: 'editor',
                        child: Text('Set as Editor'),
                      ),
                    if (user.role != 'admin')
                      const PopupMenuItem(
                        value: 'admin',
                        child: Text('Set as Admin'),
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

  Widget _statCard(String value, String label, Color bg, Color fg) => Container(
    width: (MediaQuery.of(context).size.width - 48) / 2,
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
        Text(label, style: TextStyle(fontSize: 12, color: fg.withOpacity(0.7))),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
